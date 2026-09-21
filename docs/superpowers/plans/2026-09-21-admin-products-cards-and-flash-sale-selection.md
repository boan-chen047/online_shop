# 商品管理卡片化 + 搜尋 + 活動商品挑選 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把商品管理改成卡片網格＋搜尋、點卡進獨立詳情頁編輯，並讓「網站設定」直接勾選哪些商品參加限時活動、首頁依此顯示。

**Architecture:** 拆分 `AdminProducts.vue`（縮為唯讀卡片列表＋搜尋）與新的 `AdminProductDetail.vue`（`/admin/products/:id` 詳情編輯，沿用現有 save 邏輯）；活動商品存進 `site_settings.flash_sale.product_ids`（jsonb 多幾個鍵，免 migration），`useSiteSettings` 擴充 `productIds`，`AdminSettings` 加商品勾選清單，`HomeView` 改吃 `productIds` 並在空清單時隱藏整區。

**Tech Stack:** Vue 3（`<script setup>` + TS）、Vue Router、@supabase/supabase-js、Tailwind、Vite。

## Global Constraints

- 對話與 UI 文案一律**繁體中文、台灣慣用詞**。
- 活動時間一律台灣時間 +08:00（沿用現有 `AdminSettings` 轉換函式）。
- **無單元測試框架**：每個任務驗證 = `npm run build`（`vue-tsc` 型別檢查 + 建置）通過；行為面用瀏覽器 preview。
- `site_settings.flash_sale` 的 `product_ids` 缺失一律預設 `[]`（向下相容）。**本功能不需 migration。**
- 沿用現有 Tailwind token（`bg-surface-container-lowest`、`text-on-surface`、`primary-gradient` 等）、lucide-vue-next、`formatPrice`。
- 商品**圖片管理／新增／刪除商品／拖拉排序**皆為範圍外。

---

## File Structure

- Modify: `src/composables/useSiteSettings.ts` — `FlashSaleWindow` 加 `productIds`。
- Create: `src/view/components/AdminProductDetail.vue` — 單一商品詳情編輯頁。
- Modify: `src/router/index.ts` — 加 `products/:id` 子路由。
- Modify: `src/view/components/AdminLayout.vue` — 側邊欄 active 把詳情頁併入「商品管理」群組。
- Modify: `src/view/components/AdminProducts.vue` — 改寫為卡片列表＋搜尋＋活動中標記。
- Modify: `src/view/components/AdminSettings.vue` — 加活動商品勾選清單、儲存 `product_ids`。
- Modify: `src/view/components/HomeView.vue` — 改吃 `productIds`、空則隱藏整區。

---

### Task 1: useSiteSettings 擴充 productIds

**Files:**
- Modify: `src/composables/useSiteSettings.ts`

**Interfaces:**
- Produces: `interface FlashSaleWindow { start: Date; end: Date; productIds: string[]; discount: number }`；`loadFlashSale()` 回傳含 `productIds`（缺失為 `[]`）與 `discount`（折數，缺失/超出 `(0,10]` 為 `10`）。

- [ ] **Step 1: 改 interface 與 parseWindow**

把 `src/composables/useSiteSettings.ts` 的 `FlashSaleWindow` 與 `parseWindow` 改為：

```ts
export interface FlashSaleWindow {
  start: Date
  end: Date
  productIds: string[]
  discount: number
}

// 把 jsonb value 轉成 FlashSaleWindow；任何無效情況回 null（防呆，不讓首頁出錯）
function parseWindow(value: unknown): FlashSaleWindow | null {
  if (!value || typeof value !== 'object') {
    return null
  }
  const raw = value as { start?: unknown; end?: unknown; product_ids?: unknown; discount?: unknown }
  const start = new Date(String(raw.start ?? ''))
  const end = new Date(String(raw.end ?? ''))
  if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime())) {
    return null
  }
  const productIds = Array.isArray(raw.product_ids)
    ? raw.product_ids.filter((id): id is string => typeof id === 'string')
    : []
  // discount 為折數（8 = 八折）；不在 (0,10] 一律當無折扣 10
  const discount = typeof raw.discount === 'number' && raw.discount > 0 && raw.discount <= 10
    ? raw.discount
    : 10
  return { start, end, productIds, discount }
}
```

- [ ] **Step 2: 型別檢查**

