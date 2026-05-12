<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import CountdownTimer from './CountdownTimer.vue'
import { Zap } from 'lucide-vue-next'
import { formatPrice, useCatalog } from '@/composables/useCatalog'

const { products, loadCatalog } = useCatalog()

const flashSaleItems = computed(() => {
  const taggedProducts = products.value.filter((product) => product.tag || product.originalPrice)
  const source = taggedProducts.length >= 5 ? taggedProducts : products.value

  return source.slice(0, 5)
})

onMounted(() => {
  void loadCatalog()
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
                    Start Shopping
                  </RouterLink>
                </Button>
              </div>
            </div>
          </div>
        </div>
      </section>
      <!-- 封面形象照 -->
      <!-- sales -->
      <section class="mb-14 px-5">
        <!-- sales最上方說明 -->
        <div class="mb-7 flex justify-between">
          <div>
            <div class="mb-1 flex items-center gap-2.5">
              <Zap class="size-7 fill-primary text-primary" />
              <h2 class="font-headline text-xl font-bold uppercase tracking-tight text-on-surface">Discount</h2>
            </div>
            <p class="text-sm text-outline">Premium pieces, limited time, exclusive prices.</p>
          </div>
          <CountdownTimer targetDate="2026-12-31T23:59:59" />
        </div>
        <!-- sales最上方說明 -->
        <!-- sales商品展示 -->
        <div v-if="flashSaleItems.length" class="grid grid-cols-1 gap-5 md:grid-cols-4">
          <!-- 左邊大圖 -->
          <Card class="md:col-span-2 md:row-span-2 bg-surface-container-lowest border-none overflow-hidden group hover:shadow-2xl transition-all duration-500 relative">
            <div class="h-full aspect-square md:aspect-auto">
              <img :alt="flashSaleItems[0].name" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700" :src="flashSaleItems[0].image"/>
            </div>
            <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-white via-white/90 to-transparent p-7">
              <p class="mb-2 text-sm font-bold text-primary">{{ flashSaleItems[0].tag }}</p>
              <h3 class="mb-2 text-xl font-bold">{{ flashSaleItems[0].name }}</h3>
              <div class="flex items-center gap-3">
                <span class="text-xl font-black text-on-surface">{{ formatPrice(flashSaleItems[0].price) }}</span>
                <span v-if="flashSaleItems[0].originalPrice" class="text-outline line-through text-sm">{{ formatPrice(flashSaleItems[0].originalPrice) }}</span>
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
              <span class="text-base font-bold text-primary">{{ formatPrice(item.price) }}</span>
              
              <Button as-child class="primary-gradient h-8 translate-y-4 px-3.5 text-xs font-bold text-white opacity-0 transition-all duration-300 group-hover:translate-y-0 group-hover:opacity-100">
                <RouterLink :to="`/product/${item.slug}`">查看</RouterLink>
              </Button>
            </div>
          </Card>
          <!-- 右邊四小圖 -->
        </div>
        <div v-else class="grid grid-cols-1 gap-5 md:grid-cols-4">
          <div class="h-80 animate-pulse rounded-xl bg-surface-container-lowest md:col-span-2 md:row-span-2" />
          <div v-for="index in 4" :key="index" class="h-56 animate-pulse rounded-xl bg-surface-container-lowest" />
        </div>
        <!-- sales商品展示 -->
      </section>
      <!-- sales -->
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
