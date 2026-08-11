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
  const diff = Number.isFinite(target) ? Math.max(0, target - now.value.getTime()) : 0

  return {
    days: String(Math.floor(diff / (1000 * 60 * 60 * 24))),
    hours: String(Math.floor((diff / (1000 * 60 * 60)) % 24)).padStart(2, '0'),
    minutes: String(Math.floor((diff / (1000 * 60)) % 60)).padStart(2, '0'),
    seconds: String(Math.floor((diff / 1000) % 60)).padStart(2, '0'),
    isExpired: diff <= 0
  }
})

const timeParts = computed(() => [
  { label: 'Days', value: timeLeft.value.days },
  { label: 'Hours', value: timeLeft.value.hours },
  { label: 'Minutes', value: timeLeft.value.minutes },
  { label: 'Seconds', value: timeLeft.value.seconds }
])
</script>

<template>
  <div class="flex flex-wrap items-center justify-end gap-3 rounded-xl bg-surface-container-low px-4 py-2">
    <span class="text-xs font-bold text-on-surface-variant uppercase tracking-widest">
      {{ timeLeft.isExpired ? 'Promotion Ended' : 'Ending In' }}
    </span>

    <div v-if="!timeLeft.isExpired" class="flex items-center gap-1.5" aria-label="Time remaining">
      <template v-for="(part, index) in timeParts" :key="part.label">
        <span :aria-label="`${part.label}: ${part.value}`" class="rounded bg-primary px-2 py-1 text-sm font-bold text-white">
          {{ part.value }}
        </span>
        <span v-if="index < timeParts.length - 1" aria-hidden="true" class="font-bold text-primary">:</span>
      </template>
    </div>
  </div>
</template>