Run: `npm run build`
Expected: build 成功。

- [ ] **Step 3: Commit**

```bash
git add src/composables/useSiteSettings.ts
git commit -m "feat: add productIds to flash sale window"
```

---

### Task 2: 新增商品詳情編輯頁 AdminProductDetail.vue

**Files:**
- Create: `src/view/components/AdminProductDetail.vue`

**Interfaces:**
- Consumes: `supabase`、`useAuth`、`Button`、`Input`、`RouterLink`、`useRoute`。
- Produces: 元件顯示 `/admin/products/:id` 的編輯表單；沿用現有驗證（售價≥0、原價≥售價、庫存≥已保留）與 `products.update` + `inventory.upsert`。

- [ ] **Step 1: 建立元件**

Create `src/view/components/AdminProductDetail.vue`：

```vue
<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'

interface Category { id: string; name: string }

const route = useRoute()
const { isAuthReady, isAdmin } = useAuth()

const productId = String(route.params.id ?? '')
const categories = ref<Category[]>([])
const isLoading = ref(false)
const loadError = ref('')
const notFound = ref(false)
const saving = ref(false)
const savedAt = ref<number | null>(null)
const saveError = ref('')

const form = ref({
  id: '',
  slug: '',
  category_id: '',
  name: '',
  price: '' as number | string,
  original_price: '' as number | string,
  tag: '',
  status: 'draft',
  quantity: 0 as number | string,
  reserved_quantity: 0,
})

const statusOptions = [
  { value: 'active', label: '上架' },
  { value: 'draft', label: '草稿' },
  { value: 'archived', label: '封存' },
]

async function loadData() {
  isLoading.value = true
  loadError.value = ''
  notFound.value = false

  const [{ data: categoryRows, error: categoryError }, { data: productRow, error: productError }] = await Promise.all([
    supabase.from('categories').select('id, name').order('sort_order', { ascending: true }),
    supabase
      .from('products')
      .select('id, slug, category_id, name, price, original_price, tag, status, inventory(quantity, reserved_quantity)')
      .eq('id', productId)
      .maybeSingle(),
  ])

  if (categoryError || productError) {
    loadError.value = (categoryError ?? productError)?.message ?? '資料載入失敗。'
    isLoading.value = false
    return
  }

  categories.value = (categoryRows ?? []) as Category[]

  if (!productRow) {
    notFound.value = true
    isLoading.value = false
    return
  }

  const row = productRow as unknown as Record<string, unknown>
  const inv = Array.isArray(row.inventory) ? row.inventory[0] : row.inventory
  const inventory = (inv ?? null) as { quantity: number | null; reserved_quantity: number | null } | null
  form.value = {
    id: row.id as string,
    slug: row.slug as string,
    category_id: row.category_id as string,
    name: row.name as string,
    price: Number(row.price),
    original_price: row.original_price === null ? '' : Number(row.original_price),
    tag: (row.tag as string | null) ?? '',
    status: row.status as string,
    quantity: inventory?.quantity ?? 0,
    reserved_quantity: inventory?.reserved_quantity ?? 0,
  }
  isLoading.value = false
}

async function save() {
  saving.value = true
  saveError.value = ''
  savedAt.value = null

  const price = Number(form.value.price)
  const originalPrice = form.value.original_price === null || form.value.original_price === ''
    ? null
    : Number(form.value.original_price)
  const quantity = Math.max(0, Math.trunc(Number(form.value.quantity)))

  if (Number.isNaN(price) || price < 0) {
    saveError.value = '售價需為 0 以上的數字。'
    saving.value = false
    return
  }
  if (originalPrice !== null && (Number.isNaN(originalPrice) || originalPrice < price)) {
    saveError.value = '原價需大於或等於售價。'
    saving.value = false
    return
  }
  if (quantity < form.value.reserved_quantity) {
    saveError.value = `庫存不可低於已保留數量（${form.value.reserved_quantity}）。`
    saving.value = false
    return
  }

  const { error: productError } = await supabase
    .from('products')
    .update({
      name: form.value.name,
      category_id: form.value.category_id,
      price,
      original_price: originalPrice,
      tag: form.value.tag ? form.value.tag : null,
      status: form.value.status,
    })
    .eq('id', form.value.id)

  if (productError) {
    saveError.value = productError.message
    saving.value = false
    return
  }

  const { error: inventoryError } = await supabase
    .from('inventory')
    .upsert({ product_id: form.value.id, quantity }, { onConflict: 'product_id' })

  if (inventoryError) {
    saveError.value = inventoryError.message
    saving.value = false
    return
  }

  savedAt.value = Date.now()
  saving.value = false
}

onMounted(loadData)
</script>

<template>
  <div class="max-w-3xl">
    <RouterLink :to="{ name: 'AdminProducts' }" class="mb-4 inline-flex items-center gap-1 text-sm font-bold text-primary hover:underline">
      <span aria-hidden="true">&larr;</span> 返回商品列表
    </RouterLink>

    <div v-if="!isAuthReady || isLoading" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-on-surface-variant">
      載入中...
    </div>

    <div v-else-if="!isAdmin" class="flex min-h-60 flex-col items-center justify-center rounded-xl bg-surface-container-lowest p-8 text-center">
      <h2 class="font-headline text-xl font-black text-on-surface">沒有權限</h2>
      <p class="mt-2 text-base text-on-surface-variant">這個頁面只開放給管理員帳號使用。</p>
    </div>

    <div v-else-if="loadError" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-error">
      {{ loadError }}
    </div>

    <div v-else-if="notFound" class="rounded-xl bg-surface-container-lowest p-8 text-center">
      <p class="text-base text-on-surface-variant">找不到這個商品。</p>
      <Button as-child class="primary-gradient mt-6 rounded-xl font-bold text-on-primary">
        <RouterLink :to="{ name: 'AdminProducts' }">返回商品列表</RouterLink>
      </Button>
    </div>

    <section v-else class="rounded-xl bg-surface-container-lowest p-5 shadow-sm md:p-6">
      <p class="mb-4 font-mono text-xs text-on-surface-variant">{{ form.slug }}</p>

      <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
        <label class="flex flex-col gap-1.5 md:col-span-2">
          <span class="text-sm font-semibold text-on-surface-variant">商品名稱</span>
          <Input v-model="form.name" />
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">分類</span>
          <select v-model="form.category_id" class="h-9 rounded-md border border-input bg-transparent px-3 text-sm outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50">
            <option v-for="category in categories" :key="category.id" :value="category.id">{{ category.name }}</option>
          </select>
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">狀態</span>
          <select v-model="form.status" class="h-9 rounded-md border border-input bg-transparent px-3 text-sm outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50">
            <option v-for="option in statusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
          </select>
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">售價</span>
          <Input v-model="form.price" type="number" />
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">原價（選填）</span>
          <Input v-model="form.original_price" type="number" />
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">標籤（選填）</span>
          <Input v-model="form.tag" />
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">庫存數量 <span class="text-outline">（已保留 {{ form.reserved_quantity }}）</span></span>
          <Input v-model="form.quantity" type="number" />
        </label>
      </div>

      <div class="mt-6 flex items-center justify-end gap-3">
        <span v-if="saveError" class="text-sm font-bold text-red-600">{{ saveError }}</span>
        <span v-else-if="savedAt" class="text-sm font-bold text-green-600">已儲存</span>
        <Button :disabled="saving" class="primary-gradient rounded-xl px-6 font-bold text-on-primary hover:opacity-80" @click="save">
          {{ saving ? '儲存中…' : '儲存' }}
        </Button>
      </div>
    </section>
  </div>
</template>
```

