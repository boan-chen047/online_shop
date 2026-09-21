<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useNow } from '@vueuse/core'
import { RouterLink, useRoute } from 'vue-router'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/composables/useAuth'
import { formatPrice } from '@/composables/useCatalog'
import { supabase } from '@/lib/supabase'
import { startEcpayPayment } from '@/lib/ecpay'
import {
  type Order,
  loadMyOrders,
  orderStatusOptions,
  paymentStatusLabel,
  customerStatusLabel,
  isOrderCompleted,
  isInReviewPeriod,
} from '@/composables/useOrders'

const { isAuthReady, currentUser } = useAuth()
const route = useRoute()

// 視角由網址決定：/admin/orders = 管理全部；/orders = 看自己的（進行中）。
const isManagementView = computed(() => route.name === 'AdminOrders')

const now = useNow()
const orders = ref<Order[]>([])
const isLoading = ref(false)
const loadError = ref('')
const updatingOrderId = ref('')
const payingOrderId = ref('')
const confirmingOrderId = ref('')

// 管理視角看全部；個人「我的訂單」只顯示進行中（已完結進歷史訂單頁）。
const displayedOrders = computed(() =>
  isManagementView.value
    ? orders.value
    : orders.value.filter((order) => !isOrderCompleted(order, now.value.getTime())),
)

function reviewDeadline(order: Order) {
  return order.closed_at ? new Date(order.closed_at).toLocaleString('zh-TW') : ''
}

async function loadOrders() {
  isLoading.value = true
  loadError.value = ''
  try {
    orders.value = await loadMyOrders()
  } catch (error) {
    loadError.value = error instanceof Error ? error.message : '訂單載入失敗。'
    orders.value = []
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
    await loadOrders()
  }
  updatingOrderId.value = ''
}

// 顧客提前結束鑑賞期 → 立即完結（後端 RPC 只允許操作自己的、received、鑑賞期內訂單）。
async function confirmComplete(orderId: string) {
  confirmingOrderId.value = orderId
  loadError.value = ''
  const { data, error } = await supabase.rpc('confirm_order_completed', { p_order_id: orderId })
  if (error) {
    loadError.value = error.message
  } else if (data !== 'completed') {
    loadError.value = '無法結束鑑賞期，請重新整理再試。'
  } else {
    await loadOrders()
  }
  confirmingOrderId.value = ''
}

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
      <h1 class="mb-6 font-headline text-2xl font-black">{{ isManagementView ? '訂單管理' : '我的訂單' }}</h1>

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

        <div v-else-if="!displayedOrders.length" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-on-surface-variant">
          {{ isManagementView ? '目前還沒有任何訂單。' : '目前沒有進行中的訂單。' }}
          <p v-if="!isManagementView" class="mt-1 text-sm">已完結的訂單可到「會員中心 → 歷史訂單」查看。</p>
        </div>

        <div v-else class="space-y-5">
          <section v-for="order in displayedOrders" :key="order.id" class="rounded-xl bg-surface-container-lowest p-6 shadow-sm md:p-7">
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
                <!-- 管理員可改出貨狀態，顧客看友善狀態文字 -->
                <select
                  v-if="isManagementView"
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
                  {{ customerStatusLabel(order, now.getTime()) }}
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

            <!-- 顧客／收件資訊 -->
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

            <!-- 鑑賞期提示（顧客，received 且鑑賞期內） -->
            <p v-if="!isManagementView && isInReviewPeriod(order, now.getTime())" class="mt-4 text-sm text-on-surface-variant">
              7 天鑑賞期至 {{ reviewDeadline(order) }}，期滿自動完結；也可提前確認完成。
            </p>

            <!-- 動作區 -->
            <div class="mt-4 flex flex-wrap justify-end gap-3">
              <!-- 管理員測試：一鍵模擬物流送達簽收 → 進入鑑賞期 -->
              <Button
                v-if="isManagementView && order.payment_status === 'paid' && ['created', 'shipping'].includes(order.order_status)"
                variant="outline"
                class="rounded-xl font-bold"
                :disabled="updatingOrderId === order.id"
                @click="updateOrderStatus(order.id, 'received')"
              >
                {{ updatingOrderId === order.id ? '處理中…' : '模擬送達簽收' }}
              </Button>

              <!-- 顧客：未付款可去付款 -->
              <Button
                v-if="!isManagementView && order.payment_status === 'unpaid'"
                class="primary-gradient rounded-xl font-bold text-on-primary"
                :disabled="payingOrderId === order.id"
                @click="payOrder(order.id)"
              >
                {{ payingOrderId === order.id ? '前往付款中…' : '去付款' }}
              </Button>

              <!-- 顧客：鑑賞期內可提前結束 → 完結 -->
              <Button
                v-if="!isManagementView && isInReviewPeriod(order, now.getTime())"
                class="primary-gradient rounded-xl font-bold text-on-primary"
                :disabled="confirmingOrderId === order.id"
                @click="confirmComplete(order.id)"
              >
                {{ confirmingOrderId === order.id ? '處理中…' : '確認完成（提前結束鑑賞期）' }}
              </Button>
            </div>
          </section>
        </div>
      </template>
    </main>
  </div>
</template>
