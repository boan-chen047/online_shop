-- 正式環境的 orders/order_items 缺少顧客自己的讀取 policy（只剩 admin 的），
-- 導致顧客在「我的訂單」看不到自己的訂單。這裡補回 202605120002 應有的顧客 policy。

drop policy if exists "orders_select_own" on public.orders;
create policy "orders_select_own"
on public.orders
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "order_items_select_own_orders" on public.order_items;
create policy "order_items_select_own_orders"
on public.order_items
for select
to authenticated
using (
  exists (
    select 1 from public.orders
    where orders.id = order_items.order_id
      and orders.user_id = auth.uid()
  )
);
