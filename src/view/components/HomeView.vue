<script setup>
// 引入 shadcn 元件
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardFooter } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import CountdownTimer from './CountdownTimer.vue'
// 引入 Lucide 圖示來取代原本的 Material Symbols
import { 
  Shirt, Laptop, Home, Sparkles, Dumbbell, BookOpen, Baby, Gem, 
  Zap, Heart, Star, Home as HomeIcon, Grid, ShoppingBag, User
} from 'lucide-vue-next'

// mockdata (將 icon 換成對應的 Lucide 組件)
const categories = [
  { name: 'Fashion', icon: Shirt },
  { name: 'Tech', icon: Laptop },
  { name: 'Home', icon: Home },
  { name: 'Beauty', icon: Sparkles },
  { name: 'Fitness', icon: Dumbbell },
  { name: 'Media', icon: BookOpen },
  { name: 'Kids', icon: Baby },
  { name: 'Luxury', icon: Gem }
];

const products = [
  {
    id: 1,
    tag: 'Premium Fabric',
    title: 'Tailored Artisan Overcoat',
    price: '385.00',
    rating: '4.9',
    img: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAVgIWz3aNypP-PAxQWxLIacRvzDLxQQXBuecJQs9ls-VIOVA4bG9DTyZ2iA_AxRkIMApKB7YnjvV0aHToi9md4i-1FINFJApZybmyv2AEtkqFRrl057BZW7cWSSDhJucjrMp6addwL9ILJRr7pOOCBlTsXbo4x2WajnalEqr9CZ0nuB3UQf7ABv5r8D5KTW0RrPgwi2Tv7NLBl3l6w0kjPsyCdAlkR1s4k-_9WTrIfuiTYlXwzD4i0YINWfH-BunAeAhnBbQGP_MQ',
    alt: 'high-quality beige wool coat displayed on a simple wooden hanger against a clean white wall'
  },
  {
    id: 2,
    tag: 'Everyday Essential',
    title: 'Urban Canvas High-Top',
    price: '89.00',
    rating: '4.7',
    img: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCs4gt2RmfAWYlK_tWI7CRrbD5V8_o3JAj94sfFC5gcpT0nOfN6vQynEEgOaNp7wunecyXAWhCDKvDGKN3XS0WohJfBSf5-Cks3t3nIS1UyCLfqxf7ULvS9BUUQ63MKAXfaCyF9zz6aL87FkevPWewT-HSN97r-LhfS_6y_SqbBDYAyNLZWpAgWhuV5n7m0X9gVZfswp1mv_bUjdNCHYUcXVkpgkOhN4ObvcZgEk5_vIDOL-jGWCCYCc9MKjfTPFjcfXnrr05ooE9I',
    alt: 'classic white canvas sneakers on a minimal concrete surface with soft morning shadows'
  },
  {
    id: 3,
    tag: 'Home Décor',
    title: 'Symmetry Ceramic Vase',
    price: '45.00',
    rating: '5.0',
    img: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA273pxRHiET0MqX0-kFEtkJhQERCu9LSK_i9R6HGItezDA9PSkQBIjGHNDtIH3qYxyLHjF-dM02_3-t_Rcz6JMI6SGCbT-bRElOVaEaxhhsBxLhIkW5pAcndxrLIN-ExbW6oCejOnZBVeNBU58P5GKndh0Zc4s8NnQOc9Hvh__AAfM_GxU3hrHmYDqc_3o8NucpI5mn8n1AvPv4CBFimX7pSzeJ9S4wdmTZBmjeW9yXRmeRc2O6gNS6_cf-Wq6WMfUDQ74tRnM-Gs',
    alt: 'minimalist ceramic vase with a single dried eucalyptus branch in a sun-drenched room'
  },
  {
    id: 4,
    tag: 'Self Care',
    title: 'Radiance Night Elixir',
    price: '112.00',
    rating: '4.8',
    img: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB0CDX_jbkxCOSGRDvWyEsXP6S3GXzdQG4q6ypt7M9klnvkJrs-3mKsEED3UX4JtayrrgcBg_tHvLnwAuBUIcxprYSGJNaZpY9pXiEBIz73NdU6-AD6PFHXSoZhYOsc9uqMCh-axiC6kC1zzU2w1Q1gEIkruWWEr63No6SwWLwC9VJn3urQDMvd6vKMLnJbqggot-jcBLnTeAJquJhpsd0zBNgIaN6uJEqA_2na5Y2F2ObQHRWHDwGl-oV5ZC7zH0qeGCQbQZFsLDU',
    alt: 'premium high-end skin cream in a frosted glass jar with gold lid on a marble surface'
  }
];

