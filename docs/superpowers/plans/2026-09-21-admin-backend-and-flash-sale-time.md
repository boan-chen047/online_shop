# 後台管理統整 + 首頁活動時間可後台設定 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓管理員能在後台設定首頁折扣活動的開始／結束時間，並把商品管理、訂單管理、網站設定收斂進單一的後台側邊導覽外殼。

**Architecture:** 新增 `site_settings`（key-value jsonb）表存活動時間，公開可讀、`is_admin_level_1()` 可寫；首頁透過 `useSiteSettings` composable 讀取並傳入三態的 `CountdownTimer`；後台改為 `/admin` 巢狀路由，外層掛 `AdminLayout` 側邊外殼，`AdminSettings` 為新設定頁。

**Tech Stack:** Vue 3 (`<script setup>` + TS)、Vue Router、@supabase/supabase-js、@vueuse/core、Tailwind、Vite、Supabase CLI。

## Global Constraints

- 對話與 UI 文案一律**繁體中文、台灣慣用詞**。
- 活動時間一律以**台灣時間 +08:00** 存與顯示。
- migration 一律走 **Supabase CLI `supabase db push`**；不要用 Supabase MCP 對資料庫下手（MCP 連到的是別的帳號）。
- **無單元測試框架**：每個任務的驗證 = `npm run build`（`vue-tsc` 型別檢查 + 建置）通過；行為面用瀏覽器 preview 驗證。
- RLS 沿用現有慣例：公開讀比照 `202605120006`，admin 寫比照 `202605120005` 的 `is_admin_level_1()`。
- 沿用現有 Tailwind design token（`bg-surface`、`text-on-surface`、`primary-gradient` 等）與 lucide-vue-next 圖示。
- 改動 API/邏輯需同步更新 spec 文件（`docs/superpowers/specs/2026-09-20-admin-backend-and-flash-sale-time-design.md`）。

---

## File Structure

- Create: `supabase/migrations/202609210001_create_site_settings.sql` — 建 `site_settings` 表 + RLS + 種子。
- Create: `src/composables/useSiteSettings.ts` — 讀取層，`loadFlashSale()`。
- Modify: `src/view/components/CountdownTimer.vue` — 擴充成三態（before/running/ended）。
- Modify: `src/view/components/HomeView.vue` — 讀設定並傳入 CountdownTimer，含 fallback。
- Create: `src/view/components/AdminLayout.vue` — 後台側邊導覽外殼。
- Create: `src/view/components/AdminSettings.vue` — 網站設定頁。
- Modify: `src/router/index.ts` — 改成 `/admin` 巢狀路由。
- Modify: `src/view/components/NavBar.vue` — 收斂成單一「後台管理」入口。
- Create: `.claude/launch.json` — preview 用的 dev server 設定。

> 註：`src/router/` 下的路由檔實際檔名以現場為準（`ls src/router`）。以下以 `src/router/index.ts` 代稱。

---

### Task 1: 建立 site_settings 資料表（migration）

**Files:**
- Create: `supabase/migrations/202609210001_create_site_settings.sql`

**Interfaces:**
- Produces: 資料表 `public.site_settings(key text pk, value jsonb, updated_at timestamptz, updated_by uuid)`；種子 `key='flash_sale'` 值 `{start,end}`（ISO8601 含 +08:00）。公開可 `select`，`is_admin_level_1()` 可 `insert/update`。

- [ ] **Step 1: 撰寫 migration**

Create `supabase/migrations/202609210001_create_site_settings.sql`：

```sql
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
```

- [ ] **Step 2: 套用到正確的 Supabase 專案**

Run（在 online_shop 目錄；確認已 `supabase link` 到正確專案）:

```bash
supabase db push
```

Expected: 顯示套用 `202609210001_create_site_settings` 成功，無錯誤。

- [ ] **Step 3: 驗證資料存在**

在 Supabase SQL editor 或 CLI 執行：

```sql
select key, value from public.site_settings where key = 'flash_sale';
```

