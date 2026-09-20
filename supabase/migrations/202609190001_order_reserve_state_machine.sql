-- 訂單／付款／庫存狀態機重構：預留式庫存（reserve）+ 先到先贏 + 三天逾時釋放 + 綠界付款認帳
--
-- 設計重點：
--   1. 下單當下「預留」庫存（reserved_quantity += 數量），不動實體在庫 quantity。
--      可售量 = quantity - reserved_quantity。
--   2. 併發搶貨用資料庫列鎖（for update）保證「先到伺服器的訂單先贏」，
--      後到而庫存不足者整筆訂單失敗，並回報是「哪一個」商品缺貨。
--   3. 綠界付款成功（callback）才把預留結清成實際售出（quantity -= 數量、reserved_quantity -= 數量）。
--   4. 三天未付款由排程釋放預留、訂單標記逾時取消，紀錄保留（不刪除）。
--   5. 極少數「逾時取消後才收到的遲到付款」：一律認帳，有貨復活、沒貨標記缺貨待退款。

-- ── 一、擴充狀態值 ────────────────────────────────────────────────
-- payment_status 新增 expired（逾時未付）
alter table public.orders drop constraint if exists orders_payment_status_check;
alter table public.orders
  add constraint orders_payment_status_check
  check (payment_status in ('unpaid', 'paid', 'failed', 'refunded', 'expired'));

-- order_status 新增 cancelled（取消）、out_of_stock（已付款但缺貨待退款）
alter table public.orders drop constraint if exists orders_order_status_check;
alter table public.orders
  add constraint orders_order_status_check
  check (order_status in ('created', 'shipping', 'received', 'cancelled', 'out_of_stock'));


-- ── 二、下單：預留庫存（含先到先贏列鎖與結構化缺貨回報） ─────────────
drop function if exists public.create_order_from_cart(text, text, text, text);

create or replace function public.create_order_from_cart(
  p_recipient_name text default null,
  p_recipient_phone text default null,
  p_shipping_address text default null,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_order_id uuid;
  computed_subtotal numeric(10, 2);
  unavailable_name text;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
    from public.cart_items
    where user_id = current_user_id
      and selected = true
  ) then
    raise exception 'No selected cart items';
  end if;

  -- 先鎖住本次要買到的所有商品庫存列，並「固定用 product_id 排序」上鎖，避免多商品訂單互鎖（deadlock）。
  -- 先到伺服器的交易先拿到列鎖，後到者排隊；等前者 commit 後才重新計算可售量 → 這就是「先到先贏」。
  perform 1
  from public.inventory i
  where i.product_id in (
    select ci.product_id
    from public.cart_items ci
    where ci.user_id = current_user_id
      and ci.selected = true
  )
  order by i.product_id
  for update;

  -- 拿到鎖之後，找出第一個「下架 / 沒有庫存列 / 可售量不足」的商品名稱，回報給前端（供之後的缺貨彈窗使用）。
  select p.name
  into unavailable_name
  from public.cart_items ci
  join public.products p on p.id = ci.product_id
  left join public.inventory i on i.product_id = p.id
  where ci.user_id = current_user_id
    and ci.selected = true
    and (
      p.status <> 'active'
      or i.product_id is null
      or (i.quantity - i.reserved_quantity) < ci.quantity
    )
  order by p.name
  limit 1;

  if unavailable_name is not null then
    -- 前端以 'OUT_OF_STOCK:' 前綴辨識並顯示是哪個商品缺貨。
    raise exception 'OUT_OF_STOCK:%', unavailable_name;
  end if;

  -- 訂單金額一律由伺服器端重算，不信任前端。
  select coalesce(sum(p.price * ci.quantity), 0)
  into computed_subtotal
  from public.cart_items ci
  join public.products p on p.id = ci.product_id
  where ci.user_id = current_user_id
    and ci.selected = true
    and p.status = 'active';

  insert into public.orders (
    user_id, payment_status, order_status,
    subtotal, shipping_fee, discount_amount, total,
    recipient_name, recipient_phone, shipping_address, note
  )
  values (
    current_user_id, 'unpaid', 'created',
    computed_subtotal, 0, 0, computed_subtotal,
    p_recipient_name, p_recipient_phone, p_shipping_address, p_note
  )
  returning id into new_order_id;

  insert into public.order_items (
    order_id, product_id, product_name, product_image_url,
    unit_price, quantity, line_total
  )
  select
    new_order_id, p.id, p.name, primary_image.image_url,
    p.price, ci.quantity, p.price * ci.quantity
  from public.cart_items ci
  join public.products p on p.id = ci.product_id
  left join lateral (
    select pi.image_url
    from public.product_images pi
    where pi.product_id = p.id
    order by pi.is_primary desc, pi.sort_order asc
    limit 1
  ) primary_image on true
  where ci.user_id = current_user_id
    and ci.selected = true
    and p.status = 'active';

  -- 預留庫存：只加 reserved_quantity，不動實體在庫 quantity。
  update public.inventory i
  set reserved_quantity = i.reserved_quantity + ci.quantity
  from public.cart_items ci
  where ci.user_id = current_user_id
    and ci.selected = true
    and ci.product_id = i.product_id;

  -- 清掉已結帳的購物車項目。
  delete from public.cart_items
  where user_id = current_user_id
    and selected = true;

  return new_order_id;
