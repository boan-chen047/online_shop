<script setup>
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import {
  BadgeCheck,
  ArrowRight,
  Package,
  PenTool,
  Laptop,
  ChevronRight,
  Newspaper,
  Compass,
  Users,
  User
} from 'lucide-vue-next'

// 會員基本資料
const userProfile = ref({
  name: 'Alexander Wright',
  title: 'Chief Operations Officer at Zenith Corp',
  membership: 'Kinetic Elite Member',
  avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC6uUUj-6CGNMrYHfbQPxdwZ2Q2qjyA92-pgwSsjOnc-8mUyEm2JGKup-AEXpeaxNmB92UPQVNy8irNAjOGzCKlmV2p7rMOxMYWwFDQqiekjEKrfqUhI-lakuEA1dgokiQiRrzXqrQB33Qi8pO_gG3gqUUCySvGBnikFhbn9CpbV4T5fInNYX7sTHjd-mUUoHcFE7nSpez1z52uILOBroYk98n3iwbGF5ZLgPxUDZAskjaAiv6G9O_v9IYXW-re545JScyM9ROA7xM'
})

// 購買紀錄假資料
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

// 底部導覽列設定
const navItems = ref([
  { label: 'Feed', icon: Newspaper, path: '#', active: false },
  { label: 'Discover', icon: Compass, path: '#', active: false },
  { label: 'Members', icon: Users, path: '#', active: false },
  { label: 'Profile', icon: User, path: '#', active: true }
])
</script>

<template>
  <div class="custom-bg text-on-surface antialiased h-full pb-8 font-body-md">
    
    <header class="relative pt-16 pb-12 px-6 md:px-8 max-w-4xl mx-auto">
      <div class="flex flex-col items-center text-center gap-6">
        <div class="relative">
          <div class="w-32 h-32 md:w-44 md:h-44 rounded-[40px] overflow-hidden shadow-[0_10px_30px_-5px_rgba(178,34,3,0.08)] border-4 border-white">
            <img :alt="userProfile.name" class="w-full h-full object-cover" :src="userProfile.avatar"/>
          </div>
          <div class="absolute -bottom-2 -right-2 bg-primary text-white p-2 rounded-xl shadow-lg border-2 border-white flex items-center justify-center">
            <BadgeCheck class="w-5 h-5" />
          </div>
        </div>
        <div>
          <h1 class="font-bold text-4xl text-on-surface mb-2 font-headline-lg">{{ userProfile.name }}</h1>
          <p class="text-lg text-outline">{{ userProfile.title }}</p>
          <div class="inline-flex items-center gap-2 px-4 py-1.5 bg-surface-container-high rounded-full mt-4">
            <span class="w-2 h-2 rounded-full bg-primary"></span>
            <span class="text-xs font-bold text-outline tracking-wider uppercase">{{ userProfile.membership }}</span>
          </div>
        </div>
      </div>
    </header>

    <main class="max-w-4xl mx-auto px-6 md:px-8">
      <section class="space-y-6">
        <div class="flex items-center justify-between px-2 mb-2">
          <h2 class="font-bold text-2xl">Purchase History</h2>
          <button class="text-primary font-bold text-sm flex items-center gap-1 hover:underline transition-all">
            View All <ArrowRight class="w-4 h-4" />
          </button>
        </div>

        <div class="grid grid-cols-1 gap-4">
          <div 
            v-for="order in purchaseHistory" 
            :key="order.id"
            class="bg-white p-6 rounded-[28px] shadow-[0_10px_30px_-5px_rgba(178,34,3,0.08)] flex flex-col md:flex-row justify-between items-center gap-6 border border-outline-variant/30 hover:border-primary/20 transition-colors"
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
                <span class="text-xs px-2.5 py-0.5 bg-green-100 text-green-700 rounded-md font-bold">{{ order.status }}</span>
              </div>
              <button class="p-2 rounded-full border border-outline hover:bg-surface-container transition-colors">
                <ChevronRight class="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      </section>
    </main>
  </div>
</template>

<style scoped>
/* 移植原本 body 上的精緻點狀漸層背景 */
.custom-bg {
  background-color: #fff8f6; /* 對應你的 surface color */
  background-image: radial-gradient(circle at 0% 0%, rgba(178,34,3,0.03) 0%, transparent 50%),
                    radial-gradient(circle at 100% 100%, rgba(178,34,3,0.02) 0%, transparent 50%);
}
</style>