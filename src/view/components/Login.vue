<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useAuth } from '@/composables/useAuth'
import { BadgeCheck, LogIn } from 'lucide-vue-next'

const {
  currentUser,
  isAuthReady,
  isSigningIn,
  authError,
  authNotice,
  userProfile,
  userInitials,
  signInWithEmail,
  signInWithGoogle,
  signUpWithEmail,
  signOutUser,
  sendPasswordReset,
} = useAuth()

const route = useRoute()
const router = useRouter()

// 若是被守衛導來登入頁（帶 redirect），登入成功後導回原本要去的頁面。
// 僅接受站內路徑（以單一 / 開頭），避免被導向外部網址（open redirect）。
watch(currentUser, (user) => {
  if (!user) {
    return
  }

  const redirect = route.query.redirect
  if (typeof redirect === 'string' && redirect.startsWith('/') && !redirect.startsWith('//')) {
    void router.replace(redirect)
  }
}, { immediate: true })

const authMode = ref<'sign-in' | 'sign-up' | 'reset'>('sign-in')
const email = ref('')
const password = ref('')
const rememberMe = ref(false)

// 「記住我」只記住電子郵件（不存密碼明文）；密碼交給瀏覽器自己的密碼管理儲存。
// 保持登入靠 Supabase 的持久 session（persistSession），登入一次後不用每次重登。
const REMEMBERED_EMAIL_KEY = 'shop_remembered_email'

onMounted(() => {
  try {
    const saved = localStorage.getItem(REMEMBERED_EMAIL_KEY)
    if (saved) {
      email.value = saved
      rememberMe.value = true
    }
  } catch {
    // 無痕模式或封鎖儲存時讀取會失敗，略過即可
  }
})

function persistRememberedEmail() {
  try {
    if (rememberMe.value) {
      localStorage.setItem(REMEMBERED_EMAIL_KEY, email.value.trim())
    } else {
      localStorage.removeItem(REMEMBERED_EMAIL_KEY)
    }
  } catch {
    // 略過
  }
}

const submitLabel = computed(() => {
  if (authMode.value === 'sign-up') return '建立帳號'
  if (authMode.value === 'reset') return '寄送重設連結'
  return '登入'
})

async function handleSubmit() {
  if (authMode.value === 'reset') {
    await sendPasswordReset(email.value)
    return
  }

  persistRememberedEmail()

  if (authMode.value === 'sign-in') {
    await signInWithEmail(email.value, password.value)
    return
  }

  await signUpWithEmail(email.value, password.value)
}

// 切換模式時清掉上一個模式殘留的提示訊息
function setMode(mode: 'sign-in' | 'sign-up' | 'reset') {
  authMode.value = mode
  authError.value = ''
  authNotice.value = ''
}
</script>