- [ ] **Step 2: 型別檢查**

Run: `npm run build`
Expected: build 成功（此時尚未加路由，元件單獨編譯即可）。

- [ ] **Step 3: Commit**

```bash
git add src/view/components/AdminProductDetail.vue
git commit -m "feat: add admin product detail edit page"
```

---

### Task 3: 路由加詳情頁 + 側邊欄 active

**Files:**
- Modify: `src/router/index.ts`
- Modify: `src/view/components/AdminLayout.vue`

**Interfaces:**
- Produces: 具名路由 `AdminProductDetail`（`/admin/products/:id`），為 `/admin` 子路由；側邊欄「商品管理」在詳情頁也 active。

- [ ] **Step 1: 加子路由**

在 `src/router/index.ts` 的 `/admin` children 裡，`products` 那筆之後插入：

```ts
      {
        path: 'products/:id',
        name: 'AdminProductDetail',
        component: () => import('../view/components/AdminProductDetail.vue'),
      },
```

- [ ] **Step 2: 側邊欄 active 併入群組**

在 `src/view/components/AdminLayout.vue` 把 `itemClass` 改為讓 `AdminProductDetail` 也算「商品管理」群組：

```ts
function itemClass(name: string) {
  const base = 'flex items-center gap-2.5 whitespace-nowrap rounded-lg px-4 py-2.5 text-[15px] font-bold transition-colors'
  const current = route.name === 'AdminProductDetail' ? 'AdminProducts' : route.name
  return current === name
    ? `${base} bg-primary/10 text-primary`
    : `${base} text-on-surface-variant hover:bg-surface-container-low hover:text-primary`
}
```

