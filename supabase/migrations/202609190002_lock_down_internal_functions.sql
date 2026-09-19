-- 收回內部函式的 PUBLIC 執行權限。
--
-- Postgres 對函式預設把 EXECUTE 授予 PUBLIC，導致以下兩個「僅供伺服器端呼叫」的
-- SECURITY DEFINER 函式，會透過 PostgREST 暴露成 /rest/v1/rpc/... 讓 anon / authenticated
-- 也能呼叫。其中 mark_order_paid 若被一般使用者呼叫，等於可把任意訂單標記為已付款、免付款取貨。
-- 這兩個函式只應由 service_role（綠界 callback、pg_cron）呼叫，故收回 PUBLIC 權限。

revoke all on function public.mark_order_paid(uuid) from public;
revoke all on function public.mark_order_paid(uuid) from anon;
revoke all on function public.mark_order_paid(uuid) from authenticated;
grant execute on function public.mark_order_paid(uuid) to service_role;

revoke all on function public.expire_unpaid_orders() from public;
revoke all on function public.expire_unpaid_orders() from anon;
revoke all on function public.expire_unpaid_orders() from authenticated;
grant execute on function public.expire_unpaid_orders() to service_role;

-- create_order_from_cart 仍由 authenticated 呼叫（結帳流程所需），其內部以 auth.uid() 綁定
-- 使用者本人，anon 呼叫會直接被擋，故僅收回 anon、匿名多餘權限，保留 authenticated。
revoke all on function public.create_order_from_cart(text, text, text, text) from public;
revoke all on function public.create_order_from_cart(text, text, text, text) from anon;
grant execute on function public.create_order_from_cart(text, text, text, text) to authenticated;
