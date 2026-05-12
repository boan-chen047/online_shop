import { computed, ref } from 'vue'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'
import type { CatalogProduct } from '@/composables/useCatalog'

export interface CartItem {
  id: string
  productId: string
  slug: string
  name: string
  categorySlug: string
  categoryName: string
  price: number
  quantity: number
  image: string
  selected: boolean
}

type RawCartItem = {
  id: string
  product_id: string
  quantity: number
  selected: boolean | null
}

type RawCartProduct = {
  id: string
  slug: string
  category_id: string
  name: string
  price: number | string
}

type RawCartCategory = {
  id: string
  slug: string
  name: string
}

type RawCartImage = {
  product_id: string
  image_url: string
  sort_order: number | null
  is_primary: boolean | null
}

const emptyImage = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="320" height="320" viewBox="0 0 320 320"%3E%3Crect width="320" height="320" fill="%23f0f1f3"/%3E%3Ctext x="50%25" y="50%25" dominant-baseline="middle" text-anchor="middle" fill="%23757779" font-family="Arial" font-size="18"%3E商品圖片%3C/text%3E%3C/svg%3E'

const cartItems = ref<CartItem[]>([])
const isCartLoading = ref(false)
const cartError = ref('')
let hasLoadedCart = false

function getSupabaseErrorMessage(error: unknown, fallback: string) {
  if (error instanceof Error) {
    return error.message
  }

  if (error && typeof error === 'object') {
    const record = error as Record<string, unknown>
    const parts = [record.message, record.details, record.hint, record.code]
      .filter((part): part is string => typeof part === 'string' && part.length > 0)

    if (parts.length) {
      return parts.join('\n')
    }
  }

  return fallback
}

async function getCurrentUserId() {
  if (!isSupabaseConfigured) {
    throw new Error('Supabase 尚未設定，無法同步購物車。')
  }

  const { data, error } = await supabase.auth.getSession()

  if (error) {
    throw error
  }

  const userId = data.session?.user.id

  if (!userId) {
    throw new Error('請先登入後再使用購物車。')
  }

  return userId
}

async function loadCart({ force = false } = {}) {
  if (hasLoadedCart && !force) {
    return
  }

  isCartLoading.value = true
  cartError.value = ''

  try {
    const userId = await getCurrentUserId()
    const { data: cartRows, error } = await supabase
      .from('cart_items')
      .select('id, product_id, quantity, selected')
      .eq('user_id', userId)
      .order('created_at', { ascending: true })

    if (error) {
      throw error
    }

    const rows = (cartRows ?? []) as RawCartItem[]
    const productIds = rows.map((item) => item.product_id)

    if (!productIds.length) {
      cartItems.value = []
      hasLoadedCart = true
      return
    }

    const { data: productRows, error: productError } = await supabase
      .from('products')
      .select('id, slug, category_id, name, price')
      .in('id', productIds)

    if (productError) {
      throw productError
    }

    const products = (productRows ?? []) as RawCartProduct[]
    const categoryIds = [...new Set(products.map((product) => product.category_id))]
    const [{ data: categoryRows, error: categoryError }, { data: imageRows, error: imageError }] = await Promise.all([
      supabase
        .from('categories')
        .select('id, slug, name')
        .in('id', categoryIds),
      supabase
        .from('product_images')
        .select('product_id, image_url, sort_order, is_primary')
        .in('product_id', productIds),
    ])

    if (categoryError) {
      throw categoryError
    }

    if (imageError) {
      console.warn('Cart product images could not be loaded.', imageError)
    }

    const productMap = new Map(products.map((product) => [product.id, product]))
    const categoryMap = new Map(((categoryRows ?? []) as RawCartCategory[]).map((category) => [category.id, category]))
    const imageMap = new Map<string, string>()

    if (!imageError) {
      ;((imageRows ?? []) as RawCartImage[])
        .sort((a, b) => Number(b.is_primary) - Number(a.is_primary) || (a.sort_order ?? 0) - (b.sort_order ?? 0))
        .forEach((image) => {
          if (!imageMap.has(image.product_id)) {
            imageMap.set(image.product_id, image.image_url)
          }
        })
    }

    cartItems.value = rows.flatMap((item) => {
      const product = productMap.get(item.product_id)

      if (!product) {
        return []
      }

      const category = categoryMap.get(product.category_id)

      return [{
        id: item.id,
        productId: item.product_id,
        slug: product.slug,
        name: product.name,
        categorySlug: category?.slug ?? '',
        categoryName: category?.name ?? '未分類',
        price: Number(product.price),
        quantity: Math.max(1, item.quantity),
        image: imageMap.get(item.product_id) ?? emptyImage,
        selected: item.selected ?? true,
      }]
    })
    hasLoadedCart = true
  } catch (error) {
    cartItems.value = []
    cartError.value = getSupabaseErrorMessage(error, '購物車載入失敗。')
  } finally {
    isCartLoading.value = false
  }
}

