# 結帳套用限時活動折扣 — 設計文件

- 日期：2026-09-21
- 專案：online_shop（Vue 3 + Supabase）
- 前置：[活動時間+折扣](./2026-09-20-admin-backend-and-flash-sale-time-design.md)、[活動商品挑選+折扣顯示](./2026-09-21-admin-products-cards-and-flash-sale-selection-design.md)（`site_settings.flash_sale = {start,end,product_ids,discount}`、`useFlashSalePricing` 已完成）
- 狀態：設計已確認，待實作

## 一、背景與目標

商品頁/詳情頁已改成「折扣只由限時活動決定」的顯示，但**結帳金額仍算原價**（後端 `create_order_from_cart` 用 `p.price`，購物車頁也用原價）。客人會看到 $80 卻被收 $100。

目標：讓**購物車顯示**與**實際收費**都套用活動折扣，且以**後端為權威**（防前端竄改）。

## 二、規則（前後端一致）

- `active = 現在時間 ∈ [flash_sale.start, flash_sale.end) 且 flash_sale.discount ∈ (0,10)`。
- 某商品實付單價：`active 且 product_id ∈ flash_sale.product_ids → round(price × discount / 10)`；否則 `price`。
- 前端（購物車預覽）與後端（下單）用**同一規則、同一 round**，金額才會一致。

## 三、架構設計

### 3.1 後端（權威）— 改 `create_order_from_cart`

改 `supabase/migrations/202609190001_order_reserve_state_machine.sql` 定義的函式（新增一支 migration 覆蓋定義）：

- 下單時讀 `public.site_settings` 的 `flash_sale`，取出 `start/end/product_ids/discount`；`discount` 不在 `(0,10]` 視為 `10`（無折扣）。
- 計算 `active`（`now() ∈ [start,end)` 且 `discount < 10`）。
- 每件實付單價 `eff_price(p) = case when active and p.id = any(product_ids) then round(p.price * discount / 10) else p.price end`（四捨五入到整數，與前端一致）。
- `orders`：`subtotal = Σ(p.price × qty)`（原價）、`total = Σ(eff_price × qty)`（折後）、`discount_amount = subtotal − total`。
- `order_items`：`unit_price = eff_price`、`line_total = eff_price × qty`（下單當下快照，之後改活動不影響已成立訂單）。
- 其餘（庫存鎖、缺貨判斷、預留、清購物車）不變。
- **交付**：寫一支新 migration 檔存記錄；因遠端無法 db push，另**提供 SQL 由使用者在 SQL Editor 跑**（`create or replace function` 覆蓋，冪等安全）。

> 綠界請款金額本來就是用 `orders.total`（見 ecpay-create），後端 total 改折後後，ecpay 自動跟著折後，**不需改 ecpay**。

### 3.2 前端購物車 — `ShoppingCart.vue`

- 引入 `useFlashSalePricing`，對每個 cart item 用 `priceFor(item.productId, item.price)` 取折後單價。
- 每列單價/小計、下方「小計/總金額」改用折後金額；活動中的活動商品顯示折後價 +（可選）原價刪除線。
- 這是**預覽**；最終以後端回傳的訂單金額為準（兩邊同規則，理應一致）。

### 3.3 不動的部分

- `useCart` 的 `subtotal` 維持原價加總（其他地方可能用到）；折後計算放在 `ShoppingCart.vue`，避免 `useCart` 耦合活動邏輯。
- `useFlashSalePricing`、商品頁、詳情頁、首頁（已完成）不改。

## 四、資料流

```
購物車頁：cartItems → useFlashSalePricing.priceFor → 顯示折後單價/總額（預覽）
結帳：rpc create_order_from_cart（後端讀 site_settings.flash_sale，重算 eff_price）
      → orders.total 折後 → ecpay 請款用 total → 收費 = 折後
訂單頁 AdminOrders：order_items.unit_price/line_total 已是折後（快照）
```

## 五、錯誤處理 / 邊界

- `flash_sale` 缺 `product_ids`/`discount` 或格式錯 → 後端與前端皆視為無折扣（不折）。
- 活動未開始/已結束 → `active=false` → 全部原價。
- round 到整數，前後端一致（避免 1 元誤差）。
- 下單瞬間活動剛結束/開始：以**後端 `now()`** 為準；前端預覽可能有幾秒差，但收費以後端為準（可接受）。

## 六、測試 / 驗證

- 無單元測試框架：`npm run build` + 瀏覽器 preview。
- 驗證：設一個「進行中」活動 + 折扣 + 勾商品 →
  - 購物車該商品顯示折後價、總額折後。
  - 結帳建立的訂單 `total` 為折後、`order_items.unit_price` 為折後、`discount_amount` 正確。
  - 非活動商品、非活動時間 → 原價。

## 七、範圍外

- 綠界 ecpay 程式（沿用 `orders.total`，不改）。
- 運費（維持 0）。
- 多重折扣 / 優惠券 / 會員折扣（不做）。
- 商品自身 `original_price` 的用途（已不再作為折扣來源）。
