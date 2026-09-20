-- 逾時釋放緩衝由 2 小時調整為 12 小時。
--
-- 綠界官方：ATM 虛擬帳號／超商代碼的付款結果通知「最晚於付款日後 1 天內」更新
-- （多數幾分鐘~幾小時，1 天是少數銀行批次結算的天花板）。
-- 實務做法：抓一個涵蓋絕大多數延遲的緩衝（此處 12 小時），庫存最多鎖 ~3.5 天；
-- 剩下極罕見的尾端（最後一刻繳費 + 滿 1 天延遲）落到 out_of_stock，由客服在綠界後台手動退刷。
-- 綠界 ExpireDate 仍為 3 天，顧客付款窗口不變。僅調整判定間隔。

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
      and placed_at < now() - interval '3 days 12 hours'
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
