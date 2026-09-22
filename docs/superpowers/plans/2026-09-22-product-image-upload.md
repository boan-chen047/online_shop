# 商品圖片上傳與自動輪播 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓管理員在商品詳情頁上傳多張圖片（前端壓縮）、設主圖、刪除，客人端商品詳情頁以 shadcn-vue Carousel 自動輪播呈現。

**Architecture:** 圖片存 Supabase Storage bucket `product-images`（公開讀、admin 寫），metadata 沿用既有 `product_images` 表（`is_primary` 主圖、`sort_order` 排序）；前端用 canvas 壓縮後上傳；讀取端（useCatalog 主圖、ProductDetails 圖庫）沿用現有邏輯。

**Tech Stack:** Vue 3（`<script setup>` + TS）、Supabase Storage、@supabase/supabase-js、embla-carousel-vue + embla-carousel-autoplay、Vite。

## Global Constraints

- UI 文案繁體中文、台灣慣用詞。
- **無單元測試框架**：每任務驗證 = `npm run build` 通過 + 瀏覽器 preview。
- 壓縮：寬 ≤ 1600px、JPEG 品質 0.85。
- Storage bucket 名稱固定 `product-images`；檔案路徑 `{product_id}/{uuid}.jpg`。
- 沿用 `product_images` 表，不建新表。
- DB/Storage 的 SQL 因遠端無法 db push，寫成 migration 檔存記錄 + 由使用者在 SQL Editor 執行。

---

## File Structure

- Create: `supabase/migrations/202609220001_product_images_storage.sql` — bucket + storage policies + grant（記錄）。
- Create: `src/lib/imageCompress.ts` — `compressImage(file, opts)`。
- Create: `src/composables/useProductImages.ts` — 讀取/上傳/設主圖/刪除。
- Modify: `src/view/components/AdminProductDetail.vue` — 加「商品圖片」管理區。
- Modify: `src/view/components/ProductDetails.vue` — 改自動輪播。
- Modify: `package.json` — 加 `embla-carousel-autoplay`。

---

### Task 1: Storage bucket 與權限（SQL）

**Files:**
- Create: `supabase/migrations/202609220001_product_images_storage.sql`

**Interfaces:**
- Produces: bucket `product-images`（public）；`storage.objects` 公開讀、admin 寫 policies；`product_images` 表 authenticated 的 CRUD grant。

- [ ] **Step 1: 撰寫 migration**

Create `supabase/migrations/202609220001_product_images_storage.sql`：

```sql
-- 商品圖片 Storage bucket（公開讀、admin 寫）
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

-- 確保 product_images 表寫入權限（RLS product_images_admin_manage 已用 is_admin 把關）
grant select, insert, update, delete on public.product_images to authenticated;

drop policy if exists "product_images_storage_public_read" on storage.objects;
create policy "product_images_storage_public_read" on storage.objects
for select to anon, authenticated
using (bucket_id = 'product-images');

drop policy if exists "product_images_storage_admin_insert" on storage.objects;
create policy "product_images_storage_admin_insert" on storage.objects
for insert to authenticated
with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "product_images_storage_admin_update" on storage.objects;
create policy "product_images_storage_admin_update" on storage.objects
for update to authenticated
using (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "product_images_storage_admin_delete" on storage.objects;
create policy "product_images_storage_admin_delete" on storage.objects
for delete to authenticated
using (bucket_id = 'product-images' and public.is_admin());
```

- [ ] **Step 2: 使用者在 Supabase SQL Editor 執行**

貼上該檔內容執行；到 Storage 確認出現 `product-images` bucket。

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/202609220001_product_images_storage.sql
git commit -m "feat(db): product-images storage bucket and policies"
```

---

### Task 2: 加入 embla-carousel-autoplay 依賴

**Files:**
- Modify: `package.json`

- [ ] **Step 1: 安裝**

Run:

```bash
npm install embla-carousel-autoplay@^8.6.0
```

Expected: `package.json` 的 dependencies 出現 `embla-carousel-autoplay`，版本與 `embla-carousel-vue` 同線。

- [ ] **Step 2: Commit**

```bash
git add package.json package-lock.json
git commit -m "chore: add embla-carousel-autoplay"
```

---

### Task 3: 前端圖片壓縮 imageCompress.ts

**Files:**
- Create: `src/lib/imageCompress.ts`

**Interfaces:**
- Produces: `compressImage(file: File, options?: { maxWidth?: number; quality?: number }): Promise<Blob>`（回傳 JPEG blob；非圖片檔丟錯）。

- [ ] **Step 1: 建立檔案**

Create `src/lib/imageCompress.ts`：

```ts
export interface CompressOptions {
  maxWidth?: number
  quality?: number
}

