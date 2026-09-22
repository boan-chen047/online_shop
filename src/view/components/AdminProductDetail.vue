<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'
import { type ProductImage, loadImages, uploadImages, setPrimary, deleteImage } from '@/composables/useProductImages'

interface Category { id: string; name: string }

const route = useRoute()
const router = useRouter()
const { isAuthReady, isAdmin } = useAuth()

const productId = String(route.params.id ?? '')
const categories = ref<Category[]>([])
const isLoading = ref(false)
const loadError = ref('')
const notFound = ref(false)
const saving = ref(false)
const savedAt = ref<number | null>(null)
const saveError = ref('')

const form = ref({
  id: '',
  slug: '',
  category_id: '',
  name: '',
  price: '' as number | string,
  original_price: '' as number | string,
  tag: '',
  status: 'draft',
  quantity: 0 as number | string,
  reserved_quantity: 0,
})

const statusOptions = [
  { value: 'active', label: '上架' },
  { value: 'draft', label: '草稿' },
  { value: 'archived', label: '封存' },
]

async function loadData() {
  isLoading.value = true
  loadError.value = ''
  notFound.value = false

  const [{ data: categoryRows, error: categoryError }, { data: productRow, error: productError }] = await Promise.all([
    supabase.from('categories').select('id, name').order('sort_order', { ascending: true }),
    supabase
      .from('products')
      .select('id, slug, category_id, name, price, original_price, tag, status, inventory(quantity, reserved_quantity)')
      .eq('id', productId)
      .maybeSingle(),
  ])

  if (categoryError || productError) {
    loadError.value = (categoryError ?? productError)?.message ?? '資料載入失敗。'
    isLoading.value = false
    return
  }

  categories.value = (categoryRows ?? []) as Category[]

  if (!productRow) {
    notFound.value = true
    isLoading.value = false
    return
  }

  const row = productRow as unknown as Record<string, unknown>
  const inv = Array.isArray(row.inventory) ? row.inventory[0] : row.inventory
  const inventory = (inv ?? null) as { quantity: number | null; reserved_quantity: number | null } | null
  form.value = {
    id: row.id as string,
    slug: row.slug as string,
    category_id: row.category_id as string,
    name: row.name as string,
    price: Number(row.price),
    original_price: row.original_price === null ? '' : Number(row.original_price),
    tag: (row.tag as string | null) ?? '',
    status: row.status as string,
    quantity: inventory?.quantity ?? 0,
    reserved_quantity: inventory?.reserved_quantity ?? 0,
  }
  isLoading.value = false
}

async function save() {
  saving.value = true
  saveError.value = ''
  savedAt.value = null

  const price = Number(form.value.price)
  const originalPrice = form.value.original_price === null || form.value.original_price === ''
    ? null
    : Number(form.value.original_price)
  const quantity = Math.max(0, Math.trunc(Number(form.value.quantity)))

  if (Number.isNaN(price) || price < 0) {
    saveError.value = '售價需為 0 以上的數字。'
    saving.value = false
    return
  }
  if (originalPrice !== null && (Number.isNaN(originalPrice) || originalPrice < price)) {
    saveError.value = '原價需大於或等於售價。'
    saving.value = false
    return
  }
  if (quantity < form.value.reserved_quantity) {
    saveError.value = `庫存不可低於已保留數量（${form.value.reserved_quantity}）。`
    saving.value = false
    return
  }

  const { error: productError } = await supabase
    .from('products')
    .update({
      name: form.value.name,
      category_id: form.value.category_id,
      price,
      original_price: originalPrice,
      tag: form.value.tag ? form.value.tag : null,
      status: form.value.status,
    })
    .eq('id', form.value.id)

  if (productError) {
    saveError.value = productError.message
    saving.value = false
    return
  }

  const { error: inventoryError } = await supabase
    .from('inventory')
    .upsert({ product_id: form.value.id, quantity }, { onConflict: 'product_id' })

  if (inventoryError) {
    saveError.value = inventoryError.message
    saving.value = false
    return
  }

  savedAt.value = Date.now()
  saving.value = false
}

const images = ref<ProductImage[]>([])
const imageBusy = ref(false)
const imageError = ref('')

async function refreshImages() {
  try {
    images.value = await loadImages(productId)
  } catch (error) {
    imageError.value = error instanceof Error ? error.message : '圖片載入失敗。'
  }
}

