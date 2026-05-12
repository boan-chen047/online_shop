import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import router from './router/index'
import { SpeedInsights } from "@vercel/speed-insights/vue"
const app = createApp(App)
app.use(router)
app.component('SpeedInsights', SpeedInsights)
app.mount('#app')
