-- 逾時釋放加 2 小時安全緩衝，避免與綠界繳費期限貼太緊。
--
-- 綠界端 ExpireDate = 3 天（顧客付款體驗不變）。若我們也剛好在第 3 天釋放預留，
-- 兩者時間貼齊時，理論上可能出現「釋放後綠界的遲到付款才到」→ out_of_stock。
-- 把釋放時間延後到 placed_at + 3 天 2 小時，讓綠界一定先關閉繳費，
-- 使 out_of_stock（收款成立但缺貨）在實務上不會發生。
-- 僅調整判定間隔，其餘邏輯不變。

create or replace function public.expire_unpaid_orders()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  expiring_ids uuid[];
begin
  select array_agg(id)
  into expiring_ids
  from (
    select id
    from public.orders
    where payment_status = 'unpaid'
      and placed_at < now() - interval '3 days 2 hours'
    for update skip locked
  ) locked;

  if expiring_ids is null then
    return 0;
  end if;

  update public.inventory i
  set reserved_quantity = greatest(0, i.reserved_quantity - oi.quantity)
  from public.order_items oi
  where oi.order_id = any(expiring_ids)
    and oi.product_id = i.product_id;

  update public.orders
  set payment_status = 'expired', order_status = 'cancelled', updated_at = now()
  where id = any(expiring_ids);

  return array_length(expiring_ids, 1);
end;
$$;
