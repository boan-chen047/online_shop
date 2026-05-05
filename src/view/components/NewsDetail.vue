<script setup>
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { ArrowLeft, Share2, Link, Bookmark } from 'lucide-vue-next'

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

<template>
  <div class="article-bg bg-surface font-body text-on-surface antialiased">
    <main class="min-h-screen">
      <div class="max-w-200 mx-auto px-6 py-12 md:py-16">

        <!-- Back Button -->
        <RouterLink
          to="/news"
          class="inline-flex items-center gap-2 text-primary font-bold hover:-translate-x-1 transition-transform duration-200 mb-8 group"
        >
          <ArrowLeft class="size-4" />
          <span>Back to News</span>
        </RouterLink>

        <!-- Article Header -->
        <header class="mb-8">
          <div class="flex items-center gap-3 mb-6">
            <span class="bg-surface-container-highest text-primary px-3 py-1 rounded-full text-xs font-bold tracking-widest uppercase">
              {{ article.category }}
            </span>
            <span class="text-on-surface-variant/60 text-xs font-bold">•</span>
            <time class="text-on-surface-variant text-xs font-bold" :datetime="article.dateRaw">
              {{ article.dateFormatted }}
            </time>
            <span class="text-on-surface-variant/60 text-xs font-bold">•</span>
            <span class="text-on-surface-variant text-xs font-bold">{{ article.readTime }}</span>
          </div>

          <h1 class="font-headline font-extrabold text-4xl text-on-surface leading-tight mb-6">
            {{ article.title }}
          </h1>
        </header>

        <!-- Featured Image -->
        <div class="relative w-full aspect-video rounded-4xl overflow-hidden shadow-[0_20px_50px_rgba(178,34,3,0.12)] mb-12">
          <img
            :alt="article.imageAlt"
            class="w-full h-full object-cover"
            :src="article.imageUrl"
          />
        </div>

        <!-- Article Content -->
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

        <!-- Share Row -->
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