<template>
  <div class="min-h-[calc(100vh-72px)] bg-surface px-5 py-10 text-on-surface">
    <main class="mx-auto max-w-xl rounded-2xl bg-surface-container-lowest p-6 shadow-sm sm:p-8">
        <div class="mb-6">
          <h2 class="font-headline text-3xl font-black">登入</h2>
          <p class="mt-2 text-sm text-on-surface-variant">登入帳號以繼續購物。</p>
        </div>

        <div v-if="!isAuthReady" class="rounded-xl bg-surface-container-low p-6 text-center">
          <p class="font-bold text-on-surface">確認登入狀態中…</p>
        </div>

        <div v-else-if="currentUser" class="rounded-2xl bg-surface-container-low p-6 text-center">
          <div class="mx-auto mb-4 size-20 overflow-hidden rounded-2xl bg-primary text-on-primary">
            <img v-if="userProfile.avatar" :src="userProfile.avatar" :alt="userProfile.name" class="h-full w-full object-cover">
            <div v-else class="flex h-full w-full items-center justify-center text-2xl font-black">
              {{ userInitials }}
            </div>
          </div>
          <BadgeCheck class="mx-auto mb-3 size-6 text-primary" />
          <h3 class="font-headline text-2xl font-black">{{ userProfile.name }}</h3>
          <p class="mt-1 text-sm text-on-surface-variant">{{ userProfile.email }}</p>
          <div class="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
            <Button as-child class="primary-gradient rounded-xl font-bold text-on-primary">
              <RouterLink to="/userfile">會員中心</RouterLink>
            </Button>
            <Button variant="outline" class="rounded-xl bg-surface-container-lowest font-bold" @click="signOutUser">
              登出
            </Button>
          </div>
        </div>

        <div v-else>
          <form class="space-y-4" @submit.prevent="handleSubmit">
            <div v-if="authMode !== 'reset'" class="grid grid-cols-2 rounded-xl bg-surface-container-low p-1">
              <button
                type="button"
                class="rounded-lg px-3 py-2 text-sm font-bold transition-colors"
                :class="authMode === 'sign-in' ? 'bg-surface-container-lowest text-primary shadow-sm' : 'text-on-surface-variant'"
                @click="setMode('sign-in')"
              >
                登入
              </button>
              <button
                type="button"
                class="rounded-lg px-3 py-2 text-sm font-bold transition-colors"
                :class="authMode === 'sign-up' ? 'bg-surface-container-lowest text-primary shadow-sm' : 'text-on-surface-variant'"
                @click="setMode('sign-up')"
              >
                註冊
              </button>
            </div>

            <p v-if="authMode === 'reset'" class="rounded-xl bg-surface-container-low px-4 py-3 text-sm text-on-surface-variant">
              輸入註冊時的電子郵件，我們會寄一封重設密碼的連結給你。
            </p>

            <label class="block">
              <span class="mb-2 block text-sm font-bold text-on-surface">電子郵件</span>
              <Input v-model="email" type="email" autocomplete="email" required placeholder="you@example.com" class="h-12 rounded-xl bg-surface-container-lowest" />
            </label>

            <label v-if="authMode !== 'reset'" class="block">
              <span class="mb-2 block text-sm font-bold text-on-surface">密碼</span>
              <Input
                v-model="password"
                type="password"
                :autocomplete="authMode === 'sign-in' ? 'current-password' : 'new-password'"
                required
                minlength="6"
                placeholder="至少 6 個字元"
                class="h-12 rounded-xl bg-surface-container-lowest"
              />
            </label>

            <div v-if="authMode === 'sign-in'" class="flex items-center justify-between gap-3">
              <label class="flex items-center gap-2 text-sm font-medium text-on-surface-variant">
                <input v-model="rememberMe" type="checkbox" class="size-4 rounded border-outline-variant accent-primary" />
                記住我的帳號
              </label>
              <button type="button" class="text-sm font-bold text-primary hover:underline" @click="setMode('reset')">
                忘記密碼？
              </button>
            </div>

            <Button class="primary-gradient h-12 w-full rounded-xl font-bold text-on-primary" :disabled="isSigningIn">
              <LogIn class="mr-2 size-4" />
              {{ isSigningIn ? '請稍候…' : submitLabel }}
            </Button>

            <Button
              v-if="authMode !== 'reset'"
              type="button"
              variant="outline"
              class="h-12 w-full rounded-xl bg-surface-container-lowest font-bold"
              :disabled="isSigningIn"
              @click="signInWithGoogle"
            >
              使用 Google 登入
            </Button>

            <button
              v-if="authMode === 'reset'"
              type="button"
              class="w-full text-center text-sm font-bold text-on-surface-variant hover:text-primary"
              @click="setMode('sign-in')"
            >
              ← 返回登入
            </button>

            <p v-if="authNotice" class="rounded-lg bg-primary/10 px-4 py-3 text-sm font-medium text-primary">
              {{ authNotice }}
            </p>
            <p v-if="authError" class="rounded-lg bg-error/10 px-4 py-3 text-sm font-medium text-error">
              {{ authError }}
            </p>
          </form>
        </div>
    </main>
  </div>
</template>