Expected: 回一列，`value` 含 `start` / `end` 兩個 +08:00 時間。

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/202609210001_create_site_settings.sql
git commit -m "feat(db): add site_settings table for configurable flash sale window"
```

---

### Task 2: 讀取層 composable useSiteSettings

**Files:**
- Create: `src/composables/useSiteSettings.ts`

**Interfaces:**
- Consumes: `supabase`、`isSupabaseConfigured`（來自 `@/lib/supabase`）；資料表 `site_settings`（Task 1）。
- Produces:
  - `interface FlashSaleWindow { start: Date; end: Date }`
  - `async function loadFlashSale(opts?: { force?: boolean }): Promise<FlashSaleWindow | null>`
  - `function useSiteSettings(): { flashSale: Ref<FlashSaleWindow | null>; loadFlashSale }`

- [ ] **Step 1: 寫 composable**

Create `src/composables/useSiteSettings.ts`：

```ts
import { ref } from 'vue'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'

export interface FlashSaleWindow {
  start: Date
  end: Date
}

const flashSale = ref<FlashSaleWindow | null>(null)
let hasLoaded = false

// 把 jsonb value 轉成 FlashSaleWindow；任何無效情況回 null（防呆，不讓首頁出錯）
function parseWindow(value: unknown): FlashSaleWindow | null {
  if (!value || typeof value !== 'object') {
    return null
  }
  const raw = value as { start?: unknown; end?: unknown }
  const start = new Date(String(raw.start ?? ''))
  const end = new Date(String(raw.end ?? ''))
  if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime())) {
    return null
  }
  return { start, end }
}

export async function loadFlashSale({ force = false } = {}): Promise<FlashSaleWindow | null> {
  if (hasLoaded && !force) {
    return flashSale.value
  }
  if (!isSupabaseConfigured) {
    return null
  }

  const { data, error } = await supabase
    .from('site_settings')
    .select('value')
    .eq('key', 'flash_sale')
    .maybeSingle()

  if (error) {
    console.warn('Flash sale setting could not be loaded.', error)
    return null
  }

  flashSale.value = parseWindow((data as { value?: unknown } | null)?.value)
  hasLoaded = true
  return flashSale.value
}

export function useSiteSettings() {
  return {
    flashSale,
    loadFlashSale,
  }
}
```

- [ ] **Step 2: 型別檢查通過**

Run:

```bash
npm run build
```

Expected: build 成功，無 TS 錯誤。

- [ ] **Step 3: Commit**

```bash
git add src/composables/useSiteSettings.ts
git commit -m "feat: add useSiteSettings composable to read flash sale window"
```

---

### Task 3: CountdownTimer 三態化

**Files:**
- Modify: `src/view/components/CountdownTimer.vue`

**Interfaces:**
- Consumes: `useNow`（@vueuse/core）。
- Produces: 元件 props `{ startDate?: string | Date | null; targetDate: string | Date }`；三態 `before`（Starts In，倒數到 start）/ `running`（Ending In，倒數到 end）/ `ended`（Promotion Ended，隱藏數字）。

- [ ] **Step 1: 改寫元件**

以下列內容整檔取代 `src/view/components/CountdownTimer.vue`：

```vue
<script setup lang="ts">
import { computed } from 'vue'
import { useNow } from '@vueuse/core'

// startDate 可選：沒給（或無效）就等同「已經開始」，只倒數到 targetDate
const props = defineProps<{
  startDate?: string | Date | null
  targetDate: string | Date
}>()

const now = useNow()

const timeLeft = computed(() => {
  const nowMs = now.value.getTime()
  const endMs = new Date(props.targetDate).getTime()
  const startRaw = props.startDate == null ? Number.NaN : new Date(props.startDate).getTime()

  // 決定目前狀態與要倒數的目標
  let phase: 'before' | 'running' | 'ended'
  let diff: number

  if (!Number.isFinite(endMs)) {
    // 無效結束時間：當進行中且不倒數（首頁會給 fallback，理論上不會走到）
    phase = 'running'
    diff = 0
  } else if (Number.isFinite(startRaw) && nowMs < startRaw) {
    phase = 'before'
    diff = Math.max(0, startRaw - nowMs)
  } else if (nowMs < endMs) {
    phase = 'running'
    diff = Math.max(0, endMs - nowMs)
  } else {
    phase = 'ended'
    diff = 0
  }

  return {
    phase,
    days: String(Math.floor(diff / (1000 * 60 * 60 * 24))),
    hours: String(Math.floor((diff / (1000 * 60 * 60)) % 24)).padStart(2, '0'),
    minutes: String(Math.floor((diff / (1000 * 60)) % 60)).padStart(2, '0'),
    seconds: String(Math.floor((diff / 1000) % 60)).padStart(2, '0'),
  }
})

