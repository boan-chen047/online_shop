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

const addresses = [
  { id: 1, label: 'Home (Primary)', street: '123 Kinetic Boulevard, Suite 500<br/>New York, NY 10001, US', phone: '+1 (555) 012-3456' },
  { id: 2, label: 'Office', street: '456 Innovation Drive<br/>Palo Alto, CA 94304, US' }
];

const shippingMethods = [
  { id: 'express', name: 'Express Delivery', eta: 'Arrives tomorrow, Dec 14', price: 15.00 },
  { id: 'standard', name: 'Standard Shipping', eta: 'Arrives Dec 16 - Dec 18', price: 0 }
];

const paymentMethods = [
  { id: 'card', name: 'Card', icon: 'credit_card' },
  { id: 'wallet', name: 'E-Wallet', icon: 'account_balance_wallet' },
  { id: 'kinetic', name: 'Kinetic Pay', icon: 'token', isDefault: true },
  { id: 'crypto', name: 'Crypto', icon: 'currency_bitcoin' }
];

const upsellProducts = [
  { id: 101, name: 'Stealth Shield Shades', price: 85.00, image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB8QClLsqKxWQx9oicWY3RhAAFGXlm6X5m2R9jVRzTEh48YHrL2NniPk9QOzp2SosysxIG8XTgSnCy8XizC-BYTLTLv4p5OEd78SP69ngeoPReU5pEdpSbiBtZN7vZnW2lG6BLZDi_w3_-RTCqsE-Q3GVD94Jc0DMlp6maxIVWNEkKceMnpr_cQuX8qweFfYzdAxGlCV20ETfuUCuTeD7mNkQ6dM4unPlJCk0kHQum0dzvPNYaVmlEPUIb-rLcakuVXYQZP-Gkj5wk', alt: 'Black sunglasses' },
  { id: 102, name: 'Performance Grip Socks', price: 24.00, image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAJAVPt6zpOQXLBERORTwNpmCrxto2k6ps_eTibUL5BAy2I5VRfKCt5Z73kUiAU-L6XtI0SHsCbLQau2HEbHB_IWHf9HhF6QSKHxm-h6avRtT8uJp3JBvZqQB8KfMZOT6xO0RVJuxSw5q7M4fI9Lq5f1yCt6q9bAsyWS_S_Vaj8vR1MJiHajed8kcysTYVZliBjAhkxwMpf_ZRv9MtJ6buz4ZYYlwZze9LHRoKkOywPgOpUm6pq7D1XxOiPOfWNID9eFu3jmUfS-6E', alt: 'Lime green socks' },
  { id: 103, name: 'Onyx Thermal Bottle', price: 45.00, image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBkccYpty4-9hzW5TY1tfWh61XGJ8kKt0_XVrZOU609HdBh60UvsuVwK3UvEESl2oqo3qMG4LhHlPdjOdst-5GA96EqQDGj2ykOvG-FrUjuhhOFglaJ7z8Yagn-z8MomTqY2FiFWJEyu0LjHfN-XSPcQYbiJ2fgVv1oBi280OZIpGGMLctiJV1YBd9sEgEBRvbAOB9FiYyb02_Y8nO1AT7gdvFQod_MxyGuRCsYasis8FgoMhrfzm5MvfP_fxsLrHBHPwbahA0b9Q0', alt: 'Black thermal bottle' },
  { id: 104, name: 'Core Fleece Hoodie', price: 120.00, image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAgK7U0gKfTRwCtxJ6YpO1L2oCzv_421SlxUVqvObg0gTCeyWtyve69TtoGgT3xjAEkhMVrcUxVpCjBybecPRydJ_DLNfb5fXo1wjQiVigHaju6ACPdrlZGa-7Aar5UdSHni9GlLWrbm_C2ZO4SAn-yWUnrwB1GyyQPObEiBLC8tspn6muIUCcziRkPWRI6mbRBmtqRIfPomzBuVWy4isKbT8KKNAGEidFiHeL7M3Dh3tKDzER39l2QGZHAKeWOxmev2H0Aw2Ly_hQ', alt: 'Cream hoodie' }
];

const footerLinks = ['Privacy Policy', 'Terms of Service', 'Shipping Info', 'Contact Us'];

const selectedAddress = ref(1);
const selectedShipping = ref('express');
const selectedPayment = ref('kinetic');
const discount = ref(20.00);

const subtotal = computed(() => {
  return cartItems.value.reduce((acc, item) => acc + (item.price * item.quantity), 0);
});

const shippingFee = computed(() => {
  const method = shippingMethods.find(m => m.id === selectedShipping.value);
  return method ? method.price : 0;
});

const taxes = computed(() => subtotal.value * 0.08); // Simple 8% calculation

const total = computed(() => {
  return subtotal.value + shippingFee.value + taxes.value - discount.value;
});
</script>

<template>
  <div class="bg-surface text-on-surface antialiased h-full font-body">
    <main class="pt-24 pb-20 px-4 md:px-8 max-w-[1280px] mx-auto">
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

      <div class="grid grid-cols-1 lg:grid-cols-12 gap-10">
        <div class="lg:col-span-8 space-y-8">
          
          <section class="bg-surface-container-lowest p-6 rounded-xl shadow-sm">
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

          <section class="bg-surface-container-lowest p-6 rounded-xl shadow-sm">
            <div class="flex items-center gap-2 mb-6">
              <span class="material-symbols-outlined text-primary">local_shipping</span>
              <h2 class="text-xl font-bold font-headline">Shipping Information</h2>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
              <div v-for="address in addresses" :key="address.id" @click="selectedAddress = address.id"
                :class="[
                  'border-2 p-4 rounded-xl cursor-pointer relative transition-all',
                  selectedAddress === address.id ? 'border-primary bg-primary/5' : 'border-surface-container hover:border-outline-variant'
                ]">
                <div v-if="selectedAddress === address.id" class="absolute top-3 right-3 text-primary">
                  <span class="material-symbols-outlined !fill-1">check_circle</span>
                </div>
                <p class="font-bold text-on-surface">{{ address.label }}</p>
                <p class="text-sm text-on-surface-variant leading-relaxed mt-2" v-html="address.street"></p>
                <p v-if="address.phone" class="text-xs font-semibold text-primary mt-2">{{ address.phone }}</p>
              </div>
            </div>
            
            <div class="space-y-4">
              <h3 class="text-sm font-bold uppercase tracking-wider text-outline">Delivery Method</h3>
              <div class="space-y-3">
                <label v-for="method in shippingMethods" :key="method.id" class="flex items-center justify-between p-4 bg-surface rounded-lg cursor-pointer border-2 border-transparent hover:border-primary-container transition-all">
                  <div class="flex items-center gap-4">
                    <input type="radio" v-model="selectedShipping" :value="method.id" name="delivery" class="text-primary focus:ring-primary w-5 h-5"/>
                    <div>
                      <p class="font-bold text-sm">{{ method.name }}</p>
                      <p class="text-xs text-on-surface-variant">{{ method.eta }}</p>
                    </div>
                  </div>
                  <span :class="['font-bold', method.price === 0 ? 'text-green-700' : 'text-primary']">
                    {{ method.price === 0 ? 'FREE' : '$' + method.price.toFixed(2) }}
                  </span>
                </label>
              </div>
            </div>
          </section>

          <section class="bg-surface-container-lowest p-6 rounded-xl shadow-sm">
            <div class="flex items-center gap-2 mb-6">
              <span class="material-symbols-outlined text-primary">payments</span>
              <h2 class="text-xl font-bold font-headline">Payment Method</h2>
            </div>
            <div class="flex flex-wrap gap-4">
              <button v-for="payment in paymentMethods" :key="payment.id" @click="selectedPayment = payment.id"
                :class="[
                  'flex items-center gap-3 px-6 py-4 bg-surface-container border-2 rounded-xl transition-all relative',
                  selectedPayment === payment.id ? 'border-primary' : 'border-transparent hover:border-primary/50'
                ]">
                <div v-if="payment.isDefault" class="absolute -top-2 -right-2 bg-primary text-on-primary text-[10px] font-bold px-2 py-0.5 rounded-full">DEFAULT</div>
                <span class="material-symbols-outlined text-2xl">{{ payment.icon }}</span>
                <span class="font-bold text-sm">{{ payment.name }}</span>
              </button>
            </div>
          </section>
        </div>

        <div class="lg:col-span-4">
          <div class="sticky top-24 space-y-6">
            <section class="bg-surface-container-lowest p-8 rounded-xl shadow-sm">
              <h2 class="text-xl font-bold font-headline mb-6">Order Summary</h2>
              
              <div class="space-y-4 mb-6">
                <div class="flex justify-between text-on-surface-variant">
                  <span>Subtotal ({{ cartItems.length }} items)</span>
                  <span class="font-medium text-on-surface">${{ subtotal.toFixed(2) }}</span>
                </div>
                <div class="flex justify-between text-on-surface-variant">
                  <span>Shipping Fee</span>
                  <span class="font-medium text-on-surface">${{ shippingFee.toFixed(2) }}</span>
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

              <button class="w-full bg-gradient-to-br from-primary to-primary-container text-on-primary font-bold py-4 rounded-xl shadow-lg shadow-primary/30 hover:shadow-xl transition-all transform active:scale-95">
                Proceed to Payment
              </button>
              
              <div class="mt-6 flex flex-col items-center gap-3">
                <div class="flex items-center gap-2 text-xs text-on-surface-variant">
                  <span class="material-symbols-outlined text-sm">verified_user</span>
                  <span>Secure Checkout protected by Kinetic Shield</span>
                </div>
                <div class="flex gap-3 opacity-30 grayscale">
                  <span class="material-symbols-outlined">credit_card</span>
                  <span class="material-symbols-outlined">payments</span>
                  <span class="material-symbols-outlined">account_balance</span>
                </div>
              </div>
            </section>

            <div class="bg-secondary-container/30 p-4 rounded-xl flex items-start gap-4">
              <span class="material-symbols-outlined text-secondary !fill-1">inventory_2</span>
              <div>
                <p class="text-sm font-bold text-on-secondary-container">Hassle-Free Returns</p>
                <p class="text-xs text-on-secondary-container/80 mt-1">Not happy with your items? Return them for free within 30 days of receipt.</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <section class="mt-20">
        <h2 class="text-2xl font-bold font-headline mb-8 text-center">Frequently Bought Together</h2>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-6">
          <div v-for="product in upsellProducts" :key="product.id" class="bg-surface-container-lowest p-4 rounded-xl hover:shadow-lg transition-shadow group">
            <div class="aspect-square bg-surface-container-low rounded-lg overflow-hidden mb-4">
              <img :alt="product.alt" :src="product.image" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"/>
            </div>
            <h4 class="font-bold text-sm line-clamp-1">{{ product.name }}</h4>
            <p class="text-primary font-bold mt-1">${{ product.price.toFixed(2) }}</p>
            <button class="w-full mt-4 py-2 border-2 border-surface-container hover:border-primary text-xs font-bold rounded-lg transition-colors">Add to Bundle</button>
          </div>
        </div>
      </section>
    </main>
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
/* CSS Variables for design tokens as per Tailwind v4 best practices or system mapping */
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

/* Custom Utilities for V4 compatibility if needed */
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