-- 全站設定 key-value 表；本次用於折扣活動時間 flash_sale
create table if not exists public.site_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

alter table public.site_settings enable row level security;

-- 公開可讀（比照 catalog 的 public read）
grant select on public.site_settings to anon, authenticated;
-- 寫入交給 RLS 把關，僅開放 authenticated 嘗試
grant insert, update on public.site_settings to authenticated;

drop policy if exists "site_settings_public_read" on public.site_settings;
create policy "site_settings_public_read"
on public.site_settings
for select
to anon, authenticated
using (true);

-- 僅管理員可寫（比照 products 的 admin manage）
drop policy if exists "site_settings_admin_manage" on public.site_settings;
create policy "site_settings_admin_manage"
on public.site_settings
for all
to authenticated
using (public.is_admin_level_1())
with check (public.is_admin_level_1());

-- 種子：沿用目前寫死值，改為台灣時間 +08:00
insert into public.site_settings (key, value)
values (
  'flash_sale',
  '{"start": "2026-01-01T00:00:00+08:00", "end": "2026-12-31T23:59:59+08:00"}'::jsonb
)
on conflict (key) do nothing;