const label = computed(() => {
  if (timeLeft.value.phase === 'before') return 'Starts In'
  if (timeLeft.value.phase === 'ended') return 'Promotion Ended'
  return 'Ending In'
})

const timeParts = computed(() => [
  { label: 'Days', value: timeLeft.value.days },
  { label: 'Hours', value: timeLeft.value.hours },
  { label: 'Minutes', value: timeLeft.value.minutes },
  { label: 'Seconds', value: timeLeft.value.seconds },
])
</script>

<template>
  <div class="flex flex-wrap items-center justify-end gap-3 rounded-xl bg-surface-container-low px-4 py-2">
    <span class="text-xs font-bold text-on-surface-variant uppercase tracking-widest">
      {{ label }}
    </span>

    <div v-if="timeLeft.phase !== 'ended'" class="flex items-center gap-1.5" aria-label="Time remaining">
      <template v-for="(part, index) in timeParts" :key="part.label">
        <span :aria-label="`${part.label}: ${part.value}`" class="rounded bg-primary px-2 py-1 text-sm font-bold text-white">
          {{ part.value }}
        </span>
        <span v-if="index < timeParts.length - 1" aria-hidden="true" class="font-bold text-primary">:</span>
      </template>
    </div>
  </div>
</template>
```

- [ ] **Step 2: 型別檢查通過**

Run:

```bash
npm run build
```

Expected: build 成功。（此時 HomeView 仍用舊的單一 `targetDate`，因 `startDate` 為可選 props，型別相容、不會壞。）

- [ ] **Step 3: Commit**

```bash
git add src/view/components/CountdownTimer.vue
git commit -m "feat: support three-phase countdown (starts in / ending in / ended)"
```

---

### Task 4: HomeView 串接活動時間

**Files:**
- Modify: `src/view/components/HomeView.vue`

**Interfaces:**
- Consumes: `loadFlashSale`（Task 2）、`CountdownTimer` 的新 props（Task 3）。

- [ ] **Step 1: 改 `<script setup>`**

把 `src/view/components/HomeView.vue` 開頭 import 那行（`import { computed, onMounted } from 'vue'`）改為：

```ts
import { computed, onMounted, ref } from 'vue'
```

並在 `const { products, loadCatalog } = useCatalog()` 下方新增：

```ts
import { loadFlashSale } from '@/composables/useSiteSettings'

// 讀不到設定時的 fallback（沿用原本寫死值，台灣時間）
const DEFAULT_FLASH_SALE_END = '2026-12-31T23:59:59+08:00'
const flashSaleStart = ref<string | Date | null>(null)
const flashSaleEnd = ref<string | Date>(DEFAULT_FLASH_SALE_END)
```

> 註：`import` 請放到檔案頂端的 import 區塊（與其他 import 同一段），此處為方便閱讀才並列。

- [ ] **Step 2: 改 `onMounted`**

把原本的：

```ts
onMounted(() => {
  void loadCatalog()
})
```

改成：

```ts
onMounted(async () => {
  void loadCatalog()
  const window = await loadFlashSale()
  if (window) {
    flashSaleStart.value = window.start
    flashSaleEnd.value = window.end
  }
})
```

- [ ] **Step 3: 改 template 的 CountdownTimer**

把：

```html
<CountdownTimer targetDate="2026-12-31T23:59:59" />
```

改成：

```html
<CountdownTimer :startDate="flashSaleStart" :targetDate="flashSaleEnd" />
```

- [ ] **Step 4: 型別檢查通過**

Run:

```bash
npm run build
```

Expected: build 成功。

- [ ] **Step 5: Commit**

```bash
git add src/view/components/HomeView.vue
git commit -m "feat: drive homepage countdown from site_settings flash sale window"
```

---

### Task 5: 後台側邊外殼 AdminLayout + 巢狀路由

**Files:**
- Create: `src/view/components/AdminLayout.vue`
- Modify: `src/router/index.ts`

**Interfaces:**
- Produces: 具名路由 `AdminProducts`（`/admin/products`）、`AdminOrders`（`/admin/orders`）、`AdminSettings`（`/admin/settings`），全部為 `/admin`（掛 `AdminLayout`、`meta.requiresAdmin`）的子路由；`/admin` 預設導向 `AdminProducts`。

- [ ] **Step 1: 建立 AdminLayout.vue**

Create `src/view/components/AdminLayout.vue`：

```vue
<script setup lang="ts">
import { RouterLink, RouterView, useRoute } from 'vue-router'
import { Package, ClipboardList, Settings } from 'lucide-vue-next'