async function addToCart(product: CatalogProduct, quantity = 1) {
  const normalizedQuantity = Math.max(1, quantity)
  cartError.value = ''

  try {
    const userId = await getCurrentUserId()
    const { data: existingItem, error: existingError } = await supabase
      .from('cart_items')
      .select('id, quantity')
      .eq('user_id', userId)
      .eq('product_id', product.id)
      .maybeSingle()

    if (existingError) {
      throw existingError
    }

    if (existingItem) {
      const { error } = await supabase
        .from('cart_items')
        .update({
          quantity: existingItem.quantity + normalizedQuantity,
          selected: true,
        })
        .eq('id', existingItem.id)

      if (error) {
        throw error
      }
    } else {
      const { error } = await supabase
        .from('cart_items')
        .insert({
          user_id: userId,
          product_id: product.id,
          quantity: normalizedQuantity,
          selected: true,
        })

      if (error) {
        throw error
      }
    }

    hasLoadedCart = false
    void loadCart({ force: true })
  } catch (error) {
    cartError.value = getSupabaseErrorMessage(error, '加入購物車失敗。')
    throw error
  }
}

async function checkoutSelectedCart() {
  cartError.value = ''

  try {
    const { data, error } = await supabase.rpc('create_order_from_cart')

    if (error) {
      throw error
    }

    hasLoadedCart = false
    await loadCart({ force: true })

    return data as string
  } catch (error) {
    cartError.value = getSupabaseErrorMessage(error, '建立訂單失敗。')
    throw error
  }
}

async function updateQuantity(cartItemId: string, quantity: number) {
  const normalizedQuantity = Math.max(1, quantity)
  const { error } = await supabase
    .from('cart_items')
    .update({ quantity: normalizedQuantity })
    .eq('id', cartItemId)

  if (error) {
    cartError.value = error.message
    return
  }

  const item = cartItems.value.find((cartItem) => cartItem.id === cartItemId)

  if (item) {
    item.quantity = normalizedQuantity
  }
}

async function removeFromCart(cartItemId: string) {
  const { error } = await supabase
    .from('cart_items')
    .delete()
    .eq('id', cartItemId)

  if (error) {
    cartError.value = error.message
    return
  }

  cartItems.value = cartItems.value.filter((item) => item.id !== cartItemId)
}

async function toggleItemSelected(cartItemId: string) {
  const item = cartItems.value.find((cartItem) => cartItem.id === cartItemId)

  if (!item) {
    return
  }

  const nextSelected = !item.selected
  const { error } = await supabase
    .from('cart_items')
    .update({ selected: nextSelected })
    .eq('id', cartItemId)

  if (error) {
    cartError.value = error.message
    return
  }

  item.selected = nextSelected
}

async function setAllSelected(selected: boolean) {
  const ids = cartItems.value.map((item) => item.id)

  if (!ids.length) {
    return
  }

  const { error } = await supabase
    .from('cart_items')
    .update({ selected })
    .in('id', ids)

  if (error) {
    cartError.value = error.message
    return
  }

  cartItems.value.forEach((item) => {
    item.selected = selected
  })
}

async function clearCart() {
  const ids = cartItems.value.map((item) => item.id)

  if (!ids.length) {
    return
  }

  const { error } = await supabase
    .from('cart_items')
    .delete()
    .in('id', ids)

  if (error) {
    cartError.value = error.message
    return
  }

  cartItems.value = []
}

const itemCount = computed(() =>
  cartItems.value.reduce((total, item) => total + item.quantity, 0),
)

const selectedItemCount = computed(() =>
  cartItems.value.reduce((total, item) => total + (item.selected ? item.quantity : 0), 0),
)

const subtotal = computed(() =>
  cartItems.value.reduce((total, item) => total + (item.selected ? item.price * item.quantity : 0), 0),
)

const selectedCartItems = computed(() =>
  cartItems.value.filter((item) => item.selected),
)

supabase.auth.onAuthStateChange(() => {
  hasLoadedCart = false
  void loadCart({ force: true })
})

void loadCart()

export function useCart() {
  return {
    cartItems,
    isCartLoading,
    cartError,
    itemCount,
    selectedItemCount,
    subtotal,
    selectedCartItems,
    loadCart,
    addToCart,
    checkoutSelectedCart,
    updateQuantity,
    removeFromCart,
    toggleItemSelected,
    setAllSelected,
    clearCart,
  }
}
