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
              <img v-if="product.image" :src="product.image" :alt="product.name" loading="lazy" class="h-full w-full object-cover" />
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