- [ ] **Step 3: 型別檢查**

Run: `npm run build`
Expected: build 成功。

- [ ] **Step 4: Commit**

```bash
git add src/router/index.ts src/view/components/AdminLayout.vue
git commit -m "feat: route admin product detail and keep sidebar active"
```

---

### Task 4: 商品管理改寫為卡片列表 + 搜尋 + 活動中標記

**Files:**
- Modify: `src/view/components/AdminProducts.vue`

**Interfaces:**
- Consumes: `loadFlashSale`（Task 1）、具名路由 `AdminProductDetail`（Task 3）、`formatPrice`。
- Produces: 唯讀卡片列表（不再內嵌編輯表單）。

- [ ] **Step 1: 整檔改寫**

以下列內容整檔取代 `src/view/components/AdminProducts.vue`：

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useAuth } from '@/composables/useAuth'
import { formatPrice } from '@/composables/useCatalog'
import { loadFlashSale } from '@/composables/useSiteSettings'
import { supabase } from '@/lib/supabase'

interface ProductCard {
  id: string
  slug: string
  name: string
  price: number
  originalPrice: number | null
  status: string
  image: string | null
}

const { isAuthReady, isAdmin } = useAuth()

const products = ref<ProductCard[]>([])
const activeIds = ref<Set<string>>(new Set())
const isLoading = ref(false)
const loadError = ref('')
const statusFilter = ref<'all' | 'active' | 'draft' | 'archived'>('all')
const keyword = ref('')

const statusOptions = [
  { value: 'active', label: '上架' },
  { value: 'draft', label: '草稿' },
  { value: 'archived', label: '封存' },
]

const filteredProducts = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return products.value.filter((product) => {
    const statusOk = statusFilter.value === 'all' || product.status === statusFilter.value
    const kwOk = !kw || product.name.toLowerCase().includes(kw) || product.slug.toLowerCase().includes(kw)
    return statusOk && kwOk
  })
})

function statusLabel(status: string) {
  return statusOptions.find((option) => option.value === status)?.label ?? status
}

async function loadData() {
  isLoading.value = true
  loadError.value = ''

  const { data: productRows, error: productError } = await supabase
    .from('products')
    .select('id, slug, name, price, original_price, status, sort_order, product_images(image_url, is_primary, sort_order)')
    .order('sort_order', { ascending: true })

  if (productError) {
    loadError.value = productError.message
    isLoading.value = false
    return
  }

  products.value = ((productRows ?? []) as unknown as Array<Record<string, unknown>>).map((row) => {
    const images = (Array.isArray(row.product_images) ? row.product_images : []) as Array<{
      image_url: string
      is_primary: boolean | null
      sort_order: number | null
    }>
    const primary = [...images].sort(
      (a, b) => Number(Boolean(b.is_primary)) - Number(Boolean(a.is_primary)) || (a.sort_order ?? 0) - (b.sort_order ?? 0),
    )[0]
    return {
      id: row.id as string,
      slug: row.slug as string,
      name: row.name as string,
      price: Number(row.price),
      originalPrice: row.original_price === null ? null : Number(row.original_price),
      status: row.status as string,
      image: primary?.image_url ?? null,
    }
  })

  // 標記活動中商品（來自 site_settings.flash_sale.product_ids）
  const flashSale = await loadFlashSale({ force: true })
  activeIds.value = new Set(flashSale?.productIds ?? [])

  isLoading.value = false
}

onMounted(loadData)
</script>

