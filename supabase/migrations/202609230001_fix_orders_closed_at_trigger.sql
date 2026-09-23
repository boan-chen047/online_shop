-- 修正：正式庫的 public.orders 缺少 base schema 應有的兩個 trigger
-- （set_order_closed_at_on_received、set_orders_updated_at）。
-- 造成訂單變 received 時 closed_at 未被設定 → 顧客端「確認完成（提前結束鑑賞期）」
-- 按鈕永遠不出現、鑑賞期也不會自動完結。這裡補齊函式與 trigger，並回填卡住的訂單。

-- 1) 進入 received 時，自動設定 received_at 與 7 天鑑賞期截止 closed_at
create or replace function public.set_order_closed_at()
returns trigger
language plpgsql
as $$
begin
  if new.order_status = 'received' and old.order_status is distinct from 'received' then
    new.received_at = coalesce(new.received_at, now());
    new.closed_at = coalesce(new.closed_at, new.received_at + interval '7 days');
  end if;

  return new;
end;
$$;

drop trigger if exists set_order_closed_at_on_received on public.orders;
create trigger set_order_closed_at_on_received
before update on public.orders
for each row
execute function public.set_order_closed_at();

-- 2) 補回 updated_at 自動更新 trigger（函式 set_updated_at 已存在，只缺 trigger）
drop trigger if exists set_orders_updated_at on public.orders;
create trigger set_orders_updated_at
before update on public.orders
for each row
execute function public.set_updated_at();

-- 3) 回填：已是 received 但 closed_at 仍為 NULL 的既有訂單。
--    received_at 取現有值 → 否則用 updated_at → 再否則 placed_at；closed_at = received_at + 7 天。
update public.orders
set
  received_at = coalesce(received_at, updated_at, placed_at),
  closed_at = coalesce(received_at, updated_at, placed_at) + interval '7 days'
where order_status = 'received'
  and closed_at is null;
