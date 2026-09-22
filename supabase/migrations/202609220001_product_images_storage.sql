-- 商品圖片 Storage bucket（公開讀、admin 寫）
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

-- 確保 product_images 表寫入權限（RLS product_images_admin_manage 已用 is_admin 把關）
grant select, insert, update, delete on public.product_images to authenticated;

drop policy if exists "product_images_storage_public_read" on storage.objects;
create policy "product_images_storage_public_read" on storage.objects
for select to anon, authenticated
using (bucket_id = 'product-images');

drop policy if exists "product_images_storage_admin_insert" on storage.objects;
create policy "product_images_storage_admin_insert" on storage.objects
for insert to authenticated
with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "product_images_storage_admin_update" on storage.objects;
create policy "product_images_storage_admin_update" on storage.objects
for update to authenticated
using (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "product_images_storage_admin_delete" on storage.objects;
create policy "product_images_storage_admin_delete" on storage.objects
for delete to authenticated
using (bucket_id = 'product-images' and public.is_admin());
