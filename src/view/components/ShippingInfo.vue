<script setup lang="ts">
import { RouterLink } from 'vue-router'
import StaticPageLayout from './StaticPageLayout.vue'
import { siteInfo } from '@/lib/siteInfo'

const h2 = 'mb-3 font-headline text-xl font-bold text-on-surface'
const ul = 'list-disc space-y-2 pl-6'
const link = 'font-bold text-primary underline underline-offset-2'
</script>

<template>
  <StaticPageLayout
    title="運送與退貨說明"
    intro="從付款、出貨到退貨，購物前可以先看看這裡。"
    sample
  >
    <section>
      <h2 :class="h2">付款方式</h2>
      <p>結帳時會導向綠界科技的付款頁面，可選擇信用卡、ATM 轉帳、超商代碼等方式。請於下單後 3 日內完成付款，逾期訂單會自動取消。</p>
    </section>

    <section>
      <h2 :class="h2">運費</h2>
      <p><span class="font-bold text-on-surface">目前全站免運費</span>，結帳金額即為商品金額。</p>
    </section>

    <section>
      <h2 :class="h2">出貨時間與配送範圍</h2>
      <ul :class="ul">
        <li>付款完成後，我們會在 1–3 個工作天內安排出貨（遇例假日或活動檔期可能稍有延後）。</li>
        <li>目前配送範圍為臺灣本島。</li>
        <li>訂單的付款與出貨狀態，可以到<RouterLink to="/orders" :class="link">我的訂單</RouterLink>隨時查詢。</li>
      </ul>
    </section>

    <section>
      <h2 :class="h2">7 天鑑賞期</h2>
      <ul :class="ul">
        <li>商品簽收後即進入 7 天鑑賞期，期滿後訂單會自動完成，並移到會員中心的「歷史訂單」。</li>
        <li>確認商品沒問題的話，也可以在「我的訂單」按「確認完成」提前結束鑑賞期。</li>
        <li>鑑賞期不是試用期，若要退貨，請保持商品、配件、贈品與包裝完整。</li>
      </ul>
    </section>

    <section>
      <h2 :class="h2">如何退貨</h2>
      <ul :class="ul">
        <li>
          請在鑑賞期內來信
          <a :href="`mailto:${siteInfo.contactEmail}`" :class="link">{{ siteInfo.contactEmail }}</a>，
          並附上訂單編號與退貨原因。
        </li>
        <li>我們確認後會與您聯繫收回商品的方式；收到退回商品並確認無誤後，將以原付款方式辦理退款。</li>
      </ul>
    </section>
  </StaticPageLayout>
</template>
