alter table if exists public.profiles rename to user_profile;

alter policy if exists "profiles_select_own" on public.user_profile rename to "user_profile_select_own";
alter policy if exists "profiles_insert_own" on public.user_profile rename to "user_profile_insert_own";
alter policy if exists "profiles_update_own" on public.user_profile rename to "user_profile_update_own";

alter trigger set_profiles_updated_at on public.user_profile rename to set_user_profile_updated_at;

grant select, insert, update on public.user_profile to authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profile (
    id,
    email,
    display_name,
    avatar_url,
    provider,
    last_sign_in_at
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'avatar_url',
    new.raw_app_meta_data ->> 'provider',
    new.last_sign_in_at
  )
  on conflict (id) do update
  set
    email = excluded.email,
    display_name = coalesce(excluded.display_name, public.user_profile.display_name),
    avatar_url = coalesce(excluded.avatar_url, public.user_profile.avatar_url),
    provider = coalesce(excluded.provider, public.user_profile.provider),
    last_sign_in_at = excluded.last_sign_in_at,
    updated_at = now();

  return new;
end;
$$;
