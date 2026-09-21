# 商品管理卡片化 + 商品搜尋 + 活動商品挑選 — 設計文件

- 日期：2026-09-21
- 專案：online_shop（Vue 3 + Supabase）
- 前置：延續 [2026-09-20 後台管理統整 + 活動時間](./2026-09-20-admin-backend-and-flash-sale-time-design.md)（`site_settings.flash_sale`、AdminLayout 外殼、CountdownTimer 三態均已完成）
- 狀態：設計已確認，待寫實作計畫

## 一、背景與目標

目前 `/admin/products`（[AdminProducts.vue](../../../src/view/components/AdminProducts.vue)）把每個商品都**展開成一張大表單**，商品一多就是一長串、難瀏覽、無法搜尋。同時首頁「限時優惠」區用的是**隱性判定**（有標籤或有原價的商品），管理員無法明確指定哪些商品參加活動。

本次要做三件事：

1. **商品管理卡片化**：改成小卡片網格，點卡片進獨立詳情頁編輯。
2. **商品搜尋**：列表上方加搜尋欄，即時過濾。
3. **活動商品挑選**：在「網站設定」直接勾選哪些商品參加限時活動；首頁依此顯示。

## 二、需求確認結果

| 項目 | 決策 |
|---|---|
| 卡片點入後的編輯方式 | **獨立詳情頁** `/admin/products/:id`（掛後台外殼下） |
| 活動商品的標記/控制位置 | **在「網站設定」挑選**，存進 `site_settings.flash_sale.product_ids` |
| 活動沒選任何商品時的首頁 | **隱藏整個「限時優惠」區**（含倒數） |
| 搜尋方式 | client-side 即時過濾，比對商品**名稱 + slug** |

## 三、架構設計

### 3.1 資料模型（無需 migration）

`site_settings.flash_sale` 的 jsonb 值由 `{start, end}` 擴充為：

```json
{ "start": "...+08:00", "end": "...+08:00", "product_ids": ["<uuid>", "..."] }
```

- `product_ids` 為選中商品的 id 陣列；**缺少時一律預設為空陣列 `[]`**（向下相容既有那筆只有 start/end 的資料）。
- 因為只是 jsonb 多幾個鍵，**不需要新的資料表或 migration**；由「網站設定」儲存時一併寫回。

### 3.2 商品列表頁（改寫 `AdminProducts.vue`）

- 職責縮小為**唯讀列表 + 搜尋 + 導頁**，不再內嵌編輯表單。
- 資料：沿用現有 admin 讀取（**含所有狀態** active/draft/archived，不能用只讀 active 的 `useCatalog`），另補撈每個商品的**主圖**（`product_images` 的 `is_primary`）與目前 `flash_sale.product_ids`（用來在卡片標「活動中」）。
- UI：
  - 頂部：`h1 商品管理` + **搜尋欄**（`v-model` 綁 `keyword`）+ 既有狀態下拉。
  - 網格：`grid` 響應式卡片。每張卡顯示：主圖、名稱、售價（有原價則刪除線並列）、狀態徽章、以及「活動中」小標（當 `product.id ∈ product_ids`）。
  - 整張卡是 `RouterLink` → `{ name: 'AdminProductDetail', params: { id: product.id } }`。
- 過濾：`filteredProducts = 依 keyword（名稱/slug 子字串，不分大小寫）+ 狀態下拉` 計算。

### 3.3 商品詳情編輯頁（新 `AdminProductDetail.vue`，路由 `/admin/products/:id`）

- 掛在 `/admin`（AdminLayout）子路由，`name: 'AdminProductDetail'`；側邊欄「商品管理」維持 active（用 `route.name` 判斷時需把此頁也算成 products 群組）。
- 頂部：「← 返回商品列表」（`RouterLink` to `AdminProducts`）。
- 內容 = **現有那張編輯表單的欄位**：商品名稱、分類、狀態、售價、原價（選填）、標籤（選填）、庫存數量（顯示已保留）。
- 儲存：**沿用現有 `saveProduct` 的驗證與寫入邏輯**（`products` update + `inventory` upsert，含售價≥0、原價≥售價、庫存≥已保留 的驗證），只是改為單一商品。
- 載入：以 `route.params.id` 撈單一商品 + 其 `inventory`；查無 → 顯示「找不到商品」+ 返回鈕。

