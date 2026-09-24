<script setup lang="ts">
import { RouterLink } from 'vue-router'
import StaticPageLayout from './StaticPageLayout.vue'
import { siteInfo } from '@/lib/siteInfo'

// 內文共用樣式
const h2 = 'mb-3 font-headline text-xl font-bold text-on-surface'
const ul = 'list-disc space-y-2 pl-6'
const ol = 'list-decimal space-y-2 pl-6'
const strong = 'font-bold text-on-surface'
</script>

<template>
  <StaticPageLayout
    title="隱私權政策"
    :intro="`${siteInfo.name}（以下稱「本網站」）重視您的個人資料保護。本政策依《個人資料保護法》（以下稱「個資法」）第 8 條規定，說明本網站如何蒐集、處理、利用及保護您的個人資料。當您註冊會員、下單或使用本網站服務，即表示您已閱讀並了解本政策。`"
    :updated-at="siteInfo.policyUpdatedAt"
  >
    <section>
      <h2 :class="h2">一、蒐集者名稱</h2>
      <p>{{ siteInfo.operator }}（以下稱「我們」）。</p>
    </section>

    <section>
      <h2 :class="h2">二、蒐集目的</h2>
      <p class="mb-3">依法務部「個人資料保護法之特定目的及個人資料之類別」，我們蒐集您個人資料的目的如下：</p>
      <ul :class="ul">
        <li>〇六九 契約、類似契約或其他法律關係事務</li>
        <li>〇九〇 消費者、客戶管理與服務</li>
        <li>一三六 資（通）訊與資料庫管理</li>
        <li>一四八 網路購物及其他電子商務服務</li>
        <li>一五七 調查、統計與研究分析</li>
      </ul>
    </section>

    <section>
      <h2 :class="h2">三、蒐集的個人資料類別</h2>
      <ul :class="ul">
        <li>
          <span :class="strong">帳號資料：</span>電子郵件、密碼。密碼由身分驗證服務以不可逆的雜湊方式儲存，我們無法得知您的密碼明文。
          若您使用 Google 帳號登入，我們會取得 Google 提供的姓名、電子郵件及大頭貼。
        </li>
        <li><span :class="strong">收件資料：</span>收件人姓名、聯絡電話、收件地址及訂單備註。</li>
        <li><span :class="strong">交易紀錄：</span>訂購商品、數量、金額、付款與出貨狀態、訂單時間。</li>
        <li>
          <span :class="strong">付款資料：</span>信用卡、ATM 轉帳、超商代碼等付款程序，全部在綠界科技的付款頁面完成。
          <span :class="strong">本網站不會取得或儲存您的信用卡號等完整付款資訊</span>，僅保存付款結果。
        </li>
        <li><span :class="strong">使用紀錄：</span>瀏覽的頁面、操作事件、裝置與瀏覽器資訊、IP 位址等網站使用資料。</li>
      </ul>
    </section>

    <section>
      <h2 :class="h2">四、個人資料利用之期間、地區、對象及方式</h2>
      <ol :class="ol">
        <li>
          <span :class="strong">期間：</span>於蒐集目的存續期間或您的會員帳號存續期間內利用。您申請刪除帳號後，除依法令須保存者外，我們將刪除您的個人資料；
          交易相關紀錄將依《商業會計法》等法令規定之期間保存。
        </li>
        <li>
          <span :class="strong">地區：</span>本網站資料庫主機位於日本（東京區域）；網站由託管服務商透過其全球節點提供服務；
          下列委外服務商依其所在地處理資料。
        </li>
        <li>
          <span :class="strong">對象：</span>我們，以及為完成服務所必要、並受契約約束的委外服務商：
          <ul class="mt-2 list-[circle] space-y-1.5 pl-6">
            <li>Supabase：資料庫、會員身分驗證與檔案儲存</li>
            <li>綠界科技股份有限公司（ECPay）：付款處理</li>
            <li>Google：Google 帳號登入、Google Analytics 網站流量分析</li>
            <li>Vercel：網站託管與網站效能分析</li>
            <li>電子郵件寄送服務：寄送帳號驗證信與重設密碼信</li>
            <li>物流業者：為配送商品，提供收件人姓名、電話及地址</li>
          </ul>
          <p class="mt-2">除上述情形或依法令規定（例如司法機關依法調查）外，我們不會將您的個人資料提供、出售或出租給其他第三人。</p>
        </li>
        <li>
          <span :class="strong">方式：</span>以自動化機器或其他非自動化方式，在蒐集目的範圍內處理及利用，例如：訂單處理、出貨配送、
          客服聯繫、寄送帳號相關通知、網站使用統計分析。
        </li>
      </ol>
    </section>

    <section>
      <h2 :class="h2">五、Cookie 與瀏覽器儲存</h2>
      <ul :class="ul">
        <li><span :class="strong">保持登入：</span>在您的瀏覽器儲存登入憑證，讓您不必每次重新登入。登出後即清除。</li>
        <li><span :class="strong">記住我的帳號：</span>勾選時，會在您的瀏覽器保存您的電子郵件（不保存密碼），方便下次自動帶入；取消勾選即刪除。</li>
        <li><span :class="strong">流量分析：</span>Google Analytics 會使用 Cookie 統計網站的使用情形，用於改善網站服務。</li>
      </ul>
      <p class="mt-3">您可以透過瀏覽器設定拒絕或清除 Cookie，但可能導致保持登入等部分功能無法正常使用。</p>
    </section>

    <section>
      <h2 :class="h2">六、您的權利</h2>
      <p class="mb-3">依個資法第 3 條，您可以就您的個人資料向我們行使下列權利：</p>
      <ol :class="ol">
        <li>查詢或請求閱覽</li>
        <li>請求製給複製本</li>
        <li>請求補充或更正</li>
        <li>請求停止蒐集、處理或利用</li>
        <li>請求刪除（包含刪除會員帳號）</li>
      </ol>
      <p class="mt-3">
        如欲行使上述權利，請來信
        <a :href="`mailto:${siteInfo.contactEmail}`" class="font-bold text-primary underline underline-offset-2">{{ siteInfo.contactEmail }}</a>。
        我們將在確認您的身分後，依個資法第 13 條規定處理：查詢、閱覽或製給複製本之請求，於 15 日內處理；補充、更正、停止或刪除之請求，於 30 日內處理。
        如有正當理由需延長，將以書面通知您延長原因，延長期間各以 15 日、30 日為限。
      </p>
    </section>

    <section>
      <h2 :class="h2">七、不提供個人資料的影響</h2>
      <p>
        您可以自由選擇是否提供個人資料。但若不提供註冊或訂購所必要的資料（例如電子郵件、收件人姓名、聯絡電話、收件地址），
        我們將無法為您完成會員註冊、訂單成立或商品配送。
      </p>
    </section>

    <section>
      <h2 :class="h2">八、資料安全</h2>
      <ul :class="ul">
        <li>全站使用 HTTPS 加密傳輸。</li>
        <li>資料庫採資料列層級權限控管：會員只能存取自己的購物車與訂單，後台管理功能僅限管理員使用。</li>
        <li>密碼以不可逆雜湊方式儲存；付款資訊由專業金流業者處理，不經過本網站。</li>
      </ul>
      <p class="mt-3">
        我們會採取合理的安全措施保護您的資料，但網路傳輸無法保證百分之百安全。若發生個人資料被竊取、洩漏或竄改等事故，
        我們將依個資法第 12 條，於查明後以適當方式通知您。
      </p>
    </section>

    <section>
      <h2 :class="h2">九、未成年人</h2>
      <p>若您未滿 18 歲，請在您的法定代理人閱讀並同意本政策後，再使用本網站的服務。</p>
    </section>

    <section>
      <h2 :class="h2">十、外部連結</h2>
      <p>本網站可能包含第三方網站的連結（例如綠界付款頁面）。第三方網站的隱私權保護，適用該網站自身的隱私權政策，不適用本政策。</p>
    </section>

    <section>
      <h2 :class="h2">十一、政策修訂</h2>
      <p>
        我們可能因法令變更或服務調整而修訂本政策。修訂後的內容將公布於本頁，並更新上方的「最後更新」日期；
        若有重大變更，將以網站公告或電子郵件通知您。
      </p>
    </section>

    <section>
      <h2 :class="h2">十二、聯絡我們</h2>
      <p>
        對本政策或您的個人資料有任何疑問，歡迎來信
        <a :href="`mailto:${siteInfo.contactEmail}`" class="font-bold text-primary underline underline-offset-2">{{ siteInfo.contactEmail }}</a>
        ，或參考<RouterLink to="/contact" class="font-bold text-primary underline underline-offset-2">聯絡我們</RouterLink>頁面。
      </p>
    </section>
  </StaticPageLayout>
</template>
