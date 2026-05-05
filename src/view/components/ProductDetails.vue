<script setup>
// 引入依賴
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  ChevronLeft, ChevronRight,
  Star, Truck, Heart, Share2,
  ShoppingBag, ShieldCheck,
  Minus, Plus
} from 'lucide-vue-next'
// 引入依賴

// 商品數據
const quantity = ref(1)

const relatedItems = [
  {
    name: "Kinetic ChargePad Pro",
    price: "$45.00",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuCb2wn45CXHlez3vl4esofxIatMOp2nC7q-t5IMd0WdsNfQ7A-XOITngt_bEW5bUuMJHGRk-3lE4DhqaSSfn-f2pCM5vcT-Qjcz7ECY4ptnlIXq7-QGeBbQOK-AdTViUZ5TUBEb0QcVBo5m8WGZLFtE9734M95hnvzNzKQnNK6-8rHowJ1jBjDIimHnAHgDC_R63bZC42qcuBu8QJubvtftGykMpM-PUydfbDr7VOZbcWxicfuGVEU7UPKAkAlq_iAc6aBDwBx90vg"
  },
  {
    name: "Urban Travel Hard Case",
    price: "$29.00",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuABwB3aaBB9-zFl3_nP6eA1ElSZwiTm31OioWsEk-eCq0KaxoEZY9j0mXgzGlnfdSrX-BrENinPHKwnkxXE8fZf-W-7bTfeoyJC1joUlFVwJ7yXC3bHnRTDSIE6GR8kJZ5-jnn9a0m7wjO9V3woB4JBTDdZ4JLQox2-5mb2M2O_5BERXL-_hnp7yVu5FZ-QfoxAs_nMMCfS3ItdQYn_gLK1_xxyruZ1cVioi40AdbayUlW9toX6vv9HeBrt7bsTSqFru8WUfwn066c"
  },
  {
    name: "Apex Aluminum Headphone Stand",
    price: "$59.00",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuA6P7IEV0ps-eEOFX410yan6ymOeQRAfAPSen4HSDNrD5elelJjH2bZ6EMSUSkvQjWlF4VqP17BZkTSMQn4tnoCoqHlywvxmF9WO9njZPrClnQ0g0H5p_lhmZe-uwgzupaVeBo4VYy6rrZJrVaHPdcEEtef91Ej7zHJSKRJd3CRp451G91KaHqVCnnQGvWMC2_ogS3zZs6I6gGLPtui8VVjAuIGMwCo1iLixDxtGpA8oPJMwBU70e8FSM5XqBsZxDpLR4y9AkAnVio"
  },
  {
    name: "Sonic DAC External Amp",
    price: "$129.00",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuAyNm_8fS3sjpNKYUQHPCxsB6kTsYhaSjWop7WY4kaAvIF9EHZ0LOM5DXR5N2qc-KY-3G8U6Yo5P33dV2eZLuTGq_eYYFBbuft1-UU77bF1Kk2O16ozz4XsmByQGj7jacFIdvBrPOoh8m5Ybv8kXQGynswbwSZzy5s1k6zeteBR1Qsi824p7uwE4iepNtWce6JqMDzZMVGAsrN0IdIn5rOajydFuMuNM_Sfj2XgRBDwof45vwi_9tnPoRvTEinw4jbe7-n5vNZULMI"
  }
]
// 商品數據

</script>