async function onUpload(event: Event) {
  const input = event.target as HTMLInputElement
  const files = input.files ? Array.from(input.files) : []
  if (!files.length) {
    return
  }
  imageBusy.value = true
  imageError.value = ''
  try {
    await uploadImages(productId, files, form.value.name)
    await refreshImages()
  } catch (error) {
    imageError.value = error instanceof Error ? error.message : '圖片上傳失敗。'
  }
  imageBusy.value = false
  input.value = ''
}

async function onSetPrimary(imageId: string) {
  imageBusy.value = true
  imageError.value = ''
  try {
    await setPrimary(productId, imageId)
    await refreshImages()
  } catch (error) {
    imageError.value = error instanceof Error ? error.message : '設定主圖失敗。'
  }
  imageBusy.value = false
}

async function onDeleteImage(image: ProductImage) {
  imageBusy.value = true
  imageError.value = ''
  try {
    await deleteImage(productId, image)
    await refreshImages()
  } catch (error) {
    imageError.value = error instanceof Error ? error.message : '刪除圖片失敗。'
  }
  imageBusy.value = false
}

const confirmingDelete = ref(false)
const deleting = ref(false)
const deleteError = ref('')

async function deleteProduct() {
  deleting.value = true
  deleteError.value = ''
  try {
    // 1. 從活動商品清單移除此商品（保留 start/end/discount）
    const { data: ss } = await supabase
      .from('site_settings')
      .select('value')
      .eq('key', 'flash_sale')
      .maybeSingle()
    const value = (ss as { value?: { product_ids?: string[] } } | null)?.value
    if (value && Array.isArray(value.product_ids) && value.product_ids.includes(productId)) {
      await supabase
        .from('site_settings')
        .update({ value: { ...value, product_ids: value.product_ids.filter((id) => id !== productId) } })
        .eq('key', 'flash_sale')
    }

    // 2. 刪商品（cascade 連帶刪 images/specs/inventory/cart_items 列；訂單歷史 set null 保留快照）
    const { error } = await supabase.from('products').delete().eq('id', productId)
    if (error) {
      deleteError.value = error.message
      deleting.value = false
      return
    }

    // 3. 清 Storage 該商品資料夾的圖檔（DB 列已被 cascade 刪，實體檔要自己清）
    const { data: files } = await supabase.storage.from('product-images').list(productId)
    if (files && files.length) {
      await supabase.storage
        .from('product-images')
        .remove(files.map((file) => `${productId}/${file.name}`))
    }

    void router.push({ name: 'AdminProducts' })
  } catch (error) {
    deleteError.value = error instanceof Error ? error.message : '刪除失敗。'
    deleting.value = false
  }
}

onMounted(async () => {
  await loadData()
  if (!notFound.value) {
    await refreshImages()
  }
})
</script>

