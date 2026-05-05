// 導入依賴
import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../view/components/HomeView.vue'
// 導入依賴

// 路由配置表
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
    component: () => import('../view/components/ShoppingCart.vue')
  },
  {
    path: '/userfile',
    name: 'UserFile',
    component: () => import('../view/components/UserFile.vue')
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

export default router