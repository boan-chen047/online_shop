<script setup lang="ts">
import { computed, ref } from 'vue'
import { RouterLink } from 'vue-router'
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
} = useAuth()

const authMode = ref<'sign-in' | 'sign-up'>('sign-in')
const email = ref('')
const password = ref('')

const submitLabel = computed(() => authMode.value === 'sign-in' ? 'Sign in' : 'Create account')

async function handleSubmit() {
  if (authMode.value === 'sign-in') {
    await signInWithEmail(email.value, password.value)
    return
  }

  await signUpWithEmail(email.value, password.value)
}
</script>

<template>
  <div class="min-h-[calc(100vh-72px)] bg-surface px-5 py-10 text-on-surface">
    <main class="mx-auto max-w-xl rounded-2xl bg-surface-container-lowest p-6 shadow-sm sm:p-8">
        <div class="mb-6">
          <h2 class="font-headline text-3xl font-black">Sign in</h2>
          <p class="mt-2 text-sm text-on-surface-variant">Use Supabase Authentication to continue.</p>
        </div>

        <div v-if="!isAuthReady" class="rounded-xl bg-surface-container-low p-6 text-center">
          <p class="font-bold text-on-surface">Checking sign-in status...</p>
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
              <RouterLink to="/userfile">View Profile</RouterLink>
            </Button>
            <Button variant="outline" class="rounded-xl bg-surface-container-lowest font-bold" @click="signOutUser">
              Sign out
            </Button>
          </div>
        </div>

        <div v-else>
          <form class="space-y-4" @submit.prevent="handleSubmit">
            <div class="grid grid-cols-2 rounded-xl bg-surface-container-low p-1">
              <button
                type="button"
                class="rounded-lg px-3 py-2 text-sm font-bold transition-colors"
                :class="authMode === 'sign-in' ? 'bg-surface-container-lowest text-primary shadow-sm' : 'text-on-surface-variant'"
                @click="authMode = 'sign-in'"
              >
                Sign in
              </button>
              <button
                type="button"
                class="rounded-lg px-3 py-2 text-sm font-bold transition-colors"
                :class="authMode === 'sign-up' ? 'bg-surface-container-lowest text-primary shadow-sm' : 'text-on-surface-variant'"
                @click="authMode = 'sign-up'"
              >
                Sign up
              </button>
            </div>

            <label class="block">
              <span class="mb-2 block text-sm font-bold text-on-surface">Email</span>
              <Input v-model="email" type="email" autocomplete="email" required placeholder="you@example.com" class="h-12 rounded-xl bg-surface-container-lowest" />
            </label>

            <label class="block">
              <span class="mb-2 block text-sm font-bold text-on-surface">Password</span>
              <Input
                v-model="password"
                type="password"
                :autocomplete="authMode === 'sign-in' ? 'current-password' : 'new-password'"
                required
                minlength="6"
                placeholder="At least 6 characters"
                class="h-12 rounded-xl bg-surface-container-lowest"
              />
            </label>

            <Button class="primary-gradient h-12 w-full rounded-xl font-bold text-on-primary" :disabled="isSigningIn">
              <LogIn class="mr-2 size-4" />
              {{ isSigningIn ? 'Please wait...' : submitLabel }}
            </Button>

            <Button
              type="button"
              variant="outline"
              class="h-12 w-full rounded-xl bg-surface-container-lowest font-bold"
              :disabled="isSigningIn"
              @click="signInWithGoogle"
            >
              Continue with Google
            </Button>

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