const route = useRoute()

const navItems = [
  { name: 'AdminProducts', label: '商品管理', icon: Package },
  { name: 'AdminOrders', label: '訂單管理', icon: ClipboardList },
  { name: 'AdminSettings', label: '網站設定', icon: Settings },
]

function itemClass(name: string) {
  const base = 'flex items-center gap-2 whitespace-nowrap rounded-lg px-3 py-2 text-sm font-bold transition-colors'
  return route.name === name
    ? `${base} bg-primary/10 text-primary`
    : `${base} text-on-surface-variant hover:bg-surface-container-low hover:text-primary`
}
</script>

<template>
  <div class="mx-auto max-w-[94vw] px-5 py-6 md:flex md:gap-6">
    <!-- 側邊導覽：手機版收成上方橫向可捲動列 -->
    <aside class="mb-4 md:mb-0 md:w-56 md:shrink-0">
      <p class="mb-3 px-3 text-xs font-bold uppercase tracking-widest text-outline">後台管理</p>
      <nav class="flex gap-2 overflow-x-auto md:flex-col md:gap-1">
        <RouterLink
          v-for="item in navItems"
          :key="item.name"
          :to="{ name: item.name }"
          :class="itemClass(item.name)"
        >
          <component :is="item.icon" class="size-5" />
          <span>{{ item.label }}</span>
        </RouterLink>
      </nav>
    </aside>

    <!-- 右側內容 -->
    <section class="min-w-0 flex-1">
      <RouterView />
    </section>
  </div>
</template>
```

- [ ] **Step 2: 改路由為巢狀**

在 `src/router/index.ts` 的 routes 陣列中，把原本兩筆：

```ts
  {
    path: '/admin/orders',
    name: 'AdminOrders',
    component: () => import('../view/components/AdminOrders.vue'),
    meta: { requiresAdmin: true }
  },
  {
    path: '/admin/products',
    name: 'AdminProducts',
    component: () => import('../view/components/AdminProducts.vue'),
    meta: { requiresAdmin: true }
  },
```

整段替換成：

```ts
  {
    path: '/admin',
    component: () => import('../view/components/AdminLayout.vue'),
    meta: { requiresAdmin: true },
    children: [
      { path: '', redirect: { name: 'AdminProducts' } },
      {
        path: 'products',
        name: 'AdminProducts',
        component: () => import('../view/components/AdminProducts.vue'),
      },
      {
        path: 'orders',
        name: 'AdminOrders',
        component: () => import('../view/components/AdminOrders.vue'),
      },
      {
        path: 'settings',
        name: 'AdminSettings',
        component: () => import('../view/components/AdminSettings.vue'),
      },
    ],
  },
