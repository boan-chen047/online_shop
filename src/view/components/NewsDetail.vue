<script setup lang="ts">
// 引入依賴
import { computed } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { Button } from '@/components/ui/button'
import { getNewsById, newsItems } from '@/data/news'
import { ArrowLeft, Share2, Link, Bookmark } from 'lucide-vue-next'
// 引入依賴

// 文章資料
const route = useRoute()
const article = computed(() => {
  const id = Number(route.params.id)
  return getNewsById(id) ?? newsItems[0]
})
// 文章資料

</script>

<template>
  <div class="article-bg bg-surface font-body text-on-surface antialiased">
    <main class="min-h-screen">
      <div class="max-w-200 mx-auto px-6 py-12 md:py-16">

        <!-- 返回按鈕 -->
        <RouterLink
          to="/news"
          class="inline-flex items-center gap-2 text-primary font-bold hover:-translate-x-1 transition-transform duration-200 mb-8 group"
        >
          <ArrowLeft class="size-4" />
          <span>Back to News</span>
        </RouterLink>
        <!-- 返回按鈕 -->

        <!-- 文章標題 -->
        <header class="mb-8">
          <div class="flex items-center gap-3 mb-6">
            <span class="bg-surface-container-highest text-primary px-3 py-1 rounded-full text-xs font-bold tracking-widest uppercase">
              {{ article.tag }}
            </span>
            <span class="text-on-surface-variant/60 text-xs font-bold">•</span>
            <time class="text-on-surface-variant text-xs font-bold" :datetime="article.dateRaw">
              {{ article.date }}
            </time>
            <span class="text-on-surface-variant/60 text-xs font-bold">•</span>
            <span class="text-on-surface-variant text-xs font-bold">{{ article.readTime }}</span>
          </div>

          <h1 class="font-headline font-extrabold text-4xl text-on-surface leading-tight mb-6">
            {{ article.title }}
          </h1>
        </header>
        <!-- 文章標題 -->

        <!-- 特色圖片 -->
        <div class="relative w-full aspect-video rounded-4xl overflow-hidden shadow-[0_20px_50px_rgba(178,34,3,0.12)] mb-12">
          <img
            :alt="article.alt"
            class="w-full h-full object-cover"
            :src="article.image"
          />
        </div>
        <!-- 特色圖片 -->

        <!-- 文章內容 -->
        <article class="prose prose-zinc max-w-none">
          <p class="font-body text-lg text-on-surface-variant leading-relaxed mb-8">
            {{ article.content.intro }}
          </p>

          <h2 class="font-headline font-bold text-2xl text-on-surface mt-12 mb-6">
            {{ article.content.sectionTitle }}
          </h2>

          <p class="font-body text-base text-on-surface-variant leading-relaxed mb-6">
            {{ article.content.sectionBody1 }}
          </p>

          <blockquote class="border-l-4 border-primary bg-surface-container-low p-6 my-8 rounded-r-2xl">
            <p class="font-headline italic text-primary leading-snug">
              {{ article.content.quote.text }}
            </p>
            <cite class="block mt-4 text-xs font-bold not-italic text-on-surface-variant">
              — {{ article.content.quote.author }}
            </cite>
          </blockquote>

          <p class="font-body text-base text-on-surface-variant leading-relaxed mb-12">
            {{ article.content.sectionBody2 }}
          </p>
        </article>
        <!-- 文章內容 -->

        <!-- 分享區域 -->
        <section class="border-t border-outline-variant/50 pt-6 mt-12 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex items-center gap-4">
            <span class="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Share this article</span>
            <div class="flex gap-2">
              <Button variant="outline" size="icon" class="rounded-full border-outline-variant hover:bg-surface-container-high">
                <Share2 class="size-4 text-on-surface-variant" />
              </Button>
              <Button variant="outline" size="icon" class="rounded-full border-outline-variant hover:bg-surface-container-high">
                <Link class="size-4 text-on-surface-variant" />
              </Button>
            </div>
          </div>

          <Button variant="outline" class="flex items-center gap-2 rounded-full border-primary text-primary hover:bg-primary hover:text-on-primary transition-all">
            <Bookmark class="size-4" />
            Save for later
          </Button>
        </section>
        <!-- 分享區域 -->

      </div>
    </main>
  </div>
</template>

<style scoped>
.article-bg {
  background-image:
    radial-gradient(at 0% 0%, rgba(178,34,3,0.03) 0px, transparent 50%),
    radial-gradient(at 100% 100%, rgba(178,34,3,0.02) 0px, transparent 50%);
}
</style>
