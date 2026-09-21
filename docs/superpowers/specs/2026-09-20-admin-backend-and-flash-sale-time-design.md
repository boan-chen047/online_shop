# 後台管理統整 + 首頁活動時間可後台設定 — 設計文件

- 日期：2026-09-20
- 專案：online_shop（Vue 3 + Supabase）
- 狀態：設計已確認，待寫實作計畫

## 一、背景與目標

首頁折扣區的倒數計時器（[CountdownTimer.vue](../../../src/view/components/CountdownTimer.vue)）目前把結束時間**寫死**在 [HomeView.vue](../../../src/view/components/HomeView.vue) 的 `targetDate="2026-12-31T23:59:59"`，每次調整活動期間都要改程式碼重新部署。

同時，現有後台是兩個各自獨立的路由（`/admin/products`、`/admin/orders`），從 NavBar 兩個分開的連結進入，**沒有統一的管理外殼**。

本次要達成兩件事：

1. **活動時間可由後台設定**：管理員能在後台設定折扣活動的「開始時間」與「結束時間」，首頁倒數自動反映。
2. **後台統整**：把商品管理、訂單管理、以及新的網站設定，收斂進單一的「後台管理」側邊導覽外殼。

## 二、需求確認結果

| 項目 | 決策 |
|---|---|
| 活動時間範圍 | **開始 + 結束**兩個時間 |
| 未到開始時間 | 首頁**倒數到開始**（顯示 `Starts In`），到點自動切換成倒數到結束 |
| 開始～結束之間 | 倒數到結束（現行行為，`Ending In`） |
| 結束之後 | 顯示已結束（`Promotion Ended`） |
| 設定位置 | **新增設定頁**（`/admin/settings`） |
| 後台形式 | **側邊導覽外殼**（`/admin` 外層 + 巢狀子路由） |
| 儲存方式 | **方案 A：key-value 設定表 `site_settings`**（jsonb），為日後全站設定預留擴充 |
| 時區 | 一律以**台灣時間（+08:00）**存與顯示 |

## 三、架構設計

### 3.1 資料層（Supabase migration）

新增資料表 `public.site_settings`：

- `key text primary key` — 設定鍵，本次用 `'flash_sale'`
- `value jsonb not null` — 設定值，`flash_sale` 內容為 `{"start": <ISO8601>, "end": <ISO8601>}`
- `updated_at timestamptz not null default now()`
- `updated_by uuid references auth.users(id)` — 記錄最後修改者（可為 null）

初始種子資料（沿用目前寫死值，改為台灣時間）：

```json
{ "start": "2026-01-01T00:00:00+08:00", "end": "2026-12-31T23:59:59+08:00" }
```

**RLS 政策**（沿用現有慣例）：

- 公開可讀：比照 catalog 的 public read（`migration 202605120006`），anon 可 `select`。
- 僅管理員可寫：比照 products 的 admin manage（`migration 202605120005`），`is_admin_level_1()` 才可 `insert/update`。

migration 檔名依現有慣例：`supabase/migrations/YYYYMMDDNNNN_create_site_settings.sql`。

> 部署注意：此專案 Supabase MCP 連到的是**別的帳號**，套 migration 一律走 CLI `supabase db push`，不要用 MCP 對資料庫下手。

### 3.2 讀取層（新 composable）

新增 `src/composables/useSiteSettings.ts`：

- `loadFlashSale()`：從 `site_settings` 讀 `key='flash_sale'`，回傳 `{ start: Date, end: Date } | null`。
- 防呆（比照 `useCatalog` 風格）：`isSupabaseConfigured` 為 false、查無資料、或日期無效（`Number.isFinite` 失敗）時回 `null`，不讓首頁出錯。
- 可快取結果，避免重複查詢。

### 3.3 倒數元件（改動 `CountdownTimer.vue`）

props 由單一 `targetDate` 擴充為：

- `startDate?: string | Date`（可選；沒給就等同「已經開始」）
- `targetDate: string | Date`（結束時間）

三態邏輯（`computed`，維持 `useNow()` 每秒驅動）：

