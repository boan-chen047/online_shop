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
    title="服務條款"
    :intro="`歡迎使用 ${siteInfo.name}。當您註冊會員或在本網站購物，即表示您已閱讀、了解並同意以下條款。`"
    :updated-at="siteInfo.policyUpdatedAt"
    sample
  >
    <section>
      <h2 :class="h2">一、會員帳號</h2>
      <ul :class="ul">
        <li>您可以使用電子郵件或 Google 帳號註冊會員。請提供真實、正確的資料，並妥善保管您的帳號與密碼。</li>
        <li>任何透過您帳號進行的操作，視為您本人的行為。若發現帳號遭他人盜用，請立即與我們聯絡。</li>
        <li>若您違反本條款或有不當使用的情形，我們得暫停或終止您的會員資格。</li>
      </ul>
    </section>

    <section>
      <h2 :class="h2">二、訂購與付款</h2>
      <ul :class="ul">
        <li>商品價格以您送出訂單時結帳頁面顯示的金額為準；限時特賣的折扣以活動期間內下單為限。</li>
        <li>付款透過綠界科技提供的付款頁面完成，可使用信用卡、ATM 轉帳、超商代碼等方式。</li>
        <li><span class="font-bold text-on-surface">請於下單後 3 日內完成付款</span>，逾期未付款的訂單將自動取消，保留的商品也會釋出。</li>
        <li>商品庫存以付款完成時為準。若遇缺貨，我們將與您聯繫並辦理退款。</li>
      </ul>
    </section>

    <section>
      <h2 :class="h2">三、出貨與鑑賞期</h2>
      <ul :class="ul">
        <li>付款完成後我們會安排出貨，出貨時間與配送方式詳見<RouterLink to="/shipping" :class="link">運送與退貨說明</RouterLink>。</li>
        <li>
          依《消費者保護法》第 19 條，您在收到商品後享有 7 天鑑賞期，可以不附理由解除契約、辦理退貨。
          鑑賞期不是試用期，退回的商品請保持完整包裝與配件。
        </li>
      </ul>
    </section>

    <section>
      <h2 :class="h2">四、智慧財產權</h2>
      <p>本網站的文字、圖片、商標與介面設計等內容，均受著作權及相關法令保護。未經同意，請勿重製、轉載或作其他商業用途。</p>
    </section>

    <section>
      <h2 :class="h2">五、服務中斷與免責</h2>
      <p>
        我們會盡力維持網站正常運作，但可能因系統維護、第三方服務異常或不可抗力等因素暫停服務。
        因此造成的不便，我們將盡速修復並於網站公告。
      </p>
    </section>

    <section>
      <h2 :class="h2">六、個人資料保護</h2>
      <p>我們如何蒐集與使用您的個人資料，請參閱<RouterLink to="/privacy" :class="link">隱私權政策</RouterLink>。</p>
    </section>

    <section>
      <h2 :class="h2">七、條款修訂與準據法</h2>
      <p>
        我們可能因營運需要修訂本條款，修訂後公布於本頁即生效。本條款以中華民國法律為準據法；
        如有爭議，雙方同意以臺灣臺北地方法院為第一審管轄法院。
      </p>
    </section>
  </StaticPageLayout>
</template>