```

> 註：導航守衛用 `to.matched.some(record => record.meta.requiresAdmin)`，巢狀時父層 meta 也在 `matched` 內，`requiresAdmin` 仍然生效，不需改守衛。
>
> 註：此步驟引用了尚未建立的 `AdminSettings.vue`（Task 6）。若採 subagent 逐任務執行，請先完成 Task 6 的建檔，或本步驟先暫時把 `settings` 子路由指到 `AdminProducts`，待 Task 6 完成再改回。以 `npm run build` 通過為準。

- [ ] **Step 3: 型別檢查通過（含 Task 6 完成後）**

Run:

```bash
npm run build
```

Expected: build 成功。

- [ ] **Step 4: Commit**

```bash
git add src/view/components/AdminLayout.vue src/router/index.ts
git commit -m "feat: wrap admin pages in AdminLayout shell with nested routes"
```

---

### Task 6: 網站設定頁 AdminSettings

**Files:**
- Create: `src/view/components/AdminSettings.vue`

**Interfaces:**
- Consumes: `supabase`、`isSupabaseConfigured`（`@/lib/supabase`）、`useAuth`（取 `currentUser`）、`Button`（`@/components/ui/button`）；資料表 `site_settings`。
- Produces: `/admin/settings` 頁面內容，`upsert` `key='flash_sale'` 的 `{start,end}`（+08:00 ISO）。

- [ ] **Step 1: 建立 AdminSettings.vue**

Create `src/view/components/AdminSettings.vue`：

```vue
<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/composables/useAuth'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'

const { currentUser } = useAuth()

const TW_OFFSET = '+08:00'
const startLocal = ref('') // datetime-local 值，視為台灣時間
const endLocal = ref('')
const isLoading = ref(false)
const isSaving = ref(false)
const message = ref('')
const errorMessage = ref('')

// 帶時區的 ISO → datetime-local 顯示字串（換算成台灣時間 YYYY-MM-DDTHH:mm）
function isoToLocalInput(iso: string): string {
  const d = new Date(iso)
  if (!Number.isFinite(d.getTime())) {
    return ''
  }
  const tw = new Date(d.getTime() + 8 * 60 * 60 * 1000)
  return tw.toISOString().slice(0, 16)
}

// datetime-local（視為台灣時間） → 帶 +08:00 的 ISO 字串
function localInputToIso(local: string): string {
  if (!local) {
    return ''
  }
  return `${local}:00${TW_OFFSET}`
}

async function load() {
  if (!isSupabaseConfigured) {
    errorMessage.value = 'Supabase 尚未設定，無法載入設定。'
    return
  }
  isLoading.value = true
  const { data, error } = await supabase
    .from('site_settings')
    .select('value')
    .eq('key', 'flash_sale')
    .maybeSingle()
  isLoading.value = false
  if (error) {
    errorMessage.value = '設定載入失敗。'
    return
  }
  const value = (data as { value?: { start?: string; end?: string } } | null)?.value
  startLocal.value = isoToLocalInput(value?.start ?? '')
  endLocal.value = isoToLocalInput(value?.end ?? '')
}

async function save() {
  errorMessage.value = ''
  message.value = ''
  if (!startLocal.value || !endLocal.value) {
    errorMessage.value = '請填入開始與結束時間。'
    return
  }
  const startIso = localInputToIso(startLocal.value)
  const endIso = localInputToIso(endLocal.value)
  if (new Date(endIso).getTime() <= new Date(startIso).getTime()) {
    errorMessage.value = '結束時間必須晚於開始時間。'
    return
  }

  isSaving.value = true
  const { error } = await supabase
    .from('site_settings')
    .upsert(
      {
        key: 'flash_sale',
        value: { start: startIso, end: endIso },
        updated_at: new Date().toISOString(),
        updated_by: currentUser.value?.id ?? null,
      },
      { onConflict: 'key' },
    )
  isSaving.value = false
  if (error) {
    errorMessage.value = '儲存失敗，請確認你有管理員權限。'
    return
  }
  message.value = '已儲存'
}

onMounted(load)
</script>

