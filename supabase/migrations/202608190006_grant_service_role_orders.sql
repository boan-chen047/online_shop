-- 先前的 migration 只把 orders/order_items 的權限 grant 給 anon/authenticated，
-- 漏了 service_role，導致 Edge Function（ecpay-callback）以 service_role 更新訂單時
-- 出現 42501 permission denied。這裡補上 service_role 的資料表權限。
-- （service_role 具 BYPASSRLS，但仍需資料表層級的 GRANT。）

grant select, insert, update, delete on public.orders to service_role;
grant select, insert, update, delete on public.order_items to service_role;
