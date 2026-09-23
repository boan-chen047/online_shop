<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useAuth } from '@/composables/useAuth'
import { KeyRound } from 'lucide-vue-next'

const { currentUser, isAuthReady, isSigningIn, authError, authNotice, updatePassword } = useAuth()
const router = useRouter()

const newPassword = ref('')
const confirmPassword = ref('')
const localError = ref('')
const done = ref(false)

// 使用者是點信中的重設連結進來的：detectSessionInUrl 會自動建立一個 recovery session，
// 所以此頁有 currentUser 才代表連結有效。
const hasRecoverySession = computed(() => Boolean(currentUser.value))

async function handleSubmit() {
  localError.value = ''

  if (newPassword.value.length < 6) {
    localError.value = '密碼至少需要 6 個字元。'
    return
  }
  if (newPassword.value !== confirmPassword.value) {
    localError.value = '兩次輸入的密碼不一致。'
    return
  }

  await updatePassword(newPassword.value)
  if (!authError.value) {
    done.value = true
  }
}

// 更新成功後短暫停留顯示提示，再導回登入頁
watch(done, (isDone) => {
  if (isDone) {
    window.setTimeout(() => {
      void router.replace('/login')
    }, 2500)
  }
})
</script>

<template>
  <div class="min-h-[calc(100vh-72px)] bg-surface px-5 py-10 text-on-surface">
    <main class="mx-auto max-w-xl rounded-2xl bg-surface-container-lowest p-6 shadow-sm sm:p-8">
      <div class="mb-6">
        <h2 class="font-headline text-3xl font-black">重設密碼</h2>
        <p class="mt-2 text-sm text-on-surface-variant">設定一組新的登入密碼。</p>
      </div>

      <div v-if="!isAuthReady" class="rounded-xl bg-surface-container-low p-6 text-center">
        <p class="font-bold text-on-surface">確認連結中…</p>
      </div>

      <!-- 更新完成 -->
      <div v-else-if="done" class="rounded-2xl bg-primary/10 p-6 text-center">
        <p class="font-bold text-primary">密碼已更新！</p>
        <p class="mt-2 text-sm text-on-surface-variant">即將帶你回到登入頁…</p>
        <Button as-child class="primary-gradient mt-6 rounded-xl font-bold text-on-primary">
          <RouterLink to="/login">前往登入</RouterLink>
        </Button>
      </div>

      <!-- 連結無效或已過期（沒有 recovery session） -->
      <div v-else-if="!hasRecoverySession" class="rounded-2xl bg-surface-container-low p-6 text-center">
        <p class="font-bold text-on-surface">連結無效或已過期</p>
        <p class="mt-2 text-sm text-on-surface-variant">請回到登入頁重新點「忘記密碼？」寄送新的重設連結。</p>
        <Button as-child class="primary-gradient mt-6 rounded-xl font-bold text-on-primary">
          <RouterLink to="/login">返回登入</RouterLink>
        </Button>
      </div>

      <!-- 設定新密碼 -->
      <form v-else class="space-y-4" @submit.prevent="handleSubmit">
        <label class="block">
          <span class="mb-2 block text-sm font-bold text-on-surface">新密碼</span>
          <Input
            v-model="newPassword"
            type="password"
            autocomplete="new-password"
            required
            minlength="6"
            placeholder="至少 6 個字元"
            class="h-12 rounded-xl bg-surface-container-lowest"
          />
        </label>

        <label class="block">
          <span class="mb-2 block text-sm font-bold text-on-surface">確認新密碼</span>
          <Input
            v-model="confirmPassword"
            type="password"
            autocomplete="new-password"
            required
            minlength="6"
            placeholder="再輸入一次"
            class="h-12 rounded-xl bg-surface-container-lowest"
          />
        </label>

        <Button class="primary-gradient h-12 w-full rounded-xl font-bold text-on-primary" :disabled="isSigningIn">
          <KeyRound class="mr-2 size-4" />
          {{ isSigningIn ? '更新中…' : '更新密碼' }}
        </Button>

        <p v-if="localError || authError" class="rounded-lg bg-error/10 px-4 py-3 text-sm font-medium text-error">
          {{ localError || authError }}
        </p>
        <p v-if="authNotice && !done" class="rounded-lg bg-primary/10 px-4 py-3 text-sm font-medium text-primary">
          {{ authNotice }}
        </p>
      </form>
    </main>
  </div>
</template>
