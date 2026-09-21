<script setup lang="ts">
// 引入依賴
import { computed, ref, watch } from 'vue'
import { useNow } from '@vueuse/core'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/composables/useAuth'
import { formatPrice } from '@/composables/useCatalog'
import {
  type Order,
  loadMyOrders,
  isOrderCompleted,
  customerStatusLabel,
} from '@/composables/useOrders'
import Login from './Login.vue'
import {
  BadgeCheck,
  Package,
  LogOut,
  ShoppingBag,
} from 'lucide-vue-next'
// 引入依賴

// 用戶資料
const {
  currentUser,
  isAuthReady,
  authError,
  userProfile,
  userInitials,
  signOutUser,
} = useAuth()
// 用戶資料

// 歷史訂單（已完結）
const now = useNow()
const orders = ref<Order[]>([])
const ordersLoading = ref(false)
const ordersError = ref('')
const completedOrders = computed(() =>
  orders.value.filter((order) => isOrderCompleted(order, now.value.getTime())),
)

async function loadHistory() {
  ordersLoading.value = true
  ordersError.value = ''
  try {
    orders.value = await loadMyOrders()
  } catch (error) {
    ordersError.value = error instanceof Error ? error.message : '訂單載入失敗。'
    orders.value = []
  }
  ordersLoading.value = false
}

watch(
  [isAuthReady, currentUser],
  ([ready, user]) => {
    if (ready && user) {
      void loadHistory()
    } else if (ready && !user) {
      orders.value = []
    }
  },
  { immediate: true },
)
</script>

<template>
  <div class="bg-surface text-on-surface antialiased min-h-screen pb-16 font-body">
    <div v-if="!isAuthReady" class="min-h-[60vh] flex items-center justify-center px-6">
      <div class="rounded-2xl bg-surface-container-lowest px-8 py-6 text-center shadow-sm">
        <p class="font-bold text-on-surface">確認登入狀態中…</p>
        <p class="mt-2 text-sm text-on-surface-variant">正在載入你的登入資訊。</p>
      </div>
    </div>

    <Login v-else-if="!currentUser" />

    <!-- 用戶個人資訊頭部 -->
    <template v-else>
    <header class="relative pt-16 pb-12 px-6 md:px-8 max-w-4xl mx-auto">
      <div class="flex flex-col items-center text-center gap-6">
        <div class="relative">
          <div class="w-32 h-32 md:w-44 md:h-44 rounded-[40px] overflow-hidden shadow-[0_10px_30px_-5px_rgba(178,34,3,0.08)] border-4 border-surface-container-lowest">
            <img v-if="userProfile.avatar" :alt="userProfile.name" class="w-full h-full object-cover" :src="userProfile.avatar"/>
            <div v-else class="flex h-full w-full items-center justify-center bg-primary text-5xl font-black text-on-primary">
              {{ userInitials }}
            </div>
          </div>
          <div class="absolute -bottom-2 -right-2 bg-primary text-on-primary p-2 rounded-xl shadow-lg border-2 border-surface-container-lowest flex items-center justify-center">
            <BadgeCheck class="w-5 h-5" />
          </div>
        </div>
        <div>
          <h1 class="font-bold text-4xl text-on-surface mb-2 font-headline">{{ userProfile.name }}</h1>
          <p class="text-lg text-outline">{{ userProfile.title }}</p>
          <div class="mt-5">
            <Button variant="outline" class="rounded-full border-outline bg-surface-container-lowest font-bold" @click="signOutUser">
              <LogOut class="mr-2 size-4" />
              登出
            </Button>
          </div>
          <p v-if="authError" class="mt-4 text-sm font-medium text-error">{{ authError }}</p>
        </div>
      </div>
    </header>
    <!-- 用戶個人資訊頭部 -->

    <main class="max-w-4xl mx-auto px-6 md:px-8">
      <!-- 購買歷史記錄（已完結訂單） -->
      <section class="space-y-6">
        <div class="flex items-center justify-between px-2 mb-2">
          <h2 class="font-bold text-2xl font-headline">歷史訂單</h2>
        </div>

        <div v-if="ordersLoading" class="space-y-4">
          <div v-for="index in 2" :key="index" class="h-28 animate-pulse rounded-[28px] bg-surface-container-lowest" />
        </div>

        <div v-else-if="ordersError" class="rounded-[28px] bg-surface-container-lowest p-8 text-center text-base text-error border border-outline-variant/30">
          {{ ordersError }}
        </div>

        <!-- 沒有已完結訂單 -->
        <div v-else-if="!completedOrders.length" class="bg-surface-container-lowest p-10 rounded-[28px] shadow-[0_10px_30px_-5px_rgba(178,34,3,0.08)] border border-outline-variant/30 text-center">
          <div class="mx-auto mb-5 flex size-16 items-center justify-center rounded-2xl bg-surface-container text-primary">
            <Package class="size-8" />
          </div>
          <h3 class="font-headline text-2xl font-black text-on-surface">尚無已完結的訂單</h3>
          <p class="mx-auto mt-2 max-w-md text-sm leading-relaxed text-on-surface-variant">
            訂單通過 7 天鑑賞期（或取消）後會出現在這裡。進行中的訂單請到「我的訂單」查看。
          </p>
          <Button as-child class="primary-gradient mt-6 rounded-xl font-bold text-on-primary">
            <RouterLink to="/products">
              <ShoppingBag class="mr-2 size-4" />
              去逛逛商品
            </RouterLink>
          </Button>
        </div>

        <!-- 已完結訂單清單 -->
        <div v-else class="space-y-4">
          <section
            v-for="order in completedOrders"
            :key="order.id"
            class="rounded-[28px] bg-surface-container-lowest p-6 shadow-[0_10px_30px_-5px_rgba(178,34,3,0.08)] border border-outline-variant/30"
          >
            <div class="flex flex-wrap items-start justify-between gap-3 border-b border-surface-container pb-4">
              <div class="min-w-0">
                <p class="font-mono text-xs text-on-surface-variant">{{ order.id }}</p>
                <p class="mt-1 text-sm text-on-surface-variant">{{ new Date(order.placed_at).toLocaleString('zh-TW') }}</p>
              </div>
              <span class="rounded-full bg-surface-container px-3 py-1.5 text-sm font-bold text-on-surface-variant">
                {{ customerStatusLabel(order, now.getTime()) }}
              </span>
            </div>
            <div class="mt-4 space-y-2">
              <div v-for="item in order.order_items" :key="item.id" class="flex items-center justify-between text-sm">
                <span class="text-on-surface">{{ item.product_name }} × {{ item.quantity }}</span>
                <span class="text-on-surface-variant">{{ formatPrice(item.line_total) }}</span>
              </div>
            </div>
            <div class="mt-4 border-t border-surface-container pt-3 text-right font-bold text-on-surface">
              總金額 {{ formatPrice(order.total) }}
            </div>
          </section>
        </div>
      </section>
      <!-- 購買歷史記錄 -->
    </main>
    </template>
  </div>
</template>
