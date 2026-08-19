grant select on public.inventory to anon, authenticated;

drop policy if exists "inventory_read_active_products" on public.inventory;
create policy "inventory_read_active_products"
on public.inventory
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.products
    where products.id = inventory.product_id
      and products.status = 'active'
  )
);