<template>
  <div class="text-on-surface antialiased font-body">
    <main class="pb-16">
      <div class="mb-6 flex flex-wrap items-center justify-between gap-4">
        <h1 class="font-headline text-2xl font-black">商品管理</h1>
        <div v-if="isAdmin && !isLoading && !loadError" class="flex items-center gap-2 text-sm">
          <span class="text-on-surface-variant">狀態</span>
          <select v-model="statusFilter" class="rounded-md border border-input bg-transparent px-3 py-1.5 font-bold outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50">
            <option value="all">全部</option>
            <option value="active">上架</option>
            <option value="draft">草稿</option>
            <option value="archived">封存</option>
          </select>
        </div>
      </div>

      <div v-if="isAdmin && !isLoading && !loadError" class="mb-5">
        <Input v-model="keyword" placeholder="搜尋商品名稱或代碼…" class="max-w-sm" />
      </div>

      <div v-if="!isAuthReady" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-on-surface-variant">
        載入中...
      </div>

      <div v-else-if="!isAdmin" class="flex min-h-60 flex-col items-center justify-center rounded-xl bg-surface-container-lowest p-8 text-center">
        <h2 class="font-headline text-xl font-black text-on-surface">沒有權限</h2>
        <p class="mt-2 max-w-sm text-base text-on-surface-variant">這個頁面只開放給管理員帳號使用。</p>
        <Button as-child class="primary-gradient mt-6 rounded-xl font-bold text-on-primary">
          <RouterLink to="/">回首頁</RouterLink>
        </Button>
      </div>

      <template v-else>
        <div v-if="isLoading" class="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-4">
          <div v-for="index in 8" :key="index" class="h-52 animate-pulse rounded-xl bg-surface-container-lowest" />
        </div>

        <div v-else-if="loadError" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-error">
          {{ loadError }}
        </div>

        <div v-else-if="!filteredProducts.length" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-on-surface-variant">
          找不到符合的商品。
        </div>

        <div v-else class="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-4">
          <RouterLink
            v-for="product in filteredProducts"
            :key="product.id"
            :to="{ name: 'AdminProductDetail', params: { id: product.id } }"
            class="group overflow-hidden rounded-xl bg-surface-container-lowest shadow-sm transition-all hover:-translate-y-1 hover:shadow-lg"
          >
            <div class="relative aspect-square bg-surface-container-low">
              <img v-if="product.image" :src="product.image" :alt="product.name" class="h-full w-full object-cover" />
              <div v-else class="flex h-full w-full items-center justify-center text-xs text-outline">無圖片</div>
              <span v-if="activeIds.has(product.id)" class="absolute left-2 top-2 rounded-full bg-primary px-2 py-0.5 text-[11px] font-bold text-on-primary">活動中</span>
            </div>
            <div class="p-3">
              <p class="truncate font-bold text-on-surface">{{ product.name }}</p>
              <div class="mt-1 flex items-baseline gap-2">
                <span class="font-bold text-primary">{{ formatPrice(product.price) }}</span>
                <span v-if="product.originalPrice" class="text-xs text-outline line-through">{{ formatPrice(product.originalPrice) }}</span>
              </div>
              <span
                class="mt-2 inline-block rounded-full px-2.5 py-0.5 text-xs font-bold"
                :class="{
                  'bg-primary/10 text-primary': product.status === 'active',
                  'bg-surface-container text-on-surface-variant': product.status === 'draft',
                  'bg-error/10 text-error': product.status === 'archived',
                }"
              >
                {{ statusLabel(product.status) }}
              </span>
            </div>
          </RouterLink>
        </div>
      </template>
    </main>
  </div>
</template>
```

- [ ] **Step 2: 型別檢查**

Run: `npm run build`
Expected: build 成功。

- [ ] **Step 3: Commit**

```bash
git add src/view/components/AdminProducts.vue
git commit -m "feat: turn admin products into searchable card grid with flash-sale marker"
```

---

### Task 5: 網站設定加活動商品挑選

**Files:**
- Modify: `src/view/components/AdminSettings.vue`

**Interfaces:**
- Consumes: `supabase`、`useAuth`。
- Produces: 儲存時 `site_settings.flash_sale.value = { start, end, product_ids }`。

- [ ] **Step 1: script 加商品清單與勾選狀態**

在 `src/view/components/AdminSettings.vue` 的 `<script setup>`，於現有 refs 之後加入：

```ts
interface PickProduct { id: string; name: string; price: number }
const allProducts = ref<PickProduct[]>([])
const selectedIds = ref<Set<string>>(new Set())
const productKeyword = ref('')
const discount = ref<number | string>(10) // 折數：8 = 八折；10 = 無折扣