<template>
  <div class="bg-surface font-body text-on-surface antialiased h-full">

    <main class="pt-24 pb-12 px-4 md:px-6 max-w-360 mx-auto">

      <!-- 麵包屑導航 -->
      <nav class="mb-6 flex items-center gap-2 text-sm text-on-surface-variant">
        <RouterLink to="/" class="hover:text-on-surface transition-colors">Home</RouterLink>
        <ChevronRight class="size-4" />
        <span>Tech & Gear</span>
        <ChevronRight class="size-4" />
        <span class="text-on-surface font-medium">Kinetic Ultra-Flow Headphones</span>
      </nav>
      <!-- 麵包屑導航 -->

      <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 mb-16">

        <!-- 商品圖片庫 -->
        <div class="lg:col-span-7 flex flex-col gap-4">
          <div class="aspect-square bg-surface-container-lowest rounded-xl overflow-hidden relative group">
            <img alt="Main Product" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuDxtDg9TrkUUHTs8f6sTfiuWh8jnG2hMuTm7p37TMYvkX8UMhkt7lX-VYI-A90muq5sdRG2eglC5KTwr1C1wtTZdquC_OKbYSzoSJyF5KdbeEkZTBq6yDTQnRftVpIrpSyWEVhAx4XjCsut3r-h_IHFsmJCEvjsq8xXTlxCQ3AXIH5gO2wa8v7SirgmRojjW5Q0vTfAGIDBaGSIMhO4Km5yEU-PtkmYWlFXnhfZw2oqUrGrP-DqPIVpWnOD7zfEM6FEMtpp_f0C0WA"/>
            <div class="absolute top-4 left-4 bg-primary text-on-primary px-3 py-1 rounded-full text-[10px] font-bold tracking-widest uppercase">New Arrival</div>
            <div class="absolute inset-y-0 left-2 flex items-center opacity-0 group-hover:opacity-100 transition-opacity">
              <Button size="icon" class="bg-surface/80 backdrop-blur h-9 w-9 rounded-full shadow-lg hover:bg-surface">
                <ChevronLeft class="size-4" />
              </Button>
            </div>
            <div class="absolute inset-y-0 right-2 flex items-center opacity-0 group-hover:opacity-100 transition-opacity">
              <Button size="icon" class="bg-surface/80 backdrop-blur h-9 w-9 rounded-full shadow-lg hover:bg-surface">
                <ChevronRight class="size-4" />
              </Button>
            </div>
          </div>

          <div class="flex gap-4 overflow-x-auto no-scrollbar">
            <div class="w-24 h-24 shrink-0 rounded-lg border-2 border-primary overflow-hidden cursor-pointer">
              <img alt="Thumb 1" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAp8vOt2U2yL_pbhOk0jiEU3Rp6bH4REWEoE3Q2YBlKdzgy-kECT8mV_UpMwwwLmsKJ_oj9HgnCv3AF2lZZS0Z7NHlA2g_E283XKjeZPjUz596wLFjASazWxbNcXHXo9H_eAKVi-SEyZpqZFtpvsswf3dWpu9wvy2_4kWgrZiNUjSiErqO3ns_pRfBeyFXa7ENC20ohWCo7sBaKmO7_iy8-4xlaDblvPcX0bpHyeBB_YEf4Qw4V6hwWf-MYxrb2ur1B4MpBd3NzBM4"/>
            </div>
            <div class="w-24 h-24 shrink-0 rounded-lg border-2 border-transparent hover:border-outline-variant overflow-hidden cursor-pointer transition-colors">
              <img alt="Thumb 2" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuD8dHmNK0TkTmqDUFRo1ncwGbZJmMBKWeOAjLepRptolsO75U0OkQwiL3WkFlPFo-mcJqMMkdAd8THPnYoqkr5ssmBpLLxeP0S9cI_S4mpJ4LidG5Trxn9LCS_5rOtWN39YyIRxXRWZjcFC_fB5wKU5qrsnJwlt20-IwbqOIlbEisRbSEbvmIlER6c9554aDrtce_kppxeFYMpSKnLSWVtgHiV4T7SUwmF_lNMIZKUj5xuU8zZ1OMfKC99b6KGD5WvCARu-PMlPjfM"/>
            </div>
            <div class="w-24 h-24 shrink-0 rounded-lg border-2 border-transparent hover:border-outline-variant overflow-hidden cursor-pointer transition-colors">
              <img alt="Thumb 3" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuDAyfdho-e6nVRlXMAg2sl4bD6SYolny0EcTIq9eOpNNVF3s8qLNcumOeijjB4fr59q3Nuyg57xLo1AOgNF4Ddhth6Obm84zjXkiI7UCIPcewWzgAS-64roCNCV4n18U-eWLR6UTHwuqZTCVZkG5aSMppq9nYGbLpWc8jnDbVXbZNaf6Dj_f2pvVbYqzCQdNlc8wGPRDEpPIfePxDOhaLFLj048cl1lWNfljGgmu-Rm21TKWzyGFA_S16ecbDWYHvVWysiF6f3d8Zk"/>
            </div>
            <div class="w-24 h-24 shrink-0 rounded-lg border-2 border-transparent hover:border-outline-variant overflow-hidden cursor-pointer transition-colors">
              <img alt="Thumb 4" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuA-QjqjH_HptFKmVseqfZcQU_Q1j87vpMWE-3coXKXn9pV2nHJEXw0gMTnOun4a-OExgGcsfIeB5UANmxHYgxg5_O9tUGqlKHNeByVpZwgV4LCmgaZROf_G7dn5E3xWNaVGST_kL-WZeQJ9QKVGHRsZIDZvSwKMFONxSosvMlUlX0KydBA7-9CZIF3JdhO12Y93bYLwQq0TIR-y5oSo4ZCWhcZsFFVxtxfc5obCL1GGn5M2TbDwENowOs4ijSrYrT8NdUn0g6rKgXo"/>
            </div>
          </div>
        </div>
        <!-- 商品圖片庫 -->

        <!-- 商品資訊 -->
        <div class="lg:col-span-5 flex flex-col gap-6">
          <div>
            <h1 class="text-3xl md:text-4xl font-headline font-extrabold text-on-surface leading-tight mb-2">
              Kinetic Ultra-Flow Noise Cancelling Wireless Headphones
            </h1>
            <div class="flex items-center gap-3 mb-4">
              <div class="flex items-center gap-0.5 text-primary">
                <Star class="size-4 fill-primary" />
                <Star class="size-4 fill-primary" />
                <Star class="size-4 fill-primary" />
                <Star class="size-4 fill-primary" />
                <Star class="size-4" />
              </div>
              <span class="text-sm text-on-surface-variant">(1,248 reviews)</span>
              <div class="w-px h-4 bg-outline-variant/30 mx-2"></div>
              <span class="text-sm text-secondary font-semibold">Top Rated in Tech</span>
            </div>
            <div class="flex items-baseline gap-4 mb-6">
              <span class="text-4xl font-headline font-bold text-primary">$299.00</span>
              <span class="text-lg text-outline line-through">$450.00</span>
              <Badge class="bg-error/10 text-error border-none font-bold">-35% OFF</Badge>
            </div>
          </div>

          <!-- 運送資訊 -->
          <div class="p-6 bg-surface-container-low rounded-xl border-l-4 border-primary">
            <p class="text-sm font-medium text-on-surface-variant flex items-center gap-2">
              <Truck class="text-primary size-5" />
              Free Express Shipping to <span class="text-on-surface font-bold">New York, NY</span>
            </p>
            <p class="text-xs text-outline mt-1 ml-7">Guaranteed arrival by Friday, June 14</p>
          </div>
          <!-- 運送資訊 -->

          <!-- 顏色選擇 -->
          <div class="space-y-4">
            <label class="text-sm font-bold uppercase tracking-wider text-outline">Select Color</label>
            <div class="flex gap-3">
              <button class="w-12 h-12 rounded-full bg-[#2d2f31] border-2 border-primary ring-2 ring-offset-2 ring-transparent transition-all cursor-pointer"></button>
              <button class="w-12 h-12 rounded-full bg-[#e1e2e5] border-2 border-transparent hover:border-outline transition-all cursor-pointer"></button>
              <button class="w-12 h-12 rounded-full bg-[#004da1] border-2 border-transparent hover:border-outline transition-all cursor-pointer"></button>
            </div>
          </div>
          <!-- 顏色選擇 -->

          <!-- 操作按鈕 -->
          <div class="flex flex-col gap-4 mt-4">
            <div class="flex gap-4">
              <div class="flex items-center bg-surface-container-highest rounded-lg px-4 py-2">
                <Button variant="ghost" size="icon" class="h-8 w-8 hover:text-primary" :disabled="quantity <= 1" @click="quantity--">
                  <Minus class="size-4" />
                </Button>
                <span class="mx-4 font-bold text-lg w-4 text-center">{{ quantity }}</span>
                <Button variant="ghost" size="icon" class="h-8 w-8 hover:text-primary" @click="quantity++">
                  <Plus class="size-4" />
                </Button>
              </div>
              <Button class="flex-1 primary-gradient text-on-primary font-bold py-6 rounded-xl shadow-lg hover:shadow-primary/30 transition-all active:scale-[0.98]">
                Add to Cart
              </Button>
            </div>
            <Button variant="outline" class="w-full bg-on-surface text-surface border-on-surface font-bold hover:bg-on-surface/90 hover:text-surface transition-all active:scale-[0.98] py-6 rounded-xl">
              Buy Now
            </Button>

            <div class="flex justify-between items-center px-2 py-4 border-t border-outline-variant/20">
              <Button variant="ghost" class="flex items-center gap-2 text-sm text-outline hover:text-primary px-0">
                <Heart class="size-4" /> Add to Wishlist
              </Button>
              <Button variant="ghost" class="flex items-center gap-2 text-sm text-outline hover:text-primary px-0">
                <Share2 class="size-4" /> Share Product
              </Button>
            </div>
          </div>
          <!-- 操作按鈕 -->
        </div>
      </div>

      <!-- 商品情報與側邊欄 -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16">
        <div class="md:col-span-2 bg-surface-container-lowest p-8 rounded-2xl">
          <h3 class="text-2xl font-headline font-bold mb-6">Product Intelligence</h3>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-8 text-sm">
            <div>
              <h4 class="font-bold text-primary mb-2">Sonic Flow Engine</h4>
              <p class="text-on-surface-variant leading-relaxed">Experience zero-latency audio processing with our proprietary chipset, delivering studio-grade sound in any environment.</p>
            </div>
            <div>
              <h4 class="font-bold text-primary mb-2">Active Isolation</h4>
              <p class="text-on-surface-variant leading-relaxed">Dual-mic arrays cancel up to 98% of ambient noise, from jet engines to city bustle.</p>
            </div>
            <div>
              <h4 class="font-bold text-primary mb-2">Battery Performance</h4>
              <p class="text-on-surface-variant leading-relaxed">60 hours of continuous playback with quick-charge capabilities (5 mins = 4 hours of juice).</p>
            </div>
            <div>
              <h4 class="font-bold text-primary mb-2">Sustainable Design</h4>
              <p class="text-on-surface-variant leading-relaxed">Constructed using 40% recycled aluminum and 100% biodegradable packaging.</p>
            </div>
          </div>
          <div class="mt-10 border-t border-surface-container pt-8">
            <p class="text-on-surface-variant leading-relaxed mb-4">
              The Kinetic Ultra-Flow represents the pinnacle of personal audio. Designed for creators, travelers, and audiophiles who refuse to compromise. Each component has been curated to provide a weightless fit and immersive experience.
            </p>
            <img alt="Lifestyle Detail" class="w-full h-64 object-cover rounded-xl" src="https://lh3.googleusercontent.com/aida-public/AB6AXuBvFv8qi1iSbX4MiagDRjrRFDiycuBu38G2DKkj5kGl5G5j59-kejjNuApgr9m-ravTxzXHB3Y94976AWy_nJzkFXHF9cofzDL3eMxpmL4SceYn44r8tB8fBi0KMVsmUA_nq9waSi_StqbogXBxRaoB4IccH3Au06ER_CfcnKqWI2LvFZtgTYCeIJ9zlGU65N7JyohYF4XHDbKoeSDSix2j_GkrB3JuCSepjnkKFMRYGIYdBXQHOsXkV9F-6Wpn9qtOS8ECP42oUHM"/>
          </div>
        </div>

        <div class="flex flex-col gap-6">
          <div class="bg-secondary-container p-6 rounded-2xl">
            <ShieldCheck class="text-on-secondary-container size-10 mb-4" />
            <h4 class="text-on-secondary-container font-bold text-lg mb-2">Kinetic Shield Warranty</h4>
            <p class="text-on-secondary-container/80 text-sm">Included 2-year premium coverage with accidental damage protection and 24/7 tech support.</p>
          </div>
          <div class="bg-surface-container-low p-6 rounded-2xl flex-1">
            <h4 class="font-headline font-bold mb-4">Detailed Specs</h4>
            <ul class="space-y-3 text-sm">
              <li class="flex justify-between border-b border-outline-variant/10 pb-2">
                <span class="text-outline">Driver Size</span>
                <span class="font-semibold">40mm Dynamic</span>
              </li>
              <li class="flex justify-between border-b border-outline-variant/10 pb-2">
                <span class="text-outline">Frequency</span>
                <span class="font-semibold">10Hz - 40kHz</span>
              </li>
              <li class="flex justify-between border-b border-outline-variant/10 pb-2">
                <span class="text-outline">Bluetooth</span>
                <span class="font-semibold">Version 5.3</span>
              </li>
              <li class="flex justify-between border-b border-outline-variant/10 pb-2">
                <span class="text-outline">Weight</span>
                <span class="font-semibold">245 grams</span>
              </li>
              <li class="flex justify-between">
                <span class="text-outline">Charging Port</span>
                <span class="font-semibold">USB-C</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
      <!-- 商品情報與側邊欄 -->

      <!-- 用戶評論 -->
      <section class="mb-16">
        <div class="flex justify-between items-end mb-8">
          <div>
            <h3 class="text-2xl font-headline font-bold">The Voice of the Community</h3>
            <p class="text-on-surface-variant">Real insights from 1,248 verified owners</p>
          </div>
          <Button variant="outline" class="bg-surface-container-highest px-6 py-2 rounded-full font-bold text-sm hover:bg-surface-container-high">
            Write Review
          </Button>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="bg-surface-container-lowest p-6 rounded-2xl shadow-sm border border-outline-variant/5">
            <div class="flex items-center gap-3 mb-4">
              <div class="w-10 h-10 rounded-full bg-tertiary-container flex items-center justify-center font-bold text-on-tertiary-container">AR</div>
              <div>
                <p class="font-bold text-sm">Alex Rivera</p>
                <p class="text-xs text-outline">Verified Buyer • 2 days ago</p>
              </div>
            </div>
            <div class="flex gap-0.5 text-primary mb-3">
              <Star class="size-3 fill-primary" />
              <Star class="size-3 fill-primary" />
              <Star class="size-3 fill-primary" />
              <Star class="size-3 fill-primary" />
              <Star class="size-3 fill-primary" />
            </div>
            <p class="text-sm text-on-surface-variant leading-relaxed">The noise cancellation is honestly better than the industry giants. I use these for my daily commute and it's like flicking a silence switch on the world.</p>
          </div>

          <div class="bg-surface-container-lowest p-6 rounded-2xl shadow-sm border border-outline-variant/5">
            <div class="flex items-center gap-3 mb-4">
              <div class="w-10 h-10 rounded-full bg-secondary-container flex items-center justify-center font-bold text-on-secondary-container">MK</div>
              <div>
                <p class="font-bold text-sm">Min-ho Kim</p>
                <p class="text-xs text-outline">Verified Buyer • 1 week ago</p>
              </div>
            </div>
            <div class="flex gap-0.5 text-primary mb-3">
              <Star class="size-3 fill-primary" />
              <Star class="size-3 fill-primary" />
              <Star class="size-3 fill-primary" />
              <Star class="size-3 fill-primary" />
              <Star class="size-3" />
            </div>
            <p class="text-sm text-on-surface-variant leading-relaxed">Battery life is insane. I've been using them for a week and still have 40% left. Design is premium and feels very solid but lightweight on the head.</p>
          </div>

          <div class="bg-surface-container-lowest p-6 rounded-2xl shadow-sm border border-outline-variant/5">
            <div class="flex items-center gap-3 mb-4">
              <div class="w-10 h-10 rounded-full bg-error-container/20 flex items-center justify-center font-bold text-error">SC</div>
              <div>
                <p class="font-bold text-sm">Sarah C.</p>
                <p class="text-xs text-outline">Verified Buyer • 2 weeks ago</p>
              </div>
            </div>
            <div class="flex gap-0.5 text-primary mb-3">
              <Star class="size-3 fill-primary" />
              <Star class="size-3 fill-primary" />
              <Star class="size-3 fill-primary" />
              <Star class="size-3 fill-primary" />
              <Star class="size-3 fill-primary" />
            </div>
            <p class="text-sm text-on-surface-variant leading-relaxed">The aesthetic alone is worth it. That copper/black combo is stunning. Packaging was eco-friendly which I really appreciate. Fast delivery!</p>
          </div>
        </div>
      </section>
      <!-- 用戶評論 -->

      <!-- 相關商品 -->
      <section>
        <h3 class="text-2xl font-headline font-bold mb-8">Pairs Perfectly With</h3>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-6">
          <div v-for="(item, i) in relatedItems" :key="i" class="group cursor-pointer">
            <div class="aspect-4/5 rounded-xl overflow-hidden bg-surface-container-low mb-3 relative">
              <img :alt="item.name" :src="item.image" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"/>
              <div class="absolute bottom-3 right-3 opacity-0 group-hover:opacity-100 transition-opacity">
                <Button size="icon" class="bg-surface text-primary hover:bg-primary hover:text-on-primary h-8 w-8 rounded-full shadow-lg">
                  <ShoppingBag class="size-4" />
                </Button>
              </div>
            </div>
            <h4 class="font-bold text-sm text-on-surface line-clamp-1">{{ item.name }}</h4>
            <p class="text-primary font-bold text-sm">{{ item.price }}</p>
          </div>
        </div>
      </section>
      <!-- 相關商品 -->
    </main>

    <!-- 行動版底部固定欄 -->
    <div class="md:hidden fixed bottom-0 w-full bg-surface-container-lowest/90 backdrop-blur-lg border-t border-outline-variant/10 px-6 py-4 flex justify-between items-center z-50">
      <div class="flex items-baseline gap-2">
        <span class="text-xl font-bold text-primary">$299.00</span>
      </div>
      <Button class="primary-gradient text-on-primary px-8 py-3 rounded-xl font-bold active:scale-95 transition-all">
        Add to Cart
      </Button>
    </div>
    <!-- 行動版底部固定欄 -->
  </div>
</template>

