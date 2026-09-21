<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useNow } from '@vueuse/core'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import CountdownTimer from './CountdownTimer.vue'
import { Zap } from 'lucide-vue-next'
import { formatPrice, useCatalog } from '@/composables/useCatalog'
import { loadFlashSale } from '@/composables/useSiteSettings'
import { supabase } from '@/lib/supabase'

const { products, loadCatalog } = useCatalog()

// 讀不到設定時的 fallback（沿用原本寫死值，台灣時間）
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

// 是否在活動時間內（now ∈ [開始, 結束]）；每秒更新
const now = useNow()
const isFlashActive = computed(() => {
  const t = now.value.getTime()
  const startMs = flashSaleStart.value ? new Date(flashSaleStart.value).getTime() : Number.NaN
  const endMs = new Date(flashSaleEnd.value).getTime()
  const started = !Number.isFinite(startMs) || t >= startMs
  const notEnded = !Number.isFinite(endMs) || t < endMs
  return started && notEnded
})
// 首頁限時優惠只在「有選商品」且「活動時間內」才顯示
const showFlashSale = computed(() => flashSaleItems.value.length > 0 && isFlashActive.value)

// 熱銷商品：依實際銷量排行（top_selling_products），不足 5 個用其餘上架商品補滿
const topSellerIds = ref<string[]>([])
const bestSellerItems = computed(() => {
  const byId = new Map(products.value.map((product) => [product.id, product]))
  const picked: typeof products.value = []
  const seen = new Set<string>()
  for (const id of topSellerIds.value) {
    const product = byId.get(id)
    if (product && !seen.has(id)) {
      picked.push(product)
      seen.add(id)
    }
  }
  for (const product of products.value) {
    if (picked.length >= 5) break
    if (!seen.has(product.id)) {
      picked.push(product)
      seen.add(product.id)
    }
  }
  return picked.slice(0, 5)
})

async function loadTopSellers() {
  const { data, error } = await supabase.rpc('top_selling_products', { limit_count: 8 })
  if (error) {
    console.warn('Top selling products could not be loaded.', error)
    return
  }
  topSellerIds.value = ((data ?? []) as Array<{ product_id: string }>).map((row) => row.product_id)
}

onMounted(async () => {
  void loadCatalog()
  void loadTopSellers()
  const window = await loadFlashSale()
  if (window) {
    flashSaleStart.value = window.start
    flashSaleEnd.value = window.end
    flashSaleProductIds.value = window.productIds
    flashSaleDiscount.value = window.discount
  }
})

</script>

