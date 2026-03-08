import { reactive } from "vue"
import { api } from "./api"

export const sessionState = reactive({
  ready: false,
  authenticated: false,
  user: null
})

export async function loadSession() {
  const data = await api.currentSession()
  sessionState.ready = true
  sessionState.authenticated = data.authenticated
  sessionState.user = data.user || null
  return data
}

export async function login(credentials) {
  const data = await api.login(credentials)
  sessionState.authenticated = true
  sessionState.user = data.user
  return data
}

export async function register(credentials) {
  const data = await api.register(credentials)
  sessionState.authenticated = true
  sessionState.user = data.user
  return data
}

export async function logout() {
  await api.logout()
  sessionState.authenticated = false
  sessionState.user = null
}
