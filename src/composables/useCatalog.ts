import { ref } from 'vue'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'

export interface CatalogCategory {
  id: string
  slug: string
  name: string
  sortOrder: number
}

export interface CatalogImage {
  id: string
  imageUrl: string
  alt: string
  sortOrder: number
  isPrimary: boolean
}

export interface CatalogSpec {
  id: string
  label: string
  value: string
  sortOrder: number
}

export interface CatalogProduct {
  id: string
  slug: string
  categoryId: string
  categorySlug: string
  categoryName: string
  name: string
  description: string
  price: number
  originalPrice: number | null
  tag: string | null
  status: string
  sortOrder: number
  image: string
  images: CatalogImage[]
  specs: Record<string, string>
  specList: CatalogSpec[]
}

type RawCategory = {
  id: string
  slug: string
  name: string
  sort_order: number | null
}

type RawProduct = {
  id: string
  slug: string
  category_id: string
  name: string
  description: string | null
  price: number | string
  original_price: number | string | null
  tag: string | null
  status: string
  sort_order: number | null
  categories?: RawCategory | RawCategory[] | null
  product_images: Array<{
    id: string
    product_id?: string
    image_url: string
    alt: string | null
    sort_order: number | null
    is_primary: boolean | null
  }> | null
  product_specs: Array<{
    id: string
    product_id?: string
    label: string
    value: string
    sort_order: number | null
  }> | null
}

const emptyImage = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="640" height="544" viewBox="0 0 640 544"%3E%3Crect width="640" height="544" fill="%23f0f1f3"/%3E%3Ctext x="50%25" y="50%25" dominant-baseline="middle" text-anchor="middle" fill="%23757779" font-family="Arial" font-size="28"%3E商品圖片%3C/text%3E%3C/svg%3E'

const categories = ref<CatalogCategory[]>([])
const products = ref<CatalogProduct[]>([])
const isLoading = ref(false)
const errorMessage = ref('')
let hasLoadedCatalog = false

function normalizeCategory(category: RawCategory): CatalogCategory {
  return {
    id: category.id,
    slug: category.slug,
    name: category.name,
    sortOrder: category.sort_order ?? 0,
  }
}

function firstRelation<T>(relation: T | T[] | null | undefined): T | null {
  return Array.isArray(relation) ? relation[0] ?? null : relation ?? null
}

function normalizeProduct(row: RawProduct): CatalogProduct {
  const category = firstRelation(row.categories)
  const images = (row.product_images ?? [])
    .map((image) => ({
      id: image.id,
      imageUrl: image.image_url,
      alt: image.alt || row.name,
      sortOrder: image.sort_order ?? 0,
      isPrimary: Boolean(image.is_primary),
    }))
    .sort((a, b) => Number(b.isPrimary) - Number(a.isPrimary) || a.sortOrder - b.sortOrder)

  const specList = (row.product_specs ?? [])
    .map((spec) => ({
      id: spec.id,
      label: spec.label,
      value: spec.value,
      sortOrder: spec.sort_order ?? 0,
    }))
    .sort((a, b) => a.sortOrder - b.sortOrder)

  return {
    id: row.id,
    slug: row.slug,
    categoryId: row.category_id,
    categorySlug: category?.slug ?? '',
    categoryName: category?.name ?? '未分類',
    name: row.name,
    description: row.description ?? '',
    price: Number(row.price),
    originalPrice: row.original_price === null ? null : Number(row.original_price),
    tag: row.tag,
    status: row.status,
    sortOrder: row.sort_order ?? 0,
    image: images[0]?.imageUrl ?? emptyImage,
    images,
    specs: Object.fromEntries(specList.map((spec) => [spec.label, spec.value])),
    specList,
  }
}

async function fetchCategories() {
  const { data, error } = await supabase
    .from('categories')
    .select('id, slug, name, sort_order')
    .eq('is_active', true)
    .order('sort_order', { ascending: true })

  if (error) {
    throw error
  }

  categories.value = ((data ?? []) as RawCategory[]).map(normalizeCategory)
}

