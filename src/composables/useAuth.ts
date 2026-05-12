import { computed, ref } from 'vue'
import type { User } from '@supabase/supabase-js'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'

const currentUser = ref<User | null>(null)
const isAuthReady = ref(false)
const isSigningIn = ref(false)
const authError = ref('')
const authNotice = ref('')
let isListening = false

async function syncUserProfile(user: User | null) {
  if (!user || !isSupabaseConfigured) {
    return
  }

  const profilePayload = {
    id: user.id,
    email: user.email,
    display_name:
      (user.user_metadata?.full_name as string | undefined) ||
      (user.user_metadata?.name as string | undefined) ||
      user.email?.split('@')[0] ||
      'Shopping Member',
    avatar_url: (user.user_metadata?.avatar_url as string | undefined) || null,
    provider: (user.app_metadata?.provider as string | undefined) || null,
    last_sign_in_at: user.last_sign_in_at,
  }

  const { data: existingProfile, error: selectError } = await supabase
    .from('user_profile')
    .select('id')
    .eq('id', user.id)
    .maybeSingle()

  if (selectError) {
    authError.value = getAuthErrorMessage(selectError)
    return
  }

  const { error } = existingProfile
    ? await supabase
      .from('user_profile')
      .update({
        email: profilePayload.email,
        display_name: profilePayload.display_name,
        avatar_url: profilePayload.avatar_url,
        provider: profilePayload.provider,
        last_sign_in_at: profilePayload.last_sign_in_at,
      })
      .eq('id', user.id)
    : await supabase
      .from('user_profile')
      .insert(profilePayload)

  if (error) {
    authError.value = getAuthErrorMessage(error)
  }
}

function startAuthListener() {
  if (isListening) {
    return
  }

  isListening = true
  supabase.auth.getSession().then(({ data, error }) => {
    currentUser.value = data.session?.user ?? null
    isAuthReady.value = true
    authError.value = error ? getAuthErrorMessage(error) : ''
    void syncUserProfile(data.session?.user ?? null)
  })

  supabase.auth.onAuthStateChange((_event, session) => {
    currentUser.value = session?.user ?? null
    isAuthReady.value = true
    authError.value = ''
    void syncUserProfile(session?.user ?? null)
  })
}

function getAuthErrorMessage(error: unknown) {
  const message =
    error instanceof Error
      ? error.message
      : error && typeof error === 'object' && 'message' in error && typeof error.message === 'string'
        ? error.message
        : ''

  if (!isSupabaseConfigured) {
    return 'Supabase is not configured yet. Set VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY in your environment.'
  }

  if (message.includes('Invalid login credentials')) {
    return 'Email or password is incorrect.'
  }

  if (message.includes('Email not confirmed')) {
    return 'Please confirm your email before signing in.'
  }

  return message || 'Unable to complete the authentication request. Please try again.'
}

async function signInWithEmail(email: string, password: string) {
  authError.value = ''
  authNotice.value = ''
  isSigningIn.value = true

  try {
    if (!isSupabaseConfigured) {
      throw new Error('Supabase is not configured yet. Set VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY in your environment.')
    }

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      throw error
    }
  } catch (error) {
    authError.value = getAuthErrorMessage(error)
  } finally {
    isSigningIn.value = false
  }
}

async function signInWithGoogle() {
  authError.value = ''
  authNotice.value = ''
  isSigningIn.value = true

  try {
    if (!isSupabaseConfigured) {
      throw new Error('Supabase is not configured yet. Set VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY in your environment.')
    }

    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: window.location.origin,
      },
    })

    if (error) {
      throw error
    }
  } catch (error) {
    authError.value = getAuthErrorMessage(error)
    isSigningIn.value = false
  }
}

async function signUpWithEmail(email: string, password: string) {
  authError.value = ''
  authNotice.value = ''
  isSigningIn.value = true

  try {
    if (!isSupabaseConfigured) {
      throw new Error('Supabase is not configured yet. Set VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY in your environment.')
    }

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: email.split('@')[0],
        },
      },
    })

    if (error) {
      throw error
    }

    if (!data.session) {
      authNotice.value = 'Account created. Please check your email to confirm your account before signing in.'
    }
  } catch (error) {
    authError.value = getAuthErrorMessage(error)
  } finally {
    isSigningIn.value = false
  }
}

async function signOutUser() {
  authError.value = ''
  authNotice.value = ''

  try {
    const { error } = await supabase.auth.signOut()

    if (error) {
      throw error
    }
  } catch (error) {
    authError.value = getAuthErrorMessage(error)
  }
}

const userProfile = computed(() => {
  const user = currentUser.value

  return {
    name: (user?.user_metadata?.full_name as string | undefined) || user?.email?.split('@')[0] || 'Shopping Member',
    email: user?.email || '',
    title: user?.email || 'Signed in with Supabase Auth',
    membership: 'Kinetic Elite Member',
    avatar: (user?.user_metadata?.avatar_url as string | undefined) || '',
  }
})

const userInitials = computed(() =>
  userProfile.value.name
    .split(' ')
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
    .toUpperCase(),
)

export function useAuth() {
  startAuthListener()

  return {
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
  }
}