const filteredPickProducts = computed(() => {
  const kw = productKeyword.value.trim().toLowerCase()
  return allProducts.value.filter((p) => !kw || p.name.toLowerCase().includes(kw))
})

function toggleProduct(id: string) {
  const next = new Set(selectedIds.value)
  if (next.has(id)) {
    next.delete(id)
  } else {
    next.add(id)
  }
  selectedIds.value = next
}
```

並確保 `import` 區塊有 `computed`（把頂部 `import { onMounted, ref } from 'vue'` 改為 `import { computed, onMounted, ref } from 'vue'`）。

- [ ] **Step 2: load() 帶入商品清單與已選**

在 `AdminSettings.vue` 的 `load()` 內，讀 `site_settings` 之後、設定 `startLocal/endLocal` 的地方，改為同時帶出 `product_ids`，並補撈商品清單。把 `load()` 內取得 `value` 後的區塊改為：

```ts
  const value = (data as { value?: { start?: string; end?: string; product_ids?: string[]; discount?: number } } | null)?.value
  startLocal.value = isoToLocalInput(value?.start ?? '')
  endLocal.value = isoToLocalInput(value?.end ?? '')
  selectedIds.value = new Set(Array.isArray(value?.product_ids) ? value.product_ids : [])
  discount.value = typeof value?.discount === 'number' && value.discount > 0 && value.discount <= 10 ? value.discount : 10

  const { data: productRows } = await supabase
    .from('products')
    .select('id, name, price, sort_order')
    .order('sort_order', { ascending: true })
  allProducts.value = ((productRows ?? []) as Array<Record<string, unknown>>).map((row) => ({
    id: row.id as string,
    name: row.name as string,
    price: Number(row.price),
  }))
```

- [ ] **Step 3: save() 驗證折數並一併寫回 product_ids + discount**

在 `AdminSettings.vue` 的 `save()`，於「結束需晚於開始」檢查之後、`isSaving.value = true` 之前，加入折數驗證：

```ts
  const discountNum = Number(discount.value)
  if (!Number.isFinite(discountNum) || discountNum <= 0 || discountNum > 10) {
    errorMessage.value = '折數需為 0（不含）到 10 之間（8 = 八折，10 = 無折扣）。'
    return
  }
```

並把 upsert 的 `value` 物件改為包含 `product_ids` 與 `discount`：

```ts
      {
        key: 'flash_sale',
        value: { start: startIso, end: endIso, product_ids: Array.from(selectedIds.value), discount: discountNum },
        updated_at: new Date().toISOString(),
        updated_by: currentUser.value?.id ?? null,
      },
```

- [ ] **Step 4: template 加活動商品區塊**

在 `AdminSettings.vue` template 的結束時間 `<div>` 之後、儲存按鈕那個 `<div class="flex items-center gap-3 pt-2">` 之前，插入：

```vue
      <div>
        <label class="mb-1 block text-sm font-bold text-on-surface">折扣（幾折）<span class="font-normal text-outline">（8 = 八折；10 = 無折扣）</span></label>
        <input
          v-model="discount"
          type="number"
          min="0.1"
          max="10"
          step="0.1"
          class="w-32 rounded-lg border border-outline-variant bg-surface px-3 py-2 text-sm text-on-surface"
        />
      </div>

      <div>
        <label class="mb-1 block text-sm font-bold text-on-surface">活動商品 <span class="font-normal text-outline">（勾選要參加限時優惠的商品）</span></label>
        <input
          v-model="productKeyword"
          type="text"
          placeholder="搜尋商品…"
          class="mb-2 w-full rounded-lg border border-outline-variant bg-surface px-3 py-2 text-sm text-on-surface"
        />
        <div class="max-h-64 overflow-y-auto rounded-lg border border-outline-variant">
          <label
            v-for="product in filteredPickProducts"
            :key="product.id"
            class="flex cursor-pointer items-center gap-3 border-b border-outline-variant/60 px-3 py-2 last:border-b-0 hover:bg-surface-container-low"
          >
            <input type="checkbox" :checked="selectedIds.has(product.id)" @change="toggleProduct(product.id)" />
            <span class="text-sm text-on-surface">{{ product.name }}</span>
            <span class="ml-auto text-xs text-outline">{{ product.price }}</span>
          </label>
          <p v-if="!filteredPickProducts.length" class="px-3 py-4 text-center text-sm text-outline">找不到商品。</p>
        </div>
        <p class="mt-1 text-xs text-outline">已選 {{ selectedIds.size }} 項</p>
      </div>
