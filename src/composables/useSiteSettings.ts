import { computed, ref } from 'vue'
import { useNow } from '@vueuse/core'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'

export interface FlashSaleWindow {
  start: Date
  end: Date
  productIds: string[]
  discount: number
}

const flashSale = ref<FlashSaleWindow | null>(null)
let hasLoaded = false

// 把 jsonb value 轉成 FlashSaleWindow；任何無效情況回 null（防呆，不讓首頁出錯）
function parseWindow(value: unknown): FlashSaleWindow | null {
  if (!value || typeof value !== 'object') {
    return null
  }
  const raw = value as { start?: unknown; end?: unknown; product_ids?: unknown; discount?: unknown }
  const start = new Date(String(raw.start ?? ''))
  const end = new Date(String(raw.end ?? ''))
  if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime())) {
    return null
  }
  const productIds = Array.isArray(raw.product_ids)
    ? raw.product_ids.filter((id): id is string => typeof id === 'string')
    : []
  // discount 為折數（8 = 八折）；不在 (0,10] 一律當無折扣 10
  const discount = typeof raw.discount === 'number' && raw.discount > 0 && raw.discount <= 10
    ? raw.discount
    : 10
  return { start, end, productIds, discount }
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

export interface FlashSalePriceInfo {
  onSale: boolean // 此商品目前是否在活動折扣中
  display: number // 要顯示的價格（活動中=折後價；否則=原售價）
  discountPercent: number // 省下的百分比（活動中才 > 0）
}

// 折扣定價（商品頁/詳情頁/首頁共用）：折扣一律由「限時活動」決定——
// 只有在活動時間內、且被選為活動商品、且有設折扣的商品，才有折後價。
export function useFlashSalePricing() {
  const now = useNow()
  void loadFlashSale()

  const isActive = computed(() => {
    const window = flashSale.value
    if (!window) {
      return false
    }
    const t = now.value.getTime()
    return t >= window.start.getTime() && t < window.end.getTime()
  })

  const activeIds = computed(() =>
    isActive.value ? new Set(flashSale.value?.productIds ?? []) : new Set<string>(),
  )
  const discount = computed(() => flashSale.value?.discount ?? 10)

  function priceFor(productId: string, price: number): FlashSalePriceInfo {
    const onSale = activeIds.value.has(productId) && discount.value < 10
    return {
      onSale,
      display: onSale ? Math.round((price * discount.value) / 10) : price,
      discountPercent: onSale ? Math.round((1 - discount.value / 10) * 100) : 0,
    }
  }

  return { isActive, activeIds, discount, priceFor }
}
