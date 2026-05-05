<script setup>
import { ref, computed } from 'vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Trash2, Minus, Plus } from 'lucide-vue-next'

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
])

const discount = ref(20.00)

const subtotal = computed(() =>
  cartItems.value.reduce((acc, item) => acc + (item.price * item.quantity), 0)
)

const taxes = computed(() => subtotal.value * 0.08)

const total = computed(() => subtotal.value + taxes.value - discount.value)
</script>

<template>
  <div class="bg-surface text-on-surface antialiased h-full font-body">
    <main class="pt-24 pb-8 px-4 md:px-8 max-w-[1280px] mx-auto">

      <!-- Stepper -->
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

      <div class="grid grid-cols-1 lg:grid-cols-12 gap-10 items-stretch">

        <!-- Left Column -->
        <div class="lg:col-span-8">
          <section class="bg-surface-container-lowest p-6 rounded-xl shadow-sm h-full">
            <div class="flex justify-between items-center mb-6">
              <h2 class="text-xl font-bold font-headline">Shopping Cart ({{ cartItems.length }})</h2>
              <Button variant="ghost" class="text-secondary text-sm font-semibold hover:underline px-0">Select All</Button>
            </div>

            <div class="space-y-6">
              <div v-for="item in cartItems" :key="item.id" class="flex gap-4 md:gap-6 items-start pb-6 border-b border-surface-container last:border-0 last:pb-0">
                <div class="w-24 h-24 md:w-32 md:h-32 bg-surface-container-low rounded-lg overflow-hidden shrink-0">
                  <img :alt="item.alt" :src="item.image" class="w-full h-full object-cover"/>
                </div>
                <div class="flex-1 space-y-1">
                  <div class="flex justify-between">
                    <h3 class="font-bold text-on-surface line-clamp-1">{{ item.name }}</h3>
                    <Button variant="ghost" size="icon" class="text-outline-variant hover:text-error h-8 w-8">
                      <Trash2 class="size-4" />
                    </Button>
                  </div>
                  <p class="text-on-surface-variant text-sm">{{ item.details }}</p>
                  <div class="mt-4 flex justify-between items-end">
                    <div class="flex items-center gap-1 bg-surface-container rounded-full px-3 py-1">
                      <Button variant="ghost" size="icon" @click="item.quantity > 1 && item.quantity--" :disabled="item.quantity <= 1" class="w-6 h-6 hover:text-primary disabled:opacity-30">
                        <Minus class="size-3" />
                      </Button>
                      <span class="text-sm font-bold w-4 text-center">{{ item.quantity }}</span>
                      <Button variant="ghost" size="icon" @click="item.quantity++" class="w-6 h-6 hover:text-primary">
                        <Plus class="size-3" />
                      </Button>
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
                <Input
                  type="text"
                  placeholder="Promo code"
                  class="flex-1 bg-surface-container-highest border-none rounded-lg focus-visible:ring-1 focus-visible:ring-primary"
                />
                <Button class="bg-on-surface text-surface px-6 font-bold text-sm hover:opacity-90">Apply</Button>
              </div>
            </div>

            <Button class="mt-auto w-full primary-gradient text-on-primary font-bold py-4 rounded-xl shadow-lg shadow-primary/30 hover:shadow-xl transition-all active:scale-95">
              Proceed to Checkout
            </Button>
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
        <Button class="flex-1 primary-gradient text-on-primary font-bold py-3 px-6 rounded-xl active:scale-95 transition-transform">
          Complete Order
        </Button>
      </div>
    </div>
  </div>
</template>
