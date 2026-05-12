<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { fetchProductByIdentifier, formatPrice, type CatalogProduct } from '@/composables/useCatalog'
import { useCart } from '@/composables/useCart'
import { ChevronRight, Minus, Plus, ShoppingBag } from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const quantity = ref(1)
const selectedImage = ref('')
const product = ref<CatalogProduct | null>(null)
const isLoading = ref(false)
const isAddingToCart = ref(false)
const errorMessage = ref('')
const { addToCart, cartError } = useCart()

const discountPercent = computed(() => {
  if (!product.value?.originalPrice) {
    return 0
  }

  return Math.round((1 - product.value.price / product.value.originalPrice) * 100)
})

const galleryImages = computed(() =>
  product.value?.images.length ? product.value.images : [],
)

async function loadProduct() {
  const identifier = String(route.params.id ?? '')

  if (!identifier) {
    errorMessage.value = '找不到商品。'
    return
  }

  isLoading.value = true
  errorMessage.value = ''

  try {
    product.value = await fetchProductByIdentifier(identifier)
    selectedImage.value = product.value?.image ?? ''

    if (!product.value) {
      errorMessage.value = '這項商品目前不存在或尚未上架。'
    }
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '商品資料載入失敗。'
  } finally {
    isLoading.value = false
  }
}

async function handleAddToCart() {
  if (!product.value) {
    return
  }

  isAddingToCart.value = true

  try {
    await addToCart(product.value, quantity.value)
    await router.push('/products')
  } catch (error) {
    const message = cartError.value || (error instanceof Error ? error.message : '加入購物車失敗。')
    window.alert(message)
  } finally {
    isAddingToCart.value = false
  }
}

onMounted(() => {
  void loadProduct()
})

watch(
  () => route.params.id,
  () => {
    quantity.value = 1
    void loadProduct()
  },
)
</script>

