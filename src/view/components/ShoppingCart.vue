<script setup>
import { ref, computed } from 'vue';

const cartItems = ref([
  {
    id: 1,
    name: 'Kinetic Velocity X1 - Radiant Red',
    details: 'Size: 42 | Color: Crimson',
    price: 189.00,
    quantity: 1,
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBl5U-3kzop_eibLI0bLd3ADecKQKNbMbR3uHmSr1hvz4X0FtK0RHa3g7OLNB0DrCIgerDIiiGBc7gpi1OIY5fG2tw3RyRRFEUcdYzdw4mmSUEVL_aLZnhXRx3WLBO7SEOmzNBOpMYaBW5TtXtjPa1YQhRpqP_PRyAGV1Sek-GZZvCz1ZRoVWnPW2BQhVdq8Aupx7ARWu2XnDTHsDckEDqOf9xIi4-8tGJqRrGiInT3ru9_eunijFtT6RdPzGqzifAnQrQUft6FL_E',
    alt: 'Modern red sleek running shoe floating in a minimalist studio setting'
  },
  {
    id: 2,
    name: 'Aura Smart Watch Series 5',
    details: 'Edition: Ceramic White',
    price: 349.00,
    quantity: 1,
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAXEzpmD2cEyVmVs2BNmF3bW5MyGJXwXGHeODfxdRa9h_L30sQBnFMcZraqMIOqPdbux_b1QS0mpWksMBzwkO8YuZZYHRy9hrQNDpceHUb3MPGo0HFpqXjFY_AM2Dx8EgWqrFWkWTT-CuLkDSV7eU1nMBubXWmsDbfkaVsgTe35T26j_m1zb-SJHY7ytj70qB0fIYGH_3PAygd-hcpQ79j33f-Sm2ZlAfrQa7hE5L1W2RN8dmoNXZxHvpfaMDpOelpcOJvC5w8AybM',
    alt: 'Minimalist white smart watch with high-resolution screen'
  }
]);

const discount = ref(20.00);

const subtotal = computed(() => {
  return cartItems.value.reduce((acc, item) => acc + (item.price * item.quantity), 0);
});

const taxes = computed(() => subtotal.value * 0.08); // Simple 8% calculation

const total = computed(() => {
  return subtotal.value + taxes.value - discount.value; 
});
</script>

