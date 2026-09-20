<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/composables/useAuth'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'

const { currentUser } = useAuth()

const TW_OFFSET = '+08:00'
const startLocal = ref('') // datetime-local 值，視為台灣時間
const endLocal = ref('')
const isLoading = ref(false)
const isSaving = ref(false)
const message = ref('')
const errorMessage = ref('')

// 帶時區的 ISO → datetime-local 顯示字串（換算成台灣時間 YYYY-MM-DDTHH:mm）
function isoToLocalInput(iso: string): string {
  const d = new Date(iso)
  if (!Number.isFinite(d.getTime())) {
    return ''
  }
  const tw = new Date(d.getTime() + 8 * 60 * 60 * 1000)
  return tw.toISOString().slice(0, 16)
}

// datetime-local（視為台灣時間） → 帶 +08:00 的 ISO 字串
function localInputToIso(local: string): string {
  if (!local) {
    return ''
  }
  return `${local}:00${TW_OFFSET}`
}

async function load() {
  if (!isSupabaseConfigured) {
    errorMessage.value = 'Supabase 尚未設定，無法載入設定。'
    return
  }
  isLoading.value = true
  const { data, error } = await supabase
    .from('site_settings')
    .select('value')
    .eq('key', 'flash_sale')
    .maybeSingle()
  isLoading.value = false
  if (error) {
    errorMessage.value = '設定載入失敗。'
    return
  }
  const value = (data as { value?: { start?: string; end?: string } } | null)?.value
  startLocal.value = isoToLocalInput(value?.start ?? '')
  endLocal.value = isoToLocalInput(value?.end ?? '')
}

async function save() {
  errorMessage.value = ''
  message.value = ''
  if (!startLocal.value || !endLocal.value) {
    errorMessage.value = '請填入開始與結束時間。'
    return
  }
  const startIso = localInputToIso(startLocal.value)
  const endIso = localInputToIso(endLocal.value)
  if (new Date(endIso).getTime() <= new Date(startIso).getTime()) {
    errorMessage.value = '結束時間必須晚於開始時間。'
    return
  }

  isSaving.value = true
  const { error } = await supabase
    .from('site_settings')
    .upsert(
      {
        key: 'flash_sale',
        value: { start: startIso, end: endIso },
        updated_at: new Date().toISOString(),
        updated_by: currentUser.value?.id ?? null,
      },
      { onConflict: 'key' },
    )
  isSaving.value = false
  if (error) {
    errorMessage.value = '儲存失敗，請確認你有管理員權限。'
    return
  }
  message.value = '已儲存'
}

onMounted(load)
</script>

<template>
  <div class="max-w-xl">
    <h1 class="mb-1 font-headline text-xl font-bold text-on-surface">網站設定</h1>
    <p class="mb-6 text-sm text-outline">設定首頁折扣倒數的開始與結束時間（台灣時間）。</p>

    <div class="space-y-4 rounded-xl border border-outline-variant bg-surface-container-lowest p-5">
      <div>
        <label class="mb-1 block text-sm font-bold text-on-surface">開始時間</label>
        <input
          v-model="startLocal"
          type="datetime-local"
          class="w-full rounded-lg border border-outline-variant bg-surface px-3 py-2 text-sm text-on-surface"
        />
      </div>
      <div>
        <label class="mb-1 block text-sm font-bold text-on-surface">結束時間</label>
        <input
          v-model="endLocal"
          type="datetime-local"
          class="w-full rounded-lg border border-outline-variant bg-surface px-3 py-2 text-sm text-on-surface"
        />
      </div>

      <div class="flex items-center gap-3 pt-2">
        <Button
          :disabled="isSaving || isLoading"
          class="primary-gradient font-bold text-on-primary hover:opacity-80"
          @click="save"
        >
          {{ isSaving ? '儲存中…' : '儲存' }}
        </Button>
        <span v-if="message" class="text-sm font-bold text-green-600">{{ message }}</span>
        <span v-if="errorMessage" class="text-sm font-bold text-red-600">{{ errorMessage }}</span>
      </div>
    </div>
  </div>
</template>
