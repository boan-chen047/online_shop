<script setup lang="ts">
import { computed } from 'vue'
import { useNow } from '@vueuse/core'

// startDate 可選：沒給（或無效）就等同「已經開始」，只倒數到 targetDate
const props = defineProps<{
  startDate?: string | Date | null
  targetDate: string | Date
}>()

const now = useNow()

const timeLeft = computed(() => {
  const nowMs = now.value.getTime()
  const endMs = new Date(props.targetDate).getTime()
  const startRaw = props.startDate == null ? Number.NaN : new Date(props.startDate).getTime()

  // 決定目前狀態與要倒數的目標
  let phase: 'before' | 'running' | 'ended'
  let diff: number

  if (!Number.isFinite(endMs)) {
    // 無效結束時間：當進行中且不倒數（首頁會給 fallback，理論上不會走到）
    phase = 'running'
    diff = 0
  } else if (Number.isFinite(startRaw) && nowMs < startRaw) {
    phase = 'before'
    diff = Math.max(0, startRaw - nowMs)
  } else if (nowMs < endMs) {
    phase = 'running'
    diff = Math.max(0, endMs - nowMs)
  } else {
    phase = 'ended'
    diff = 0
  }

  return {
    phase,
    days: String(Math.floor(diff / (1000 * 60 * 60 * 24))),
    hours: String(Math.floor((diff / (1000 * 60 * 60)) % 24)).padStart(2, '0'),
    minutes: String(Math.floor((diff / (1000 * 60)) % 60)).padStart(2, '0'),
    seconds: String(Math.floor((diff / 1000) % 60)).padStart(2, '0'),
  }
})

const label = computed(() => {
  if (timeLeft.value.phase === 'before') return '即將開始'
  if (timeLeft.value.phase === 'ended') return '活動已結束'
  return '限時倒數'
})

const timeParts = computed(() => [
  { label: 'Days', value: timeLeft.value.days },
  { label: 'Hours', value: timeLeft.value.hours },
  { label: 'Minutes', value: timeLeft.value.minutes },
  { label: 'Seconds', value: timeLeft.value.seconds },
])
</script>

<template>
  <div class="flex flex-wrap items-center justify-end gap-3 rounded-xl bg-surface-container-low px-4 py-2">
    <span class="text-xs font-bold text-on-surface-variant uppercase tracking-widest">
      {{ label }}
    </span>

    <div v-if="timeLeft.phase !== 'ended'" class="flex items-center gap-1.5" aria-label="Time remaining">
      <template v-for="(part, index) in timeParts" :key="part.label">
        <span :aria-label="`${part.label}: ${part.value}`" class="rounded bg-primary px-2 py-1 text-sm font-bold text-white">
          {{ part.value }}
        </span>
        <span v-if="index < timeParts.length - 1" aria-hidden="true" class="font-bold text-primary">:</span>
      </template>
    </div>
  </div>
</template>
