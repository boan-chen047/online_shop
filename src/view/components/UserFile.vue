<script setup>
// 引入依賴
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  BadgeCheck,
  ArrowRight,
  Package,
  PenTool,
  Laptop,
  ChevronRight
} from 'lucide-vue-next'
// 引入依賴

// 用戶資料
const userProfile = ref({
  name: 'Alexander Wright',
  title: 'Chief Operations Officer at Zenith Corp',
  membership: 'Kinetic Elite Member',
  avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC6uUUj-6CGNMrYHfbQPxdwZ2Q2qjyA92-pgwSsjOnc-8mUyEm2JGKup-AEXpeaxNmB92UPQVNy8irNAjOGzCKlmV2p7rMOxMYWwFDQqiekjEKrfqUhI-lakuEA1dgokiQiRrzXqrQB33Qi8pO_gG3gqUUCySvGBnikFhbn9CpbV4T5fInNYX7sTHjd-mUUoHcFE7nSpez1z52uILOBroYk98n3iwbGF5ZLgPxUDZAskjaAiv6G9O_v9IYXW-re545JScyM9ROA7xM'
})
// 用戶資料

// 購買歷史
const purchaseHistory = ref([
  {
    id: 'KN-89231',
    name: 'Precision Workstation Pro',
    date: 'Oct 14, 2023',
    price: 4299.00,
    status: 'DELIVERED',
    icon: Package
  },
  {
    id: 'KN-88902',
    name: 'Architectural Drafting Set',
    date: 'Sept 28, 2023',
    price: 850.00,
    status: 'DELIVERED',
    icon: PenTool
  },
  {
    id: 'KN-88415',
    name: 'Minimalist Tech Sleeve',
    date: 'Aug 12, 2023',
    price: 120.00,
    status: 'DELIVERED',
    icon: Laptop
  }
])
// 購買歷史

</script>

<template>
  <div class="bg-surface text-on-surface antialiased min-h-screen pb-16 font-body">

    <!-- 用戶個人資訊頭部 -->
    <header class="relative pt-16 pb-12 px-6 md:px-8 max-w-4xl mx-auto">
      <div class="flex flex-col items-center text-center gap-6">
        <div class="relative">
          <div class="w-32 h-32 md:w-44 md:h-44 rounded-[40px] overflow-hidden shadow-[0_10px_30px_-5px_rgba(178,34,3,0.08)] border-4 border-surface-container-lowest">
            <img :alt="userProfile.name" class="w-full h-full object-cover" :src="userProfile.avatar"/>
          </div>
          <div class="absolute -bottom-2 -right-2 bg-primary text-on-primary p-2 rounded-xl shadow-lg border-2 border-surface-container-lowest flex items-center justify-center">
            <BadgeCheck class="w-5 h-5" />
          </div>
        </div>
        <div>
          <h1 class="font-bold text-4xl text-on-surface mb-2 font-headline">{{ userProfile.name }}</h1>
          <p class="text-lg text-outline">{{ userProfile.title }}</p>
          <div class="inline-flex items-center gap-2 px-4 py-1.5 bg-surface-container-high rounded-full mt-4">
            <span class="w-2 h-2 rounded-full bg-primary"></span>
            <span class="text-xs font-bold text-outline tracking-wider uppercase">{{ userProfile.membership }}</span>
          </div>
        </div>
      </div>
    </header>
    <!-- 用戶個人資訊頭部 -->

    <main class="max-w-4xl mx-auto px-6 md:px-8">
      <!-- 購買歷史記錄 -->
      <section class="space-y-6">
        <div class="flex items-center justify-between px-2 mb-2">
          <h2 class="font-bold text-2xl font-headline">Purchase History</h2>
          <Button variant="ghost" class="text-primary font-bold text-sm flex items-center gap-1 hover:text-primary/80 px-0">
            View All <ArrowRight class="w-4 h-4" />
          </Button>
        </div>
        <div class="grid grid-cols-1 gap-4">
          <div
            v-for="order in purchaseHistory"
            :key="order.id"
            class="bg-surface-container-lowest p-6 rounded-[28px] shadow-[0_10px_30px_-5px_rgba(178,34,3,0.08)] flex flex-col md:flex-row justify-between items-center gap-6 border border-outline-variant/30 hover:border-primary/20 transition-colors"
          >
            <div class="flex items-center gap-6 w-full md:w-auto">
              <div class="w-16 h-16 bg-surface-container rounded-2xl flex items-center justify-center">
                <component :is="order.icon" class="text-primary w-8 h-8 stroke-[1.5]" />
              </div>
              <div>
                <h3 class="font-bold text-base text-on-surface">{{ order.name }}</h3>
                <p class="text-sm text-outline">Order #{{ order.id }} • {{ order.date }}</p>
              </div>
            </div>

            <div class="flex items-center justify-between w-full md:w-auto gap-8">
              <div class="text-right">
                <p class="font-bold text-base text-on-surface">${{ order.price.toFixed(2) }}</p>
                <Badge class="bg-primary/10 text-primary border-none font-bold mt-1">{{ order.status }}</Badge>
              </div>
              <Button variant="outline" size="icon" class="rounded-full border-outline hover:bg-surface-container">
                <ChevronRight class="w-5 h-5" />
              </Button>
            </div>
          </div>
        </div>
      </section>
      <!-- 購買歷史記錄 -->
    </main>
  </div>
</template>
