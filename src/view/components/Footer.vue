<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { siteInfo } from '@/lib/siteInfo'

const links = [
  { to: '/privacy', label: '隱私權政策' },
  { to: '/terms', label: '服務條款' },
  { to: '/shipping', label: '運送與退貨' },
  { to: '/contact', label: '聯絡我們' },
]
</script>

<template>
  <!-- 頁尾區域 -->
  <footer class="mt-10 w-full bg-surface-container-low py-12 font-body text-sm">
    <div class="mx-auto flex max-w-[94vw] flex-col items-center justify-between px-5 md:flex-row">
      <!-- 品牌與版權資訊 -->
      <div class="mb-8 flex flex-col items-center gap-4 md:mb-0 md:items-start">
        <span class="text-lg font-black text-on-surface">{{ siteInfo.name }}</span>
        <p class="text-outline">© 2026 {{ siteInfo.name }} 版權所有</p>
      </div>
      <!-- 品牌與版權資訊 -->

      <!-- 導航連結 -->
      <nav class="flex flex-wrap justify-center gap-8">
        <RouterLink
          v-for="link in links"
          :key="link.to"
          :to="link.to"
          class="text-outline underline underline-offset-4 transition-all hover:text-on-surface"
        >
          {{ link.label }}
        </RouterLink>
      </nav>
      <!-- 導航連結 -->
    </div>
  </footer>
  <!-- 頁尾區域 -->
</template>