end;
$$;

grant execute on function public.create_order_from_cart(text, text, text, text) to authenticated;


-- ── 三、付款成功：把預留結清成實際售出（幂等、可處理遲到付款） ──────────
-- 由 ecpay-callback（service_role 身分）呼叫。回傳處理結果字串：
--   'paid'            正常付款、庫存已結清
--   'already_paid'    已處理過（綠界重送通知時的幂等回應）
--   'paid_out_of_stock' 遲到付款、貨已被搶走 → 收款成立但需退款
--   'not_found'       查無訂單
--   'refunded'        訂單已退款，不再處理
create or replace function public.mark_order_paid(p_order_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  insufficient boolean;
begin
  -- 鎖住訂單列：與逾時排程 / 綠界重送通知互斥，確保只結清一次。
  select payment_status
  into v_status
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    return 'not_found';
  end if;

  if v_status = 'paid' then
    return 'already_paid';
  end if;

  if v_status = 'refunded' then
    return 'refunded';
  end if;

  if v_status = 'expired' then
    -- 遲到付款：預留早已被排程釋放，必須重新確認並直接扣實體在庫。
    perform 1
    from public.inventory i
    where i.product_id in (
      select oi.product_id from public.order_items oi where oi.order_id = p_order_id
    )
    order by i.product_id
    for update;

    select exists (
      select 1
      from public.order_items oi
      join public.inventory i on i.product_id = oi.product_id
      where oi.order_id = p_order_id
        and (i.quantity - i.reserved_quantity) < oi.quantity
    )
    into insufficient;

    if insufficient then
      -- 貨已被別人買走：收款成立，但標記缺貨待退款，交由後續退款流程處理。
      update public.orders
      set payment_status = 'paid', paid_at = now(), order_status = 'out_of_stock', updated_at = now()
      where id = p_order_id;
      return 'paid_out_of_stock';
    end if;

    update public.inventory i
    set quantity = i.quantity - oi.quantity
    from public.order_items oi
    where oi.order_id = p_order_id
      and oi.product_id = i.product_id;

    update public.orders
    set payment_status = 'paid', paid_at = now(), order_status = 'created', updated_at = now()
    where id = p_order_id;
    return 'paid';
  end if;

  -- 正常情況（unpaid / failed）：預留還握著，直接把預留結清成實際售出。
  update public.inventory i
  set quantity = i.quantity - oi.quantity,
      reserved_quantity = greatest(0, i.reserved_quantity - oi.quantity)
  from public.order_items oi
  where oi.order_id = p_order_id
    and oi.product_id = i.product_id;

  update public.orders
  set payment_status = 'paid', paid_at = now(), updated_at = now()
  where id = p_order_id;

  return 'paid';
end;
$$;

grant execute on function public.mark_order_paid(uuid) to service_role;


-- ── 四、三天逾時：釋放預留、標記取消（紀錄保留，不刪除） ──────────────
create or replace function public.expire_unpaid_orders()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  expiring_ids uuid[];
begin
  -- 先鎖住要逾時的訂單列（skip locked：正在付款而被 mark_order_paid 鎖住的訂單本輪先跳過，下輪再處理）。
  select array_agg(id)
  into expiring_ids
  from (
    select id
    from public.orders
    where payment_status = 'unpaid'
      and placed_at < now() - interval '3 days'
    for update skip locked
  ) locked;

  if expiring_ids is null then
    return 0;
  end if;

  -- 釋放這些訂單佔住的預留庫存。
  update public.inventory i
  set reserved_quantity = greatest(0, i.reserved_quantity - oi.quantity)
  from public.order_items oi
  where oi.order_id = any(expiring_ids)
    and oi.product_id = i.product_id;

  -- 訂單標記逾時取消（保留紀錄供對帳／客訴）。
  update public.orders
  set payment_status = 'expired', order_status = 'cancelled', updated_at = now()
  where id = any(expiring_ids);

  return array_length(expiring_ids, 1);
end;
$$;

grant execute on function public.expire_unpaid_orders() to service_role;


-- ── 五、排程：每 10 分鐘掃一次逾時訂單 ───────────────────────────────
-- 需要 Supabase 專案已啟用 pg_cron 擴充。若擴充尚未啟用，本段會失敗，
-- 請先於 Supabase Dashboard → Database → Extensions 開啟 pg_cron 後再套用。
create extension if not exists pg_cron;

do $$
begin
  -- 重複套用時先移除舊排程，避免重複註冊。
  if exists (select 1 from cron.job where jobname = 'expire-unpaid-orders') then
    perform cron.unschedule('expire-unpaid-orders');
  end if;

  perform cron.schedule(
    'expire-unpaid-orders',
    '*/10 * * * *',
    $cron$ select public.expire_unpaid_orders(); $cron$
  );
end;
$$;
