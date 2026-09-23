import { computed, ref, watch } from 'vue'
import type { User } from '@supabase/supabase-js'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'

const currentUser = ref<User | null>(null)
const currentRole = ref<string | null>(null)
const isAuthReady = ref(false)
const isSigningIn = ref(false)
const authError = ref('')
const authNotice = ref('')
let isListening = false

async function syncUserProfile(user: User | null) {
  if (!user || !isSupabaseConfigured) {
    currentRole.value = null
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

  const { data: roleRow } = await supabase
    .from('user_profile')
    .select('role')
    .eq('id', user.id)
    .maybeSingle()

  currentRole.value = (roleRow?.role as string | undefined) ?? null
}

function startAuthListener() {
  if (isListening) {
    return
  }

  isListening = true
  // 初次載入：先把使用者角色（syncUserProfile）抓齊，再標記 isAuthReady，
  // 這樣路由守衛在 isAuthReady 為 true 時就能拿到正確的 isAdmin，不會有角色未載入的競態。
  supabase.auth.getSession().then(async ({ data, error }) => {
    currentUser.value = data.session?.user ?? null
    authError.value = error ? getAuthErrorMessage(error) : ''
    await syncUserProfile(data.session?.user ?? null)
    isAuthReady.value = true
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
    // 環境變數 VITE_SUPABASE_URL / VITE_SUPABASE_PUBLISHABLE_KEY 未設定時顯示
    return '系統尚未設定完成，請聯繫管理員。'
  }

  if (message.includes('Invalid login credentials')) {
    return '電子郵件或密碼錯誤。'
  }

  if (message.includes('Email not confirmed')) {
    return '請先到信箱完成驗證後再登入。'
  }

  return message || '無法完成驗證請求，請稍後再試。'
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
      authNotice.value = '帳號已建立，請至信箱點擊確認信後再登入。'
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

// 寄送重設密碼信；使用者點信中連結會帶著 recovery token 回到 /reset-password。
// 註：為避免帳號探測，無論該 email 是否存在都顯示相同的成功訊息。
async function sendPasswordReset(email: string) {
  authError.value = ''
  authNotice.value = ''
  isSigningIn.value = true

  try {
    if (!isSupabaseConfigured) {
      throw new Error('not-configured')
    }

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    })

    if (error) {
      throw error
    }

    authNotice.value = '若這個 email 有註冊過，我們已寄出重設密碼信，請至信箱點擊連結。'
  } catch (error) {
    authError.value = getAuthErrorMessage(error)
  } finally {
    isSigningIn.value = false
  }
}

// 使用者從重設密碼信連結回來（此時已有 recovery session）後，設定新密碼。
async function updatePassword(newPassword: string) {
  authError.value = ''
  authNotice.value = ''
  isSigningIn.value = true

  try {
    if (!isSupabaseConfigured) {
      throw new Error('not-configured')
    }

    const { error } = await supabase.auth.updateUser({ password: newPassword })

    if (error) {
      throw error
    }

    authNotice.value = '密碼已更新，請用新密碼登入。'
  } catch (error) {
    authError.value = getAuthErrorMessage(error)
  } finally {
    isSigningIn.value = false
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

const isAdmin = computed(() => currentRole.value === 'admin')

// 供路由守衛使用：確保初次的登入狀態（含角色）已解析完成才回傳，避免守衛在載入前誤判。
export function ensureAuthReady(): Promise<void> {
  startAuthListener()

  if (isAuthReady.value) {
    return Promise.resolve()
  }

  return new Promise((resolve) => {
    const stop = watch(isAuthReady, (ready) => {
      if (ready) {
        stop()
        resolve()
      }
    })
  })
}

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
    isAdmin,
    signInWithEmail,
    signInWithGoogle,
    signUpWithEmail,
    signOutUser,
    sendPasswordReset,
    updatePassword,
  }
}