// 讀圖 → 若寬 > maxWidth 按比例縮 → 畫到 canvas → 輸出 JPEG blob
export async function compressImage(file: File, options: CompressOptions = {}): Promise<Blob> {
  const { maxWidth = 1600, quality = 0.85 } = options
  if (!file.type.startsWith('image/')) {
    throw new Error('只能上傳圖片檔。')
  }

  const dataUrl = await new Promise<string>((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result as string)
    reader.onerror = () => reject(new Error('讀取圖片失敗。'))
    reader.readAsDataURL(file)
  })

  const img = await new Promise<HTMLImageElement>((resolve, reject) => {
    const image = new Image()
    image.onload = () => resolve(image)
    image.onerror = () => reject(new Error('圖片格式無法解析。'))
    image.src = dataUrl
  })

  const scale = img.width > maxWidth ? maxWidth / img.width : 1
  const canvas = document.createElement('canvas')
  canvas.width = Math.round(img.width * scale)
  canvas.height = Math.round(img.height * scale)
  const ctx = canvas.getContext('2d')
  if (!ctx) {
    throw new Error('無法建立畫布。')
  }
  ctx.drawImage(img, 0, 0, canvas.width, canvas.height)

  const blob = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, 'image/jpeg', quality),
  )
  if (!blob) {
    throw new Error('圖片壓縮失敗。')
  }
  return blob
}
```

- [ ] **Step 2: 型別檢查**

Run: `npm run build`
Expected: build 成功。

- [ ] **Step 3: Commit**

```bash
git add src/lib/imageCompress.ts
git commit -m "feat: client-side image compression helper"
```

---

### Task 4: 圖片資料層 useProductImages.ts

**Files:**
- Create: `src/composables/useProductImages.ts`

**Interfaces:**
- Consumes: `supabase`、`compressImage`（Task 3）。
- Produces:
  - `interface ProductImage { id: string; image_url: string; alt: string | null; sort_order: number; is_primary: boolean }`
  - `loadImages(productId): Promise<ProductImage[]>`
  - `uploadImages(productId, files: File[], productName: string): Promise<void>`
  - `setPrimary(productId, imageId): Promise<void>`
  - `deleteImage(productId, image: ProductImage): Promise<void>`

- [ ] **Step 1: 建立檔案**

Create `src/composables/useProductImages.ts`：

```ts
import { supabase } from '@/lib/supabase'
import { compressImage } from '@/lib/imageCompress'

export interface ProductImage {
  id: string
  image_url: string
  alt: string | null
  sort_order: number
  is_primary: boolean
}

const BUCKET = 'product-images'

export async function loadImages(productId: string): Promise<ProductImage[]> {
  const { data, error } = await supabase
    .from('product_images')
    .select('id, image_url, alt, sort_order, is_primary')
    .eq('product_id', productId)
    .order('is_primary', { ascending: false })
    .order('sort_order', { ascending: true })
  if (error) {
    throw error
  }
  return (data ?? []) as ProductImage[]
}

function uuid(): string {
  const c = crypto as Crypto & { randomUUID?: () => string }
  return c.randomUUID?.() ?? `${Date.now()}-${Math.random().toString(16).slice(2)}`
}

// 從 public URL 反推 storage 內路徑（供刪除用）
function storagePathFromUrl(url: string): string | null {
  const marker = `/storage/v1/object/public/${BUCKET}/`
  const idx = url.indexOf(marker)
  return idx >= 0 ? url.slice(idx + marker.length) : null
}

