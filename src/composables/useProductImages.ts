import { supabase } from '@/lib/supabase'
import { compressImage } from '@/lib/imageCompress'

export interface ProductImage {
  id: string
  image_url: string
  alt: string | null
  sort_order: number
  is_primary: boolean
}

// 最新消息的圖片也共用這個 bucket（放在 news/ 資料夾下）
export const BUCKET = 'product-images'

export async function loadImages(productId: string): Promise<ProductImage[]> {
  const { data, error } = await supabase
    .from('product_images')
    .select('id, image_url, alt, sort_order, is_primary')
    .eq('product_id', productId)
    .order('is_primary', { ascending: false })
    .order('sort_order', { ascending: true })
  if (error) {
    throw error
  }
  return (data ?? []) as ProductImage[]
}

export function uuid(): string {
  const c = crypto as Crypto & { randomUUID?: () => string }
  return c.randomUUID?.() ?? `${Date.now()}-${Math.random().toString(16).slice(2)}`
}

// 從 public URL 反推 storage 內路徑（供刪除用）
export function storagePathFromUrl(url: string): string | null {
  const marker = `/storage/v1/object/public/${BUCKET}/`
  const idx = url.indexOf(marker)
  return idx >= 0 ? url.slice(idx + marker.length) : null
}

export async function uploadImages(productId: string, files: File[], productName: string): Promise<void> {
  const existing = await loadImages(productId)
  let nextSort = existing.reduce((max, img) => Math.max(max, img.sort_order), -1) + 1
  let hasPrimary = existing.some((img) => img.is_primary)

  for (const file of files) {
    const blob = await compressImage(file)
    const path = `${productId}/${uuid()}.jpg`
    const { error: uploadError } = await supabase.storage
      .from(BUCKET)
      .upload(path, blob, { contentType: 'image/jpeg', upsert: false })
    if (uploadError) {
      throw uploadError
    }
    const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(path)
    const { error: insertError } = await supabase.from('product_images').insert({
      product_id: productId,
      image_url: pub.publicUrl,
      alt: productName,
      sort_order: nextSort,
      is_primary: !hasPrimary,
    })
    if (insertError) {
      throw insertError
    }
    nextSort += 1
    hasPrimary = true
  }
}

export async function setPrimary(productId: string, imageId: string): Promise<void> {
  const { error: clearError } = await supabase
    .from('product_images')
    .update({ is_primary: false })
    .eq('product_id', productId)
  if (clearError) {
    throw clearError
  }
  const { error } = await supabase
    .from('product_images')
    .update({ is_primary: true })
    .eq('id', imageId)
  if (error) {
    throw error
  }
}

export async function deleteImage(productId: string, image: ProductImage): Promise<void> {
  const { error } = await supabase.from('product_images').delete().eq('id', image.id)
  if (error) {
    throw error
  }
  const path = storagePathFromUrl(image.image_url)
  if (path) {
    const { error: removeError } = await supabase.storage.from(BUCKET).remove([path])
    if (removeError) {
      console.warn('Storage object could not be removed.', removeError)
    }
  }
  // 刪的是主圖 → 把最前面一張補為主圖
  if (image.is_primary) {
    const remaining = await loadImages(productId)
    if (remaining.length && !remaining.some((img) => img.is_primary)) {
      await setPrimary(productId, remaining[0].id)
    }
  }
}
