import { ref } from 'vue'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'

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

export function useNews() {
  return { newsItems, loadNews, fetchNewsById }
}
