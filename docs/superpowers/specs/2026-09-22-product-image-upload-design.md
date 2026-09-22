# 商品圖片上傳與自動輪播 — 設計文件

- 日期：2026-09-22
- 專案：online_shop（Vue 3 + Supabase）
- 分支：feature/product-image-upload
- 狀態：設計已確認，待實作

## 一、背景與目標

目前商品圖片只能靠既有種子資料，後台無法上傳，導致很多商品共用同一張佔位圖。要讓管理員能在商品詳情頁**上傳多張圖片**、**指定主圖（大圖）**、**刪除**，並讓客人端商品詳情頁以**自動輪播**呈現多圖。

沿用既有 `product_images` 表（`is_primary` = 主圖、`sort_order` = 順序），不另建表；讀取端（`useCatalog` 取主圖、`ProductDetails` 圖庫）本來就吃這張表，上傳後立即生效。

## 二、需求確認結果

| 項目 | 決策 |
|---|---|
| 資料表 | 沿用 `product_images`（`is_primary` 主圖、`sort_order` 排序） |
| 壓縮 | **前端上傳前壓縮**：縮到寬 ≤ 1600px、轉 JPEG（品質約 0.85） |
| 後台操作 | **上傳（多張）＋ 設為主圖 ＋ 刪除單張**（不做拖拉排序） |
| 客人端顯示 | shadcn-vue `Carousel` **自動播放 + 無限循環**，移入暫停 |
| 自動播放 | 官方外掛 `embla-carousel-autoplay` |
| 檔案儲存 | Supabase Storage bucket `product-images`，公開讀、admin 寫 |

## 三、架構設計

### 3.1 Storage（SQL，使用者在 SQL Editor 跑）

- 建 bucket：`insert into storage.buckets (id, name, public) values ('product-images','product-images', true) on conflict do nothing;`
- `storage.objects` policies：
  - 公開讀（`select`，`bucket_id='product-images'`，to anon, authenticated）
  - admin 寫（`insert/update/delete`，`bucket_id='product-images' and public.is_admin()`）
- 確保 `product_images` 表 grant：`grant select, insert, update, delete on public.product_images to authenticated;`（RLS `product_images_admin_manage` 已用 `is_admin()` 把關；遠端可能漏 grant，一併補）。
- 檔案路徑慣例：`{product_id}/{uuid}.jpg`。

### 3.2 前端壓縮（`src/lib/imageCompress.ts`）

- 純瀏覽器 canvas，不裝額外套件。
- `compressImage(file, { maxWidth = 1600, quality = 0.85 }): Promise<Blob>`：
  - 讀檔為 image → 若寬 > maxWidth 按比例縮 → 畫到 canvas → `toBlob('image/jpeg', quality)`。
  - 非圖片檔（`type` 不以 `image/` 開頭）丟錯。

### 3.3 上傳與圖片管理（`src/composables/useProductImages.ts`）

- `loadImages(productId)`：讀 `product_images`（依 `is_primary desc, sort_order asc`）。
- `uploadImages(productId, files, productName)`：逐檔 → 壓縮 → `storage.upload('{product_id}/{uuid}.jpg', blob)` → `getPublicUrl` → `insert product_images`（`image_url`、`alt`=productName、`sort_order`=現有最大+1）。若該商品原本沒有圖，第一張自動 `is_primary=true`。
- `setPrimary(productId, imageId)`：把該商品所有列 `is_primary=false`，再把目標列設 `true`。
- `deleteImage(image)`：刪 `product_images` 該列 → 刪 Storage 檔（`storage.remove`）；若刪的是主圖且還有其他張，把最前面一張補 `is_primary=true`。

### 3.4 後台 UI（`AdminProductDetail.vue` 加「商品圖片」區）

- 詳情頁編輯表單下方新增「商品圖片」區塊：
  - 現有圖片**縮圖網格**：每張顯示縮圖、**主圖徽章**（is_primary）、「設為主圖」「刪除」。
  - **上傳按鈕**（`<input type="file" accept="image/*" multiple>`）。
- 載入詳情時同時 `loadImages`。上傳/設主圖/刪除後重新 `loadImages` 並更新畫面。

### 3.5 客人端輪播（`ProductDetails.vue`）

- 以 `product.images`（已依主圖優先排序）餵給 shadcn-vue `Carousel`：
  - `opts={{ loop: true }}`、`:plugins="[Autoplay({ delay: 3500, stopOnMouseEnter: true, stopOnInteraction: false })]"`。
  - `CarouselContent` + `CarouselItem`（每張一張大圖）+ `CarouselPrevious/Next` + 圓點指示。
- 取代現有「大圖 `selectedImage` + 縮圖點選」的實作；只有一張圖時仍正常顯示（不必輪播）。

### 3.6 依賴

- 新增 `embla-carousel-autoplay`（Embla 官方，與現有 `embla-carousel-vue` 同版線）。

## 四、資料流

```
後台：選檔 → compressImage → storage.upload → getPublicUrl → insert product_images
      設主圖 → update is_primary；刪除 → delete row + storage.remove
客人：ProductDetails 讀 product.images → Carousel(autoplay, loop) 自動輪播
卡片/首頁：useCatalog 取 is_primary 主圖（不變，立即反映新圖）
```

## 五、錯誤處理 / 邊界

- 非圖片檔 / 讀取失敗 → 前端擋下並提示，不上傳。
- 上傳失敗 → 提示，不寫 `product_images`（避免孤兒紀錄）。
- Storage 檔刪除失敗但 DB 已刪 → 記 console，不擋流程（孤兒檔可容忍）。
- 商品無任何圖片 → 卡片/詳情顯示「無圖片」佔位（沿用現有 emptyImage 行為）。
- 權限：非 admin 上傳/刪除被 Storage policy 擋（`is_admin()`）。

## 六、測試 / 驗證

- 無單元測試框架：`npm run build` + 瀏覽器 preview。
- 驗證：
  - 後台詳情頁上傳多張 → 縮圖網格出現；設主圖 → 徽章移動、卡片/首頁主圖更新；刪除 → 該張消失（含 Storage）。
  - 客人端商品詳情頁多圖自動輪播、可左右切、移入暫停。
  - 壓縮：上傳大圖後，Storage 檔明顯變小、載入變快。

## 七、範圍外

- 圖片裁切 / 濾鏡 / 浮水印。
- 拖拉排序（依上傳順序）。
- 影片、CDN 動態轉檔。
- 既有種子資料的舊圖批次替換（本次只做「能上傳」）。