const flashSaleItems = [
  {
    id: 'f1', // 第一筆永遠是主打商品 (大卡片)
    title: 'Chronos Minimalist Series',
    price: '$249.00',
    originalPrice: '$420.00',
    tag: '40% OFF',
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCS6aDbrbCrrlZHDnkTmKh25SySzFX9RP3BjQXaEI0fN25FZlDu5wxtJi29SDZ0jjMhyZEgisrPUGuH5z2zKZ8wAfW1FCD0oL03qOxeWtnXat-3SkVtOWMXgzOF09-L3qqjJKKBzZbldOhgGF9V9xHhboOLVcGVyYMvX19GT2KMR97pbZzA1lrKCif2HrtTzGVKQCAatWC6HM7ppgbqI3zg6AZfkzoASxSTSEd15_Qxhf9Dib0iiJxR4fk-LJMfwLq-15xxgD0E_hU'
  },
  {
    id: 'f2',
    title: 'Velocity Run Pro',
    price: '$120',
    tag: 'SALE',
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuALcfjCgCF9-2VyM3uUGNcEEIRq_OfvKOzED6wXLvkyFXCWffyoiQjhGFjTFNj4SwmF3mHd3h3sQ8DXpUtH3niEU0ifHxHvXXCpXD4xa9OnY_fQIFvs-vZTY7ym2aDVs7OCP8BMI9_S-4brgIQvlmTSAIGwBAlUl25jFeemwv1Tq84a4ENLAEiKc6P1kaq-2lngx2KK01vpiByaQVVpvNwjF8RdMKAJPwkBtOAbiHkFKZjqm5dcnOUIjmZ8A4m6qsWuM_wrG8hBYkg'
  },
  {
    id: 'f3',
    title: 'Acoustic Pure Over-Ear',
    price: '$185',
    tag: 'LAST FEW',
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3ivThTKfJYIMC1vA0z5rYigzHDnDIyDkL-EX27cbxZpdeydfbEqtoCkxTKh36sY8LbVKb7nQMyPOp9fZ_bzTG1I0M9zWBJjtAn7ZFZOATh_UAYeCxm4_vOj036h0t90UHbpK8gYtzk3JEUOvRflhXxYWLdcD9lsH5EC1NmEiK0WSDBW6X02ga-YtaIA_Ydklxs6DuyzZVJszdCdytoYQsQmhaEHFmjV5tB9R4STranc--cftVfb3P7kZ2m1LZxZwWJ0lA8Ehqd9I'
  },
  {
    id: 'f4',
    title: 'Lumina Desk Architect',
    price: '$79',
    tag: 'TOP PICK',
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDqxooAJ9LDHZVzIiz1_ijaePfHKqSMW4XwxIp7mLcz8ZyfnF5c6YlyXtoTAiTVhHHXNliq8cXXQBTiwG9udrLWBhate1Iz7pyD7NnUMCOcZX9GdagzvE0kBGbTbEPCno4GxrIjF32N9NH7doMd7Hyh16TNdo0JVPEbtXs3alTH32544CRE-m-8gphmCMxVpu8PYe-SWx1cfrImh9a4gx9DxRRJAn7gAOxGlw0whAoLY3-1Tgyzai9rxh-r1z6E8M9J_RXvzulqSJw'
  },
  {
    id: 'f5',
    title: 'RetroSnap Instant 2.0',
    price: '$145',
    tag: 'NEW',
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC_JN52CUdo7ClN0rtcaan77JTi4Uu88-byZuN8dsiiB-WstlQ5_CITPPP8TuAC2sbw0-q42-UDd1myLQBJozRt5-WUdsqHJhpS0msD1nKj7lGdpngdskO0E7ggPnfvNwW70u5VBVgtmLhu3zDPHqvdxzP8Qou9Q2fvLYTt0JImEQHCR8EIdrPhkFvtbr5XWJREwZmRFUYCMgeQrNkXcvYEjDvLLx9x7EYLa301wih8115HPF6wW-JPIQBw334Yu2uAwb1LhA3710w'
  }
]

</script>

