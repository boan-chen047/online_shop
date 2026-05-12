<script setup lang="ts">
import { ref, computed } from 'vue'
import { Card, CardContent } from '@/components/ui/card'
import { useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { newsItems } from '@/data/news'
import {
  Pagination,
  PaginationContent,
  PaginationEllipsis,
  PaginationItem,
  PaginationNext,
  PaginationPrevious,
} from '@/components/ui/pagination'

const router = useRouter()

// 分頁邏輯設定
const currentPage = ref(1)
const itemsPerPage = 5
const totalItems = computed(() => newsItems.length)

const paginatedNews = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  const end = start + itemsPerPage
  return newsItems.slice(start, end)
})
</script>

<template>
  <div class="relative w-full h-full bg-surface">
    <!-- Page Title -->
    <section class="mx-auto max-w-[94vw] px-5 pt-24 pb-12">
      <h1 class="font-display-xl text-4xl md:text-5xl font-extrabold text-on-surface mb-2">News</h1>
    </section>

    <!-- News List Section -->
    <section class="mx-auto max-w-[94vw] px-5 pb-16">
      <div class="flex items-center justify-between mb-8 border-b border-outline-variant/30 pb-4">
        <h2 class="font-headline-lg text-3xl font-bold text-on-surface">Latest</h2>
      </div>

      <!-- Card List Layout -->
      <div class="flex flex-col gap-6">
        <Card 
          v-for="item in paginatedNews" 
          :key="item.id"
          @click="router.push(`/news/${item.id}`)"
          class="group cursor-pointer overflow-hidden border border-outline-variant/20 shadow-sm hover:shadow-md transition-all bg-surface-container-lowest flex flex-col md:flex-row p-4 md:p-6 gap-6 md:gap-8 rounded-2xl"
        >
          <!-- 左側圖片 -->
          <div class="md:w-[320px] shrink-0 overflow-hidden rounded-xl aspect-[16/9] md:aspect-[4/3] bg-surface-container-low">
            <img 
              :alt="item.alt" 
              class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" 
              :src="item.image"
            />
          </div>
          <!-- 右側內容 -->
          <CardContent class="flex-1 flex flex-col justify-center p-0">
            <div class="flex items-center gap-3 mb-3">
              <span class="text-primary font-bold text-xs uppercase tracking-widest">{{ item.tag }}</span>
              <span class="text-outline-variant">•</span>
              <span class="text-on-surface-variant font-bold text-xs uppercase">{{ item.date }}</span>
            </div>
            <!-- 依據圖片，標題改為 primary 顏色 -->
            <h3 class="font-headline-md text-2xl md:text-3xl font-bold text-primary mb-4 group-hover:text-primary/80 transition-colors">
              {{ item.title }}
            </h3>
            <p class="font-body-md text-on-surface-variant text-base md:text-lg line-clamp-2 leading-relaxed">
              {{ item.description }}
            </p>
          </CardContent>
        </Card>
      </div>

      <!-- Pagination Component -->
      <div class="mt-12 flex justify-center">
        <!-- items-per-page 必須設定為 5，Shadcn 才能正確計算總頁數 -->
        <Pagination 
          v-model:page="currentPage" 
          :total="totalItems" 
          :items-per-page="itemsPerPage" 
          :sibling-count="1" 
          show-edges 
        >
          <PaginationContent v-slot="{ items }" class="flex items-center gap-1">
            <PaginationPrevious class="h-10 px-4 border-2 border-surface-container bg-white hover:bg-surface-container-low cursor-pointer" />
            
            <template v-for="(item, index) in items">
              <PaginationItem v-if="item.type === 'page'" :key="index" :value="item.value" as-child>
                <Button 
                  class="w-10 h-10 p-0 font-bold cursor-pointer transition-colors" 
                  :variant="item.value === currentPage ? 'default' : 'outline'" 
                  :class="item.value === currentPage ? 'bg-primary text-white hover:bg-primary/90' : 'bg-white border-2 border-surface-container hover:bg-surface-container-low text-on-surface'"
                >
                  {{ item.value }}
                </Button>
              </PaginationItem>
              
              <PaginationEllipsis v-else :key="item.type" :index="index" />
            </template>
            
            <PaginationNext class="h-10 px-4 border-2 border-surface-container bg-white hover:bg-surface-container-low cursor-pointer" />
          </PaginationContent>
        </Pagination>
      </div>
    </section>

    <!-- Background Decoration -->
    <!-- <div class="fixed inset-0 pointer-events-none z-[-1] opacity-20">
      <div class="absolute top-0 right-0 w-[600px] h-[600px] bg-gradient-to-bl from-primary-container/20 to-transparent blur-[120px]"></div>
      <div class="absolute bottom-0 left-0 w-[400px] h-[400px] bg-gradient-to-tr from-secondary-container/10 to-transparent blur-[80px]"></div>
    </div> -->
  </div>
</template>

<style scoped>
.material-symbols-outlined {
  font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
}
</style>
