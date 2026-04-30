/// <reference types="vite/client" />

declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  // 告訴 TypeScript 所有的 .vue 檔案都是一個 Vue 元件
  const component: DefineComponent<{}, {}, any>
  export default component
}