<template>
  <div class="bg-surface font-body text-on-surface antialiased min-h-screen">
    
    <main >
      <!-- 封面形象照 -->
      <section class="px-6 mb-12">
        <div class="relative w-full h-[480px] rounded-xl overflow-hidden group">
          <img alt="minimalist fashion boutique" class="w-full h-full object-cover" src="@/assets/—Pngtree—supermarket blur background_15628023.png"/>
          <div class="absolute inset-0 bg-gradient-to-r from-black/60 to-transparent flex items-center px-16">
            <div class="max-w-xl text-white">
              <span class="inline-block  py-1.5 rounded-full font-bold text-s uppercase tracking-widest mb-4">The Summer Edit '26</span>
              <h1 class="text-5xl font-extrabold font-headline leading-tight mb-8">Small Goods<br/>Big Joy</h1>
              <!-- <p class="text-lg text-white/80 mb-8 font-body">Discover a curated selection of minimalist essentials designed for the modern professional.</p> -->
              <div class="flex">
                <Button as-child size="lg" class="primary-gradient text-on-primary font-bold shadow-lg hover:opacity-80">
                  <RouterLink to="/products">
                    Start Shopping
                  </RouterLink>
                </Button>
              </div>
            </div>
          </div>
        </div>
      </section>
      <!-- 封面形象照 -->
      <!-- sales -->
      <section class="px-6 mb-16">
        <!-- sales最上方說明 -->
        <div class="flex justify-between  mb-8">
          <div>
            <div class="flex items-center gap-3 mb-1">
              <Zap class="text-primary fill-primary size-8" />  
              <h2 class="text-2xl font-bold font-headline text-on-surface uppercase tracking-tight">Discount</h2>
            </div>
            <p class="text-outline">Premium pieces, limited time, exclusive prices.</p>
          </div>
          <CountdownTimer targetDate="2026-12-31T23:59:59" />
        </div>
        <!-- sales最上方說明 -->
        <!-- sales商品展示 -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
          <!-- 左邊大圖 -->
          <Card class="md:col-span-2 md:row-span-2 bg-surface-container-lowest border-none overflow-hidden group hover:shadow-2xl transition-all duration-500 relative">
            <div class="h-full aspect-square md:aspect-auto">
              <img :alt="flashSaleItems[0].title" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700" :src="flashSaleItems[0].image"/>
            </div>
            <div class="absolute bottom-0 left-0 right-0 p-8 bg-gradient-to-t from-white via-white/90 to-transparent">
              <p class="text-primary font-bold text-sm mb-2">{{ flashSaleItems[0].tag }}</p>
              <h3 class="text-2xl font-bold mb-2">{{ flashSaleItems[0].title }}</h3>
              <div class="flex items-center gap-4">
                <span class="text-2xl font-black text-on-surface">{{ flashSaleItems[0].price }}</span>
                <span class="text-outline line-through text-sm">{{ flashSaleItems[0].originalPrice }}</span>
              </div>
              <Button as-child class="mt-6 w-full primary-gradient text-white font-bold opacity-0 translate-y-4 group-hover:opacity-100 group-hover:translate-y-0 transition-all duration-300 ">
                <RouterLink to="/products">DETAILS</RouterLink>
              </Button>
            </div>
          </Card>
          <!-- 左邊大圖 -->
          <!-- 右邊四小圖 -->
          <Card v-for="item in flashSaleItems.slice(1)" :key="item.id" class="bg-surface-container-lowest border-none p-4 group hover:-translate-y-1 transition-all shadow-sm flex flex-col justify-between">
            <div>
              <div class="aspect-square rounded-lg overflow-hidden mb-4 bg-surface-container-low">
                <img :alt="item.title" class="w-full h-full object-cover mix-blend-multiply" :src="item.image"/>
              </div>
              <h4 class="font-bold text-on-surface truncate">{{ item.title }}</h4>
            </div>
            
            <div class="flex justify-between items-center mt-4">
              <span class="text-primary font-bold text-lg">{{ item.price }}</span>
              
              <Button as-child class="primary-gradient text-white font-bold opacity-0 translate-y-4 group-hover:opacity-100 group-hover:translate-y-0 transition-all duration-300 px-4 h-8 text-xs ">
                <RouterLink to="/products">DETAILS</RouterLink>
              </Button>
            </div>
          </Card>
          <!-- 右邊四小圖 -->
        </div>
        <!-- sales商品展示 -->
      </section>
      <!-- sales -->
    </main>
  </div>
</template>

<style>
@layer base {
  :root {
    --primary: #b22203;
    --primary-container: #ff775b;
    --on-primary: #ffefec;
    --on-primary-container: #4b0700;
    --secondary-container: #bdd2ff;
    --on-secondary-container: #004592;
    --surface: #f6f6f8;
    --surface-container-low: #f0f1f3;
    --surface-container-highest: #dbdde0;
    --surface-container-lowest: #ffffff;
    --on-surface: #2d2f31;
    --on-surface-variant: #5a5c5d;
    --outline: #757779;
    --outline-variant: #acadaf;
    --error-container: #f74b6d;
    --on-error-container: #510017;
  }
}

</style>  