<template>
  <div class="bg-surface font-body text-on-surface antialiased h-full">
    <main class="mx-auto max-w-[94vw] px-5 pt-24 pb-12">
      <nav class="mb-6 flex items-center gap-2 text-sm text-on-surface-variant">
        <RouterLink to="/" class="hover:text-on-surface transition-colors">首頁</RouterLink>
        <ChevronRight class="size-4" />
        <RouterLink v-if="product" :to="`/products?category=${product.categorySlug}`" class="hover:text-on-surface transition-colors">
          {{ product.categoryName }}
        </RouterLink>
        <span v-else>商品</span>
        <ChevronRight class="size-4" />
        <span class="text-on-surface font-medium">{{ product?.name || '商品詳情' }}</span>
      </nav>

      <div v-if="isLoading" class="grid grid-cols-1 gap-8 lg:grid-cols-2">
        <div class="aspect-[4/3] animate-pulse rounded-xl bg-surface-container-lowest" />
        <div class="h-[520px] animate-pulse rounded-xl bg-surface-container-lowest" />
      </div>

      <div v-else-if="errorMessage" class="rounded-xl bg-surface-container-lowest p-10 text-center text-on-surface-variant">
        <p class="font-bold text-on-surface">{{ errorMessage }}</p>
        <Button as-child class="primary-gradient mt-6 rounded-xl font-bold text-on-primary">
          <RouterLink to="/products">回商品列表</RouterLink>
        </Button>
      </div>

      <template v-else-if="product">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-12 items-stretch">
          <div class="flex flex-col gap-4">
            <div class="h-full min-h-[420px] max-h-[640px] bg-surface-container-lowest rounded-xl overflow-hidden relative group lg:aspect-[4/3]">
              <img :alt="product.name" class="w-full h-full object-cover" :src="selectedImage || product.image"/>
              <div v-if="product.tag" class="absolute top-4 left-4 bg-primary text-on-primary px-3 py-1 rounded-full text-[10px] font-bold tracking-widest">
                {{ product.tag }}
              </div>
            </div>

            <div v-if="galleryImages.length > 1" class="flex gap-4 overflow-x-auto no-scrollbar">
              <button
                v-for="image in galleryImages"
                :key="image.id"
                type="button"
                class="h-24 w-24 shrink-0 overflow-hidden rounded-lg border-2 transition-colors"
                :class="selectedImage === image.imageUrl ? 'border-primary' : 'border-transparent hover:border-outline-variant'"
                @click="selectedImage = image.imageUrl"
              >
                <img :alt="image.alt" class="h-full w-full object-cover" :src="image.imageUrl">
              </button>
            </div>
          </div>

          <div class="bg-surface-container-lowest rounded-xl p-6 md:p-8 shadow-sm flex min-h-[420px] flex-col justify-between gap-8">
            <div class="space-y-5">
              <p class="mb-3 text-sm font-bold text-primary">{{ product.categoryName }}</p>
              <h1 class="max-w-xl text-3xl md:text-4xl font-headline font-extrabold text-on-surface leading-tight">
                {{ product.name }}
              </h1>
              <div class="flex flex-wrap items-baseline gap-4">
                <span class="text-4xl md:text-5xl font-headline font-bold text-primary">{{ formatPrice(product.price) }}</span>
                <span v-if="product.originalPrice" class="text-lg text-outline line-through">{{ formatPrice(product.originalPrice) }}</span>
                <Badge v-if="discountPercent" class="bg-error/10 text-error border-none font-bold">
                  省 {{ discountPercent }}%
                </Badge>
              </div>
            </div>

            <div class="flex flex-col gap-4">
              <div class="flex flex-col gap-4 sm:flex-row">
                <div class="flex h-16 items-center justify-center bg-surface-container-highest rounded-lg px-4 py-2 sm:w-52">
                  <Button variant="ghost" size="icon" class="h-8 w-8 hover:text-primary" :disabled="quantity <= 1" @click="quantity--">
                    <Minus class="size-4" />
                  </Button>
                  <span class="mx-4 font-bold text-lg w-4 text-center">{{ quantity }}</span>
                  <Button variant="ghost" size="icon" class="h-8 w-8 hover:text-primary" @click="quantity++">
                    <Plus class="size-4" />
                  </Button>
                </div>
                <Button class="h-16 flex-1 primary-gradient text-on-primary font-bold rounded-xl shadow-lg hover:shadow-primary/30 transition-all active:scale-[0.98]" :disabled="isAddingToCart" @click="handleAddToCart">
                  <ShoppingBag class="mr-2 size-5" />
                  {{ isAddingToCart ? '加入中' : '加入購物車' }}
                </Button>
              </div>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16">
          <div class="md:col-span-2 bg-surface-container-lowest p-8 rounded-xl">
            <h3 class="text-2xl font-headline font-bold mb-4">商品說明</h3>
            <p class="text-on-surface-variant leading-relaxed">
              {{ product.description }}
            </p>
          </div>

          <div class="bg-surface-container-low p-6 rounded-xl">
            <h4 class="font-headline font-bold mb-4">商品規格</h4>
            <ul v-if="product.specList.length" class="space-y-3 text-sm">
              <li v-for="spec in product.specList" :key="spec.id" class="flex justify-between gap-4 border-b border-outline-variant/10 pb-2 last:border-b-0">
                <span class="text-outline">{{ spec.label }}</span>
                <span class="font-semibold text-right">{{ spec.value }}</span>
              </li>
            </ul>
            <p v-else class="text-sm text-on-surface-variant">此商品尚未填寫規格。</p>
          </div>
        </div>
      </template>
    </main>

    <div v-if="product" class="md:hidden fixed bottom-0 w-full bg-surface-container-lowest/90 backdrop-blur-lg border-t border-outline-variant/10 px-6 py-4 flex justify-between items-center z-50">
      <div class="flex items-baseline gap-2">
        <span class="text-xl font-bold text-primary">{{ formatPrice(product.price) }}</span>
      </div>
      <Button class="primary-gradient text-on-primary px-8 py-3 rounded-xl font-bold active:scale-95 transition-all" :disabled="isAddingToCart" @click="handleAddToCart">
        {{ isAddingToCart ? '加入中' : '加入購物車' }}
      </Button>
    </div>
  </div>
</template>
