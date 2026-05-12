grant usage on schema public to authenticated;
grant select, insert, update, delete on public.cart_items to authenticated;

drop policy if exists "cart_items_select_own" on public.cart_items;
create policy "cart_items_select_own"
on public.cart_items
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "cart_items_insert_own" on public.cart_items;
create policy "cart_items_insert_own"
on public.cart_items
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "cart_items_update_own" on public.cart_items;
create policy "cart_items_update_own"
on public.cart_items
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "cart_items_delete_own" on public.cart_items;
create policy "cart_items_delete_own"
on public.cart_items
for delete
to authenticated
using (auth.uid() = user_id);
