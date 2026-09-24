<script setup lang="ts">
// 後台各頁共用頁首：標題、說明與右側操作按鈕位置固定，換頁時不會跳動
defineProps<{
  title: string
  description?: string
}>()
</script>

<template>
  <header class="mb-6 flex min-h-12 flex-wrap items-end justify-between gap-4">
    <div class="min-w-0">
      <h1 class="font-headline text-2xl font-black text-on-surface">{{ title }}</h1>
      <p v-if="description" class="mt-1 text-sm text-on-surface-variant">{{ description }}</p>
    </div>
    <div v-if="$slots.actions" class="flex shrink-0 items-center gap-3">
      <slot name="actions" />
    </div>
  </header>
</template>