export async function uploadImages(productId: string, files: File[], productName: string): Promise<void> {
  const existing = await loadImages(productId)
  let nextSort = existing.reduce((max, img) => Math.max(max, img.sort_order), -1) + 1
  let hasPrimary = existing.some((img) => img.is_primary)

  for (const file of files) {
    const blob = await compressImage(file)
    const path = `${productId}/${uuid()}.jpg`
    const { error: uploadError } = await supabase.storage
      .from(BUCKET)
      .upload(path, blob, { contentType: 'image/jpeg', upsert: false })
    if (uploadError) {
      throw uploadError
    }
    const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(path)
    const { error: insertError } = await supabase.from('product_images').insert({
      product_id: productId,
      image_url: pub.publicUrl,
      alt: productName,
      sort_order: nextSort,
      is_primary: !hasPrimary,
    })
    if (insertError) {
      throw insertError
    }
    nextSort += 1
    hasPrimary = true
  }
}

export async function setPrimary(productId: string, imageId: string): Promise<void> {
  const { error: clearError } = await supabase
    .from('product_images')
    .update({ is_primary: false })
    .eq('product_id', productId)
  if (clearError) {
    throw clearError
  }
  const { error } = await supabase
    .from('product_images')
    .update({ is_primary: true })
    .eq('id', imageId)
  if (error) {
    throw error
  }
}

export async function deleteImage(productId: string, image: ProductImage): Promise<void> {
  const { error } = await supabase.from('product_images').delete().eq('id', image.id)
  if (error) {
    throw error
  }
  const path = storagePathFromUrl(image.image_url)
  if (path) {
    const { error: removeError } = await supabase.storage.from(BUCKET).remove([path])
    if (removeError) {
      console.warn('Storage object could not be removed.', removeError)
    }
  }
  // 刪的是主圖 → 把最前面一張補為主圖
  if (image.is_primary) {
    const remaining = await loadImages(productId)
    if (remaining.length && !remaining.some((img) => img.is_primary)) {
      await setPrimary(productId, remaining[0].id)
    }
  }
}
```

- [ ] **Step 2: 型別檢查**

Run: `npm run build`
Expected: build 成功。

- [ ] **Step 3: Commit**

```bash
git add src/composables/useProductImages.ts
git commit -m "feat: product images data layer (upload/setPrimary/delete)"
```

---

### Task 5: 後台商品圖片管理 UI（AdminProductDetail.vue）

**Files:**
- Modify: `src/view/components/AdminProductDetail.vue`

**Interfaces:**
- Consumes: `useProductImages`（Task 4）。

- [ ] **Step 1: script 加圖片狀態與動作**

在 `src/view/components/AdminProductDetail.vue` 的 `<script setup>`，於 `import` 區塊加入：

```ts
import { type ProductImage, loadImages, uploadImages, setPrimary, deleteImage } from '@/composables/useProductImages'
```

並在 `onMounted(loadData)` 之前加入圖片相關狀態與函式：

```ts
const images = ref<ProductImage[]>([])
const imageBusy = ref(false)
const imageError = ref('')

async function refreshImages() {
  try {
    images.value = await loadImages(productId)
  } catch (error) {
    imageError.value = error instanceof Error ? error.message : '圖片載入失敗。'
  }
}

async function onUpload(event: Event) {
  const input = event.target as HTMLInputElement
  const files = input.files ? Array.from(input.files) : []
  if (!files.length) {
    return
  }
  imageBusy.value = true
  imageError.value = ''
  try {
    await uploadImages(productId, files, form.value.name)
    await refreshImages()
  } catch (error) {
    imageError.value = error instanceof Error ? error.message : '圖片上傳失敗。'
  }
  imageBusy.value = false
  input.value = ''
}

async function onSetPrimary(imageId: string) {
  imageBusy.value = true
  imageError.value = ''
  try {
    await setPrimary(productId, imageId)
    await refreshImages()
  } catch (error) {
    imageError.value = error instanceof Error ? error.message : '設定主圖失敗。'
  }
  imageBusy.value = false
}

