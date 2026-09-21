<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useAuth } from '@/composables/useAuth'
import { formatPrice } from '@/composables/useCatalog'
import { supabase } from '@/lib/supabase'

interface EditableProduct {
  id: string
  slug: string
  category_id: string
  name: string
  price: number | string
  original_price: number | string
  tag: string
  status: string
  quantity: number | string
  reserved_quantity: number
  saving: boolean
  savedAt: number | null
  error: string
}

interface Category {
  id: string
  name: string
}

const { isAuthReady, isAdmin } = useAuth()

const products = ref<EditableProduct[]>([])
const categories = ref<Category[]>([])
const isLoading = ref(false)
const loadError = ref('')
const statusFilter = ref<'all' | 'active' | 'draft' | 'archived'>('all')

const statusOptions = [
  { value: 'active', label: '上架' },
  { value: 'draft', label: '草稿' },
  { value: 'archived', label: '封存' },
]

const filteredProducts = computed(() =>
  statusFilter.value === 'all'
    ? products.value
    : products.value.filter((product) => product.status === statusFilter.value),
)

async function loadData() {
  isLoading.value = true
  loadError.value = ''

  const [{ data: categoryRows, error: categoryError }, { data: productRows, error: productError }] = await Promise.all([
    supabase.from('categories').select('id, name').order('sort_order', { ascending: true }),
    // 管理員可讀所有狀態的商品；帶出庫存
    supabase
      .from('products')
      .select('id, slug, category_id, name, price, original_price, tag, status, sort_order, inventory(quantity, reserved_quantity)')
      .order('sort_order', { ascending: true }),
  ])

  if (categoryError || productError) {
    loadError.value = (categoryError ?? productError)?.message ?? '資料載入失敗。'
    isLoading.value = false
    return
  }

  categories.value = (categoryRows ?? []) as Category[]

  products.value = ((productRows ?? []) as unknown as Array<Record<string, unknown>>).map((row) => {
    const inv = Array.isArray(row.inventory) ? row.inventory[0] : row.inventory
    const inventory = (inv ?? null) as { quantity: number | null; reserved_quantity: number | null } | null
    return {
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
      saving: false,
      savedAt: null,
      error: '',
    }
  })

  isLoading.value = false
}

async function saveProduct(product: EditableProduct) {
  product.saving = true
  product.error = ''
  product.savedAt = null

  const price = Number(product.price)
  const originalPrice = product.original_price === null || product.original_price === ''
    ? null
    : Number(product.original_price)
  const quantity = Math.max(0, Math.trunc(Number(product.quantity)))

  if (Number.isNaN(price) || price < 0) {
    product.error = '售價需為 0 以上的數字。'
    product.saving = false
    return
  }
  if (originalPrice !== null && (Number.isNaN(originalPrice) || originalPrice < price)) {
    product.error = '原價需大於或等於售價。'
    product.saving = false
    return
  }
  if (quantity < product.reserved_quantity) {
    product.error = `庫存不可低於已保留數量（${product.reserved_quantity}）。`
    product.saving = false
    return
  }

  const { error: productError } = await supabase
    .from('products')
    .update({
      name: product.name,
      category_id: product.category_id,
      price,
      original_price: originalPrice,
      tag: product.tag ? product.tag : null,
      status: product.status,
    })
    .eq('id', product.id)

  if (productError) {
    product.error = productError.message
    product.saving = false
    return
  }

  const { error: inventoryError } = await supabase
    .from('inventory')
    .upsert({ product_id: product.id, quantity }, { onConflict: 'product_id' })

  if (inventoryError) {
    product.error = inventoryError.message
    product.saving = false
    return
  }

  product.price = price
  product.original_price = originalPrice ?? ''
  product.quantity = quantity
  product.saving = false
  product.savedAt = Date.now()
}

watch(
  [isAuthReady, isAdmin],
  ([ready, admin]) => {
    if (ready && admin) {
      void loadData()
    }
  },
  { immediate: true },
)
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
        <div v-if="isLoading" class="space-y-4">
          <div v-for="index in 4" :key="index" class="h-28 animate-pulse rounded-xl bg-surface-container-lowest" />
        </div>

        <div v-else-if="loadError" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-error">
          {{ loadError }}
        </div>

        <div v-else class="space-y-4">
          <section v-for="product in filteredProducts" :key="product.id" class="rounded-xl bg-surface-container-lowest p-5 shadow-sm md:p-6">
            <div class="mb-4 flex items-center justify-between gap-3">
              <p class="font-mono text-xs text-on-surface-variant">{{ product.slug }}</p>
              <span
                class="rounded-full px-3 py-1 text-xs font-bold"
                :class="{
                  'bg-primary/10 text-primary': product.status === 'active',
                  'bg-surface-container text-on-surface-variant': product.status === 'draft',
                  'bg-error/10 text-error': product.status === 'archived',
                }"
              >
                {{ statusOptions.find((option) => option.value === product.status)?.label ?? product.status }}
              </span>
            </div>

            <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
              <label class="flex flex-col gap-1.5 md:col-span-2 lg:col-span-1">
                <span class="text-sm font-semibold text-on-surface-variant">商品名稱</span>
                <Input v-model="product.name" />
              </label>
              <label class="flex flex-col gap-1.5">
                <span class="text-sm font-semibold text-on-surface-variant">分類</span>
                <select v-model="product.category_id" class="h-9 rounded-md border border-input bg-transparent px-3 text-sm outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50">
                  <option v-for="category in categories" :key="category.id" :value="category.id">{{ category.name }}</option>
                </select>
              </label>
              <label class="flex flex-col gap-1.5">
                <span class="text-sm font-semibold text-on-surface-variant">狀態</span>
                <select v-model="product.status" class="h-9 rounded-md border border-input bg-transparent px-3 text-sm outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50">
                  <option v-for="option in statusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
              </label>
              <label class="flex flex-col gap-1.5">
                <span class="text-sm font-semibold text-on-surface-variant">售價</span>
                <Input v-model="product.price" type="number" min="0" />
              </label>
              <label class="flex flex-col gap-1.5">
                <span class="text-sm font-semibold text-on-surface-variant">原價（選填）</span>
                <Input v-model="product.original_price" type="number" min="0" placeholder="無折扣可留空" />
              </label>
              <label class="flex flex-col gap-1.5">
                <span class="text-sm font-semibold text-on-surface-variant">標籤（選填）</span>
                <Input v-model="product.tag" placeholder="例：人氣、新品" />
              </label>
              <label class="flex flex-col gap-1.5">
                <span class="text-sm font-semibold text-on-surface-variant">
                  庫存數量<span class="ml-1 font-normal text-outline-variant">（已保留 {{ product.reserved_quantity }}）</span>
                </span>
                <Input v-model="product.quantity" type="number" min="0" />
              </label>
            </div>

            <div class="mt-4 flex items-center justify-end gap-3">
              <p v-if="product.error" class="mr-auto text-sm font-medium text-error">{{ product.error }}</p>
              <p v-else-if="product.savedAt" class="mr-auto text-sm font-medium text-primary">已儲存</p>
              <span class="text-sm text-on-surface-variant">目前售價 {{ formatPrice(Number(product.price) || 0) }}</span>
              <Button class="primary-gradient rounded-lg px-6 font-bold text-on-primary" :disabled="product.saving" @click="saveProduct(product)">
                {{ product.saving ? '儲存中' : '儲存' }}
              </Button>
            </div>
          </section>

          <div v-if="!filteredProducts.length" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-on-surface-variant">
            這個狀態目前沒有商品。
          </div>
        </div>
      </template>
    </main>
  </div>
</template>
