<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useNews, type NewsArticle, type NewsInput } from '@/composables/useNews'

const { newsItems, loadNews, createNews, updateNews, deleteNews } = useNews()

const isLoading = ref(true)
const showForm = ref(false)
const isSaving = ref(false)
const deletingId = ref<number | null>(null)
const message = ref('')
const errorMessage = ref('')

// 編輯狀態：null = 新增；有值 = 正在編輯該則消息
const editingId = ref<number | null>(null)
const editingArticle = ref<NewsArticle | null>(null)
const existingImageUrl = ref('') // 編輯時原本的封面圖（沒換新圖就沿用）
const isEditing = computed(() => editingId.value !== null)

// 台灣時間的今天（yyyy-mm-dd），當作發布日期預設值
function todayInTaiwan(): string {
  return new Date().toLocaleDateString('sv-SE', { timeZone: 'Asia/Taipei' })
}

function emptyForm(): NewsInput {
  return {
    tag: '',
    title: '',
    description: '',
    publishedAt: todayInTaiwan(),
    intro: '',
    sectionTitle: '',
    sectionBody1: '',
    quoteText: '',
    quoteAuthor: '',
    sectionBody2: '',
  }
}

const form = reactive<NewsInput>(emptyForm())
const imageFile = ref<File | null>(null)
const imagePreview = ref('')
const fileInput = ref<HTMLInputElement | null>(null)

// 已用過的分類標籤，給輸入框當建議選項
const existingTags = computed(() => [...new Set(newsItems.value.map((item) => item.tag).filter(Boolean))])

// 列表搜尋：比對標題、分類標籤、摘要
const keyword = ref('')
const filteredNews = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  if (!kw) {
    return newsItems.value
  }
  return newsItems.value.filter((item) =>
    [item.title, item.tag, item.description].some((field) => (field ?? '').toLowerCase().includes(kw)),
  )
})

function clearPreview() {
  if (imagePreview.value) {
    URL.revokeObjectURL(imagePreview.value)
  }
  imagePreview.value = ''
}

function onPickImage(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0] ?? null
  clearPreview()
  imageFile.value = file
  if (file) {
    imagePreview.value = URL.createObjectURL(file)
  }
}

