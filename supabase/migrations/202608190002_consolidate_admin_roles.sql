-- Collapse the two-tier admin system (admin_level_1 / admin_level_2) from
-- 202605120005_roles_and_admin_permissions.sql into a single 'admin' role.

-- Drop the old check constraint BEFORE touching the data: it only allows
-- ('customer', 'admin_level_1', 'admin_level_2'), so writing 'admin' while
-- it's still active fails with a check-constraint violation.
do $$
declare
  constraint_name text;
begin
  select conname
  into constraint_name
  from pg_constraint
  where conrelid = 'public.user_profile'::regclass
    and contype = 'c'
    and pg_get_constraintdef(oid) ilike '%admin_level_1%';

  if constraint_name is not null then
    execute format('alter table public.user_profile drop constraint %I', constraint_name);
  end if;
end;
$$;

update public.user_profile
set role = 'admin', updated_at = now()
where role in ('admin_level_1', 'admin_level_2');

alter table public.user_profile
  add constraint user_profile_role_check check (role in ('customer', 'admin'));

drop policy if exists "user_profile_select_admin_level_2" on public.user_profile;
drop policy if exists "user_profile_update_admin_level_2" on public.user_profile;
drop policy if exists "categories_admin_manage" on public.categories;
drop policy if exists "products_admin_manage" on public.products;
drop policy if exists "product_images_admin_manage" on public.product_images;
drop policy if exists "product_specs_admin_manage" on public.product_specs;
drop policy if exists "inventory_admin_manage" on public.inventory;

drop trigger if exists prevent_user_profile_privilege_escalation on public.user_profile;
drop function if exists public.prevent_user_profile_privilege_escalation();
drop function if exists public.admin_delete_user_account(uuid);
drop function if exists public.is_admin_level_1();
drop function if exists public.is_admin_level_2();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_user_role() = 'admin';
$$;

grant execute on function public.is_admin() to authenticated;

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
  ) and not public.is_admin() then
    raise exception 'Only administrators can change account privileges or account status';
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

create trigger prevent_user_profile_privilege_escalation
before update on public.user_profile
for each row
execute function public.prevent_user_profile_privilege_escalation();

drop policy if exists "user_profile_select_admin" on public.user_profile;
create policy "user_profile_select_admin"
on public.user_profile
for select
to authenticated
using (public.is_admin());

drop policy if exists "user_profile_update_admin" on public.user_profile;
create policy "user_profile_update_admin"
on public.user_profile
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "categories_admin_manage"
on public.categories
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "products_admin_manage"
on public.products
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "product_images_admin_manage"
on public.product_images
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "product_specs_admin_manage"
on public.product_specs
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "inventory_admin_manage"
on public.inventory
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create or replace function public.admin_delete_user_account(target_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_admin() then
    raise exception 'Only administrators can delete accounts';
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

grant execute on function public.admin_delete_user_account(uuid) to authenticated;
