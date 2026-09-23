import { ref } from 'vue'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'
import { compressImage } from '@/lib/imageCompress'
import { BUCKET, storagePathFromUrl, uuid } from '@/composables/useProductImages'

export interface NewsArticle {
  id: number
  tag: string
  date: string // 已格式化的中文日期，供顯示用
  dateRaw: string // ISO 日期（yyyy-mm-dd），供 <time datetime> 用
  title: string
  description: string
  image: string
  alt: string
  readTime: string
  content: {
    intro: string
    sectionTitle: string
    sectionBody1: string
    quote: {
      text: string
      author: string
    }
    sectionBody2: string
  }
}

// 資料庫回傳的原始列（snake_case）
interface NewsRow {
  id: number
  tag: string
  title: string
  description: string
  image_url: string
  alt: string
  read_time: string
  published_at: string
  intro: string
  section_title: string
  section_body_1: string
  quote_text: string
  quote_author: string
  section_body_2: string
}

// 把 ISO 日期轉成「2024年10月24日」；無效日期原樣回傳（防呆）
function formatNewsDate(iso: string): string {
  const parsed = new Date(`${iso}T00:00:00`)
  if (!Number.isFinite(parsed.getTime())) {
    return iso
  }
  return `${parsed.getFullYear()}年${parsed.getMonth() + 1}月${parsed.getDate()}日`
}

function mapRow(row: NewsRow): NewsArticle {
  return {
    id: row.id,
    tag: row.tag,
    date: formatNewsDate(row.published_at),
    dateRaw: row.published_at,
    title: row.title,
    description: row.description,
    image: row.image_url,
    alt: row.alt,
    readTime: row.read_time,
    content: {
      intro: row.intro,
      sectionTitle: row.section_title,
      sectionBody1: row.section_body_1,
      quote: {
        text: row.quote_text,
        author: row.quote_author,
      },
      sectionBody2: row.section_body_2,
    },
  }
}

const newsItems = ref<NewsArticle[]>([])
let hasLoaded = false

// 載入所有消息（依發布日新到舊）；快取起來，除非 force 重新抓
export async function loadNews({ force = false } = {}): Promise<NewsArticle[]> {
  if (hasLoaded && !force) {
    return newsItems.value
  }
  if (!isSupabaseConfigured) {
    return []
  }

  const { data, error } = await supabase
    .from('news')
    .select('*')
    .order('published_at', { ascending: false })
    .order('id', { ascending: false })

  if (error) {
    console.warn('News could not be loaded.', error)
    return newsItems.value
  }

  newsItems.value = (data as NewsRow[] | null)?.map(mapRow) ?? []
  hasLoaded = true
  return newsItems.value
}

// 單篇查詢（詳情頁用，深連結時不依賴列表先載入）
export async function fetchNewsById(id: number): Promise<NewsArticle | null> {
  if (!Number.isFinite(id)) {
    return null
  }
  // 若列表已載入，直接命中快取
  const cached = newsItems.value.find((item) => item.id === id)
  if (cached) {
    return cached
  }
  if (!isSupabaseConfigured) {
    return null
  }

  const { data, error } = await supabase
    .from('news')
    .select('*')
    .eq('id', id)
    .maybeSingle()

  if (error || !data) {
    return null
  }
  return mapRow(data as NewsRow)
}

// 後台新增消息用的表單內容（圖片另外傳檔案）
export interface NewsInput {
  tag: string
  title: string
  description: string
  publishedAt: string // yyyy-mm-dd
  intro: string
  sectionTitle: string
  sectionBody1: string
  quoteText: string
  quoteAuthor: string
  sectionBody2: string
}

// 依內文字數估算閱讀時間：中文約每分鐘 400 字，至少 1 分鐘
function estimateReadTime(input: NewsInput): string {
  const length = [input.intro, input.sectionTitle, input.sectionBody1, input.quoteText, input.sectionBody2]
    .join('')
    .replace(/\s/g, '').length
  return `${Math.max(1, Math.ceil(length / 400))} 分鐘閱讀`
}