async function fetchProducts() {
  const { data, error } = await supabase
    .from('products')
    .select(`
      id,
      slug,
      category_id,
      name,
      description,
      price,
      original_price,
      tag,
      status,
      sort_order
    `)
    .eq('status', 'active')
    .order('sort_order', { ascending: true })

  if (error) {
    throw error
  }

  const productRows = (data ?? []) as unknown as RawProduct[]
  const productIds = productRows.map((product) => product.id)
  const categoryMap = new Map(categories.value.map((category) => [category.id, category]))

  if (!productIds.length) {
    products.value = []
    return
  }

  const [{ data: imageRows, error: imageError }, { data: specRows, error: specError }] = await Promise.all([
    supabase
      .from('product_images')
      .select('id, product_id, image_url, alt, sort_order, is_primary')
      .in('product_id', productIds),
    supabase
      .from('product_specs')
      .select('id, product_id, label, value, sort_order')
      .in('product_id', productIds),
  ])

  if (imageError) {
    console.warn('Product images could not be loaded.', imageError)
  }

  if (specError) {
    console.warn('Product specs could not be loaded.', specError)
  }

  products.value = productRows.map((product) => {
    const category = categoryMap.get(product.category_id)
    const productImages = imageError ? [] : (imageRows ?? [])
    const productSpecs = specError ? [] : (specRows ?? [])

    return normalizeProduct({
      ...product,
      categories: category
        ? {
          id: category.id,
          slug: category.slug,
          name: category.name,
          sort_order: category.sortOrder,
        }
        : null,
      product_images: (productImages as NonNullable<RawProduct['product_images']>)
        .filter((image) => image.product_id === product.id),
      product_specs: (productSpecs as NonNullable<RawProduct['product_specs']>)
        .filter((spec) => spec.product_id === product.id),
    })
  })
}

export async function loadCatalog({ force = false } = {}) {
  if (hasLoadedCatalog && !force) {
    return
  }

  if (!isSupabaseConfigured) {
    errorMessage.value = 'Supabase 尚未設定，無法載入商品資料。'
    return
  }

  isLoading.value = true
  errorMessage.value = ''

  try {
    await fetchCategories()
    await fetchProducts()
    hasLoadedCatalog = true
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '商品資料載入失敗。'
  } finally {
    isLoading.value = false
  }
}

export async function fetchProductByIdentifier(identifier: string) {
  if (!isSupabaseConfigured) {
    throw new Error('Supabase 尚未設定，無法載入商品資料。')
  }

  const key = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(identifier)
    ? 'id'
    : 'slug'

  const { data, error } = await supabase
    .from('products')
    .select(`
      id,
      slug,
      category_id,
      name,
      description,
      price,
      original_price,
      tag,
      status,
      sort_order
    `)
    .eq(key, identifier)
    .eq('status', 'active')
    .maybeSingle()

  if (error) {
    throw error
  }

  if (!data) {
    return null
  }

  const productRow = data as unknown as RawProduct
  const [{ data: categoryRow, error: categoryError }, { data: imageRows, error: imageError }, { data: specRows, error: specError }] = await Promise.all([
    supabase
      .from('categories')
      .select('id, slug, name, sort_order')
      .eq('id', productRow.category_id)
      .maybeSingle(),
    supabase
      .from('product_images')
      .select('id, product_id, image_url, alt, sort_order, is_primary')
      .eq('product_id', productRow.id),
    supabase
      .from('product_specs')
      .select('id, product_id, label, value, sort_order')
      .eq('product_id', productRow.id),
  ])

  if (categoryError) {
    throw categoryError
  }

  if (imageError) {
    console.warn('Product images could not be loaded.', imageError)
  }

  if (specError) {
    console.warn('Product specs could not be loaded.', specError)
  }

  return normalizeProduct({
    ...productRow,
    categories: categoryRow as RawCategory | null,
    product_images: (imageError ? [] : imageRows ?? []) as RawProduct['product_images'],
    product_specs: (specError ? [] : specRows ?? []) as RawProduct['product_specs'],
  })
}

export function formatPrice(value: number) {
  return new Intl.NumberFormat('zh-TW', {
    style: 'currency',
    currency: 'TWD',
    maximumFractionDigits: 0,
  }).format(value)
}

export function useCatalog() {
  return {
    categories,
    products,
    isLoading,
    errorMessage,
    loadCatalog,
  }
}
