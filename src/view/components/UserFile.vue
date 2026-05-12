<script setup lang="ts">
// 引入依賴
import { Button } from '@/components/ui/button'
import { useAuth } from '@/composables/useAuth'
import Login from './Login.vue'
import {
  BadgeCheck,
  Package,
  LogOut,
  ShoppingBag,
} from 'lucide-vue-next'
// 引入依賴

// 用戶資料
const {
  currentUser,
  isAuthReady,
  authError,
  userProfile,
  userInitials,
  signOutUser,
} = useAuth()
// 用戶資料

</script>

<template>
  <div class="bg-surface text-on-surface antialiased min-h-screen pb-16 font-body">
    <div v-if="!isAuthReady" class="min-h-[60vh] flex items-center justify-center px-6">
      <div class="rounded-2xl bg-surface-container-lowest px-8 py-6 text-center shadow-sm">
        <p class="font-bold text-on-surface">Checking sign-in status...</p>
        <p class="mt-2 text-sm text-on-surface-variant">Supabase Auth is loading your session.</p>
      </div>
    </div>

    <Login v-else-if="!currentUser" />

    <!-- 用戶個人資訊頭部 -->
    <template v-else>
    <header class="relative pt-16 pb-12 px-6 md:px-8 max-w-4xl mx-auto">
      <div class="flex flex-col items-center text-center gap-6">
        <div class="relative">
          <div class="w-32 h-32 md:w-44 md:h-44 rounded-[40px] overflow-hidden shadow-[0_10px_30px_-5px_rgba(178,34,3,0.08)] border-4 border-surface-container-lowest">
            <img v-if="userProfile.avatar" :alt="userProfile.name" class="w-full h-full object-cover" :src="userProfile.avatar"/>
            <div v-else class="flex h-full w-full items-center justify-center bg-primary text-5xl font-black text-on-primary">
              {{ userInitials }}
            </div>
          </div>
          <div class="absolute -bottom-2 -right-2 bg-primary text-on-primary p-2 rounded-xl shadow-lg border-2 border-surface-container-lowest flex items-center justify-center">
            <BadgeCheck class="w-5 h-5" />
          </div>
        </div>
        <div>
          <h1 class="font-bold text-4xl text-on-surface mb-2 font-headline">{{ userProfile.name }}</h1>
          <p class="text-lg text-outline">{{ userProfile.title }}</p>
          <div class="mt-5">
            <Button variant="outline" class="rounded-full border-outline bg-surface-container-lowest font-bold" @click="signOutUser">
              <LogOut class="mr-2 size-4" />
              Sign out
            </Button>
          </div>
          <p v-if="authError" class="mt-4 text-sm font-medium text-error">{{ authError }}</p>
        </div>
      </div>
    </header>
    <!-- 用戶個人資訊頭部 -->

    <main class="max-w-4xl mx-auto px-6 md:px-8">
      <!-- 購買歷史記錄 -->
      <section class="space-y-6">
        <div class="flex items-center justify-between px-2 mb-2">
          <h2 class="font-bold text-2xl font-headline">Purchase History</h2>
        </div>
        <div class="bg-surface-container-lowest p-10 rounded-[28px] shadow-[0_10px_30px_-5px_rgba(178,34,3,0.08)] border border-outline-variant/30 text-center">
          <div class="mx-auto mb-5 flex size-16 items-center justify-center rounded-2xl bg-surface-container text-primary">
            <Package class="size-8" />
          </div>
          <h3 class="font-headline text-2xl font-black text-on-surface">No purchase records yet</h3>
          <p class="mx-auto mt-2 max-w-md text-sm leading-relaxed text-on-surface-variant">
            Orders placed with this account will appear here after checkout. Start browsing products when you are ready.
          </p>
          <Button as-child class="primary-gradient mt-6 rounded-xl font-bold text-on-primary">
            <RouterLink to="/products">
              <ShoppingBag class="mr-2 size-4" />
              Browse Products
            </RouterLink>
          </Button>
        </div>
      </section>
      <!-- 購買歷史記錄 -->
    </main>
    </template>
  </div>
</template>
