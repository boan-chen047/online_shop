-- Supabase Advisor 建議處理：安全收斂 + 效能優化
--
-- 對應 Advisor 項目：
--   (2) 收回觸發器函式的 API 執行權（安全）
--   (4) 補外鍵索引（效能：unindexed_foreign_keys）
--   (5) RLS policy 改用 (select auth.uid())，避免每列重算（效能：auth_rls_initplan）
-- 註：外洩密碼防護（Auth 設定）與「未使用索引/多重 policy」不在此處理。

-- ── (2) 觸發器函式：收回 PUBLIC / anon / authenticated 的執行權 ──────────
-- 這三個都是「觸發器」函式，只會由 trigger 自動呼叫（觸發器不檢查呼叫者對函式的 EXECUTE 權），
-- 不應透過 PostgREST 暴露成 /rest/v1/rpc/... 讓前端呼叫。
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.rls_auto_enable() from public, anon, authenticated;
revoke all on function public.prevent_user_profile_privilege_escalation() from public, anon, authenticated;

-- ── (4) 補外鍵索引 ───────────────────────────────────────────────────
-- 這些外鍵原 schema 有規劃索引但未實際套到正式庫，補上以改善 join 效能。
create index if not exists cart_items_product_id_idx on public.cart_items(product_id);
create index if not exists order_items_order_id_idx on public.order_items(order_id);
create index if not exists order_items_product_id_idx on public.order_items(product_id);
create index if not exists orders_user_created_at_idx on public.orders(user_id, created_at desc);

-- ── (5) RLS policy 改用 (select auth.uid())：讓 auth.uid() 只求值一次 ────
-- cart_items
drop policy if exists "cart_items_select_own" on public.cart_items;
create policy "cart_items_select_own" on public.cart_items
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "cart_items_insert_own" on public.cart_items;
create policy "cart_items_insert_own" on public.cart_items
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "cart_items_update_own" on public.cart_items;
create policy "cart_items_update_own" on public.cart_items
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "cart_items_delete_own" on public.cart_items;
create policy "cart_items_delete_own" on public.cart_items
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- orders
drop policy if exists "orders_select_own" on public.orders;
create policy "orders_select_own" on public.orders
  for select to authenticated
  using ((select auth.uid()) = user_id);

-- order_items
drop policy if exists "order_items_select_own_orders" on public.order_items;
create policy "order_items_select_own_orders" on public.order_items
  for select to authenticated
  using (
    exists (
      select 1
      from public.orders
      where orders.id = order_items.order_id
        and orders.user_id = (select auth.uid())
    )
  );

-- user_profile
drop policy if exists "user_profile_select_own" on public.user_profile;
create policy "user_profile_select_own" on public.user_profile
  for select to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "user_profile_update_own" on public.user_profile;
create policy "user_profile_update_own" on public.user_profile
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);