<template>
  <div class="max-w-xl">
    <h1 class="mb-1 font-headline text-xl font-bold text-on-surface">網站設定</h1>
    <p class="mb-6 text-sm text-outline">設定首頁折扣倒數的開始與結束時間（台灣時間）。</p>

    <div class="space-y-4 rounded-xl border border-outline-variant bg-surface-container-lowest p-5">
      <div>
        <label class="mb-1 block text-sm font-bold text-on-surface">開始時間</label>
        <input
          v-model="startLocal"
          type="datetime-local"
          class="w-full rounded-lg border border-outline-variant bg-surface px-3 py-2 text-sm text-on-surface"
        />
      </div>
      <div>
        <label class="mb-1 block text-sm font-bold text-on-surface">結束時間</label>
        <input
          v-model="endLocal"
          type="datetime-local"
          class="w-full rounded-lg border border-outline-variant bg-surface px-3 py-2 text-sm text-on-surface"
        />
      </div>

      <div class="flex items-center gap-3 pt-2">
        <Button
          :disabled="isSaving || isLoading"
          class="primary-gradient font-bold text-on-primary hover:opacity-80"
          @click="save"
        >
          {{ isSaving ? '儲存中…' : '儲存' }}
        </Button>
        <span v-if="message" class="text-sm font-bold text-green-600">{{ message }}</span>
        <span v-if="errorMessage" class="text-sm font-bold text-red-600">{{ errorMessage }}</span>
      </div>
    </div>
  </div>
</template>
```

- [ ] **Step 2: 型別檢查通過**

Run:

```bash
npm run build
```

Expected: build 成功。

- [ ] **Step 3: Commit**

```bash
git add src/view/components/AdminSettings.vue
git commit -m "feat: add admin site settings page to edit flash sale window"
```

---

### Task 7: NavBar 收斂成單一「後台管理」入口

**Files:**
- Modify: `src/view/components/NavBar.vue`

**Interfaces:**
- Consumes: 具名路由 `/admin`（Task 5）。

- [ ] **Step 1: 桌機版入口改為單一「後台管理」**

在 `src/view/components/NavBar.vue` 桌機版 `<div class="hidden md:flex ...">` 內，把原本兩個分開的 admin 連結：

```html
        <RouterLink v-if="isAdmin" to="/admin/products" :class="navItemClass('/admin/products')" class="gap-2">
          <Package class="size-5" />
          <span class="font-bold text-xs">商品管理</span>
        </RouterLink>

        <RouterLink v-if="currentUser" to="/admin/orders" :class="navItemClass('/admin/orders')" class="gap-2">
          <ClipboardList class="size-5" />
          <span class="font-bold text-xs">{{ isAdmin ? '訂單管理' : '我的訂單' }}</span>
        </RouterLink>
```

替換成（僅管理員可見的單一入口；`navItemClass('/admin')` 讓整個後台區段都維持 active）：

```html
        <RouterLink v-if="isAdmin" to="/admin" :class="navItemClass('/admin')" class="gap-2">
          <LayoutDashboard class="size-5" />
          <span class="font-bold text-xs">後台管理</span>
        </RouterLink>
```

> 註：一般客人的「我的訂單」入口本來就因 `/admin/orders` 為 `requiresAdmin` 而無法使用（既有 bug，屬範圍外）。本次移除該入口即可，不在此修客人訂單流程。

- [ ] **Step 2: 手機版入口同步**

在手機版底部 `<nav class="fixed bottom-0 ...">` 內，把：

```html
    <RouterLink v-if="isAdmin" to="/admin/products" class="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors">
      <Package class="size-6" />
      <span class="text-[10px] font-bold">商品</span>
    </RouterLink>
```

替換成：

```html
    <RouterLink v-if="isAdmin" to="/admin" class="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors">
      <LayoutDashboard class="size-6" />
      <span class="text-[10px] font-bold">後台</span>
    </RouterLink>
