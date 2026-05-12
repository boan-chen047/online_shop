<script setup lang="ts">
// 引入依賴
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Trash2, Minus, Plus } from 'lucide-vue-next'
import { useCart } from '@/composables/useCart'
import { cn } from '@/lib/utils'
import { formatPrice } from '@/composables/useCatalog'
// 引入依賴

// 購物車資料
const {
  cartItems,
  isCartLoading,
  cartError,
  itemCount,
  selectedItemCount,
  selectedCartItems,
  subtotal,
  loadCart,
  checkoutSelectedCart,
  updateQuantity,
  removeFromCart,
  toggleItemSelected,
  setAllSelected,
} = useCart()
// 購物車資料

const total = computed(() => subtotal.value)
const isCheckingOut = ref(false)

const isAllSelected = computed(() =>
  cartItems.value.length > 0 && cartItems.value.every((item) => item.selected),
)

function toggleAllSelected() {
  void setAllSelected(!isAllSelected.value)
}

async function handleCheckout() {
  if (!selectedCartItems.value.length) {
    window.alert('請先勾選要結帳的商品。')
    return
  }

  isCheckingOut.value = true

  try {
    const orderId = await checkoutSelectedCart()
    window.alert(`訂單已建立：${orderId}`)
  } catch {
    window.alert(cartError.value || '建立訂單失敗。')
  } finally {
    isCheckingOut.value = false
  }
}

onMounted(() => {
  void loadCart({ force: true })
})
</script>

