import { ref } from 'vue'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'

export interface FlashSaleWindow {
  start: Date
  end: Date
}

const flashSale = ref<FlashSaleWindow | null>(null)
let hasLoaded = false

// 把 jsonb value 轉成 FlashSaleWindow；任何無效情況回 null（防呆，不讓首頁出錯）
function parseWindow(value: unknown): FlashSaleWindow | null {
  if (!value || typeof value !== 'object') {
    return null
  }
  const raw = value as { start?: unknown; end?: unknown }
  const start = new Date(String(raw.start ?? ''))
  const end = new Date(String(raw.end ?? ''))
  if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime())) {
    return null
  }
  return { start, end }
}

export async function loadFlashSale({ force = false } = {}): Promise<FlashSaleWindow | null> {
  if (hasLoaded && !force) {
    return flashSale.value
  }
  if (!isSupabaseConfigured) {
    return null
  }

  const { data, error } = await supabase
    .from('site_settings')
    .select('value')
    .eq('key', 'flash_sale')
    .maybeSingle()

  if (error) {
    console.warn('Flash sale setting could not be loaded.', error)
    return null
  }

  flashSale.value = parseWindow((data as { value?: unknown } | null)?.value)
  hasLoaded = true
  return flashSale.value
}

export function useSiteSettings() {
  return {
    flashSale,
    loadFlashSale,
  }
}
