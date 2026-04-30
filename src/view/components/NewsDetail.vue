<template>
  <!-- 最外層容器，取代原本的 body 樣式 -->
  <div class="article-page bg-surface font-body-md text-on-surface selection:bg-primary-container selection:text-on-primary">
    <main class="min-h-screen">
      <div class="max-w-[800px] mx-auto px-gutter py-lg md:py-xl">
        
        <!-- Back Button -->
        <a 
          href="#" 
          @click.prevent="goBack"
          class="inline-flex items-center gap-xs text-primary-container font-label-bold hover:translate-x-[-4px] transition-transform duration-200 mb-lg group"
        >
          <span class="material-symbols-outlined">arrow_back</span>
          <span>Back to News</span>
        </a>

        <!-- Article Header -->
        <header class="mb-lg">
          <div class="flex items-center gap-sm mb-md">
            <span class="bg-surface-container-high text-primary-container px-3 py-1 rounded-full text-[12px] font-bold tracking-widest uppercase">
              {{ article.category }}
            </span>
            <span class="text-on-surface-variant/60 text-label-bold">•</span>
            <time class="text-on-surface-variant text-label-bold" :datetime="article.dateRaw">
              {{ article.dateFormatted }}
            </time>
            <span class="text-on-surface-variant/60 text-label-bold">•</span>
            <span class="text-on-surface-variant text-label-bold">{{ article.readTime }}</span>
          </div>
          
          <h1 class="font-display-xl text-display-xl text-on-surface leading-tight mb-md">
            {{ article.title }}
          </h1>
        </header>

        <!-- Featured Image -->
        <div class="relative w-full aspect-video rounded-[32px] overflow-hidden shadow-[0_20px_50px_rgba(178,34,3,0.12)] mb-xl">
          <img 
            :alt="article.imageAlt" 
            class="w-full h-full object-cover" 
            :src="article.imageUrl"
          />
        </div>

        <!-- Article Content -->
        <article class="prose prose-zinc max-w-none">
          <p class="font-body-lg text-body-lg text-on-surface-variant leading-relaxed mb-lg">
            {{ article.content.intro }}
          </p>
          
          <h2 class="font-headline-md text-headline-md text-on-surface mt-xl mb-md">
            {{ article.content.sectionTitle }}
          </h2>
          
          <p class="font-body-md text-body-md text-on-surface-variant leading-relaxed mb-md">
            {{ article.content.sectionBody1 }}
          </p>
          
          <blockquote class="border-l-4 border-primary-container bg-surface-container-low p-lg my-lg rounded-r-2xl">
            <p class="font-headline-md italic text-primary-container leading-snug">
              {{ article.content.quote.text }}
            </p>
            <cite class="block mt-md text-label-bold not-italic text-on-surface-variant">
              — {{ article.content.quote.author }}
            </cite>
          </blockquote>
          
          <p class="font-body-md text-body-md text-on-surface-variant leading-relaxed mb-xl">
            {{ article.content.sectionBody2 }}
          </p>
        </article>

        <!-- Share Row -->
        <section class="border-t border-outline-variant/50 pt-lg mt-xl flex flex-col md:flex-row md:items-center justify-between gap-md">
          <div class="flex items-center gap-md">
            <span class="text-label-bold text-on-surface-variant uppercase tracking-wider">Share this article</span>
            <div class="flex gap-xs">
              <button class="w-10 h-10 flex items-center justify-center rounded-full border border-outline-variant hover:bg-surface-container-high transition-colors">
                <span class="material-symbols-outlined text-on-surface-variant text-body-md">share</span>
              </button>
              <button class="w-10 h-10 flex items-center justify-center rounded-full border border-outline-variant hover:bg-surface-container-high transition-colors">
                <span class="material-symbols-outlined text-on-surface-variant text-body-md">link</span>
              </button>
            </div>
          </div>
          
          <div class="flex gap-sm">
            <button class="flex items-center gap-xs px-md py-xs rounded-full border border-primary-container text-primary-container font-label-bold hover:bg-primary-container hover:text-on-primary transition-all">
              <span class="material-symbols-outlined text-[18px]">bookmark</span>
              Save for later
            </button>
          </div>
        </section>

      </div>
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue'

// 如果有使用 Vue Router，可以引入 useRouter
// import { useRouter } from 'vue-router'
// const router = useRouter()

const goBack = () => {
  // router.back()
  console.log('Return to previous page')
}

// 模擬從 API 獲取的文章資料
const article = ref({
  category: 'GLOBAL EXPANSION',
  dateRaw: '2024-10-24',
  dateFormatted: 'Oct 24, 2024',
  readTime: '6 min read',
  title: 'Kinetic Scaling: Redefining Logistics Infrastructure in Emerging Markets',
  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBvUem801bZe11XWswiTy0LRr-N78E-YDzNQPYkRPxJIutxsGfMcrxMSt2xjwoRzgEG5tXa8Xca3TcCdg7SFSyUAst0ipObB21gCZrl9eyUn9J7VdY-oxxN4A2Zv4spF4FkRJm_28PWjnd1xgvN6R73m0WyYbKms8TOTRmxOYkcEiTv9fm1KeG_ua0BFVuYdPZJAKqEtZlhy8Xxe78DJXhuqV-O8hPYMQ6FffuYQYv0AufYRuiDS7G6cFXH4ouHEPN9QREB-o3-E2I',
  imageAlt: 'Modern minimalist corporate office building with clean glass lines and concrete textures under bright natural daylight',
  content: {
    intro: 'In an era defined by rapid digital transformation, Kinetic is taking a bold step forward by physicalizing the digital shelf. Our recent initiatives across the Southeast Asian corridor mark a pivotal shift from traditional warehousing to agile, tech-enabled fulfillment hubs.',
    sectionTitle: 'Bridging the Infrastructure Gap',
    sectionBody1: 'The challenge has never been a lack of demand, but rather a lack of connective tissue. By integrating proprietary AI-routing with architectural precision, Kinetic has managed to reduce last-mile delivery windows by 40% in previously unreachable zones.',
    quote: {
      text: '"Expansion is not merely about geographic presence; it is about the structural integrity of the service we provide to every merchant, regardless of their location."',
      author: 'Elena Rossi, Chief Operating Officer'
    },
    sectionBody2: 'As we look toward 2025, our focus remains on "Dynamic Professionalism"—a core brand pillar that demands we move fast without breaking the trust of our enterprise partners. The new centers are not just storage facilities; they are the heart of a local economy, powered by Kinetic\'s vision of a unified digital workspace.'
  }
})
</script>

<style scoped>
.article-page {
  /* 將原本 body 的漸層背景移到這裡 */
  background-image: 
    radial-gradient(at 0% 0%, rgba(178,34,3,0.03) 0px, transparent 50%), 
    radial-gradient(at 100% 100%, rgba(178,34,3,0.02) 0px, transparent 50%);
}

.material-symbols-outlined {
  font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
}
</style>