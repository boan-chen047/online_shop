grant select, insert, update on public.profiles to authenticated;

grant select on public.categories to anon, authenticated;
grant select on public.products to anon, authenticated;
grant select on public.product_images to anon, authenticated;
grant select on public.product_specs to anon, authenticated;

grant select, insert, update, delete on public.cart_items to authenticated;
grant select on public.orders to authenticated;
grant select on public.order_items to authenticated;

do $$
begin
  if exists (
    select 1
    from pg_proc
    join pg_namespace on pg_namespace.oid = pg_proc.pronamespace
    where pg_namespace.nspname = 'public'
      and pg_proc.proname = 'create_order_from_cart'
  ) then
    grant execute on function public.create_order_from_cart() to authenticated;
  end if;
end;
$$;

insert into public.profiles (
  id,
  email,
  display_name,
  avatar_url,
  provider,
  last_sign_in_at
)
select
  users.id,
  users.email,
  coalesce(users.raw_user_meta_data ->> 'full_name', users.raw_user_meta_data ->> 'name', split_part(users.email, '@', 1)),
  users.raw_user_meta_data ->> 'avatar_url',
  users.raw_app_meta_data ->> 'provider',
  users.last_sign_in_at
from auth.users
left join public.profiles on profiles.id = users.id
where profiles.id is null
on conflict (id) do update
set
  email = excluded.email,
  display_name = coalesce(excluded.display_name, public.profiles.display_name),
  avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
  provider = coalesce(excluded.provider, public.profiles.provider),
  last_sign_in_at = excluded.last_sign_in_at,
  updated_at = now();
