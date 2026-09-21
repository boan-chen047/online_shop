-- 熱銷商品排行：聚合已付款訂單的銷量，回傳上架商品的 product_id 與售出數量。
-- 用 security definer 讓首頁 anon 也能取得排行（order_items 本身有 RLS，只回自己的訂單）。
create or replace function public.top_selling_products(limit_count int default 8)
returns table (product_id uuid, sold bigint)
language sql
security definer
set search_path = public
as $$
  select oi.product_id, sum(oi.quantity)::bigint as sold
  from public.order_items oi
  join public.orders o on o.id = oi.order_id
  join public.products p on p.id = oi.product_id
  where o.payment_status = 'paid'
    and p.status = 'active'
    and oi.product_id is not null
  group by oi.product_id
  order by sold desc
  limit limit_count;
$$;

grant execute on function public.top_selling_products(int) to anon, authenticated;
