<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { SearchX } from 'lucide-vue-next'
</script>

<template>
  <div class="flex min-h-[calc(100vh-72px)] items-center justify-center bg-surface px-5 py-16 text-on-surface">
    <main class="max-w-md text-center">
      <SearchX class="mx-auto mb-6 size-14 text-outline" />
      <p class="font-headline text-6xl font-black text-primary">404</p>
      <h1 class="mt-4 font-headline text-2xl font-black">找不到這個頁面</h1>
      <p class="mt-3 text-base text-on-surface-variant">網址可能打錯了，或這個頁面已經移除。</p>
      <div class="mt-8 flex flex-col justify-center gap-3 sm:flex-row">
        <Button as-child class="primary-gradient rounded-xl font-bold text-on-primary">
          <RouterLink to="/">回首頁</RouterLink>
        </Button>
        <Button as-child variant="outline" class="rounded-xl font-bold">
          <RouterLink to="/products">逛逛商品</RouterLink>
        </Button>
      </div>
    </main>
  </div>
</template>
