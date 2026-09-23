-- ─────────────────────────────────────────────────────────────────────────────
-- Schema 健康檢查 / 防漂移
--
-- 用途：檢查正式庫是否具備「migration 檔理應建立」的關鍵物件（資料表、函式、
--       orders 的 trigger、RLS）。任何缺項就 RAISE EXCEPTION 並列出，藉此抓出
--       「migration 檔有寫、prod 卻沒有」的 schema 漂移。
--
-- 背景：2026-09-23 曾發生 orders 的 set_order_closed_at_on_received /
--       set_orders_updated_at 兩個 trigger 從沒套到 prod（migration 歷史對不齊），
--       導致鑑賞期「提前完成」按鈕失效，且無任何機制會發現。詳見
--       supabase/migrations/202609230001_fix_orders_closed_at_trigger.sql。
--
-- 怎麼跑：
--   - Supabase Dashboard → SQL Editor 貼上執行；或
--   - 每次 `supabase db push` 之後跑一次。
--   通過 → 顯示 "schema health OK"；有缺 → 直接報錯並列出缺少的物件。
-- ─────────────────────────────────────────────────────────────────────────────

do $$
declare
  missing text[] := array[]::text[];
  v_name text;
  -- 關鍵資料表
  expected_tables text[] := array[
    'user_profile','categories','products','product_images','product_specs',
    'inventory','cart_items','orders','order_items','site_settings','news'
  ];
  -- 關鍵資料庫函式（RPC / trigger 函式）
  expected_functions text[] := array[
    'create_order_from_cart','mark_order_paid','expire_unpaid_orders',
    'top_selling_products','confirm_order_completed','is_admin',
    'set_order_closed_at','set_updated_at'
  ];
  -- orders 上必備的 trigger（這次踩雷的兩個）
  expected_orders_triggers text[] := array[
    'set_order_closed_at_on_received','set_orders_updated_at'
  ];
  -- 一定要開 RLS 的資料表
  expected_rls_tables text[] := array[
    'products','inventory','orders','order_items','cart_items','site_settings','news'
  ];
begin
  -- 1) 資料表存在？
  foreach v_name in array expected_tables loop
    if not exists (
      select 1 from information_schema.tables
      where table_schema = 'public' and table_name = v_name
    ) then
      missing := missing || ('table: ' || v_name);
    end if;
  end loop;

  -- 2) 函式存在？
  foreach v_name in array expected_functions loop
    if not exists (
      select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.proname = v_name
    ) then
      missing := missing || ('function: ' || v_name);
    end if;
  end loop;

  -- 3) orders 的 trigger 存在？
  foreach v_name in array expected_orders_triggers loop
    if not exists (
      select 1 from pg_trigger t
      join pg_class c on c.oid = t.tgrelid
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relname = 'orders'
        and t.tgname = v_name and not t.tgisinternal
    ) then
      missing := missing || ('trigger on orders: ' || v_name);
    end if;
  end loop;

  -- 4) RLS 有開啟？
  foreach v_name in array expected_rls_tables loop
    if not exists (
      select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relname = v_name and c.relrowsecurity
    ) then
      missing := missing || ('RLS disabled: ' || v_name);
    end if;
  end loop;

  -- 結果
  if array_length(missing, 1) is null then
    raise notice 'schema health OK — 所有關鍵物件都在。';
  else
    raise exception 'Schema 漂移：缺少 % 項物件 → %',
      array_length(missing, 1), array_to_string(missing, ' | ');
  end if;
end $$;
