// 導入依賴
import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../view/components/HomeView.vue'
import { ensureAuthReady, useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'
import { trackPageView } from '@/lib/analytics'
// 導入依賴

// 路由配置表
// meta.requiresAuth：需登入才能進；meta.requiresAdmin：需管理員才能進
const routes = [
  {
    path: '/',
    name: 'Home',
    component: HomeView
  },
  {
    path: '/products',
    name: 'Products',
    component: () => import('../view/components/ProductList.vue')
  },
  {
    // 使用動態路由 (:id) 來抓取不同商品的編號
    path: '/product/:id',
    name: 'ProductDetails',
    component: () => import('../view/components/ProductDetails.vue')
  },
  {
    path: '/cart',
    name: 'Cart',
    component: () => import('../view/components/ShoppingCart.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/userfile',
    name: 'UserFile',
    component: () => import('../view/components/UserFile.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../view/components/Login.vue')
  },
  {
    path: '/news',
    name: 'News',
    component: () => import('../view/components/News.vue')
  },
  {
    path: '/news/:id',
    name: 'NewsDetail',
    component: () => import('../view/components/NewsDetail.vue')
  },
  {
    // 顧客「我的訂單」：與管理員訂單管理共用 AdminOrders.vue（元件內以 isAdmin 切換，
    // RLS 只回自己的訂單），只需登入即可。管理員版在 /admin/orders（後台外殼內）。
    path: '/orders',
    name: 'MyOrders',
    component: () => import('../view/components/AdminOrders.vue'),
    meta: { requiresAuth: true }
  },
  {
    // 後台管理外殼：商品／訂單／最新消息／網站設定，全區要求管理員權限
    path: '/admin',
    component: () => import('../view/components/AdminLayout.vue'),
    meta: { requiresAdmin: true },
    children: [
      { path: '', redirect: { name: 'AdminProducts' } },
      {
        path: 'products',
        name: 'AdminProducts',
        component: () => import('../view/components/AdminProducts.vue'),
      },
      {
        path: 'products/:id',
        name: 'AdminProductDetail',
        component: () => import('../view/components/AdminProductDetail.vue'),
      },
      {
        path: 'orders',
        name: 'AdminOrders',
        component: () => import('../view/components/AdminOrders.vue'),
      },
      {
        path: 'news',
        name: 'AdminNews',
        component: () => import('../view/components/AdminNews.vue'),
      },
      {
        path: 'settings',
        name: 'AdminSettings',
        component: () => import('../view/components/AdminSettings.vue'),
      },
    ],
  },
  {
    path: '/checkout/result',
    name: 'CheckoutResult',
    component: () => import('../view/components/CheckoutResult.vue'),
    meta: { requiresAuth: true }
  }
]
// 路由配置表

// 建立路由實例
const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior() {
    return { top: 0, behavior: 'auto' }
  }
})
// 建立路由實例

// 導航守衛：前端擋登入/管理員頁面（後端 RLS 仍是最終防線，這裡只負責導頁與體驗）
router.beforeEach(async (to) => {
  const requiresAuth = to.matched.some((record) => record.meta.requiresAuth)
  const requiresAdmin = to.matched.some((record) => record.meta.requiresAdmin)

  if (!requiresAuth && !requiresAdmin) {
    return true
  }

  // 等初次登入狀態（含角色）解析完成，避免重整後在載入前誤判
  await ensureAuthReady()
  const { currentUser, isAdmin } = useAuth()

  // 未登入：導去登入頁，並記住原本要去的頁面，登入後導回
  if (!currentUser.value) {
    return { name: 'Login', query: { redirect: to.fullPath } }
  }

  if (requiresAdmin && !isAdmin.value) {
    // 二次確認：剛登入時前端角色可能還沒載入，向後端問一次權威答案再決定是否擋下
    const { data } = await supabase.rpc('is_admin')
    if (!data) {
      return { name: 'Home' }
    }
  }

  return true
})

// GA4：SPA 換頁不會重新整理，於每次導航完成後手動送出 page_view
router.afterEach((to) => {
  trackPageView(to.fullPath)
})

export default router
