alter table public.user_profile
  add column if not exists role text not null default 'customer'
    check (role in ('customer', 'admin_level_1', 'admin_level_2')),
  add column if not exists account_status text not null default 'active'
    check (account_status in ('active', 'suspended', 'deleted')),
  add column if not exists deleted_at timestamptz;

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select user_profile.role
      from public.user_profile
      where user_profile.id = auth.uid()
        and user_profile.account_status = 'active'
      limit 1
    ),
    'customer'
  );
$$;

create or replace function public.is_admin_level_1()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_user_role() in ('admin_level_1', 'admin_level_2');
$$;

create or replace function public.is_admin_level_2()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_user_role() = 'admin_level_2';
$$;

create or replace function public.prevent_user_profile_privilege_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- SQL Editor / migration runs do not have auth.uid(). Allow those trusted
  -- database-side writes so test seeds and admin bootstrap scripts can work.
  if auth.uid() is null then
    return new;
  end if;

  if (
    new.role is distinct from old.role
    or new.account_status is distinct from old.account_status
    or new.deleted_at is distinct from old.deleted_at
  ) and not public.is_admin_level_2() then
    raise exception 'Only level 2 administrators can change account privileges or account status';
  end if;

  if new.account_status = 'deleted' and new.deleted_at is null then
    new.deleted_at = now();
  end if;

  if new.account_status <> 'deleted' then
    new.deleted_at = null;
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_user_profile_privilege_escalation on public.user_profile;
create trigger prevent_user_profile_privilege_escalation
before update on public.user_profile
for each row
execute function public.prevent_user_profile_privilege_escalation();

drop policy if exists "user_profile_select_own" on public.user_profile;
create policy "user_profile_select_own"
on public.user_profile
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "user_profile_select_admin_level_2" on public.user_profile;
create policy "user_profile_select_admin_level_2"
on public.user_profile
for select
to authenticated
using (public.is_admin_level_2());

drop policy if exists "user_profile_insert_own" on public.user_profile;
create policy "user_profile_insert_own"
on public.user_profile
for insert
to authenticated
with check (
  auth.uid() = id
  and role = 'customer'
  and account_status = 'active'
);

drop policy if exists "user_profile_update_own" on public.user_profile;
create policy "user_profile_update_own"
on public.user_profile
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "user_profile_update_admin_level_2" on public.user_profile;
create policy "user_profile_update_admin_level_2"
on public.user_profile
for update
to authenticated
using (public.is_admin_level_2())
with check (public.is_admin_level_2());

drop policy if exists "categories_admin_manage" on public.categories;
create policy "categories_admin_manage"
on public.categories
for all
to authenticated
using (public.is_admin_level_1())
with check (public.is_admin_level_1());

drop policy if exists "products_admin_manage" on public.products;
create policy "products_admin_manage"
on public.products
for all
to authenticated
using (public.is_admin_level_1())
with check (public.is_admin_level_1());

drop policy if exists "product_images_admin_manage" on public.product_images;
create policy "product_images_admin_manage"
on public.product_images
for all
to authenticated
using (public.is_admin_level_1())
with check (public.is_admin_level_1());

drop policy if exists "product_specs_admin_manage" on public.product_specs;
create policy "product_specs_admin_manage"
on public.product_specs
for all
to authenticated
using (public.is_admin_level_1())
with check (public.is_admin_level_1());

drop policy if exists "inventory_admin_manage" on public.inventory;
create policy "inventory_admin_manage"
on public.inventory
for all
to authenticated
using (public.is_admin_level_1())
with check (public.is_admin_level_1());

do $$
declare
  constraint_name text;
begin
  select conname
  into constraint_name
  from pg_constraint
  where conrelid = 'public.orders'::regclass
    and contype = 'f'
    and conkey = array[
      (
        select attnum
        from pg_attribute
        where attrelid = 'public.orders'::regclass
          and attname = 'user_id'
      )
    ];

  if constraint_name is not null then
    execute format('alter table public.orders drop constraint %I', constraint_name);
  end if;
end;
$$;

alter table public.orders
  alter column user_id drop not null,
  add constraint orders_user_id_fkey
    foreign key (user_id) references auth.users(id) on delete set null;

create or replace function public.admin_delete_user_account(target_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_admin_level_2() then
    raise exception 'Only level 2 administrators can delete accounts';
  end if;

  if target_user_id = auth.uid() then
    raise exception 'Administrators cannot delete their own account through this function';
  end if;

  update public.user_profile
  set
    account_status = 'deleted',
    deleted_at = now(),
    updated_at = now()
  where id = target_user_id;

  delete from auth.users
  where id = target_user_id;

  return true;
end;
$$;

grant select, insert, update on public.user_profile to authenticated;
grant select, insert, update, delete on public.categories to authenticated;
grant select, insert, update, delete on public.products to authenticated;
grant select, insert, update, delete on public.product_images to authenticated;
grant select, insert, update, delete on public.product_specs to authenticated;
grant select, insert, update, delete on public.inventory to authenticated;

grant execute on function public.current_user_role() to authenticated;
grant execute on function public.is_admin_level_1() to authenticated;
grant execute on function public.is_admin_level_2() to authenticated;
grant execute on function public.admin_delete_user_account(uuid) to authenticated;