async function onDeleteImage(image: ProductImage) {
  imageBusy.value = true
  imageError.value = ''
  try {
    await deleteImage(productId, image)
    await refreshImages()
  } catch (error) {
    imageError.value = error instanceof Error ? error.message : '刪除圖片失敗。'
  }
  imageBusy.value = false
}
```

- [ ] **Step 2: loadData 完成後載入圖片**

把 `onMounted(loadData)` 改為同時載入圖片：

```ts
onMounted(async () => {
  await loadData()
  if (!notFound.value) {
    await refreshImages()
  }
})
```

- [ ] **Step 3: template 加「商品圖片」區塊**

在 `AdminProductDetail.vue` 編輯表單的儲存列（`<div class="mt-6 flex items-center justify-end gap-3">…</div>`）之後、`</section>` 之前，插入：

```vue
      <div class="mt-8 border-t border-outline-variant/50 pt-6">
        <div class="mb-3 flex items-center justify-between">
          <h2 class="font-bold text-on-surface">商品圖片</h2>
          <label class="cursor-pointer rounded-lg border border-outline-variant px-3 py-1.5 text-sm font-bold text-on-surface hover:bg-surface-container-low" :class="{ 'pointer-events-none opacity-60': imageBusy }">
            {{ imageBusy ? '處理中…' : '＋ 上傳圖片' }}
            <input type="file" accept="image/*" multiple class="hidden" :disabled="imageBusy" @change="onUpload" />
          </label>
        </div>
        <p v-if="imageError" class="mb-3 text-sm font-bold text-red-600">{{ imageError }}</p>

        <div v-if="!images.length" class="rounded-lg bg-surface-container-low p-6 text-center text-sm text-outline">
          尚無圖片，點右上角「上傳圖片」新增。
        </div>
        <div v-else class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
          <div v-for="image in images" :key="image.id" class="overflow-hidden rounded-lg border border-outline-variant/60 bg-surface-container-lowest">
            <div class="relative aspect-square bg-surface-container-low">
              <img :src="image.image_url" :alt="image.alt ?? ''" class="h-full w-full object-cover" />
              <span v-if="image.is_primary" class="absolute left-1.5 top-1.5 rounded-full bg-primary px-2 py-0.5 text-[11px] font-bold text-on-primary">主圖</span>
            </div>
            <div class="flex items-center justify-between gap-1 p-2">
              <button
                type="button"
                class="text-xs font-bold text-primary disabled:opacity-40"
                :disabled="imageBusy || image.is_primary"
                @click="onSetPrimary(image.id)"
              >
                設為主圖
              </button>
              <button
                type="button"
                class="text-xs font-bold text-red-600 disabled:opacity-40"
                :disabled="imageBusy"
                @click="onDeleteImage(image)"
              >
                刪除
              </button>
            </div>
          </div>
        </div>
      </div>
```

- [ ] **Step 4: 型別檢查**

Run: `npm run build`
Expected: build 成功。

- [ ] **Step 5: Commit**

```bash
git add src/view/components/AdminProductDetail.vue
git commit -m "feat: product image management UI in admin detail page"
```

---

### Task 6: 客人端商品詳情頁自動輪播（ProductDetails.vue）

**Files:**
- Modify: `src/view/components/ProductDetails.vue`

**Interfaces:**
- Consumes: shadcn-vue `Carousel` 系列、`embla-carousel-autoplay`（Task 2）。

- [ ] **Step 1: script 加輪播依賴與圖片清單**

在 `src/view/components/ProductDetails.vue` 的 import 區塊加入：

```ts
import Autoplay from 'embla-carousel-autoplay'
import {
  Carousel,
  CarouselContent,
  CarouselItem,
  CarouselNext,
  CarouselPrevious,
} from '@/components/ui/carousel'
```

並在 `galleryImages` computed 之後加入輪播用的圖片網址清單（主圖優先；沒有圖時用佔位 `product.image`）：

```ts
const carouselImages = computed<string[]>(() => {
  const list = product.value?.images ?? []
  if (list.length) {
    return list.map((image) => image.imageUrl)
  }
  return product.value?.image ? [product.value.image] : []
})
```

- [ ] **Step 2: template 換成 Carousel**

把左側圖片區（從 `<div class="flex flex-col gap-4">` 內的主圖 `<div class="relative aspect-[4/3] ...">` 到縮圖列 `<div v-if="galleryImages.length > 1" ...>…</div>` 那整段）替換為：

```vue
          <div class="flex flex-col gap-4">
            <Carousel
              class="relative w-full"
              :opts="{ loop: true }"
              :plugins="[Autoplay({ delay: 3500, stopOnMouseEnter: true, stopOnInteraction: false })]"
            >
              <CarouselContent>
                <CarouselItem v-for="(url, index) in carouselImages" :key="index">
                  <div class="relative aspect-[4/3] overflow-hidden rounded-xl bg-surface-container-lowest">
                    <img :alt="product.name" class="w-full h-full object-cover" :src="url" />
                    <div v-if="product.tag && index === 0" class="absolute top-4 left-4 bg-primary text-on-primary px-3 py-1 rounded-full text-[10px] font-bold tracking-widest">
                      {{ product.tag }}
                    </div>
                  </div>
                </CarouselItem>
              </CarouselContent>
              <template v-if="carouselImages.length > 1">
                <CarouselPrevious class="left-3" />
                <CarouselNext class="right-3" />
              </template>
            </Carousel>
          </div>