// 新增消息：先上傳圖片 → 再寫入資料表；寫入失敗就把剛上傳的圖刪掉，避免留下孤兒檔案
export async function createNews(input: NewsInput, imageFile: File): Promise<void> {
  const blob = await compressImage(imageFile)
  const path = `news/${uuid()}.jpg`
  const { error: uploadError } = await supabase.storage
    .from(BUCKET)
    .upload(path, blob, { contentType: 'image/jpeg', upsert: false })
  if (uploadError) {
    throw uploadError
  }
  const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(path)

  const { error: insertError } = await supabase.from('news').insert({
    tag: input.tag,
    title: input.title,
    description: input.description,
    image_url: pub.publicUrl,
    alt: input.title,
    read_time: estimateReadTime(input),
    published_at: input.publishedAt,
    intro: input.intro,
    section_title: input.sectionTitle,
    section_body_1: input.sectionBody1,
    quote_text: input.quoteText,
    quote_author: input.quoteAuthor,
    section_body_2: input.sectionBody2,
  })
  if (insertError) {
    await supabase.storage.from(BUCKET).remove([path])
    throw insertError
  }

  await loadNews({ force: true })
}

// 編輯消息：更新內容；有換新封面圖才上傳、成功後把舊圖（僅限我們 bucket 裡的）刪掉。
export async function updateNews(
  article: NewsArticle,
  input: NewsInput,
  imageFile?: File | null,
): Promise<void> {
  const patch: Record<string, unknown> = {
    tag: input.tag,
    title: input.title,
    description: input.description,
    alt: input.title,
    read_time: estimateReadTime(input),
    published_at: input.publishedAt,
    intro: input.intro,
    section_title: input.sectionTitle,
    section_body_1: input.sectionBody1,
    quote_text: input.quoteText,
    quote_author: input.quoteAuthor,
    section_body_2: input.sectionBody2,
  }

  // 有選新圖才上傳並換 image_url；沒選就沿用原本的圖
  let newPath: string | null = null
  if (imageFile) {
    const blob = await compressImage(imageFile)
    newPath = `news/${uuid()}.jpg`
    const { error: uploadError } = await supabase.storage
      .from(BUCKET)
      .upload(newPath, blob, { contentType: 'image/jpeg', upsert: false })
    if (uploadError) {
      throw uploadError
    }
    const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(newPath)
    patch.image_url = pub.publicUrl
  }

  const { error } = await supabase.from('news').update(patch).eq('id', article.id)
  if (error) {
    // 更新失敗就把剛上傳的新圖刪掉，避免孤兒檔案
    if (newPath) {
      await supabase.storage.from(BUCKET).remove([newPath])
    }
    throw error
  }

  // 換了新圖 → 清掉舊圖（外部種子網址 storagePathFromUrl 會回 null，不動）
  if (newPath) {
    const oldPath = storagePathFromUrl(article.image)
    if (oldPath) {
      const { error: removeError } = await supabase.storage.from(BUCKET).remove([oldPath])
      if (removeError) {
        console.warn('Old news image could not be removed.', removeError)
      }
    }
  }

  await loadNews({ force: true })
}

// 刪除消息：先刪資料列，再刪我們自己 bucket 裡的圖片（外部網址的種子圖片不動）
export async function deleteNews(article: NewsArticle): Promise<void> {
  const { error } = await supabase.from('news').delete().eq('id', article.id)
  if (error) {
    throw error
  }
  const path = storagePathFromUrl(article.image)
  if (path) {
    const { error: removeError } = await supabase.storage.from(BUCKET).remove([path])
    if (removeError) {
      console.warn('News image could not be removed.', removeError)
    }
  }

  await loadNews({ force: true })
}

export function useNews() {
  return { newsItems, loadNews, fetchNewsById, createNews, updateNews, deleteNews }
}