```

- [ ] **Step 3: 更新 lucide 圖示 import**

在 `src/view/components/NavBar.vue` 的 lucide-vue-next import 區塊，把 `LayoutDashboard` 加入（`ClipboardList`、`Package` 若已無其他使用可一併移除，以 build 是否報未使用為準）：

```ts
import {
  Search, ShoppingCart, User,
  LayoutGrid, Cookie, Coffee, Laptop, Watch,
  Home as HomeIcon, Grid, ShoppingBag, LayoutDashboard
} from 'lucide-vue-next'
```

> 註：`ClipboardList`、`Package` 若移除後 build 沒報未使用錯誤即可；若仍有其他地方使用則保留。以 `npm run build` 通過為準。

- [ ] **Step 4: 型別檢查通過**

Run:

```bash
npm run build
```

Expected: build 成功，無未使用變數錯誤。

- [ ] **Step 5: Commit**

```bash
git add src/view/components/NavBar.vue
git commit -m "feat: consolidate admin nav into single 後台管理 entry"
```

---

### Task 8: 端對端驗證（三態 + 後台外殼）

**Files:**
- Create: `.claude/launch.json`

- [ ] **Step 1: 建立 preview 設定**

Create `.claude/launch.json`：

```json
{
  "version": "0.0.1",
  "configurations": [
    {
      "name": "online_shop dev",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "port": 5173
    }
  ]
}
```

- [ ] **Step 2: 起 dev server 並驗證後台外殼**

用 preview 開 `online_shop dev`，以管理員帳號登入後前往 `/admin`：

Expected:
- 自動導向 `/admin/products`，左側側邊欄有「商品管理／訂單管理／網站設定」。
- 點三個項目網址分別為 `/admin/products`、`/admin/orders`、`/admin/settings`，內容正確、當前項目 active。
- 以非管理員身分開 `/admin` 會被導回首頁。

- [ ] **Step 3: 驗證設定頁存檔**

在 `/admin/settings` 改開始／結束時間後按「儲存」：

Expected:
- 顯示「已儲存」。
- 結束早於開始時，顯示「結束時間必須晚於開始時間。」且不送出。
- 重新整理頁面後，欄位仍顯示剛儲存的值。

- [ ] **Step 4: 驗證首頁倒數三態**

在設定頁分別設定三種情境並回首頁觀察折扣區倒數：

Expected:
- 開始時間設在未來 → 顯示 `Starts In` 並倒數到開始。
- 開始在過去、結束在未來 → 顯示 `Ending In` 並倒數到結束。
- 結束時間設在過去 → 顯示 `Promotion Ended`，數字隱藏。

- [ ] **Step 5: 更新 spec 文件狀態並 commit**

把 `docs/superpowers/specs/2026-09-20-admin-backend-and-flash-sale-time-design.md` 的狀態標記為「已實作」，並在根目錄 README 的「功能」表補一列（若該專案 README 有此慣例的表）。

```bash
git add .claude/launch.json docs/superpowers/specs/2026-09-20-admin-backend-and-flash-sale-time-design.md README.md
git commit -m "chore: add dev preview config and mark flash sale feature implemented"
```

---

## Self-Review

**1. Spec coverage：**
- 資料層 `site_settings` + RLS + 種子 → Task 1 ✅
- 讀取層 `useSiteSettings` + 防呆 → Task 2 ✅
- CountdownTimer 三態 → Task 3 ✅
- HomeView 串接 + fallback → Task 4 ✅
- 後台側邊外殼 + 巢狀路由 → Task 5 ✅
- 設定頁（datetime-local + 驗證 + upsert） → Task 6 ✅
- NavBar 收斂單一入口 → Task 7 ✅
- 台灣時間 +08:00：Task 1 種子、Task 4 fallback、Task 6 轉換函式皆採用 ✅
- 驗證三態 / 外殼 / 存檔 → Task 8 ✅
- 範圍外（客人「我的訂單」bug、多活動管理、其他設定）→ 未新增任務，符合 spec ✅

**2. Placeholder scan：** 無 TBD/TODO；每個程式步驟皆附完整程式碼與確切指令。✅

**3. Type consistency：**
- `loadFlashSale()` 回傳 `FlashSaleWindow | null`，Task 4 以 `if (window)` 取用 `window.start/end`（`Date`）→ 對應 CountdownTimer `startDate?: string | Date | null`、`targetDate: string | Date` ✅
- 具名路由 `AdminProducts / AdminOrders / AdminSettings` 在 Task 5 定義，Task 5 AdminLayout 的 `navItems.name` 與 Task 7 `to="/admin"` 一致 ✅
- `site_settings` 欄位 `key/value/updated_at/updated_by` 在 Task 1 定義，Task 2 讀 `value`、Task 6 upsert 四欄一致 ✅
- 相依順序註記：Task 5 引用 Task 6 的 `AdminSettings.vue`，已在 Task 5 Step 2 註明先後處理方式 ✅
