<script setup lang="ts">
import { computed } from 'vue'
import { useNow } from '@vueuse/core'

// 定義組件接收的參數：目標結束時間
const props = defineProps<{
  targetDate: string | Date
}>()

// 取得當前時間
const now = useNow()

// 計算剩下的時間差
const timeLeft = computed(() => {
  const target = new Date(props.targetDate).getTime()
  const diff = Math.max(0, target - now.value.getTime())

  return {
    hours: String(Math.floor((diff / (1000 * 60 * 60)) % 24)).padStart(2, '0'),
    minutes: String(Math.floor((diff / 1000 / 60) % 60)).padStart(2, '0'),
    seconds: String(Math.floor((diff / 1000) % 60)).padStart(2, '0'),
    isExpired: diff <= 0
  }
})
</script>

<template>
  <div class="flex items-center gap-4 bg-surface-container-low px-4 py-2 rounded-xl">
    <span class="text-xs font-bold text-on-surface-variant uppercase tracking-widest">
      {{ timeLeft.isExpired ? 'Promotion Ended' : 'Ending In' }}
    </span>

    <div v-if="!timeLeft.isExpired" class="flex gap-2">
      <span class="bg-primary px-2 py-1 rounded text-white font-bold text-sm">
        {{ timeLeft.hours }}
      </span>
      <span class="text-primary font-bold">:</span>
      
      <span class="bg-primary px-2 py-1 rounded text-white font-bold text-sm">
        {{ timeLeft.minutes }}
      </span>
      <span class="text-primary font-bold">:</span>
      
      <span class="bg-primary px-2 py-1 rounded text-white font-bold text-sm">
        {{ timeLeft.seconds }}
      </span>
    </div>
  </div>
</template>