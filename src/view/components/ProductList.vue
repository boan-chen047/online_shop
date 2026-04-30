<script setup>
import { ref, computed } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { ChevronRight, ChevronDown } from 'lucide-vue-next'
import {
  Pagination,
  PaginationContent,  // 用這個來取代 PaginationList
  PaginationEllipsis,
  PaginationItem,     // 用這個來取代 PaginationListItem
  PaginationNext,
  PaginationPrevious,
} from '@/components/ui/pagination'

const route = useRoute()

const categoryMap = {
  'snacks': '零食',
  'beverages': '飲料',
  'daily': '生活用品',
  'electronics': '電子設備',
  'watches': '手錶'
}

const currentCategoryName = computed(() => {
  const category = route.query.category
  return category ? categoryMap[category] || '未知分類' : '全部商品'
})

const sortBy = ref('Relevance')

const baseItems = [
  { name: 'Velocity Run Pro', price: 120.00, image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuALcfjCgCF9-2VyM3uUGNcEEIRq_OfvKOzED6wXLvkyFXCWffyoiQjhGFjTFNj4SwmF3mHd3h3sQ8DXpUtH3niEU0ifHxHvXXCpXD4xa9OnY_fQIFvs-vZTY7ym2aDVs7OCP8BMI9_S-4brgIQvlmTSAIGwBAlUl25jFeemwv1Tq84a4ENLAEiKc6P1kaq-2lngx2KK01vpiByaQVVpvNwjF8RdMKAJPwkBtOAbiHkFKZjqm5dcnOUIjmZ8A4m6qsWuM_wrG8hBYkg' },
  { name: 'Acoustic Pure Over-Ear', price: 185.00, image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3ivThTKfJYIMC1vA0z5rYigzHDnDIyDkL-EX27cbxZpdeydfbEqtoCkxTKh36sY8LbVKb7nQMyPOp9fZ_bzTG1I0M9zWBJjtAn7ZFZOATh_UAYeCxm4_vOj036h0t90UHbpK8gYtzk3JEUOvRflhXxYWLdcD9lsH5EC1NmEiK0WSDBW6X02ga-YtaIA_Ydklxs6DuyzZVJszdCdytoYQsQmhaEHFmjV5tB9R4STranc--cftVfb3P7kZ2m1LZxZwWJ0lA8Ehqd9I' },
  { name: 'Lumina Desk Architect', price: 79.00, image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDqxooAJ9LDHZVzIiz1_ijaePfHKqSMW4XwxIp7mLcz8ZyfnF5c6YlyXtoTAiTVhHHXNliq8cXXQBTiwG9udrLWBhate1Iz7pyD7NnUMCOcZX9GdagzvE0kBGbTbEPCno4GxrIjF32N9NH7doMd7Hyh16TNdo0JVPEbtXs3alTH32544CRE-m-8gphmCMxVpu8PYe-SWx1cfrImh9a4gx9DxRRJAn7gAOxGlw0whAoLY3-1Tgyzai9rxh-r1z6E8M9J_RXvzulqSJw' },
  { name: 'Sonic DAC External Amp', price: 129.00, image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAyNm_8fS3sjpNKYUQHPCxsB6kTsYhaSjWop7WY4kaAvIF9EHZ0LOM5DXR5N2qc-KY-3G8U6Yo5P33dV2eZLuTGq_eYYFBbuft1-UU77bF1Kk2O16ozz4XsmByQGj7jacFIdvBrPOoh8m5Ybv8kXQGynswbwSZzy5s1k6zeteBR1Qsi824p7uwE4iepNtWce6JqMDzZMVGAsrN0IdIn5rOajydFuMuNM_Sfj2XgRBDwof45vwi_9tnPoRvTEinw4jbe7-n5vNZULMI' },
  { name: 'Kinetic ChargePad Pro', price: 45.00, image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCb2wn45CXHlez3vl4esofxIatMOp2nC7q-t5IMd0WdsNfQ7A-XOITngt_bEW5bUuMJHGRk-3lE4DhqaSSfn-f2pCM5vcT-Qjcz7ECY4ptnlIXq7-QGeBbQOK-AdTViUZ5TUBEb0QcVBo5m8WGZLFtE9734M95hnvzNzKQnNK6-8rHowJ1jBjDIimHnAHgDC_R63bZC42qcuBu8QJubvtftGykMpM-PUydfbDr7VOZbcWxicfuGVEU7UPKAkAlq_iAc6aBDwBx90vg' }
]

const products = ref(
  Array.from({ length: 15 }).map((_, index) => {
    const base = baseItems[index % baseItems.length];
    return {
      id: index + 1,
      name: `${base.name} ${index > 4 ? `V${Math.floor(index/5) + 1}` : ''}`.trim(),
      price: base.price + (index * 5),
      image: base.image
    };
  })
)

const sortedProducts = computed(() => {
  let result = [...products.value]
  if (sortBy.value === 'Price: Low to High') {
    result.sort((a, b) => a.price - b.price)
  } else if (sortBy.value === 'Price: High to Low') {
    result.sort((a, b) => b.price - a.price)
  } else if (sortBy.value === 'Newest Arrivals') {
    result.sort((a, b) => b.id - a.id)
  }
  return result
})
</script>

<template>
  <div class="bg-surface text-on-surface font-body antialiased h-full">
    <main class="mx-auto flex max-w-[1440px] flex-col gap-6 px-6 pt-4 pb-4">
      
      <section class="grow">
        <div class="mb-6 flex flex-col justify-between gap-4 md:flex-row md:items-center">
          <nav class="flex items-center gap-2 text-sm text-outline">
            <RouterLink class="hover:text-on-surface transition-colors" to="/">Home</RouterLink>
            <ChevronRight class="size-4" />
            <span class="font-medium text-on-surface">{{ currentCategoryName }}</span>
          </nav>
          
          <div class="flex items-center gap-3">
            <span class="text-sm text-outline">Sort by:</span>
            <div class="relative">
              <select v-model="sortBy" class="cursor-pointer appearance-none rounded-full border-2 border-primary bg-transparent py-1.5 pr-10 pl-4 text-sm font-semibold text-on-surface focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all">
                <option>Relevance</option>
                <option>Price: Low to High</option>
                <option>Price: High to Low</option>
                <option>Newest Arrivals</option>
              </select>
              <ChevronDown class="size-4 pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-on-surface" />
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 md:grid-cols-3">
          <Card v-for="product in sortedProducts" :key="product.id" class="bg-surface-container-lowest border-none p-4 group hover:-translate-y-1 transition-all shadow-sm flex flex-col justify-between">
            <div>
              <div class="aspect-square rounded-lg overflow-hidden mb-4 bg-surface-container-low">
                <img :alt="product.name" class="w-full h-full object-cover mix-blend-multiply" :src="product.image"/>
              </div>
              <h4 class="font-bold text-on-surface truncate">{{ product.name }}</h4>
            </div>
            
            <div class="flex justify-between items-center mt-4">
              <span class="text-primary font-bold text-lg">${{ product.price.toFixed(2) }}</span>
              <Button class="primary-gradient text-white font-bold opacity-0 translate-y-4 group-hover:opacity-100 group-hover:translate-y-0 transition-all duration-300 px-4 h-8 text-xs as-child">
                <RouterLink :to="`/product/${product.id}`">DETAILS</RouterLink>
              </Button>
            </div>
          </Card>
        </div>

        <div class="mt-8 flex justify-center">
            <Pagination v-slot="{ page }" :total="100" :sibling-count="1" show-edges :default-page="1">
              
              <!-- 1. 這裡補上 v-slot="{ items }" 來取得頁碼資料 -->
              <PaginationContent v-slot="{ items }" class="flex items-center gap-1">
                
                <!-- 2. 移除 w-10，可以補上 px-4 讓左右留一點留白，讓按鈕自適應文字寬度 -->
                <PaginationPrevious class="h-10 px-4 border-2 bg-white hover:bg-gray-100" />
                
                <template v-for="(item, index) in items">
                  <PaginationItem v-if="item.type === 'page'" :key="index" :value="item.value" as-child>
                    <Button class="w-10 h-10 p-0 font-bold" :variant="item.value === page ? 'default' : 'outline'" :class="item.value === page ? 'bg-primary text-white hover:bg-primary/90' : 'bg-white hover:bg-gray-100'">
                      {{ item.value }}
                    </Button>
                  </PaginationItem>
                  
                  <PaginationEllipsis v-else :key="item.type" :index="index" />
                </template>
                
                <!-- 2. 移除 w-10，補上 px-4 -->
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