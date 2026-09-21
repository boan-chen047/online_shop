-- 結帳套用限時活動折扣：create_order_from_cart 在後端（權威）依 site_settings.flash_sale
-- 重算每件實付單價，寫入折後的 order_items 與 orders.total/discount_amount。
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
  computed_total numeric(10, 2);
  unavailable_name text;
  -- 限時活動折扣
  v_start timestamptz;
  v_end timestamptz;
  v_discount numeric := 10;
  v_product_ids uuid[] := '{}';
  v_active boolean := false;
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

  -- 找出第一個「下架 / 沒有庫存列 / 可售量不足」的商品名稱。
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
    raise exception 'OUT_OF_STOCK:%', unavailable_name;
  end if;

  -- 讀取限時活動設定（缺值/格式錯 → 視為無折扣）。
  select
    (s.value->>'start')::timestamptz,
    (s.value->>'end')::timestamptz,
    coalesce((s.value->>'discount')::numeric, 10),
    coalesce(
      (select array_agg(x::uuid) from jsonb_array_elements_text(s.value->'product_ids') as x),
      '{}'::uuid[]
    )
  into v_start, v_end, v_discount, v_product_ids
  from public.site_settings s
  where s.key = 'flash_sale';

  if v_discount is null or v_discount <= 0 or v_discount > 10 then
    v_discount := 10;
  end if;

  v_active := v_start is not null and v_end is not null
    and now() >= v_start and now() < v_end and v_discount < 10;

  -- 訂單金額一律由伺服器端重算，不信任前端。
  -- 原價小計、折後總額（折扣只套在「活動中的活動商品」）。
  select
    coalesce(sum(p.price * ci.quantity), 0),
    coalesce(sum(
      (case when v_active and p.id = any(v_product_ids)
            then round(p.price * v_discount / 10)
            else p.price end) * ci.quantity
    ), 0)
  into computed_subtotal, computed_total
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
    computed_subtotal, 0, computed_subtotal - computed_total, computed_total,
    p_recipient_name, p_recipient_phone, p_shipping_address, p_note
  )
  returning id into new_order_id;

  insert into public.order_items (
    order_id, product_id, product_name, product_image_url,
    unit_price, quantity, line_total
  )
  select
    new_order_id, p.id, p.name, primary_image.image_url,
    (case when v_active and p.id = any(v_product_ids)
          then round(p.price * v_discount / 10)
          else p.price end),
    ci.quantity,
    (case when v_active and p.id = any(v_product_ids)
          then round(p.price * v_discount / 10)
          else p.price end) * ci.quantity
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