### 3.4 網站設定擴充活動商品（`AdminSettings.vue`）

- 在開始/結束時間下方新增「**活動商品**」區塊：
  - 一個可搜尋的**商品勾選清單**（撈全部商品的 id/名稱/主圖/售價；搜尋比對名稱）。
  - 已勾選的即為 `product_ids`。
- 載入時：讀 `flash_sale.product_ids`（缺則 `[]`）帶入勾選狀態。
- 儲存時：`upsert` 的 `value` 改為 `{ start, end, product_ids }`（沿用現有結束需晚於開始的驗證）。

### 3.5 讀取層擴充（`useSiteSettings.ts`）

- `FlashSaleWindow` 增加 `productIds: string[]`。
- `parseWindow` 解析 `product_ids`（非陣列或缺少 → `[]`）。
- 保持既有防呆：日期無效仍回 `null`。

### 3.6 首頁改吃 product_ids（`HomeView.vue`）

- `loadFlashSale()` 取得 `{ start, end, productIds }`。
- `flashSaleItems` 改為：`products` 中 `id ∈ productIds` 的商品，依 `productIds` 順序，取前 5 個（維持「1 大 + 4 小」版面）。
- **若 `productIds` 為空或對應不到任何商品 → 整個「限時優惠」區塊（含 CountdownTimer）以 `v-if` 隱藏。**
- 移除現有「有標籤/原價才算活動」的隱性判定。

## 四、路由

```
/admin（AdminLayout, requiresAdmin）
  ├─ products              → AdminProducts.vue（卡片列表）
  ├─ products/:id          → AdminProductDetail.vue（新，詳情編輯）
  ├─ orders                → AdminOrders.vue
  └─ settings              → AdminSettings.vue（擴充活動商品）
```

`AdminLayout` 側邊欄 active 判斷：`AdminProducts` 與 `AdminProductDetail` 都要讓「商品管理」亮起（以 `route.name` 是否屬於 products 群組判斷）。

## 五、資料流

```
網站設定：勾選商品 + 時間 → upsert site_settings.flash_sale = {start,end,product_ids}
                                        │（is_admin 可寫）
首頁 onMounted → loadFlashSale() → {start,end,productIds}（anon 可讀）
   → 有 productIds：顯示對應商品（1大+4小）+ CountdownTimer 三態
   → 無 productIds：整區隱藏

商品管理：卡片(唯讀+搜尋) → 點卡 → /admin/products/:id → 編輯 → 沿用 saveProduct 寫回
```

## 六、錯誤處理

- `product_ids` 缺失/型別錯 → 視為 `[]`（首頁隱藏該區，不出錯）。
- 詳情頁查無商品 → 顯示「找不到商品」+ 返回鈕，不崩。
- 詳情頁儲存沿用現有驗證與錯誤訊息（售價/原價/庫存/RLS 拒絕）。
- 網站設定撈商品清單失敗 → 顯示錯誤訊息，時間仍可單獨儲存。

## 七、測試 / 驗證

- 無單元測試框架：以 `npm run build`（型別檢查）+ 瀏覽器 preview 驗證。
- 驗證點：
  - 商品管理呈現卡片、搜尋即時過濾、點卡進詳情頁、編輯儲存成功。
  - 網站設定勾選商品後儲存，`site_settings.flash_sale.product_ids` 正確。
  - 首頁：有選商品 → 只顯示選中的（1大+4小）；沒選 → 整區隱藏。
  - 卡片「活動中」標記與選中狀態一致。

## 八、範圍外（本次不做）

- 商品**圖片**的上傳/編輯（詳情頁沿用現有欄位，不含圖片管理）。
- 商品**新增/刪除**（維持現況，只做既有商品的瀏覽與編輯）。
- 活動商品的**排序**自訂（首頁依 `product_ids` 陣列順序，不另做拖拉排序）。
- i18n / 登入頁中文化（另案）。
