<script setup lang="ts">
// 引入依賴
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Trash2, Minus, Plus, CheckCircle2 } from 'lucide-vue-next'
import { useCart } from '@/composables/useCart'
import { cn } from '@/lib/utils'
import { formatPrice } from '@/composables/useCatalog'
import { taiwanCities, taiwanDistricts } from '@/lib/taiwanDistricts'
import { startEcpayPayment } from '@/lib/ecpay'
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

// 結帳步驟：1 購物車 → 2 收件資訊 → 4 完成（目前沒有金流串接，暫時略過 3 付款）
const step = ref<'cart' | 'info' | 'done'>('cart')
const stepIndex = computed(() => (step.value === 'cart' ? 1 : step.value === 'info' ? 2 : 4))

const steps = [
  { n: 1, label: 'Cart' },
  { n: 2, label: 'Info' },
  { n: 3, label: 'Payment' },
  { n: 4, label: 'Done' },
]

function markerClass(n: number) {
  if (n < stepIndex.value) {
    return 'bg-primary text-on-primary shadow-lg shadow-primary/20'
  }
  if (n === stepIndex.value) {
    return 'border-2 border-primary text-primary'
  }
  return 'border-2 border-outline-variant text-outline'
}

function lineClass(n: number) {
  return n < stepIndex.value ? 'bg-primary-container' : 'bg-surface-container-high'
}

const recipientName = ref('')
const recipientPhone = ref('')
const shippingCity = ref('')
const shippingDistrict = ref('')
const shippingDetail = ref('')
const note = ref('')
const formError = ref('')
const lastOrderId = ref('')

const cities = taiwanCities
const districts = computed(() => (shippingCity.value ? taiwanDistricts[shippingCity.value] ?? [] : []))

// 換縣市時清掉已選的鄉鎮區，避免殘留不屬於新縣市的選項
watch(shippingCity, () => {
  shippingDistrict.value = ''
})

function handleProceedToInfo() {
  if (!selectedCartItems.value.length) {
    window.alert('請先勾選要結帳的商品。')
    return
  }

  step.value = 'info'
}

function handleBackToCart() {
  step.value = 'cart'
}

async function handleSubmitOrder() {
  formError.value = ''

  const name = recipientName.value.trim()
  const phoneRaw = recipientPhone.value.trim()
  const detail = shippingDetail.value.trim()

  if (!name || !phoneRaw || !shippingCity.value || !shippingDistrict.value || !detail) {
    formError.value = '請填寫收件人姓名、聯絡電話、縣市、鄉鎮區與詳細地址。'
    return
  }

  if (name.length < 2) {
    formError.value = '收件人姓名至少需要 2 個字。'
    return
  }

  // 收件人姓名限純文字：中文、英文字母、空白與間隔號，不可含數字或特殊符號
  if (!/^[一-鿿 a-zA-Z·‧・]+$/.test(name)) {
    formError.value = '收件人姓名只能是中文或英文，不可包含數字或特殊符號。'
    return
  }

  // 台灣電話：去掉空白與連字號後，須為 0 開頭的 9~10 碼數字
  // （手機 09xxxxxxxx 共 10 碼；市話 0x-xxxxxxx(x) 共 9~10 碼）
  const phoneDigits = phoneRaw.replace(/[\s-]/g, '')
  if (!/^0\d{8,9}$/.test(phoneDigits)) {
    formError.value = '請輸入正確的電話號碼（例如 0912345678 或 02-12345678）。'
    return
  }

  if (detail.length < 4) {
    formError.value = '詳細地址過短，請填寫街道、門牌等資訊。'
    return
  }

  const address = `${shippingCity.value}${shippingDistrict.value}${detail}`

  isCheckingOut.value = true

  try {
    // 1. 先在資料庫建立未付款訂單（金額伺服器端計算）
    const orderId = await checkoutSelectedCart({
      recipientName: name,
      recipientPhone: phoneRaw,
      shippingAddress: address,
      note: note.value.trim(),
    })
    lastOrderId.value = orderId
    // 2. 取得綠界付款參數並導向綠界收銀台；成功會離開本頁，付款結果由結果頁確認
    await startEcpayPayment(orderId)
  } catch (error) {
    formError.value =
      cartError.value ||
      (error instanceof Error ? error.message : '') ||
      '建立訂單或前往付款失敗，請稍後再試。'
    isCheckingOut.value = false
  }
}

const ctaLabel = computed(() => {
  if (step.value === 'cart') return '前往結帳'
  return isCheckingOut.value ? '前往付款中' : '前往綠界付款'
})

