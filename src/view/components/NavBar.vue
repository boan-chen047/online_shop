<script setup lang="ts">
import { useRoute, RouterLink } from 'vue-router'
import { Input } from '@/components/ui/input'
import { cn } from '@/lib/utils'
import { useAuth } from '@/composables/useAuth'
import { useCart } from '@/composables/useCart'
import {
  NavigationMenu,
  NavigationMenuContent,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
  NavigationMenuTrigger,
} from '@/components/ui/navigation-menu'

import { 
  Search, ShoppingCart, User,
  LayoutGrid, Cookie, Coffee, Laptop, Watch,
  Home as HomeIcon, Grid, ShoppingBag
} from 'lucide-vue-next'

// 商品類別定義
const products = [
  { name: '全部', icon: LayoutGrid, path: '/products' },
  { name: '零食', icon: Cookie, path: '/products?category=snacks' },
  { name: '飲料', icon: Coffee, path: '/products?category=beverages' },
  { name: '生活用品', icon: HomeIcon, path: '/products?category=daily' },
  { name: '電子設備', icon: Laptop, path: '/products?category=electronics' },
  { name: '手錶', icon: Watch, path: '/products?category=watches' }
]

const route = useRoute()
const { itemCount } = useCart()
const { currentUser, userProfile, userInitials } = useAuth()

/**
 * 導覽列動態樣式邏輯
 * 1. 判斷 isActive：首頁需精準匹配，其他路徑使用 startsWith 匹配。
 * 2. 套用 after 偽元素：實現底線動畫。
 * 3. 狀態切換：根據 isActive 決定顏色與底線是否展開。
 */
const navItemClass = (path: string) => {
  const isActive = path === '/' ? route.path === '/' : route.path.startsWith(path)

  return cn(
    // 基礎排版：統一高度與間距，移除背景
    'h-10 px-4 py-2 font-bold relative transition-colors cursor-pointer inline-flex items-center justify-center rounded-md text-sm',
    'bg-transparent hover:bg-transparent data-[state=open]:bg-transparent',
    // 隱形底線動畫設定
    'after:absolute after:bottom-0 after:left-4 after:right-4 after:h-[2px] after:bg-primary after:transition-transform after:duration-300 after:origin-center',
    // 根據 active 狀態套用樣式
    isActive
      ? 'text-primary after:scale-x-100 data-[state=open]:text-primary' 
      : 'text-on-surface-variant hover:text-primary after:scale-x-0 hover:after:scale-x-100 data-[state=open]:text-primary data-[state=open]:after:scale-x-100' 
  )
}
</script>

