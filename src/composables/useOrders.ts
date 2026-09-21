import { supabase } from '@/lib/supabase'

export interface OrderItem {
  id: string
  product_name: string
  quantity: number
  unit_price: number
  line_total: number
}

export interface Order {
  id: string
  payment_status: string
  order_status: string
  total: number
  recipient_name: string | null
  recipient_phone: string | null
  shipping_address: string | null
  note: string | null
  placed_at: string
  received_at: string | null
  closed_at: string | null
  order_items: OrderItem[]
}

export const ORDER_SELECT =
  'id, payment_status, order_status, total, recipient_name, recipient_phone, shipping_address, note, placed_at, received_at, closed_at, order_items(id, product_name, quantity, unit_price, line_total)'

// 管理員可手動切換的出貨狀態
export const orderStatusOptions = [
  { value: 'created', label: '已建立' },
  { value: 'shipping', label: '出貨中' },
  { value: 'received', label: '已簽收' },
]

export const paymentStatusLabel: Record<string, string> = {
  unpaid: '未付款',
  paid: '已付款',
  failed: '付款失敗',
  refunded: '已退款',
  expired: '逾時未付',
}

// RLS 自動過濾：顧客只拿自己的訂單、管理員拿全部。
export async function loadMyOrders(): Promise<Order[]> {
  const { data, error } = await supabase
    .from('orders')
    .select(ORDER_SELECT)
    .order('placed_at', { ascending: false })
  if (error) {
    throw error
  }
  return (data ?? []) as unknown as Order[]
}

// 已完結：已過 7 天鑑賞期（received 且 now ≥ closed_at）、或已取消、或已退款。
export function isOrderCompleted(order: Order, nowMs: number = Date.now()): boolean {
  if (order.order_status === 'cancelled' || order.payment_status === 'refunded') {
    return true
  }
  if (order.order_status === 'received' && order.closed_at) {
    return nowMs >= new Date(order.closed_at).getTime()
  }
  return false
}

// received 且仍在鑑賞期內（顧客可提前結束）
export function isInReviewPeriod(order: Order, nowMs: number = Date.now()): boolean {
  return (
    order.order_status === 'received' &&
    !!order.closed_at &&
    nowMs < new Date(order.closed_at).getTime()
  )
}

// 顧客視角的狀態文字
export function customerStatusLabel(order: Order, nowMs: number = Date.now()): string {
  if (order.order_status === 'cancelled') return '已取消'
  if (order.payment_status === 'refunded') return '已退款'
  if (order.payment_status === 'unpaid') return '待付款'
  if (order.order_status === 'received') {
    return isOrderCompleted(order, nowMs) ? '已完成' : '鑑賞期中'
  }
  if (order.order_status === 'shipping') return '出貨中'
  return '處理中'
}
