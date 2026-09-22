// Google Analytics 4（GA4）整合。
//
// Measurement ID 由環境變數 VITE_GA_MEASUREMENT_ID 提供（例如 G-XXXXXXXXXX）。
// 未設定時所有函式都是 no-op：本機開發不設定就不會送出任何資料，
// 只要在 Vercel 的環境變數設定該 ID，就只在正式環境生效。

const GA_ID = import.meta.env.VITE_GA_MEASUREMENT_ID as string | undefined

declare global {
  interface Window {
    dataLayer: unknown[]
    gtag: (...args: unknown[]) => void
  }
}

let initialized = false

// 動態載入 gtag.js 並初始化。SPA 換頁不會重新整理，因此關閉自動 page_view，改由路由手動送。
export function initAnalytics() {
  if (initialized || !GA_ID || typeof window === 'undefined') {
    return
  }
  initialized = true

  const script = document.createElement('script')
  script.async = true
  script.src = `https://www.googletagmanager.com/gtag/js?id=${GA_ID}`
  document.head.appendChild(script)

  window.dataLayer = window.dataLayer || []
  window.gtag = function gtag() {
    // gtag 依賴 arguments 物件，必須用一般函式而非箭頭函式
    // eslint-disable-next-line prefer-rest-params
    window.dataLayer.push(arguments)
  }
  window.gtag('js', new Date())
  window.gtag('config', GA_ID, { send_page_view: false })
}

function track(event: string, params: Record<string, unknown> = {}) {
  if (!GA_ID || typeof window === 'undefined' || typeof window.gtag !== 'function') {
    return
  }
  window.gtag('event', event, params)
}

// 換頁瀏覽
export function trackPageView(path: string) {
  track('page_view', {
    page_path: path,
    page_title: typeof document !== 'undefined' ? document.title : undefined,
    page_location: typeof window !== 'undefined' ? window.location.href : undefined,
  })
}

// GA4 電商事件用的商品格式
export interface AnalyticsItem {
  id: string
  name: string
  price: number
  category?: string
  quantity?: number
}

function toGaItem(item: AnalyticsItem) {
  return {
    item_id: item.id,
    item_name: item.name,
    item_category: item.category,
    price: item.price,
    quantity: item.quantity ?? 1,
  }
}

// 瀏覽商品
export function trackViewItem(item: AnalyticsItem) {
  track('view_item', { currency: 'TWD', value: item.price, items: [toGaItem(item)] })
}

// 加入購物車
export function trackAddToCart(item: AnalyticsItem) {
  const quantity = item.quantity ?? 1
  track('add_to_cart', { currency: 'TWD', value: item.price * quantity, items: [toGaItem(item)] })
}

// 開始結帳
export function trackBeginCheckout(value: number, items: AnalyticsItem[]) {
  track('begin_checkout', { currency: 'TWD', value, items: items.map(toGaItem) })
}

// 完成付款
export function trackPurchase(transactionId: string, value: number) {
  track('purchase', { transaction_id: transactionId, currency: 'TWD', value })
}