```

- [ ] **Step 5: 型別檢查**

Run: `npm run build`
Expected: build 成功。

- [ ] **Step 6: Commit**

```bash
git add src/view/components/AdminSettings.vue
git commit -m "feat: pick flash-sale products in site settings"
```

---

### Task 6: 首頁改吃 productIds，空清單隱藏整區

**Files:**
- Modify: `src/view/components/HomeView.vue`

**Interfaces:**
- Consumes: `loadFlashSale()` 回傳的 `productIds`（Task 1）。

- [ ] **Step 1: script 改用 productIds**

把 `src/view/components/HomeView.vue` 的 flash sale 相關 script 改為：

```ts
import { loadFlashSale } from '@/composables/useSiteSettings'

const DEFAULT_FLASH_SALE_END = '2026-12-31T23:59:59+08:00'
const flashSaleStart = ref<string | Date | null>(null)
const flashSaleEnd = ref<string | Date>(DEFAULT_FLASH_SALE_END)
const flashSaleProductIds = ref<string[]>([])
const flashSaleDiscount = ref<number>(10) // 折數：8 = 八折；10 = 無折扣

const flashSaleItems = computed(() => {
  const idOrder = new Map(flashSaleProductIds.value.map((id, index) => [id, index]))
  return products.value
    .filter((product) => idOrder.has(product.id))
    .sort((a, b) => (idOrder.get(a.id) ?? 0) - (idOrder.get(b.id) ?? 0))
    .slice(0, 5)
})

// 折後價：round(售價 × 折數 / 10)；無折扣時就是原售價
function salePrice(price: number) {
  return Math.round((price * flashSaleDiscount.value) / 10)
}
const hasDiscount = computed(() => flashSaleDiscount.value < 10)
```

（移除舊的 `flashSaleItems`：`products.value.filter((product) => product.tag || product.originalPrice)…` 那段。）

- [ ] **Step 2: onMounted 帶入 productIds**

把 `HomeView.vue` 的 `onMounted` 改為：

```ts
onMounted(async () => {
  void loadCatalog()
  const window = await loadFlashSale()
  if (window) {
    flashSaleStart.value = window.start
    flashSaleEnd.value = window.end
    flashSaleProductIds.value = window.productIds
    flashSaleDiscount.value = window.discount
  }
})
```

- [ ] **Step 3: template 整區以 v-if 隱藏**

把首頁「sales」`<section class="mb-14 px-5">` 的開頭改成帶條件：只有 `flashSaleItems.length` 才顯示整區（含說明與倒數）。將該 `<section ...>` 改為：

```vue
      <section v-if="flashSaleItems.length" class="mb-14 px-5">
```

並移除該區塊內原本 `v-else` 的骨架 loading 區塊（`<div v-else class="grid grid-cols-1 gap-5 md:grid-cols-4"> … </div>`，即四個 `animate-pulse` 佔位），因為整區在無商品時直接隱藏、不再需要空狀態骨架。把原本的 `<div v-if="flashSaleItems.length" …>` 改為 `<div …>`（去掉該層的 v-if，因為外層 section 已保證有商品）。

- [ ] **Step 4: 折後價即時顯示（大圖卡 + 小卡）**

把首頁**左邊大圖卡**的價格區塊（原為 `formatPrice(flashSaleItems[0].price)` + `flashSaleItems[0].originalPrice` 刪除線）改為：

```vue
              <div class="flex items-center gap-3">
                <span class="text-xl font-black text-on-surface">{{ formatPrice(salePrice(flashSaleItems[0].price)) }}</span>
                <span v-if="hasDiscount" class="text-outline line-through text-sm">{{ formatPrice(flashSaleItems[0].price) }}</span>
              </div>