const ctaDisabled = computed(() => {
  if (step.value === 'cart') return !selectedCartItems.value.length || isCheckingOut.value
  return isCheckingOut.value
})

function handleCtaClick() {
  if (step.value === 'cart') {
    handleProceedToInfo()
  } else if (step.value === 'info') {
    void handleSubmitOrder()
  }
}

// 切換結帳步驟時捲回頁面最上方，避免停在原本的捲動位置
watch(step, () => {
  window.scrollTo({ top: 0, behavior: 'smooth' })
})

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
          <template v-for="(item, index) in steps" :key="item.n">
            <div class="flex flex-col items-center gap-2">
              <div :class="cn('w-10 h-10 rounded-full flex items-center justify-center font-bold', markerClass(item.n))">{{ item.n }}</div>
              <span :class="cn('text-xs font-bold uppercase tracking-widest', item.n <= stepIndex ? 'text-primary' : 'text-outline')">{{ item.label }}</span>
            </div>
            <div v-if="index < steps.length - 1" :class="cn('flex-1 h-[2px] mx-4 mb-6', lineClass(item.n))"></div>
          </template>
        </div>
      </div>
      <!-- 購物步驟指示器 -->

      <!-- ===== 完成畫面 ===== -->
      <div v-if="step === 'done'" class="mx-auto flex max-w-lg flex-col items-center rounded-xl bg-surface-container-lowest p-10 text-center shadow-sm">
        <CheckCircle2 class="size-14 text-primary" />
        <h2 class="mt-5 font-headline text-2xl font-black text-on-surface">訂單已建立</h2>
        <p class="mt-2 text-sm text-on-surface-variant">訂單編號</p>
        <p class="mt-1 font-mono text-sm text-on-surface">{{ lastOrderId }}</p>
        <Button as-child class="primary-gradient mt-8 rounded-xl px-8 font-bold text-on-primary">
          <RouterLink to="/products">繼續購物</RouterLink>
        </Button>
      </div>
      <!-- ===== 完成畫面 ===== -->

      <div v-else class="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_380px] xl:grid-cols-[minmax(0,1fr)_400px]">

        <!-- 左欄：購物車商品 -->
        <div v-if="step === 'cart'">
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
              <div v-for="item in cartItems" :key="item.id" class="grid grid-cols-[128px_minmax(0,1fr)] gap-4 border-b border-surface-container pb-6 last:border-0 last:pb-0 md:grid-cols-[144px_minmax(0,1fr)_160px] md:gap-6">
                <div class="h-32 w-32 overflow-hidden rounded-lg bg-surface-container-low md:h-36 md:w-36">
                  <img :alt="item.name" :src="item.image" class="w-full h-full object-cover"/>
                </div>
                <div class="min-w-0">
                  <h3 class="text-lg font-bold text-on-surface line-clamp-1">{{ item.name }}</h3>
                  <p class="mt-1.5 text-on-surface-variant text-base">{{ item.categoryName }}</p>
                  <div class="mt-6 flex items-center gap-2">
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
                  <span :class="cn('font-bold text-xl md:text-2xl', item.selected ? 'text-primary' : 'text-outline-variant')">{{ formatPrice(item.price * item.quantity) }}</span>
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
        <!-- 左欄：購物車商品 -->

        <!-- 左欄：收件資訊表單 -->
        <div v-else-if="step === 'info'">
          <section class="bg-surface-container-lowest p-5 md:p-6 rounded-xl shadow-sm h-full">
            <div class="flex items-center gap-3 mb-6">
              <Button variant="ghost" size="sm" class="px-2 text-on-surface-variant" @click="handleBackToCart">‹ 返回購物車</Button>
              <h2 class="text-xl font-bold font-headline">收件資訊</h2>
            </div>

            <div class="space-y-5">
              <div>
                <label class="mb-1.5 block text-sm font-bold text-on-surface-variant">收件人姓名</label>
                <Input v-model="recipientName" placeholder="王小明" />
              </div>
              <div>
                <label class="mb-1.5 block text-sm font-bold text-on-surface-variant">聯絡電話</label>
                <Input v-model="recipientPhone" type="tel" placeholder="0912-345-678" />
              </div>
              <div>
                <label class="mb-1.5 block text-sm font-bold text-on-surface-variant">收件地址（限台灣本島與離島）</label>
                <div class="grid grid-cols-2 gap-3">
                  <select
                    v-model="shippingCity"
                    class="h-9 w-full rounded-md border border-input bg-transparent px-3 text-sm shadow-xs outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50"
                    :class="shippingCity ? 'text-on-surface' : 'text-muted-foreground'"
                  >
                    <option value="" disabled>縣市</option>
                    <option v-for="city in cities" :key="city" :value="city">{{ city }}</option>
                  </select>
                  <select
                    v-model="shippingDistrict"
                    :disabled="!shippingCity"
                    class="h-9 w-full rounded-md border border-input bg-transparent px-3 text-sm shadow-xs outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50"
                    :class="shippingDistrict ? 'text-on-surface' : 'text-muted-foreground'"
                  >
                    <option value="" disabled>{{ shippingCity ? '鄉鎮區' : '請先選縣市' }}</option>
                    <option v-for="district in districts" :key="district" :value="district">{{ district }}</option>
                  </select>
                </div>
                <Input v-model="shippingDetail" class="mt-3" placeholder="街道、門牌號碼（例如：忠孝東路四段 1 號 5 樓）" />
              </div>
              <div>
                <label class="mb-1.5 block text-sm font-bold text-on-surface-variant">備註（選填）</label>
                <textarea
                  v-model="note"
                  rows="2"
                  placeholder="例如：希望的到貨時段、包裝需求"
                  class="w-full resize-none rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-xs outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50"
                ></textarea>
              </div>

              <p v-if="formError" class="text-sm font-medium text-error">{{ formError }}</p>
            </div>
          </section>
        </div>
        <!-- 左欄：收件資訊表單 -->

        <!-- 右欄訂單摘要 -->
        <div>
          <section class="bg-surface-container-lowest p-8 rounded-xl shadow-sm flex flex-col justify-between gap-6 lg:sticky lg:top-24 lg:min-h-[520px]">
            <h2 class="text-xl font-bold font-headline">訂單摘要</h2>

            <div class="space-y-4">
              <div v-if="selectedCartItems.length" class="space-y-4 rounded-lg bg-surface-container-low p-5">
                <div v-for="item in selectedCartItems" :key="item.id" class="flex items-start justify-between gap-3 text-sm">
                  <div class="min-w-0">
                    <p class="line-clamp-1 font-semibold text-on-surface">{{ item.name }}</p>
                    <p class="mt-1 text-xs text-on-surface-variant">數量 {{ item.quantity }} · {{ formatPrice(item.price) }}</p>
                  </div>
                  <span class="shrink-0 font-bold text-on-surface">{{ formatPrice(item.price * item.quantity) }}</span>
                </div>
              </div>
              <div v-else class="rounded-lg bg-surface-container-low p-5 text-sm text-on-surface-variant">
                尚未勾選要結帳的商品。
              </div>
              <div class="flex justify-between text-on-surface-variant">
                <span>小計 ({{ selectedItemCount }} 件)</span>
                <span class="font-medium text-on-surface">{{ formatPrice(subtotal) }}</span>
              </div>
            </div>

            <div class="pt-6 border-t border-surface-container">
              <div class="flex justify-between items-center gap-4">
                <span class="text-on-surface-variant font-medium">總金額</span>
                <div class="text-right">
                  <span class="block text-2xl font-black font-headline text-on-surface">{{ formatPrice(total) }}</span>
                  <span class="text-xs text-outline-variant">未含運費或付款折扣</span>
                </div>
              </div>
            </div>

            <Button class="w-full primary-gradient text-on-primary font-bold py-5 rounded-xl shadow-lg shadow-primary/30 hover:shadow-xl transition-all active:scale-95" :disabled="ctaDisabled" @click="handleCtaClick">
              {{ ctaLabel }}
            </Button>
          </section>
        </div>
        <!-- 右欄訂單摘要 -->
      </div>
    </main>

    <!-- 行動版底部固定欄 -->
    <div v-if="step !== 'done'" class="lg:hidden fixed bottom-[72px] left-0 w-full p-4 bg-surface-container-lowest border-t border-surface-container shadow-2xl z-[60]">
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-xs text-on-surface-variant font-medium">總金額</p>
          <p class="text-xl font-black text-on-surface">{{ formatPrice(total) }}</p>
        </div>
        <Button class="flex-1 primary-gradient text-on-primary font-bold py-3 px-6 rounded-xl active:scale-95 transition-transform" :disabled="ctaDisabled" @click="handleCtaClick">
          {{ ctaLabel }}
        </Button>
      </div>
    </div>
    <!-- 行動版底部固定欄 -->
  </div>
</template>
