<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
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
