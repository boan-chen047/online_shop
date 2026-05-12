grant usage on schema public to anon, authenticated;

grant select on public.categories to anon, authenticated;
grant select on public.products to anon, authenticated;
grant select on public.product_images to anon, authenticated;
grant select on public.product_specs to anon, authenticated;

drop policy if exists "categories_public_read_active" on public.categories;
create policy "categories_public_read_active"
on public.categories
for select
to anon, authenticated
using (is_active = true);

drop policy if exists "products_public_read_active" on public.products;
create policy "products_public_read_active"
on public.products
for select
to anon, authenticated
using (status = 'active');

drop policy if exists "product_images_public_read_active_products" on public.product_images;
create policy "product_images_public_read_active_products"
on public.product_images
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.products
    where products.id = product_images.product_id
      and products.status = 'active'
  )
);

drop policy if exists "product_specs_public_read_active_products" on public.product_specs;
create policy "product_specs_public_read_active_products"
on public.product_specs
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.products
    where products.id = product_specs.product_id
      and products.status = 'active'
  )
);