<template>
  <div class="max-w-3xl">
    <RouterLink :to="{ name: 'AdminProducts' }" class="mb-4 inline-flex items-center gap-1 text-sm font-bold text-primary hover:underline">
      <span aria-hidden="true">&larr;</span> 返回商品列表
    </RouterLink>

    <div v-if="!isAuthReady || isLoading" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-on-surface-variant">
      載入中...
    </div>

    <div v-else-if="!isAdmin" class="flex min-h-60 flex-col items-center justify-center rounded-xl bg-surface-container-lowest p-8 text-center">
      <h2 class="font-headline text-xl font-black text-on-surface">沒有權限</h2>
      <p class="mt-2 text-base text-on-surface-variant">這個頁面只開放給管理員帳號使用。</p>
    </div>

    <div v-else-if="loadError" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-error">
      {{ loadError }}
    </div>

    <div v-else-if="notFound" class="rounded-xl bg-surface-container-lowest p-8 text-center">
      <p class="text-base text-on-surface-variant">找不到這個商品。</p>
      <Button as-child class="primary-gradient mt-6 rounded-xl font-bold text-on-primary">
        <RouterLink :to="{ name: 'AdminProducts' }">返回商品列表</RouterLink>
      </Button>
    </div>

    <section v-else class="rounded-xl bg-surface-container-lowest p-5 shadow-sm md:p-6">
      <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
        <label class="flex flex-col gap-1.5 md:col-span-2">
          <span class="text-sm font-semibold text-on-surface-variant">商品名稱</span>
          <Input v-model="form.name" />
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">分類</span>
          <select v-model="form.category_id" class="h-9 rounded-md border border-input bg-transparent px-3 text-sm outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50">
            <option v-for="category in categories" :key="category.id" :value="category.id">{{ category.name }}</option>
          </select>
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">狀態</span>
          <select v-model="form.status" class="h-9 rounded-md border border-input bg-transparent px-3 text-sm outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50">
            <option v-for="option in statusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
          </select>
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">售價</span>
          <Input v-model="form.price" type="number" />
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">原價（選填）</span>
          <Input v-model="form.original_price" type="number" />
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">標籤（選填）</span>
          <Input v-model="form.tag" />
        </label>
        <label class="flex flex-col gap-1.5">
          <span class="text-sm font-semibold text-on-surface-variant">庫存數量 <span class="text-outline">（已保留 {{ form.reserved_quantity }}）</span></span>
          <Input v-model="form.quantity" type="number" />
        </label>
      </div>

      <div class="mt-6 flex items-center justify-end gap-3">
        <span v-if="saveError" class="text-sm font-bold text-red-600">{{ saveError }}</span>
        <span v-else-if="savedAt" class="text-sm font-bold text-green-600">已儲存</span>
        <Button :disabled="saving" class="primary-gradient rounded-xl px-6 font-bold text-on-primary hover:opacity-80" @click="save">
          {{ saving ? '儲存中…' : '儲存' }}
        </Button>
      </div>

      <div class="mt-8 border-t border-outline-variant/50 pt-6">
        <div class="mb-3 flex items-center justify-between">
          <h2 class="font-bold text-on-surface">商品圖片</h2>
          <label
            class="cursor-pointer rounded-lg border border-outline-variant px-3 py-1.5 text-sm font-bold text-on-surface hover:bg-surface-container-low"
            :class="{ 'pointer-events-none opacity-60': imageBusy }"
          >
            {{ imageBusy ? '處理中…' : '＋ 上傳圖片' }}
            <input type="file" accept="image/*" multiple class="hidden" :disabled="imageBusy" @change="onUpload" />
          </label>
        </div>
        <p v-if="imageError" class="mb-3 text-sm font-bold text-red-600">{{ imageError }}</p>

        <div v-if="!images.length" class="rounded-lg bg-surface-container-low p-6 text-center text-sm text-outline">
          尚無圖片，點右上角「上傳圖片」新增。
        </div>
        <div v-else class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
          <div v-for="image in images" :key="image.id" class="overflow-hidden rounded-lg border border-outline-variant/60 bg-surface-container-lowest">
            <div class="relative aspect-square bg-surface-container-low">
              <img :src="image.image_url" :alt="image.alt ?? ''" class="h-full w-full object-cover" />
              <span v-if="image.is_primary" class="absolute left-1.5 top-1.5 rounded-full bg-primary px-2 py-0.5 text-[11px] font-bold text-on-primary">主圖</span>
            </div>
            <div class="flex items-center justify-between gap-1 p-2">
              <button
                type="button"
                class="text-xs font-bold text-primary disabled:opacity-40"
                :disabled="imageBusy || image.is_primary"
                @click="onSetPrimary(image.id)"
              >
                設為主圖
              </button>
              <button
                type="button"
                class="text-xs font-bold text-red-600 disabled:opacity-40"
                :disabled="imageBusy"
                @click="onDeleteImage(image)"
              >
                刪除
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 危險操作：刪除商品 -->
    <div v-if="isAuthReady && isAdmin && !isLoading && !loadError && !notFound" class="mt-6 rounded-xl border border-red-300 bg-red-50/50 p-5">
      <h3 class="font-bold text-red-700">危險操作</h3>
      <p class="mt-1 text-sm text-on-surface-variant">刪除後無法復原（商品、圖片、庫存都會移除；歷史訂單仍保留紀錄）。</p>
      <p v-if="deleteError" class="mt-2 text-sm font-bold text-red-600">{{ deleteError }}</p>
      <div class="mt-3">
        <button
          v-if="!confirmingDelete"
          type="button"
          class="rounded-lg border border-red-500 px-4 py-2 text-sm font-bold text-red-600 hover:bg-red-50"
          @click="confirmingDelete = true"
        >
          刪除商品
        </button>
        <div v-else class="flex flex-wrap items-center gap-3">
          <span class="text-sm font-bold text-red-700">確定刪除？此動作無法復原。</span>
          <button
            type="button"
            class="rounded-lg bg-red-600 px-4 py-2 text-sm font-bold text-white hover:bg-red-700 disabled:opacity-50"
            :disabled="deleting"
            @click="deleteProduct"
          >
            {{ deleting ? '刪除中…' : '確定刪除' }}
          </button>
          <button
            type="button"
            class="rounded-lg px-4 py-2 text-sm font-bold text-on-surface-variant hover:bg-surface-container-low"
            :disabled="deleting"
            @click="confirmingDelete = false"
          >
            取消
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
