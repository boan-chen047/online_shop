<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { ArrowRight, ChevronRight, ChevronDown } from 'lucide-vue-next'
import { formatPrice, useCatalog } from '@/composables/useCatalog'
import {
  Pagination,
  PaginationContent,
  PaginationEllipsis,
  PaginationItem,
  PaginationNext,
  PaginationPrevious,
} from '@/components/ui/pagination'

const route = useRoute()
const { categories, products, isLoading, errorMessage, loadCatalog } = useCatalog()

onMounted(() => {
  void loadCatalog()
})

const categoryNames = computed(() =>
  Object.fromEntries(categories.value.map((category) => [category.slug, category.name])),
)

const currentCategoryName = computed(() => {
  const category = typeof route.query.category === 'string' ? route.query.category : ''
  return category && category in categoryNames.value ? categoryNames.value[category] : '全部商品'
})

const sortBy = ref('推薦排序')
const currentPage = ref(1)
const itemsPerPage = 16

const filteredProducts = computed(() => {
  const category = typeof route.query.category === 'string' ? route.query.category : ''
  return category && category in categoryNames.value
    ? products.value.filter(product => product.categorySlug === category)
    : products.value
})

const sortedProducts = computed(() => {
  const result = [...filteredProducts.value]
  if (sortBy.value === '價格：低到高') {
    result.sort((a, b) => a.price - b.price)
  } else if (sortBy.value === '價格：高到低') {
    result.sort((a, b) => b.price - a.price)
  } else if (sortBy.value === '最新上架') {
    result.sort((a, b) => b.sortOrder - a.sortOrder)
  }
  return result
})

const paginatedProducts = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return sortedProducts.value.slice(start, start + itemsPerPage)
})

watch(
  () => route.query.category,
  () => {
    currentPage.value = 1
  }
)
</script>

<template>
  <div class="bg-surface text-on-surface font-body antialiased h-full">
    <main class="mx-auto flex max-w-[94vw] flex-col gap-6 px-5 pt-4 pb-4">
      
      <section class="grow">
        <div class="mb-6 flex flex-col justify-between gap-4 md:flex-row md:items-center">
          <nav class="flex items-center gap-2 text-sm text-outline">
            <RouterLink class="hover:text-on-surface transition-colors" to="/">首頁</RouterLink>
            <ChevronRight class="size-4" />
            <span class="font-medium text-on-surface">{{ currentCategoryName }}</span>
          </nav>
          
          <div class="flex items-center gap-3">
            <span class="text-sm text-outline">排序：</span>
            <div class="relative">
              <select v-model="sortBy" class="cursor-pointer appearance-none rounded-full border-2 border-primary bg-transparent py-1.5 pr-10 pl-4 text-sm font-semibold text-on-surface focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all">
                <option>推薦排序</option>
                <option>價格：低到高</option>
                <option>價格：高到低</option>
                <option>最新上架</option>
              </select>
              <ChevronDown class="size-4 pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-on-surface" />
            </div>
          </div>
        </div>

        <div v-if="isLoading" class="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
          <div v-for="index in 8" :key="index" class="h-80 animate-pulse rounded-xl bg-surface-container-lowest" />
        </div>

        <div v-else-if="errorMessage" class="rounded-xl bg-surface-container-lowest p-10 text-center text-error">
          {{ errorMessage }}
        </div>

        <div v-else class="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
          <RouterLink
            v-for="product in paginatedProducts"
            :key="product.id"
            :to="`/product/${product.slug}`"
            class="group flex flex-row overflow-hidden rounded-xl border border-outline-variant/30 bg-surface-container-lowest shadow-sm transition-all hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary lg:flex-col"
            :aria-label="`查看 ${product.name}`"
          >
            <div class="h-40 w-40 shrink-0 overflow-hidden bg-surface-container-low sm:h-44 sm:w-44 lg:h-auto lg:w-full lg:aspect-[20/17]">
              <img :alt="product.name" class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-[1.03]" :src="product.image"/>
            </div>
            <div class="flex flex-1 flex-col px-4 pb-4 pt-3.5">
              <div class="mb-2.5 flex min-h-5 items-center justify-between gap-3">
                <p class="text-xs font-semibold text-on-surface-variant">{{ product.categoryName }}</p>
                <span v-if="product.tag" class="rounded-full bg-primary/10 px-2 py-0.5 text-[11px] font-bold text-primary">{{ product.tag }}</span>
              </div>

              <h4 class="line-clamp-2 text-lg font-extrabold leading-[1.35] text-on-surface transition-colors group-hover:text-primary">{{ product.name }}</h4>

              <div class="mt-3 flex items-end justify-between gap-3">
                <div class="flex items-baseline gap-2">
                  <span class="text-xl font-extrabold text-primary">{{ formatPrice(product.price) }}</span>
                  <span v-if="product.originalPrice" class="text-xs font-medium text-outline line-through">{{ formatPrice(product.originalPrice) }}</span>
                </div>
                <span class="mt-auto inline-flex items-center gap-1 self-end text-xs font-bold uppercase tracking-[0.06em] text-on-surface-variant transition-colors group-hover:text-primary">
                  查看
                  <ArrowRight class="size-4 transition-transform group-hover:translate-x-0.5" />
                </span>
              </div>
            </div>
          </RouterLink>
        </div>

        <div v-if="!isLoading && !errorMessage && paginatedProducts.length === 0" class="rounded-xl bg-surface-container-lowest p-10 text-center text-on-surface-variant">
          這個分類目前沒有可購買商品。
        </div>

        <div class="mt-8 flex justify-center">
            <Pagination v-slot="{ page }" v-model:page="currentPage" :total="sortedProducts.length" :items-per-page="itemsPerPage" :sibling-count="1" show-edges>
              
              <PaginationContent v-slot="{ items }" class="flex items-center gap-1">
                
                <PaginationPrevious class="h-10 px-4 border-2 bg-white hover:bg-gray-100" />
                
                <template v-for="(item, index) in items">
                  <PaginationItem v-if="item.type === 'page'" :key="index" :value="item.value" as-child>
                    <Button class="w-10 h-10 p-0 font-bold" :variant="item.value === page ? 'default' : 'outline'" :class="item.value === page ? 'bg-primary text-white hover:bg-primary/90' : 'bg-white hover:bg-gray-100'">
                      {{ item.value }}
                    </Button>
                  </PaginationItem>
                  
                  <PaginationEllipsis v-else :key="item.type" :index="index" />
                </template>
                
                <PaginationNext class="h-10 px-4 border-2 bg-white hover:bg-gray-100" />
                
              </PaginationContent>
            </Pagination>
          </div>
      </section>
    </main>
  </div>
</template>

<style scoped>
/* 這裡只保留原生的漸層背景，@apply 的部分已經完全移除，不會再報錯！ */
.primary-gradient { 
  background: linear-gradient(135deg, #b22203 0%, #ff775b 100%); 
}
</style>
