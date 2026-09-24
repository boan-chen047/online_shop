<script setup lang="ts">
// 網站資訊頁（隱私權政策、服務條款、運送說明、聯絡我們）共用版型
defineProps<{
  title: string
  intro?: string
  updatedAt?: string
  // 示範內容頁在頁尾加註，提醒正式營運前需依實際情形修訂
  sample?: boolean
}>()
</script>

<template>
  <div class="bg-surface font-body text-on-surface antialiased">
    <main class="mx-auto max-w-3xl px-5 py-12 md:py-16">
      <header class="mb-10 border-b border-outline-variant/40 pb-6">
        <h1 class="font-headline text-3xl font-black md:text-4xl">{{ title }}</h1>
        <p v-if="intro" class="mt-4 text-base leading-relaxed text-on-surface-variant">{{ intro }}</p>
        <p v-if="updatedAt" class="mt-3 text-sm text-outline">最後更新：{{ updatedAt }}</p>
      </header>

      <div class="space-y-10 text-base leading-relaxed text-on-surface-variant">
        <slot />
      </div>

      <p v-if="sample" class="mt-12 rounded-xl bg-surface-container-low px-4 py-3 text-sm text-outline">
        ※ 本頁為示範內容，正式營運前請依實際營業情形修訂。
      </p>
    </main>
  </div>
</template>