<template>
  <div class="bg-surface text-on-surface antialiased h-full font-body">
    <main class="mx-auto max-w-[94vw] px-5 pt-24 pb-8">

      <!-- 購物步驟指示器 -->
      <div class="mb-12">
        <div class="flex items-center justify-center max-w-2xl mx-auto">
          <div class="flex flex-col items-center gap-2">
            <div class="w-10 h-10 rounded-full bg-primary text-on-primary flex items-center justify-center font-bold shadow-lg shadow-primary/20">1</div>
            <span class="text-xs font-bold text-primary uppercase tracking-widest">Cart</span>
          </div>
          <div class="flex-1 h-[2px] mx-4 bg-primary-container mb-6"></div>

          <div class="flex flex-col items-center gap-2">
            <div class="w-10 h-10 rounded-full border-2 border-primary text-primary flex items-center justify-center font-bold">2</div>
            <span class="text-xs font-bold text-primary uppercase tracking-widest">Info</span>
          </div>
          <div class="flex-1 h-[2px] mx-4 bg-surface-container-high mb-6"></div>

          <div class="flex flex-col items-center gap-2 opacity-40">
            <div class="w-10 h-10 rounded-full border-2 border-outline-variant text-outline flex items-center justify-center font-bold">3</div>
            <span class="text-xs font-bold text-outline uppercase tracking-widest">Payment</span>
          </div>
          <div class="flex-1 h-[2px] mx-4 bg-surface-container-high mb-6"></div>

          <div class="flex flex-col items-center gap-2 opacity-40">
            <div class="w-10 h-10 rounded-full border-2 border-outline-variant text-outline flex items-center justify-center font-bold">4</div>
            <span class="text-xs font-bold text-outline uppercase tracking-widest">Done</span>
          </div>
        </div>
      </div>
      <!-- 購物步驟指示器 -->

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_380px] xl:grid-cols-[minmax(0,1fr)_400px]">

        <!-- 左欄購物車商品 -->
        <div>
          <section class="bg-surface-container-lowest p-5 md:p-6 rounded-xl shadow-sm h-full">
            <div class="flex justify-between items-center mb-6">
              <h2 class="text-xl font-bold font-headline">購物車 ({{ itemCount }})</h2>
              <Button variant="ghost" class="text-secondary text-sm font-semibold hover:underline px-0" :disabled="!cartItems.length" @click="toggleAllSelected">
                {{ isAllSelected ? '取消全選' : '全選' }}
              </Button>
            </div>

            <div v-if="isCartLoading" class="space-y-5">
              <div v-for="index in 3" :key="index" class="h-36 animate-pulse rounded-xl bg-surface-container-low" />
            </div>

            <div v-else-if="cartError" class="flex min-h-80 flex-col items-center justify-center rounded-xl bg-surface-container-low p-8 text-center">
              <h3 class="font-headline text-2xl font-black text-on-surface">購物車暫時無法載入</h3>
              <p class="mt-2 max-w-sm text-sm text-on-surface-variant">{{ cartError }}</p>
              <Button as-child class="primary-gradient mt-6 rounded-xl font-bold text-on-primary">
                <RouterLink to="/login">前往登入</RouterLink>
              </Button>
            </div>

            <div v-else-if="cartItems.length" class="space-y-5">
              <div v-for="item in cartItems" :key="item.id" class="grid grid-cols-[104px_minmax(0,1fr)] gap-4 border-b border-surface-container pb-5 last:border-0 last:pb-0 md:grid-cols-[128px_minmax(0,1fr)_160px] md:gap-6">
                <div class="h-28 w-28 overflow-hidden rounded-lg bg-surface-container-low md:h-32 md:w-32">
                  <img :alt="item.name" :src="item.image" class="w-full h-full object-cover"/>
                </div>
                <div class="min-w-0">
                  <h3 class="text-base font-bold text-on-surface line-clamp-1">{{ item.name }}</h3>
                  <p class="mt-1 text-on-surface-variant text-sm">{{ item.categoryName }}</p>
                  <div class="mt-5 flex items-center gap-2">
                    <div class="flex items-center gap-1 bg-surface-container rounded-full px-3 py-1">
                      <Button variant="ghost" size="icon" @click="updateQuantity(item.id, item.quantity - 1)" :disabled="item.quantity <= 1" class="w-6 h-6 hover:text-primary disabled:opacity-30">
                        <Minus class="size-3" />
                      </Button>
                      <span class="text-sm font-bold w-4 text-center">{{ item.quantity }}</span>
                      <Button variant="ghost" size="icon" @click="updateQuantity(item.id, item.quantity + 1)" class="w-6 h-6 hover:text-primary">
                        <Plus class="size-3" />
                      </Button>
                    </div>
                    <Button variant="ghost" size="icon" class="text-outline-variant hover:text-error h-8 w-8" @click="removeFromCart(item.id)">
                      <Trash2 class="size-4" />
                    </Button>
                  </div>
                </div>

                <div class="col-span-2 flex items-center justify-between gap-4 md:col-span-1 md:flex-col md:items-end md:justify-between">
                  <label class="inline-flex items-center gap-2 text-xs font-bold text-on-surface-variant">
                      <input
                        type="checkbox"
                        :checked="item.selected"
                        class="size-4 accent-primary"
                        @change="toggleItemSelected(item.id)"
                      >
                    計入
                  </label>
                  <span :class="cn('font-bold text-lg md:text-xl', item.selected ? 'text-primary' : 'text-outline-variant')">{{ formatPrice(item.price * item.quantity) }}</span>
                </div>
              </div>
            </div>
            <div v-else class="flex min-h-80 flex-col items-center justify-center rounded-xl bg-surface-container-low p-8 text-center">
              <h3 class="font-headline text-2xl font-black text-on-surface">購物車是空的</h3>
              <p class="mt-2 max-w-sm text-sm text-on-surface-variant">從商品列表加入商品後，會在這裡看到資料庫同步的購物車內容。</p>
              <Button as-child class="primary-gradient mt-6 rounded-xl font-bold text-on-primary">
                <RouterLink to="/products">瀏覽商品</RouterLink>
              </Button>
            </div>
          </section>
        </div>
        <!-- 左欄購物車商品 -->

        <!-- 右欄訂單摘要 -->
        <div>
          <section class="bg-surface-container-lowest p-7 rounded-xl shadow-sm flex flex-col lg:sticky lg:top-24">
            <h2 class="text-xl font-bold font-headline mb-5">訂單摘要</h2>

            <div class="space-y-3 mb-5">
              <div v-if="selectedCartItems.length" class="space-y-3 rounded-lg bg-surface-container-low p-4">
                <div v-for="item in selectedCartItems" :key="item.id" class="flex items-start justify-between gap-3 text-sm">
                  <div class="min-w-0">
                    <p class="line-clamp-1 font-semibold text-on-surface">{{ item.name }}</p>
                    <p class="mt-0.5 text-xs text-on-surface-variant">數量 {{ item.quantity }} · {{ formatPrice(item.price) }}</p>
                  </div>
                  <span class="shrink-0 font-bold text-on-surface">{{ formatPrice(item.price * item.quantity) }}</span>
                </div>
              </div>
              <div v-else class="rounded-lg bg-surface-container-low p-4 text-sm text-on-surface-variant">
                尚未勾選要結帳的商品。
              </div>
              <div class="flex justify-between text-on-surface-variant">
                <span>小計 ({{ selectedItemCount }} 件)</span>
                <span class="font-medium text-on-surface">{{ formatPrice(subtotal) }}</span>
              </div>
            </div>

            <div class="pt-5 border-t border-surface-container mb-6">
              <div class="flex justify-between items-center gap-4">
                <span class="text-on-surface-variant font-medium">總金額</span>
                <div class="text-right">
                  <span class="block text-2xl font-black font-headline text-on-surface">{{ formatPrice(total) }}</span>
                  <span class="text-xs text-outline-variant">未含運費或付款折扣</span>
                </div>
              </div>
            </div>

            <Button class="w-full primary-gradient text-on-primary font-bold py-4 rounded-xl shadow-lg shadow-primary/30 hover:shadow-xl transition-all active:scale-95" :disabled="!selectedCartItems.length || isCheckingOut" @click="handleCheckout">
              {{ isCheckingOut ? '建立訂單中' : '前往結帳' }}
            </Button>
          </section>
        </div>
      </div>
      <!-- 右欄訂單摘要 -->
    </main>

    <!-- 行動版底部固定欄 -->
    <div class="lg:hidden fixed bottom-0 left-0 w-full p-4 bg-surface-container-lowest border-t border-surface-container shadow-2xl z-40">
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-xs text-on-surface-variant font-medium">總金額</p>
          <p class="text-xl font-black text-on-surface">{{ formatPrice(total) }}</p>
        </div>
        <Button class="flex-1 primary-gradient text-on-primary font-bold py-3 px-6 rounded-xl active:scale-95 transition-transform" :disabled="!selectedCartItems.length || isCheckingOut" @click="handleCheckout">
          {{ isCheckingOut ? '建立訂單中' : '前往結帳' }}
        </Button>
      </div>
    </div>
    <!-- 行動版底部固定欄 -->
  </div>
</template>