- `now < start` → 標籤 `Starts In`，倒數到 `start`
- `start ≤ now < end` → 標籤 `Ending In`，倒數到 `end`（現行行為）
- `now ≥ end` → 標籤 `Promotion Ended`，隱藏數字

保留現有兩道防呆：`Math.max(0, …)`（不出現負數）與 `Number.isFinite`（無效日期歸零）。天/時/分/秒換算與 `padStart(2,'0')` 不變。

### 3.4 首頁（改動 `HomeView.vue`）

- `onMounted` 時呼叫 `loadFlashSale()`。
- 把取得的 `start` / `end` 傳進 `CountdownTimer`。
- 讀不到（回 `null`）時，退回目前寫死的預設值當 fallback，首頁不開天窗。

### 3.5 後台外殼（新 `AdminLayout.vue` + 巢狀路由）

- 新增 `src/view/components/AdminLayout.vue`：
  - 左側固定側邊欄，導覽項目：商品管理 / 訂單管理 / 網站設定。
  - 右側 `<RouterView>` 顯示子頁內容。
  - 手機版：側邊欄收合為上方橫向列或漢堡選單。
- 路由改為巢狀：

```
/admin           → AdminLayout（meta.requiresAdmin）
  ├─ (預設)       → redirect 到 products
  ├─ products     → AdminProducts.vue
  ├─ orders       → AdminOrders.vue
  └─ settings     → AdminSettings.vue（新）
```

- 對外網址維持 `/admin/products`、`/admin/orders` 不變（不破壞既有連結與書籤）。
- `AdminProducts.vue`、`AdminOrders.vue` 內容**不動**，只是被放進外殼的 `<RouterView>`。
- NavBar：把原本兩個分開的 admin 連結，收斂成**單一「後台管理」入口**指向 `/admin`（桌機與手機版皆同步）。

### 3.6 設定頁（新 `AdminSettings.vue`）

- 兩個 `datetime-local` 輸入：開始時間、結束時間（視為台灣時間）。
- 載入時讀現值填入；儲存時 `upsert` 進 `site_settings`（`key='flash_sale'`）。
- 前端驗證：**結束時間必須晚於開始時間**，否則不給存並提示。
- 儲存成功 / 失敗給明確回饋（沿用現有 admin 頁的訊息樣式）。

## 四、資料流

```
管理員 → AdminSettings（datetime-local，台灣時間）
        → upsert site_settings.flash_sale = {start, end}   [RLS: is_admin_level_1]
                              │
              首頁 onMounted → loadFlashSale()（anon 可讀）
                              → CountdownTimer(startDate=start, targetDate=end)
                              → 三態：Starts In / Ending In / Ended
```

## 五、錯誤處理

- Supabase 未設定 / 查詢失敗 / 日期無效 → `loadFlashSale()` 回 `null` → 首頁用寫死預設值。
- 倒數元件遇到無效或缺失日期 → 既有防呆歸零，不崩潰。
- 設定頁儲存失敗（含 RLS 拒絕）→ 顯示錯誤訊息，不改動畫面既有值。
- 結束早於開始 → 前端擋下，不送出。

## 六、測試 / 驗證

- migration：走 CLI `supabase db push` 套用到正確專案。
- 本機 dev server + 瀏覽器 preview 驗證三態切換：
  - 設「開始在未來」→ 首頁顯示 `Starts In` 並倒數到開始。
  - 設「現在正在活動中」→ 顯示 `Ending In` 倒數到結束。
  - 設「結束在過去」→ 顯示 `Promotion Ended`。
- 後台外殼：三個子頁側邊欄切換正常、網址不變、非管理員被守衛擋下。

## 七、範圍外（本次不做）

- **既有小 bug**：NavBar 給一般客人的「我的訂單」連結指向 `/admin/orders`，但該路由 `requiresAdmin`，客人點了會被導回首頁。屬既有問題，另案處理。
- 完整多活動管理（多筆活動、名稱、啟用切換）——本次僅單一 `flash_sale` 設定。
- 其他全站設定項目（標語、運費等）——`site_settings` 已預留擴充，但本次不實作。
