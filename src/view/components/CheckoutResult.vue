<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { CheckCircle2, Clock, XCircle } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'

const route = useRoute()
const router = useRouter()
const orderId = String(route.query.order ?? '')

// pending：等待綠界回呼把訂單改成 paid；paid：已付款；unknown：查不到或逾時
const state = ref<'loading' | 'paid' | 'pending' | 'unknown'>('loading')
const total = ref<number | null>(null)

let timer: ReturnType<typeof setTimeout> | null = null
let attempts = 0
const maxAttempts = 10

// 付款成功後倒數自動返回商店
const redirectSeconds = ref(20)
let redirectTimer: ReturnType<typeof setInterval> | null = null

function startRedirectCountdown() {
  redirectTimer = setInterval(() => {
    redirectSeconds.value -= 1
    if (redirectSeconds.value <= 0) {
      if (redirectTimer) clearInterval(redirectTimer)
      void router.push('/products')
    }
  }, 1000)
}

async function checkStatus() {
  if (!orderId) {
    state.value = 'unknown'
    return
  }

  const { data, error } = await supabase
    .from('orders')
    .select('payment_status, total')
    .eq('id', orderId)
    .maybeSingle()

  if (error || !data) {
    state.value = 'unknown'
    return
  }

  total.value = Number(data.total)

  if (data.payment_status === 'paid') {
    state.value = 'paid'
    startRedirectCountdown()
    return
  }

  // 綠界的 server-to-server 通知可能比使用者導回稍慢，重試幾次再判定為 pending
  attempts += 1
  if (attempts >= maxAttempts) {
    state.value = 'pending'
    return
  }

  state.value = 'loading'
  timer = setTimeout(checkStatus, 2000)
}

onMounted(checkStatus)
onBeforeUnmount(() => {
  if (timer) clearTimeout(timer)
  if (redirectTimer) clearInterval(redirectTimer)
})
</script>

<template>
  <div class="bg-surface text-on-surface antialiased min-h-screen font-body">
    <main class="mx-auto flex max-w-lg flex-col items-center px-5 pt-16 pb-16 text-center">
      <template v-if="state === 'loading'">
        <div class="size-14 animate-spin rounded-full border-4 border-surface-container-high border-t-primary" />
        <h1 class="mt-6 font-headline text-2xl font-black">確認付款結果中…</h1>
        <p class="mt-2 text-base text-on-surface-variant">正在向綠界確認你的付款狀態，請稍候。</p>
      </template>

      <template v-else-if="state === 'paid'">
        <CheckCircle2 class="size-16 text-primary" />
        <h1 class="mt-5 font-headline text-2xl font-black">付款成功</h1>
        <p v-if="total !== null" class="mt-2 text-base text-on-surface-variant">已完成付款，金額 NT${{ total }}。</p>
        <p class="mt-1 text-sm text-on-surface-variant">訂單編號</p>
        <p class="font-mono text-sm">{{ orderId }}</p>
        <p class="mt-4 text-sm text-on-surface-variant">{{ redirectSeconds }} 秒後自動返回商店…</p>
        <div class="mt-6 flex gap-3">
          <Button as-child class="primary-gradient rounded-xl px-6 font-bold text-on-primary">
            <RouterLink to="/orders">查看我的訂單</RouterLink>
          </Button>
          <Button as-child variant="outline" class="rounded-xl px-6 font-bold">
            <RouterLink to="/products">立即返回商店</RouterLink>
          </Button>
        </div>
      </template>

      <template v-else-if="state === 'pending'">
        <Clock class="size-16 text-secondary" />
        <h1 class="mt-5 font-headline text-2xl font-black">付款確認中</h1>
        <p class="mt-2 text-base text-on-surface-variant">
          訂單已建立，但尚未收到綠界的付款確認。若你已完成付款，狀態通常會在數分鐘內更新，可稍後至「我的訂單」查看。
        </p>
        <div class="mt-8 flex gap-3">
          <Button as-child class="primary-gradient rounded-xl px-6 font-bold text-on-primary">
            <RouterLink to="/orders">前往我的訂單</RouterLink>
          </Button>
        </div>
      </template>

      <template v-else>
        <XCircle class="size-16 text-error" />
        <h1 class="mt-5 font-headline text-2xl font-black">找不到這筆訂單</h1>
        <p class="mt-2 text-base text-on-surface-variant">無法確認付款結果，請至「我的訂單」查看，或聯絡客服。</p>
        <div class="mt-8 flex gap-3">
          <Button as-child class="primary-gradient rounded-xl px-6 font-bold text-on-primary">
            <RouterLink to="/orders">前往我的訂單</RouterLink>
          </Button>
          <Button as-child variant="outline" class="rounded-xl px-6 font-bold">
            <RouterLink to="/">回首頁</RouterLink>
          </Button>
        </div>
      </template>
    </main>
  </div>
</template>
