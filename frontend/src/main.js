import { createApp } from "vue"
import { createRouter, createWebHistory } from "vue-router"
import App from "./App.vue"
import LoginPage from "./pages/LoginPage.vue"
import DashboardPage from "./pages/DashboardPage.vue"
import AdminPage from "./pages/AdminPage.vue"
import "./styles.css"

const routes = [
  { path: "/", redirect: "/login" },
  { path: "/login", component: LoginPage },
  { path: "/dashboard", component: DashboardPage },
  { path: "/admin", component: AdminPage }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

createApp(App).use(router).mount("#app")