function resetForm() {
  Object.assign(form, emptyForm())
  imageFile.value = null
  clearPreview()
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

function openForm() {
  message.value = ''
  errorMessage.value = ''
  resetForm()
  editingId.value = null
  editingArticle.value = null
  existingImageUrl.value = ''
  showForm.value = true
}

// 開啟編輯：把該則消息內容填入表單，封面圖預設沿用舊圖
function openEdit(item: NewsArticle) {
  message.value = ''
  errorMessage.value = ''
  Object.assign(form, {
    tag: item.tag,
    title: item.title,
    description: item.description,
    publishedAt: item.dateRaw,
    intro: item.content.intro,
    sectionTitle: item.content.sectionTitle,
    sectionBody1: item.content.sectionBody1,
    quoteText: item.content.quote.text,
    quoteAuthor: item.content.quote.author,
    sectionBody2: item.content.sectionBody2,
  } satisfies NewsInput)
  imageFile.value = null
  clearPreview()
  if (fileInput.value) {
    fileInput.value.value = ''
  }
  existingImageUrl.value = item.image
  editingId.value = item.id
  editingArticle.value = item
  showForm.value = true
  // 捲到表單方便編輯
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function cancelForm() {
  resetForm()
  editingId.value = null
  editingArticle.value = null
  existingImageUrl.value = ''
  errorMessage.value = ''
  showForm.value = false
}

async function submit() {
  message.value = ''
  errorMessage.value = ''

  const missing = [
    [form.tag, '分類標籤'],
    [form.title, '標題'],
    [form.description, '摘要'],
    [form.intro, '開頭段落'],
    [form.publishedAt, '發布日期'],
  ]
    .filter(([value]) => !value.trim())
    .map(([, label]) => label)
  // 封面圖：新增必填；編輯時可留空，沿用原本的圖
  if (!isEditing.value && !imageFile.value) {
    missing.push('封面圖片')
  }
  if (missing.length) {
    errorMessage.value = `請填寫：${missing.join('、')}`
    return
  }

  // 前後空白一律去掉再存
  const trimmed = Object.fromEntries(
    Object.entries(form).map(([key, value]) => [key, value.trim()]),
  ) as unknown as NewsInput

  isSaving.value = true
  try {
    if (isEditing.value && editingArticle.value) {
      await updateNews(editingArticle.value, trimmed, imageFile.value)
      message.value = `已更新「${trimmed.title}」`
    } else {
      await createNews(trimmed, imageFile.value!)
      message.value = `已發布「${trimmed.title}」`
    }
    resetForm()
    editingId.value = null
    editingArticle.value = null
    existingImageUrl.value = ''
    showForm.value = false
  } catch (error) {
    const action = isEditing.value ? '更新' : '發布'
    errorMessage.value = error instanceof Error ? `${action}失敗：${error.message}` : `${action}失敗，請確認你有管理員權限。`
  }
  isSaving.value = false
}

async function remove(article: NewsArticle) {
  if (!window.confirm(`確定要刪除「${article.title}」嗎？刪除後無法復原。`)) {
    return
  }
  message.value = ''
  errorMessage.value = ''
  deletingId.value = article.id
  try {
    await deleteNews(article)
    message.value = `已刪除「${article.title}」`
  } catch (error) {
    errorMessage.value = error instanceof Error ? `刪除失敗：${error.message}` : '刪除失敗，請確認你有管理員權限。'
  }
  deletingId.value = null
}

onMounted(async () => {
  // 後台一律抓最新資料，不用前台的快取
  await loadNews({ force: true })
  isLoading.value = false
})

onBeforeUnmount(clearPreview)

const inputClass = 'w-full rounded-lg border border-outline-variant bg-surface px-3 py-2 text-sm text-on-surface'
</script>

<template>
  <div class="text-on-surface antialiased font-body">
    <main class="pb-16">
      <div class="mb-6 flex flex-wrap items-center justify-between gap-4">
        <h1 class="font-headline text-2xl font-black">最新消息管理</h1>
        <Button
          v-if="!showForm"
          class="primary-gradient rounded-lg font-bold text-on-primary"
          @click="openForm"
        >
          ＋ 新增消息
        </Button>
      </div>

      <p v-if="message" class="mb-4 rounded-lg bg-primary/10 px-4 py-3 text-sm font-bold text-primary">{{ message }}</p>
      <p v-if="errorMessage" class="mb-4 rounded-lg bg-error/10 px-4 py-3 text-sm font-bold text-error">{{ errorMessage }}</p>

      <!-- 新增表單 -->
      <section v-if="showForm" class="mb-8 space-y-5 rounded-xl border border-outline-variant bg-surface-container-lowest p-5 md:p-6">
        <h2 class="font-headline text-lg font-bold">{{ isEditing ? '編輯消息' : '新增消息' }}</h2>

        <div class="grid gap-4 md:grid-cols-[1fr_1fr_12rem]">
          <div>
            <label class="mb-1 block text-sm font-bold">分類標籤 <span class="text-error">*</span></label>
            <input v-model="form.tag" list="news-tag-options" placeholder="例如：新品上架" :class="inputClass" />
            <datalist id="news-tag-options">
              <option v-for="tag in existingTags" :key="tag" :value="tag" />
            </datalist>
          </div>
          <div>
            <label class="mb-1 block text-sm font-bold">標題 <span class="text-error">*</span></label>
            <input v-model="form.title" :class="inputClass" />
          </div>
          <div>
            <label class="mb-1 block text-sm font-bold">發布日期 <span class="text-error">*</span></label>
            <input v-model="form.publishedAt" type="date" :class="inputClass" />
          </div>
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold">摘要 <span class="text-error">*</span><span class="font-normal text-outline">（列表頁顯示的兩行介紹）</span></label>
          <textarea v-model="form.description" rows="2" :class="inputClass" />
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold">
            封面圖片 <span v-if="!isEditing" class="text-error">*</span>
            <span class="font-normal text-outline">（上傳時會自動壓縮{{ isEditing ? '；不選就沿用原本的圖' : '' }}）</span>
          </label>
          <input ref="fileInput" type="file" accept="image/*" class="text-sm" @change="onPickImage" />
          <img v-if="imagePreview" :src="imagePreview" alt="封面預覽" class="mt-3 aspect-video w-full max-w-sm rounded-lg object-cover" />
          <img v-else-if="existingImageUrl" :src="existingImageUrl" alt="目前封面" class="mt-3 aspect-video w-full max-w-sm rounded-lg object-cover" />
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold">開頭段落 <span class="text-error">*</span></label>
          <textarea v-model="form.intro" rows="3" :class="inputClass" />
        </div>

        <p class="border-t border-outline-variant/60 pt-4 text-sm text-outline">以下為選填，沒填的區塊在內文頁不會顯示。</p>

        <div>
          <label class="mb-1 block text-sm font-bold">小標題</label>
          <input v-model="form.sectionTitle" :class="inputClass" />
        </div>
        <div>
          <label class="mb-1 block text-sm font-bold">內文</label>
          <textarea v-model="form.sectionBody1" rows="3" :class="inputClass" />
        </div>
        <div class="grid gap-4 md:grid-cols-[1fr_14rem]">
          <div>
            <label class="mb-1 block text-sm font-bold">引言</label>
            <input v-model="form.quoteText" :class="inputClass" />
          </div>
          <div>
            <label class="mb-1 block text-sm font-bold">引言出處</label>
            <input v-model="form.quoteAuthor" placeholder="例如：採購團隊" :class="inputClass" />
          </div>
        </div>
        <div>
          <label class="mb-1 block text-sm font-bold">結尾段落</label>
          <textarea v-model="form.sectionBody2" rows="3" :class="inputClass" />
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <Button variant="outline" class="rounded-lg font-bold" :disabled="isSaving" @click="cancelForm">取消</Button>
          <Button class="primary-gradient rounded-lg font-bold text-on-primary" :disabled="isSaving" @click="submit">
            {{ isSaving ? (isEditing ? '更新中…' : '發布中…') : (isEditing ? '更新' : '發布') }}
          </Button>
        </div>
      </section>

      <!-- 列表搜尋 -->
      <div v-if="!isLoading && newsItems.length" class="mb-5">
        <Input v-model="keyword" placeholder="搜尋標題、分類或摘要…" class="max-w-md" />
        <p v-if="keyword.trim()" class="mt-2 text-sm text-on-surface-variant">找到 {{ filteredNews.length }} 則符合的消息。</p>
      </div>

      <!-- 消息列表 -->
      <div v-if="isLoading" class="space-y-3">
        <div v-for="index in 4" :key="index" class="h-24 animate-pulse rounded-xl bg-surface-container-lowest" />
      </div>

      <div v-else-if="!newsItems.length" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-on-surface-variant">
        目前沒有任何消息。
      </div>

      <div v-else-if="!filteredNews.length" class="rounded-xl bg-surface-container-lowest p-8 text-center text-base text-on-surface-variant">
        找不到符合的消息。
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="item in filteredNews"
          :key="item.id"
          class="flex items-center gap-4 rounded-xl bg-surface-container-lowest p-3 shadow-sm md:p-4"
        >
          <img :src="item.image" :alt="item.alt" loading="lazy" class="aspect-[4/3] w-24 shrink-0 rounded-lg bg-surface-container-low object-cover md:w-32" />
          <div class="min-w-0 flex-1">
            <p class="text-xs font-bold text-on-surface-variant">
              <span class="text-primary">{{ item.tag }}</span> • {{ item.date }}
            </p>
            <p class="mt-1 truncate font-bold text-on-surface">{{ item.title }}</p>
            <p class="mt-0.5 truncate text-sm text-on-surface-variant">{{ item.description }}</p>
          </div>
          <div class="flex shrink-0 flex-col gap-2 sm:flex-row">
            <Button variant="outline" size="sm" class="rounded-lg font-bold" @click="openEdit(item)">
              編輯
            </Button>
            <Button
              variant="outline"
              size="sm"
              class="rounded-lg border-error/40 font-bold text-error hover:bg-error/10 hover:text-error"
              :disabled="deletingId === item.id"
              @click="remove(item)"
            >
              {{ deletingId === item.id ? '刪除中…' : '刪除' }}
            </Button>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>