```

- [ ] **Step 3: 清掉不再使用的 selectedImage**

`selectedImage` 若已無其他用途，移除其宣告（`const selectedImage = ref('')`）與 `loadProduct` 中設定它的那行（`selectedImage.value = product.value?.image ?? ''`）。若 build 報 `selectedImage` 未使用即依提示移除；`galleryImages` 若也無其他用途可一併移除。以 `npm run build` 通過為準。

- [ ] **Step 4: 型別檢查**

Run: `npm run build`
Expected: build 成功。

- [ ] **Step 5: Commit**

```bash
git add src/view/components/ProductDetails.vue
git commit -m "feat: auto-playing carousel on product detail page"
```

---

### Task 7: 端對端驗證

- [ ] **Step 1: 確認已跑 Task 1 的 SQL**（bucket + policies）。

- [ ] **Step 2: 起 dev server，後台上傳**

管理員登入 → 商品管理 → 點一個商品 → 「商品圖片」區「上傳圖片」選 2–3 張：

Expected：縮圖網格出現；第一張自動有「主圖」徽章；點別張「設為主圖」→ 徽章移動；「刪除」→ 該張消失。

- [ ] **Step 3: 驗證卡片/首頁主圖更新**

回商品管理列表與首頁 → 該商品縮圖變成剛設定的主圖。

- [ ] **Step 4: 驗證客人端輪播**

到該商品的商品詳情頁（`/product/:slug`）：

Expected：多圖自動輪播、可左右切、滑鼠移入暫停；只有一張圖時正常顯示不報錯。

- [ ] **Step 5: 驗證壓縮**

上傳一張大圖後，於 Supabase Storage 看該檔大小明顯小於原檔（寬被縮到 ≤1600、JPEG）。

- [ ] **Step 6: 更新規格書狀態並 commit**

把 `docs/superpowers/specs/2026-09-22-product-image-upload-design.md` 狀態標為「已實作」。

```bash
git add docs/superpowers/specs/2026-09-22-product-image-upload-design.md
git commit -m "docs: mark product image upload implemented"
```

---

## Self-Review

**1. Spec coverage：**
- Storage bucket + 權限（SQL）→ Task 1 ✅
- 前端壓縮 → Task 3 ✅
- 上傳/設主圖/刪除資料層 → Task 4 ✅
- 後台圖片管理 UI → Task 5 ✅
- 客人端自動輪播 → Task 6（+ 依賴 Task 2）✅
- 沿用 product_images、is_primary 主圖 → Task 4/5 ✅
- 錯誤處理（非圖片檔、上傳失敗不寫 DB、Storage 刪除失敗不擋、孤兒圖補主圖）→ Task 3（型別擋）、Task 4（流程）✅
- 驗證 → Task 7 ✅
- 範圍外（裁切/濾鏡/拖拉排序/影片）→ 未新增任務 ✅

**2. Placeholder scan：** 無 TBD/TODO；每個程式步驟附完整程式碼與指令（Task 6 Step 3 的移除以 build 未使用提示為準，屬明確清理指示）。✅

**3. Type consistency：**
- `ProductImage`（Task 4）欄位 `id/image_url/alt/sort_order/is_primary` 於 Task 5 UI 使用一致 ✅
- `compressImage(file, opts)` 回傳 `Blob`（Task 3）→ Task 4 `uploadImages` 以 blob 上傳 ✅
- `loadImages/uploadImages/setPrimary/deleteImage` 簽章（Task 4）與 Task 5 呼叫一致（`deleteImage(productId, image)`、`setPrimary(productId, imageId)`）✅
- bucket 名稱 `product-images` 於 Task 1 建立、Task 4 使用一致 ✅
- `carouselImages: string[]`（Task 6）餵給 CarouselItem 的 `url` 一致 ✅