```

把**右邊小卡**的價格（原為單一 `<span class="text-base font-bold text-primary">{{ formatPrice(item.price) }}</span>`）改為折後價 + 原價刪除線：

```vue
              <span class="flex items-baseline gap-1.5">
                <span class="text-base font-bold text-primary">{{ formatPrice(salePrice(item.price)) }}</span>
                <span v-if="hasDiscount" class="text-outline line-through text-xs">{{ formatPrice(item.price) }}</span>
              </span>
```

- [ ] **Step 5: 型別檢查**

Run: `npm run build`
Expected: build 成功。

- [ ] **Step 6: Commit**

```bash
git add src/view/components/HomeView.vue
git commit -m "feat: homepage flash sale reads product_ids, applies live discount, hides when empty"
```

---

### Task 7: 端對端驗證

- [ ] **Step 1: 起 dev server 驗證商品管理**

用 preview 開 dev server，管理員登入後到 `/admin/products`：

Expected：呈現商品卡片網格；搜尋欄輸入關鍵字即時過濾；狀態下拉可篩；有原價的卡顯示刪除線；活動中商品左上角有「活動中」標。

- [ ] **Step 2: 驗證詳情頁**

點任一張卡 → 到 `/admin/products/:id`：

Expected：頂部「← 返回商品列表」；帶出該商品欄位；改售價/庫存按儲存顯示「已儲存」；輸入原價<售價按儲存顯示「原價需大於或等於售價。」；側邊欄「商品管理」維持 active。

- [ ] **Step 3: 驗證網站設定挑選商品 + 折扣**

到 `/admin/settings`：設折扣（例如 `8`）、勾幾個商品、按儲存 → 顯示「已儲存」；重整後折數與勾選狀態保留；折數輸入 `0` 或 `11` 按儲存 → 顯示折數範圍錯誤、不送出。

- [ ] **Step 4: 驗證首頁**

回首頁：

Expected：只顯示剛勾選的商品（1 大 + 4 小，最多 5 個）；價格顯示**折後價**（例：售價 100、八折 → 顯示 $80，原 $100 刪除線）；折數改 `10` → 只顯示原價、無刪除線；把商品全部取消再儲存 → 首頁「限時優惠」整區（含倒數）消失。

- [ ] **Step 5: 更新規格書狀態並 commit**

把 `docs/superpowers/specs/2026-09-21-admin-products-cards-and-flash-sale-selection-design.md` 狀態標為「已實作」。

```bash
git add docs/superpowers/specs/2026-09-21-admin-products-cards-and-flash-sale-selection-design.md
git commit -m "docs: mark product cards and flash-sale selection implemented"
```

---

## Self-Review

**1. Spec coverage：**
- 卡片化列表 + 搜尋 + 活動中標記 → Task 4 ✅
- 獨立詳情頁 `/admin/products/:id` + 沿用 save → Task 2 + Task 3 ✅
- 側邊欄 active 併群組 → Task 3 ✅
- 活動商品挑選存 `product_ids` → Task 5 ✅（`useSiteSettings` 擴充 → Task 1）
- 折扣（幾折）設定 + 首頁折後價即時顯示 → Task 5（輸入/驗證/存 `discount`）+ Task 6（`salePrice`/`hasDiscount`/顯示）+ Task 1（parse `discount` 預設 `10`）✅
- 首頁改吃 `product_ids`、空則隱藏整區 → Task 6 ✅
- 無 migration（jsonb 多鍵、預設 `[]`/`10`）→ Task 1 parse 預設、Task 5 寫回 ✅
- 範圍外（圖片管理/新增刪除/排序）→ 未新增任務 ✅

**2. Placeholder scan：** 無 TBD/TODO；每個程式步驟皆附完整程式碼與指令。✅

**3. Type consistency：**
- `FlashSaleWindow.productIds: string[]`（Task 1）→ Task 4 `flashSale?.productIds`、Task 6 `window.productIds` 一致 ✅
- 具名路由 `AdminProductDetail` / `AdminProducts`（Task 3）→ Task 2 返回連結、Task 4 卡片連結一致 ✅
- `product_ids`（jsonb key，snake_case）於 Task 1 parse、Task 5 寫回一致；前端型別 `productIds`（camelCase）於讀取層轉換 ✅
- save 驗證與欄位（name/category_id/price/original_price/tag/status/quantity）於 Task 2 與原 `AdminProducts` 一致 ✅
