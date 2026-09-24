<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/composables/useAuth'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'
import { formatPrice } from '@/composables/useCatalog'
import AdminPageHeader from './AdminPageHeader.vue'

const { currentUser } = useAuth()

const TW_OFFSET = '+08:00'
const startLocal = ref('') // datetime-local 值，視為台灣時間
const endLocal = ref('')
const isLoading = ref(false)
const isSaving = ref(false)
const message = ref('')
const errorMessage = ref('')

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
  const discountNum = Number(discount.value)
  if (!Number.isFinite(discountNum) || discountNum <= 0 || discountNum > 10) {
    errorMessage.value = '折數需為 0（不含）到 10 之間（8 = 八折，10 = 無折扣）。'
    return
  }

  isSaving.value = true
  const { error } = await supabase
    .from('site_settings')
    .upsert(
      {
        key: 'flash_sale',
        value: { start: startIso, end: endIso, product_ids: Array.from(selectedIds.value), discount: discountNum },
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

// 依目前填的時間判斷活動狀態（未開始／進行中／已結束），顯示在左欄標題旁
const saleStatus = computed(() => {
  const start = new Date(localInputToIso(startLocal.value)).getTime()
  const end = new Date(localInputToIso(endLocal.value)).getTime()
  if (!Number.isFinite(start) || !Number.isFinite(end)) {
    return { label: '尚未設定', class: 'bg-surface-container text-on-surface-variant' }
  }
  const now = Date.now()
  if (now < start) return { label: '未開始', class: 'bg-surface-container text-on-surface-variant' }
  if (now < end) return { label: '進行中', class: 'bg-primary/10 text-primary' }
  return { label: '已結束', class: 'bg-surface-container text-outline' }
})

// 折扣試算：原價 $100 在目前折數下的折後價；折數不合法就不顯示
const discountPreview = computed(() => {
  const value = Number(discount.value)
  if (!Number.isFinite(value) || value <= 0 || value > 10) {
    return ''
  }
  return formatPrice(Math.round(value * 10))
})

const labelClass = 'mb-1.5 block text-sm font-bold text-on-surface'
const inputClass = 'w-full rounded-lg border border-outline-variant bg-surface px-3 py-2 text-sm text-on-surface'
</script>

<template>
  <div class="pb-16">
    <AdminPageHeader title="網站設定" description="設定首頁限時特賣的時間（台灣時間）、折數與參加商品。" />

    <p v-if="message" class="mb-4 rounded-lg bg-primary/10 px-4 py-3 text-sm font-bold text-primary">{{ message }}</p>
    <p v-if="errorMessage" class="mb-4 rounded-lg bg-error/10 px-4 py-3 text-sm font-bold text-error">{{ errorMessage }}</p>

    <!-- 全寬卡片，內部左右兩欄：左＝時間與折扣，右＝活動商品 -->
    <div class="rounded-xl bg-surface-container-lowest shadow-sm">
      <div class="grid gap-8 p-5 md:p-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.4fr)]">
        <!-- 左欄：活動時間與折扣 -->
        <section class="space-y-5">
          <div class="flex items-center justify-between gap-3">
            <h2 class="font-headline text-lg font-bold">活動時間與折扣</h2>
            <span :class="['rounded-full px-3 py-1 text-xs font-bold', saleStatus.class]">{{ saleStatus.label }}</span>
          </div>

          <div>
            <label :class="labelClass">開始時間</label>
            <input v-model="startLocal" type="datetime-local" :class="inputClass" />
          </div>
          <div>
            <label :class="labelClass">結束時間</label>
            <input v-model="endLocal" type="datetime-local" :class="inputClass" />
          </div>

          <div>
            <label :class="labelClass">折扣（幾折）<span class="font-normal text-outline">（8 = 八折；10 = 無折扣）</span></label>
            <input v-model="discount" type="number" min="0.1" max="10" step="0.1" :class="inputClass" />
            <p v-if="discountPreview" class="mt-2 rounded-lg bg-surface-container-low px-3 py-2 text-sm text-on-surface-variant">
              試算：原價 $100 → 折後 <span class="font-bold text-primary">{{ discountPreview }}</span>
            </p>
          </div>
        </section>

        <!-- 右欄：活動商品 -->
        <section class="flex min-w-0 flex-col">
          <div class="mb-3 flex items-center justify-between gap-3">
            <h2 class="font-headline text-lg font-bold">活動商品</h2>
            <span class="text-sm text-on-surface-variant">已選 <span class="font-bold text-primary">{{ selectedIds.size }}</span> 項</span>
          </div>
          <input v-model="productKeyword" type="text" placeholder="搜尋商品…" :class="['mb-3', inputClass]" />
          <div class="max-h-[22rem] flex-1 overflow-y-auto rounded-lg border border-outline-variant/60">
            <label
              v-for="product in filteredPickProducts"
              :key="product.id"
              class="flex cursor-pointer items-center gap-3 border-b border-outline-variant/40 px-4 py-2.5 last:border-b-0 hover:bg-surface-container-low"
            >
              <input type="checkbox" class="size-4 accent-primary" :checked="selectedIds.has(product.id)" @change="toggleProduct(product.id)" />
              <span class="text-sm text-on-surface">{{ product.name }}</span>
              <span class="ml-auto text-sm text-outline">{{ formatPrice(product.price) }}</span>
            </label>
            <p v-if="!filteredPickProducts.length" class="px-3 py-6 text-center text-sm text-outline">找不到商品。</p>
          </div>
        </section>
      </div>

      <!-- 底部操作列 -->
      <div class="flex justify-end border-t border-outline-variant/40 px-5 py-4 md:px-6">
        <Button
          :disabled="isSaving || isLoading"
          class="primary-gradient rounded-lg font-bold text-on-primary"
          @click="save"
        >
          {{ isSaving ? '儲存中…' : '儲存設定' }}
        </Button>
      </div>
    </div>
  </div>
</template>
