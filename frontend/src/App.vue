<script setup>
import { onMounted } from "vue"
import { useRouter } from "vue-router"
import { loadSession, logout, sessionState } from "./useSession"

const router = useRouter()

onMounted(async () => {
  await loadSession()
  if (sessionState.authenticated && router.currentRoute.value.path === "/login") {
    router.replace("/dashboard")
  }
})

async function handleLogout() {
  await logout()
  router.replace("/login")
}
</script>

<template>
  <div class="app-shell">
    <header class="topbar">
      <div>
        <div class="eyebrow">Pixeltech.ru</div>
        <h1>приложение по цене хостинга</h1>
      </div>
      <nav class="nav" v-if="sessionState.authenticated">
        <RouterLink to="/dashboard" class="ghost">Кабинет</RouterLink>
        <RouterLink v-if="sessionState.user?.role === 'admin'" to="/admin" class="ghost">Админка</RouterLink>
        <button class="danger" @click="handleLogout">Выйти</button>
      </nav>
    </header>
    <RouterView />
  </div>
</template>