<template>
  <div class="bg-surface text-on-surface antialiased h-full font-body">
    <!-- 移除了原本過大的 pb-20，改為 pb-8 減少底部留白 -->
    <main class="pt-24 pb-8 px-4 md:px-8 max-w-[1280px] mx-auto">
      
      <!-- Stepper -->
      <div class="mb-12">
        <div class="flex items-center justify-center max-w-2xl mx-auto">
          <div class="flex flex-col items-center gap-2 group">
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

      <!-- 加入 items-stretch 確保網格高度一致 -->
      <div class="grid grid-cols-1 lg:grid-cols-12 gap-10 items-stretch">
        
        <!-- Left Column -->
        <div class="lg:col-span-8">
          <!-- 加上 h-full 讓卡片高度向下延展 -->
          <section class="bg-surface-container-lowest p-6 rounded-xl shadow-sm h-full">
            <div class="flex justify-between items-center mb-6">
              <h2 class="text-xl font-bold font-headline">Shopping Cart ({{ cartItems.length }})</h2>
              <button class="text-secondary text-sm font-semibold hover:underline">Select All</button>
            </div>
            
            <div class="space-y-6">
              <div v-for="item in cartItems" :key="item.id" class="flex gap-4 md:gap-6 items-start pb-6 border-b border-surface-container last:border-0 last:pb-0">
                <div class="w-24 h-24 md:w-32 md:h-32 bg-surface-container-low rounded-lg overflow-hidden flex-shrink-0">
                  <img :alt="item.alt" :src="item.image" class="w-full h-full object-cover"/>
                </div>
                <div class="flex-1 space-y-1">
                  <div class="flex justify-between">
                    <h3 class="font-bold text-on-surface line-clamp-1">{{ item.name }}</h3>
                    <button class="text-outline-variant hover:text-error transition-colors">
                      <span class="material-symbols-outlined">delete</span>
                    </button>
                  </div>
                  <p class="text-on-surface-variant text-sm">{{ item.details }}</p>
                  <div class="mt-4 flex justify-between items-end">
                    <div class="flex items-center gap-3 bg-surface-container rounded-full px-3 py-1">
                      <button @click="item.quantity--" :disabled="item.quantity <= 1" class="w-6 h-6 flex items-center justify-center text-on-surface hover:text-primary transition-colors disabled:opacity-30">
                        <span class="material-symbols-outlined text-sm">remove</span>
                      </button>
                      <span class="text-sm font-bold w-4 text-center">{{ item.quantity }}</span>
                      <button @click="item.quantity++" class="w-6 h-6 flex items-center justify-center text-on-surface hover:text-primary transition-colors">
                        <span class="material-symbols-outlined text-sm">add</span>
                      </button>
                    </div>
                    <span class="font-bold text-lg text-primary">${{ (item.price * item.quantity).toFixed(2) }}</span>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>

        <!-- Right Column (Order Summary) -->
        <div class="lg:col-span-4">
          <!-- 移除 sticky div，並加上 h-full 與 flex flex-col 實現內部推擠 -->
          <section class="bg-surface-container-lowest p-8 rounded-xl shadow-sm h-full flex flex-col">
            <h2 class="text-xl font-bold font-headline mb-6">Order Summary</h2>
            
            <div class="space-y-4 mb-6">
              <div class="flex justify-between text-on-surface-variant">
                <span>Subtotal ({{ cartItems.length }} items)</span>
                <span class="font-medium text-on-surface">${{ subtotal.toFixed(2) }}</span>
              </div>
              <div class="flex justify-between text-on-surface-variant">
                <span>Taxes (Estimated)</span>
                <span class="font-medium text-on-surface">${{ taxes.toFixed(2) }}</span>
              </div>
              <div class="flex justify-between text-primary font-bold">
                <span>Discount (WELCOME20)</span>
                <span>-${{ discount.toFixed(2) }}</span>
              </div>
            </div>
            
            <div class="pt-6 border-t border-surface-container mb-8">
              <div class="flex justify-between items-end">
                <span class="text-on-surface-variant font-medium">Total Amount</span>
                <div class="text-right">
                  <span class="block text-3xl font-black font-headline text-on-surface">${{ total.toFixed(2) }}</span>
                  <span class="text-xs text-outline-variant">Includes all duties and taxes</span>
                </div>
              </div>
            </div>

            <div class="mb-8">
              <div class="flex gap-2">
                <input type="text" placeholder="Promo code" class="flex-1 bg-surface-container-highest border-none rounded-lg px-4 py-3 text-sm focus:ring-2 focus:ring-primary transition-all"/>
                <button class="bg-on-surface text-surface px-6 py-3 rounded-lg font-bold text-sm hover:opacity-90 transition-opacity">Apply</button>
              </div>
            </div>

            <!-- 加入 mt-auto，這個按鈕會自動被推到底部，與左邊的購物車列表對齊 -->
            <button class="mt-auto w-full bg-gradient-to-br from-primary to-primary-container text-on-primary font-bold py-4 rounded-xl shadow-lg shadow-primary/30 hover:shadow-xl transition-all transform active:scale-95">
              Proceed to Checkout
            </button>
            
          </section>
        </div>
      </div>
    </main>

    <!-- Mobile Fixed Footer -->
    <div class="lg:hidden fixed bottom-0 left-0 w-full p-4 bg-surface-container-lowest border-t border-surface-container shadow-2xl z-40">
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-xs text-on-surface-variant font-medium">Total Amount</p>
          <p class="text-xl font-black text-on-surface">${{ total.toFixed(2) }}</p>
        </div>
        <button class="flex-1 bg-primary text-on-primary font-bold py-3 px-6 rounded-xl active:scale-95 transition-transform">
          Complete Order
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
:root {
  --primary: #b22203;
  --primary-container: #ff775b;
  --on-primary: #ffefec;
  --surface: #f6f6f8;
  --on-surface: #2d2f31;
  --on-surface-variant: #5a5c5d;
  --surface-container: #e7e8ea;
  --surface-container-low: #f0f1f3;
  --surface-container-lowest: #ffffff;
  --surface-container-high: #e1e2e5;
  --surface-container-highest: #dbdde0;
  --outline: #757779;
  --outline-variant: #acadaf;
  --secondary: #0059b8;
  --secondary-container: #bdd2ff;
  --on-secondary-container: #004592;
  --error: #b41340;
}
.font-headline { font-family: 'Plus Jakarta Sans', sans-serif; }
.font-body { font-family: 'Inter', sans-serif; }
.material-symbols-outlined {
  font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
}

@theme {
  --color-primary: var(--primary);
  --color-primary-container: var(--primary-container);
  --color-on-primary: var(--on-primary);
  --color-surface: var(--surface);
  --color-on-surface: var(--on-surface);
  --color-on-surface-variant: var(--on-surface-variant);
  --color-surface-container: var(--surface-container);
  --color-surface-container-low: var(--surface-container-low);
  --color-surface-container-lowest: var(--surface-container-lowest);
  --color-surface-container-high: var(--surface-container-high);
  --color-surface-container-highest: var(--surface-container-highest);
  --color-outline: var(--outline);
  --color-outline-variant: var(--outline-variant);
  --color-secondary: var(--secondary);
  --color-secondary-container: var(--secondary-container);
  --color-on-secondary-container: var(--on-secondary-container);
  --color-error: var(--error);
  --font-headline: 'Plus Jakarta Sans', sans-serif;
  --font-body: 'Inter', sans-serif;
}
</style>