<template>
  <nav class="fixed top-0 w-full z-50 bg-[#f6f6f8]/80 dark:bg-gray-900/80 backdrop-blur-xl border-b border-border/40 shadow-sm font-['Plus_Jakarta_Sans'] antialiased">
    <div class="mx-auto flex max-w-[94vw] items-center justify-between px-5 py-4">
      
      <div class="flex items-center gap-6">
        <RouterLink to="/" class="text-2xl font-bold tracking-tighter text-primary mr-4">
          Shopping
        </RouterLink>
        
        <div class="hidden md:flex items-center gap-1">
          <RouterLink to="/" :class="navItemClass('/')">
            Home
          </RouterLink>
          
          <NavigationMenu>
            <NavigationMenuList>
              <NavigationMenuItem>
                <NavigationMenuTrigger :class="navItemClass('/products')" class="hover:bg-transparent focus:bg-transparent data-[state=open]:bg-transparent">
                  Product
                </NavigationMenuTrigger>
                
                <NavigationMenuContent>
                  <div class="w-[750px] p-6 bg-surface-container-lowest shadow-2xl rounded-2xl border border-outline-variant/10">
                    <div class="flex justify-between items-center mb-6 px-2">
                      <h3 class="font-bold text-lg font-headline text-on-surface">Explore Categories</h3>
                      <RouterLink to="/products" class="text-xs text-primary font-bold hover:underline">View All &rarr;</RouterLink>
                    </div>

                    <div class="grid grid-cols-6 gap-3">
                      <NavigationMenuLink as-child v-for="cat in products" :key="cat.name">
                        <RouterLink 
                          :to="cat.path" 
                          class="flex flex-col items-center justify-center gap-3 p-4 rounded-xl border border-surface-container hover:border-primary hover:bg-primary/5 transition-all group/item"
                        >
                          <component :is="cat.icon" class="size-8 text-outline group-hover/item:text-primary transition-colors" />
                          <span class="text-sm font-bold text-on-surface group-hover/item:text-primary whitespace-nowrap">{{ cat.name }}</span>
                        </RouterLink>
                      </NavigationMenuLink>
                    </div>
                  </div>
                </NavigationMenuContent>
              </NavigationMenuItem>
            </NavigationMenuList>
          </NavigationMenu>

          <RouterLink to="/news" :class="navItemClass('/news')">
            News
          </RouterLink>
        </div>
      </div>
      
      <div class="flex-1 max-w-xl mx-8 hidden lg:block">
        <div class="relative flex items-center w-full">
          <Input 
            type="text" 
            placeholder="Search curated collections..." 
            class="w-full bg-surface-container-highest dark:bg-muted border-none focus-visible:ring-1 focus-visible:ring-primary rounded-full pl-6 pr-10 py-5 text-sm"
          />
          <span class="absolute end-0 inset-y-0 flex items-center justify-center px-4">
            <Search class="size-4 text-muted-foreground" />
          </span>
        </div>
      </div>
      
      <div class="hidden md:flex items-center gap-1">
        <RouterLink to="/cart" :class="navItemClass('/cart')" class="gap-2">
          <span class="relative">
            <ShoppingCart class="size-5" />
            <span v-if="itemCount" class="absolute -right-2 -top-2 flex min-w-4 h-4 items-center justify-center rounded-full bg-primary px-1 text-[10px] leading-none text-on-primary">
              {{ itemCount }}
            </span>
          </span>
          <span class="font-bold text-xs">Shopping Cart</span>
        </RouterLink>
        
        <RouterLink to="/userfile" :class="navItemClass('/userfile')" class="gap-2">
          <img v-if="currentUser && userProfile.avatar" :src="userProfile.avatar" :alt="userProfile.name" class="size-6 rounded-full object-cover">
          <span v-else-if="currentUser" class="flex size-6 items-center justify-center rounded-full bg-primary text-[10px] font-black text-on-primary">
            {{ userInitials }}
          </span>
          <User v-else class="size-5" />
          <span class="font-bold text-xs">{{ currentUser ? userProfile.name : 'User Profile' }}</span>
        </RouterLink>
      </div>
      
    </div>
  </nav>

  <nav class="fixed bottom-0 left-0 right-0 bg-white/80 glass-effect md:hidden z-50 flex justify-around items-center py-3 border-t shadow-[0_-4px_24px_rgba(0,0,0,0.06)]">
    <RouterLink to="/" class="flex flex-col items-center gap-1 text-primary">
      <HomeIcon class="size-6 fill-primary" />
      <span class="text-[10px] font-bold">Home</span>
    </RouterLink>
    <RouterLink to="/products" class="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors">
      <Grid class="size-6" />
      <span class="text-[10px] font-bold">Browse</span>
    </RouterLink>
    <RouterLink to="/cart" class="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors">
      <span class="relative">
        <ShoppingBag class="size-6" />
        <span v-if="itemCount" class="absolute -right-2 -top-2 flex min-w-4 h-4 items-center justify-center rounded-full bg-primary px-1 text-[10px] leading-none text-on-primary">
          {{ itemCount }}
        </span>
      </span>
      <span class="text-[10px] font-bold">Cart</span>
    </RouterLink>
    <RouterLink to="/userfile" class="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors">
      <img v-if="currentUser && userProfile.avatar" :src="userProfile.avatar" :alt="userProfile.name" class="size-6 rounded-full object-cover">
      <span v-else-if="currentUser" class="flex size-6 items-center justify-center rounded-full bg-primary text-[10px] font-black text-on-primary">
        {{ userInitials }}
      </span>
      <User v-else class="size-6" />
      <span class="text-[10px] font-bold">Account</span>
    </RouterLink>
  </nav>
</template>

<style scoped>
.glass-effect { backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px); }
</style>