<template>
  <div class="bg-surface font-body text-on-surface antialiased min-h-screen">
    
    <main class="mx-auto max-w-[94vw]">
      <!-- 封面形象照 -->
      <section class="mb-10 px-5">
        <div class="relative h-[450px] w-full overflow-hidden rounded-xl group">
          <img alt="minimalist fashion boutique" class="w-full h-full object-cover" src="@/assets/—Pngtree—supermarket blur background_15628023.png"/>
          <div class="absolute inset-0 bg-gradient-to-r from-black/60 to-transparent flex items-center px-14">
            <div class="max-w-lg text-white">
              <span class="mb-3 inline-block rounded-full py-1.5 text-sm font-bold uppercase tracking-widest">The Summer Edit '26</span>
              <h1 class="mb-7 font-headline text-[46px] font-extrabold leading-tight">Small Goods<br/>Big Joy</h1>
              <!-- <p class="text-lg text-white/80 mb-8 font-body">Discover a curated selection of minimalist essentials designed for the modern professional.</p> -->
              <div class="flex">
                <Button as-child class="primary-gradient h-11 px-6 font-bold text-on-primary shadow-lg hover:opacity-80">
                  <RouterLink to="/products">
                    開始購物
                  </RouterLink>
                </Button>
              </div>
            </div>
          </div>
        </div>
      </section>
      <!-- 封面形象照 -->
      <!-- sales -->
      <section v-if="showFlashSale" class="mb-14 px-5">
        <!-- sales最上方說明 -->
        <div class="mb-7 flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
          <div>
            <div class="mb-1 flex items-center gap-2.5">
              <Zap class="size-7 fill-primary text-primary" />
              <h2 class="font-headline text-xl font-bold uppercase tracking-tight text-on-surface">限時優惠</h2>
            </div>
            <p class="text-sm text-outline">嚴選好物，限時特價，錯過不再。</p>
          </div>
          <CountdownTimer :startDate="flashSaleStart" :targetDate="flashSaleEnd" />
        </div>
        <!-- sales最上方說明 -->
        <!-- sales商品展示 -->
        <div class="grid grid-cols-1 gap-5 md:grid-cols-4">
          <!-- 左邊大圖 -->
          <Card class="md:col-span-2 md:row-span-2 bg-surface-container-lowest border-none overflow-hidden group hover:shadow-2xl transition-all duration-500 relative">
            <div class="h-full aspect-square md:aspect-auto">
              <img :alt="flashSaleItems[0].name" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700" :src="flashSaleItems[0].image"/>
            </div>
            <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-white via-white/90 to-transparent p-7">
              <p class="mb-2 text-sm font-bold text-primary">{{ flashSaleItems[0].tag }}</p>
              <h3 class="mb-2 text-xl font-bold">{{ flashSaleItems[0].name }}</h3>
              <div class="flex items-center gap-3">
                <span class="text-xl font-black text-on-surface">{{ formatPrice(salePrice(flashSaleItems[0].price)) }}</span>
                <span v-if="hasDiscount" class="text-outline line-through text-sm">{{ formatPrice(flashSaleItems[0].price) }}</span>
              </div>
              <Button as-child class="primary-gradient mt-5 w-full translate-y-4 font-bold text-white opacity-0 transition-all duration-300 group-hover:translate-y-0 group-hover:opacity-100">
                <RouterLink :to="`/product/${flashSaleItems[0].slug}`">查看商品</RouterLink>
              </Button>
            </div>
          </Card>
          <!-- 左邊大圖 -->
          <!-- 右邊四小圖 -->
          <Card v-for="item in flashSaleItems.slice(1)" :key="item.id" class="group flex flex-col justify-between border-none bg-surface-container-lowest p-3.5 shadow-sm transition-all hover:-translate-y-1">
            <div>
              <div class="mb-3.5 aspect-square overflow-hidden rounded-lg bg-surface-container-low">
                <img :alt="item.name" class="w-full h-full object-cover mix-blend-multiply" :src="item.image"/>
              </div>
              <h4 class="font-bold text-on-surface truncate">{{ item.name }}</h4>
            </div>
            
            <div class="mt-3.5 flex items-center justify-between">
              <span class="flex items-baseline gap-1.5">
                <span class="text-base font-bold text-primary">{{ formatPrice(salePrice(item.price)) }}</span>
                <span v-if="hasDiscount" class="text-outline line-through text-xs">{{ formatPrice(item.price) }}</span>
              </span>

              <Button as-child class="primary-gradient h-8 translate-y-4 px-3.5 text-xs font-bold text-white opacity-0 transition-all duration-300 group-hover:translate-y-0 group-hover:opacity-100">
                <RouterLink :to="`/product/${item.slug}`">查看</RouterLink>
              </Button>
            </div>
          </Card>
          <!-- 右邊四小圖 -->
        </div>
        <!-- sales商品展示 -->
      </section>
      <!-- sales -->

      <!-- 熱銷商品：不在活動時間時補上 -->
      <section v-if="!showFlashSale && bestSellerItems.length" class="mb-14 px-5">
        <div class="mb-7">
          <div class="mb-1 flex items-center gap-2.5">
            <Zap class="size-7 fill-primary text-primary" />
            <h2 class="font-headline text-xl font-bold uppercase tracking-tight text-on-surface">熱銷商品</h2>
          </div>
          <p class="text-sm text-outline">大家都在買，人氣精選推薦。</p>
        </div>

        <div class="grid grid-cols-1 gap-5 md:grid-cols-4">
          <!-- #1 大圖 -->
          <Card class="md:col-span-2 md:row-span-2 bg-surface-container-lowest border-none overflow-hidden group hover:shadow-2xl transition-all duration-500 relative">
            <div class="h-full aspect-square md:aspect-auto">
              <img :alt="bestSellerItems[0].name" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700" :src="bestSellerItems[0].image"/>
            </div>
            <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-white via-white/90 to-transparent p-7">
              <p class="mb-2 text-sm font-bold text-primary">熱銷 #1</p>
              <h3 class="mb-2 text-xl font-bold">{{ bestSellerItems[0].name }}</h3>
              <div class="flex items-center gap-3">
                <span class="text-xl font-black text-on-surface">{{ formatPrice(bestSellerItems[0].price) }}</span>
                <span v-if="bestSellerItems[0].originalPrice" class="text-outline line-through text-sm">{{ formatPrice(bestSellerItems[0].originalPrice) }}</span>
              </div>
              <Button as-child class="primary-gradient mt-5 w-full translate-y-4 font-bold text-white opacity-0 transition-all duration-300 group-hover:translate-y-0 group-hover:opacity-100">
                <RouterLink :to="`/product/${bestSellerItems[0].slug}`">查看商品</RouterLink>
              </Button>
            </div>
          </Card>
          <!-- #2~#5 四小圖 -->
          <Card v-for="(item, index) in bestSellerItems.slice(1)" :key="item.id" class="group flex flex-col justify-between border-none bg-surface-container-lowest p-3.5 shadow-sm transition-all hover:-translate-y-1">
            <div>
              <div class="mb-3.5 aspect-square overflow-hidden rounded-lg bg-surface-container-low">
                <img :alt="item.name" class="w-full h-full object-cover mix-blend-multiply" :src="item.image"/>
              </div>
              <p class="mb-1 text-xs font-bold text-primary">熱銷 #{{ index + 2 }}</p>
              <h4 class="font-bold text-on-surface truncate">{{ item.name }}</h4>
            </div>

            <div class="mt-3.5 flex items-center justify-between">
              <span class="flex items-baseline gap-1.5">
                <span class="text-base font-bold text-primary">{{ formatPrice(item.price) }}</span>
                <span v-if="item.originalPrice" class="text-outline line-through text-xs">{{ formatPrice(item.originalPrice) }}</span>
              </span>

              <Button as-child class="primary-gradient h-8 translate-y-4 px-3.5 text-xs font-bold text-white opacity-0 transition-all duration-300 group-hover:translate-y-0 group-hover:opacity-100">
                <RouterLink :to="`/product/${item.slug}`">查看</RouterLink>
              </Button>
            </div>
          </Card>
        </div>
      </section>
      <!-- 熱銷商品 -->
    </main>
  </div>
</template>

<style>
@layer base {
  :root {
    --primary: #b22203;
    --primary-container: #ff775b;
    --on-primary: #ffefec;
    --on-primary-container: #4b0700;
    --secondary-container: #bdd2ff;
    --on-secondary-container: #004592;
    --surface: #f6f6f8;
    --surface-container-low: #f0f1f3;
    --surface-container-highest: #dbdde0;
    --surface-container-lowest: #ffffff;
    --on-surface: #2d2f31;
    --on-surface-variant: #5a5c5d;
    --outline: #757779;
    --outline-variant: #acadaf;
    --error-container: #f74b6d;
    --on-error-container: #510017;
  }
}

</style>
