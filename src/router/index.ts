import { createRouter, createWebHistory } from 'vue-router'
// 引入所有的頁面元件
import HomeView from '../view/components/HomeView.vue'
import ProductList from '../view/components/ProductList.vue'
import ProductDetails from '../view/components/ProductDetails.vue'
import ShoppingCart from '../view/components/ShoppingCart.vue'

// 定義路由規則
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

// 建立 Router 實體
  const router = createRouter({
  history: createWebHistory(), 
  routes,
})

export default router