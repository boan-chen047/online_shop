<script setup lang="ts">
import { RouterLink, RouterView, useRoute } from 'vue-router'
import { Package, ClipboardList, Newspaper, Settings } from 'lucide-vue-next'

const route = useRoute()

const navItems = [
  { name: 'AdminProducts', label: '商品管理', icon: Package },
  { name: 'AdminOrders', label: '訂單管理', icon: ClipboardList },
  { name: 'AdminNews', label: '最新消息', icon: Newspaper },
  { name: 'AdminSettings', label: '網站設定', icon: Settings },
]

function itemClass(name: string) {
  const base = 'flex items-center gap-2.5 whitespace-nowrap rounded-lg px-4 py-2.5 text-[15px] font-bold transition-colors'
  const current = route.name === 'AdminProductDetail' ? 'AdminProducts' : route.name
  return current === name
    ? `${base} bg-primary/10 text-primary`
    : `${base} text-on-surface-variant hover:bg-surface-container-low hover:text-primary`
}
</script>

<template>
  <div class="mx-auto max-w-[94vw] px-5 py-8 md:flex md:gap-8">
    <!-- 側邊導覽：手機版收成上方橫向可捲動列 -->
    <aside class="mb-6 md:mb-0 md:w-60 md:shrink-0 md:sticky md:top-[88px] md:self-start md:rounded-xl md:bg-surface-container-lowest md:p-3 md:shadow-sm">
      <p class="mb-3 px-4 pt-1 text-xs font-bold tracking-widest text-outline">後台管理</p>
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

    <!-- 右側內容：固定最小高度，換頁載入新頁面的空檔頁尾不會往上彈 -->
    <section class="min-h-[70vh] min-w-0 flex-1">
      <RouterView v-slot="{ Component, route: viewRoute }">
        <Transition name="admin-fade" mode="out-in">
          <component :is="Component" :key="viewRoute.name" />
        </Transition>
      </RouterView>
    </section>
  </div>
</template>

<style scoped>
/* 換頁淡入淡出：時間很短，只讓切換不突兀，不拖慢操作 */
.admin-fade-enter-active,
.admin-fade-leave-active {
  transition: opacity 0.12s ease;
}
.admin-fade-enter-from,
.admin-fade-leave-to {
  opacity: 0;
}
</style>
