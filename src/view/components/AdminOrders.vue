<script setup lang="ts">
import { ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/composables/useAuth'
import { formatPrice } from '@/composables/useCatalog'
import { supabase } from '@/lib/supabase'
import { startEcpayPayment } from '@/lib/ecpay'

interface OrderItem {
  id: string
  product_name: string
  quantity: number
  unit_price: number
  line_total: number
}

interface Order {
  id: string
  payment_status: string
  order_status: string
  total: number
  recipient_name: string | null
  recipient_phone: string | null
  shipping_address: string | null
  note: string | null
  placed_at: string
  order_items: OrderItem[]
}

const { isAuthReady, isAdmin, currentUser } = useAuth()

const orders = ref<Order[]>([])
const isLoading = ref(false)
const loadError = ref('')
const updatingOrderId = ref('')
const payingOrderId = ref('')

const orderStatusOptions = [
  { value: 'created', label: '已建立' },
  { value: 'shipping', label: '出貨中' },
  { value: 'received', label: '已完成' },
]

// 顯示用標籤：除了管理員可手動切換的三種，另含系統自動設定的取消／缺貨狀態。
const orderStatusLabel: Record<string, string> = {
  ...Object.fromEntries(orderStatusOptions.map((option) => [option.value, option.label])),
  cancelled: '已取消',
  out_of_stock: '缺貨待退款',
}

const paymentStatusLabel: Record<string, string> = {
  unpaid: '未付款',
  paid: '已付款',
  failed: '付款失敗',
  refunded: '已退款',
  expired: '逾時未付',
}

async function loadOrders() {
  isLoading.value = true
  loadError.value = ''

  // RLS 會自動過濾：顧客只拿得到自己的訂單，管理員拿得到全部。
  const { data, error } = await supabase
    .from('orders')
    .select('id, payment_status, order_status, total, recipient_name, recipient_phone, shipping_address, note, placed_at, order_items(id, product_name, quantity, unit_price, line_total)')
    .order('placed_at', { ascending: false })

  if (error) {
    loadError.value = error.message
    orders.value = []
  } else {
    orders.value = (data ?? []) as unknown as Order[]
  }

  isLoading.value = false
}

async function updateOrderStatus(orderId: string, nextStatus: string) {
  updatingOrderId.value = orderId

  const { error } = await supabase
    .from('orders')
    .update({ order_status: nextStatus })
    .eq('id', orderId)

  if (error) {
    loadError.value = error.message
  } else {
    const order = orders.value.find((item) => item.id === orderId)
    if (order) {
      order.order_status = nextStatus
    }
  }

  updatingOrderId.value = ''
}

// 顧客對既有的未付款訂單重新前往綠界付款（沿用結帳時的 startEcpayPayment，
// 會呼叫 ecpay-create 取得參數並導向綠界；成功會離開本頁，因此正常不會 resolve）。
async function payOrder(orderId: string) {
  payingOrderId.value = orderId
  loadError.value = ''

  try {
    await startEcpayPayment(orderId)
  } catch (error) {
    loadError.value = error instanceof Error ? error.message : '前往付款失敗，請稍後再試。'
    payingOrderId.value = ''
  }
}

watch(
  [isAuthReady, currentUser],
  ([ready, user]) => {
    if (ready && user) {
      void loadOrders()
    } else if (ready && !user) {
      orders.value = []
    }
  },
  { immediate: true },
)
</script>

<template>
  <div class="text-on-surface antialiased font-body">
    <main class="mx-auto max-w-[94vw] px-5 pb-16">
      <h1 class="mb-6 font-headline text-2xl font-black">{{ isAdmin ? '訂單管理' : '我的訂單' }}</h1>

      <div v-if="!isAuthReady" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-on-surface-variant">
        載入中...
      </div>

      <div v-else-if="!currentUser" class="flex min-h-60 flex-col items-center justify-center rounded-xl bg-surface-container-lowest p-8 text-center">
        <h2 class="font-headline text-xl font-black text-on-surface">請先登入</h2>
        <p class="mt-2 max-w-sm text-base text-on-surface-variant">登入後即可查看你的訂單紀錄。</p>
        <Button as-child class="primary-gradient mt-6 rounded-xl font-bold text-on-primary">
          <RouterLink to="/login">前往登入</RouterLink>
        </Button>
      </div>

      <template v-else>
        <div v-if="isLoading" class="space-y-4">
          <div v-for="index in 3" :key="index" class="h-32 animate-pulse rounded-xl bg-surface-container-lowest" />
        </div>

        <div v-else-if="loadError" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-error">
          {{ loadError }}
        </div>

        <div v-else-if="!orders.length" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-on-surface-variant">
          {{ isAdmin ? '目前還沒有任何訂單。' : '你還沒有訂單。' }}
        </div>

        <div v-else class="space-y-5">
          <section v-for="order in orders" :key="order.id" class="rounded-xl bg-surface-container-lowest p-6 shadow-sm md:p-7">
            <!-- 訂單表頭 -->
            <div class="flex flex-wrap items-start justify-between gap-4 border-b border-surface-container pb-4">
              <div class="min-w-0">
                <p class="font-mono text-sm text-on-surface-variant">{{ order.id }}</p>
                <p class="mt-1 text-sm text-on-surface-variant">{{ new Date(order.placed_at).toLocaleString('zh-TW') }}</p>
              </div>
              <div class="flex items-center gap-3">
                <span class="rounded-full bg-surface-container px-3 py-1.5 text-sm font-bold text-on-surface-variant">
                  {{ paymentStatusLabel[order.payment_status] ?? order.payment_status }}
                </span>
                <!-- 管理員可改出貨狀態，顧客只能看 -->
                <select
                  v-if="isAdmin"
                  :value="order.order_status"
                  :disabled="updatingOrderId === order.id"
                  class="rounded-md border border-input bg-transparent px-3 py-1.5 text-sm font-bold outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50"
                  @change="updateOrderStatus(order.id, ($event.target as HTMLSelectElement).value)"
                >
                  <option v-for="option in orderStatusOptions" :key="option.value" :value="option.value">
                    {{ option.label }}
                  </option>
                </select>
                <span v-else class="rounded-full bg-primary/10 px-3 py-1.5 text-sm font-bold text-primary">
                  {{ orderStatusLabel[order.order_status] ?? order.order_status }}
                </span>
              </div>
            </div>

            <!-- 商品明細 -->
            <div class="mt-4 space-y-2.5">
              <div v-for="item in order.order_items" :key="item.id" class="flex items-center justify-between text-base">
                <span class="text-on-surface">{{ item.product_name }} × {{ item.quantity }}</span>
                <span class="font-medium text-on-surface-variant">{{ formatPrice(item.line_total) }}</span>
              </div>
            </div>

            <!-- 總金額 -->
            <div class="mt-4 border-t border-surface-container pt-4 text-right text-lg font-bold text-on-surface">
              總金額 {{ formatPrice(order.total) }}
            </div>

            <!-- 顧客／收件資訊：總金額下方，橫式呈現 -->
            <div class="mt-4 flex flex-wrap items-center gap-x-8 gap-y-3 rounded-lg bg-surface-container-low px-5 py-4 text-base">
              <div class="flex items-baseline gap-2">
                <span class="text-sm font-semibold text-on-surface-variant">收件人</span>
                <span class="font-bold text-on-surface">{{ order.recipient_name || '未填寫' }}</span>
              </div>
              <div class="flex items-baseline gap-2">
                <span class="text-sm font-semibold text-on-surface-variant">電話</span>
                <span class="text-on-surface">{{ order.recipient_phone || '未填寫' }}</span>
              </div>
              <div class="flex min-w-0 items-baseline gap-2">
                <span class="shrink-0 text-sm font-semibold text-on-surface-variant">地址</span>
                <span class="text-on-surface">{{ order.shipping_address || '未填寫' }}</span>
              </div>
              <div v-if="order.note" class="flex min-w-0 items-baseline gap-2">
                <span class="shrink-0 text-sm font-semibold text-on-surface-variant">備註</span>
                <span class="text-on-surface">{{ order.note }}</span>
              </div>
            </div>

            <!-- 未付款：顧客可繼續前往綠界付款 -->
            <div v-if="!isAdmin && order.payment_status === 'unpaid'" class="mt-4 flex justify-end">
              <Button
                class="primary-gradient rounded-xl font-bold text-on-primary"
                :disabled="payingOrderId === order.id"
                @click="payOrder(order.id)"
              >
                {{ payingOrderId === order.id ? '前往付款中…' : '去付款' }}
              </Button>
            </div>
          </section>
        </div>
      </template>
    </main>
  </div>
</template>
