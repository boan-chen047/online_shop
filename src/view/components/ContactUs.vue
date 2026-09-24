<script setup lang="ts">
import { RouterLink } from 'vue-router'
import StaticPageLayout from './StaticPageLayout.vue'
import { siteInfo } from '@/lib/siteInfo'
import { Clock, Mail, MessageCircle } from 'lucide-vue-next'

const h2 = 'mb-3 font-headline text-xl font-bold text-on-surface'
const link = 'font-bold text-primary underline underline-offset-2'
</script>

<template>
  <StaticPageLayout
    title="聯絡我們"
    intro="對商品、訂單或網站使用有任何問題，都歡迎與我們聯繫。"
    sample
  >
    <section class="grid gap-4 sm:grid-cols-3">
      <div class="rounded-2xl bg-surface-container-lowest p-5 shadow-sm">
        <Mail class="mb-3 size-6 text-primary" />
        <p class="text-sm font-bold text-on-surface">客服信箱</p>
        <a :href="`mailto:${siteInfo.contactEmail}`" class="mt-1 block break-all text-sm text-primary underline underline-offset-2">
          {{ siteInfo.contactEmail }}
        </a>
      </div>
      <div class="rounded-2xl bg-surface-container-lowest p-5 shadow-sm">
        <Clock class="mb-3 size-6 text-primary" />
        <p class="text-sm font-bold text-on-surface">客服時間</p>
        <p class="mt-1 text-sm">{{ siteInfo.serviceHours }}</p>
      </div>
      <div class="rounded-2xl bg-surface-container-lowest p-5 shadow-sm">
        <MessageCircle class="mb-3 size-6 text-primary" />
        <p class="text-sm font-bold text-on-surface">回覆時間</p>
        <p class="mt-1 text-sm">來信後約 {{ siteInfo.replyTime }}內回覆</p>
      </div>
    </section>

    <section>
      <h2 :class="h2">來信前可以先準備</h2>
      <p>詢問訂單相關問題時，請附上<span class="font-bold text-on-surface">訂單編號</span>（可在「我的訂單」找到）與註冊的電子郵件，能幫助我們更快為您處理。</p>
    </section>

    <section>
      <h2 :class="h2">常見問題</h2>
      <ul class="list-disc space-y-2 pl-6">
        <li>查詢訂單狀態：請到<RouterLink to="/orders" :class="link">我的訂單</RouterLink>。</li>
        <li>付款、出貨與退貨：請看<RouterLink to="/shipping" :class="link">運送與退貨說明</RouterLink>。</li>
        <li>忘記密碼：在<RouterLink to="/login" :class="link">登入頁</RouterLink>點「忘記密碼？」即可重設。</li>
        <li>個人資料查詢或刪除帳號：請參考<RouterLink to="/privacy" :class="link">隱私權政策</RouterLink>第六點。</li>
      </ul>
    </section>
  </StaticPageLayout>
</template>
