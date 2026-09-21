<script setup lang="ts">
import { RouterLink, RouterView, useRoute } from 'vue-router'
import { Package, ClipboardList, Settings } from 'lucide-vue-next'

const route = useRoute()

const navItems = [
  { name: 'AdminProducts', label: '商品管理', icon: Package },
  { name: 'AdminOrders', label: '訂單管理', icon: ClipboardList },
  { name: 'AdminSettings', label: '網站設定', icon: Settings },
]

function itemClass(name: string) {
  const base = 'flex items-center gap-2.5 whitespace-nowrap rounded-lg px-4 py-2.5 text-[15px] font-bold transition-colors'
  return route.name === name
    ? `${base} bg-primary/10 text-primary`
    : `${base} text-on-surface-variant hover:bg-surface-container-low hover:text-primary`
}
</script>

<template>
  <div class="mx-auto max-w-[94vw] px-5 py-6 md:flex md:gap-10">
    <!-- 側邊導覽：手機版收成上方橫向可捲動列 -->
    <aside class="mb-4 md:mb-0 md:w-64 md:shrink-0 md:sticky md:top-[88px] md:self-start md:pt-4">
      <p class="mb-3 px-4 text-xs font-bold uppercase tracking-widest text-outline">後台管理</p>
      <nav class="flex gap-2 overflow-x-auto md:flex-col md:gap-1.5">
        <RouterLink
          v-for="item in navItems"
          :key="item.name"
          :to="{ name: item.name }"
          :class="itemClass(item.name)"
        >
          <component :is="item.icon" class="size-5" />
          <span>{{ item.label }}</span>
        </RouterLink>
      </nav>
    </aside>

    <!-- 右側內容 -->
    <section class="min-w-0 flex-1">
      <RouterView />
    </section>
  </div>
</template>
