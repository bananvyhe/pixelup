<script setup>
import { computed, reactive, ref } from "vue"
import { useRouter } from "vue-router"
import { login, register } from "../useSession"

const router = useRouter()
const mode = ref("login")
const form = reactive({
  email: "",
  password: "",
  passwordConfirmation: ""
})
const error = ref("")
const loading = ref(false)
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

const isEmailValid = computed(() => emailPattern.test(form.email.trim()))
const doPasswordsMatch = computed(() => form.password.length > 0 && form.password === form.passwordConfirmation)
const canRegister = computed(() => isEmailValid.value && form.password.length >= 8 && doPasswordsMatch.value)

async function submit() {
  loading.value = true
  error.value = ""

  try {
    const data = mode.value === "login"
      ? await login({ email: form.email, password: form.password })
      : await register({
          email: form.email,
          password: form.password,
          password_confirmation: form.passwordConfirmation
        })

    router.replace(data.user.role === "admin" ? "/admin" : "/dashboard")
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <main class="hero">
    <section class="card intro">
      <div class="eyebrow">Веб - разработка</div>
      <h2>{{ mode === "login" ? "Вход в Pixeltech" : "Регистрация в Pixeltech" }}</h2>
      <p>
        Проект стартуется на: backend - Rails API для более быстрого прототипирования, все уязвимые вычисления происходят здесь, фронтенд - Vue 3 Composition API для максимальной гибкости и реактивности интерфейсов, в случае высоконагруженных мест на сайте, производится вынос в модуль на более быстрый язык</p>
    </section>

    <section class="card form-card">
      <div class="button-row">
        <button :class="{ ghost: mode !== 'login' }" @click="mode = 'login'">Вход</button>
        <button :class="{ ghost: mode !== 'register' }" @click="mode = 'register'">Регистрация</button>
      </div>

      <h3>{{ mode === "login" ? "Войти" : "Создать аккаунт" }}</h3>
      <p v-if="error" class="error">{{ error }}</p>

      <form @submit.prevent="submit">
        <label>
          E-mail
          <input v-model="form.email" type="email" required />
          <span :class="isEmailValid || !form.email ? 'hint' : 'error'">
            {{ !form.email ? "Введите e-mail" : isEmailValid ? "E-mail выглядит корректно" : "Некорректный формат e-mail" }}
          </span>
        </label>

        <label>
          Пароль
          <input v-model="form.password" type="password" required minlength="8" />
          <span class="hint">Минимум 8 символов</span>
        </label>

        <label v-if="mode === 'register'">
          Повторите пароль
          <input v-model="form.passwordConfirmation" type="password" required minlength="8" />
          <span :class="doPasswordsMatch || !form.passwordConfirmation ? 'hint' : 'error'">
            {{
              !form.passwordConfirmation
                ? "Повторите пароль"
                : doPasswordsMatch
                  ? "Пароли совпадают"
                  : "Пароли не совпадают"
            }}
          </span>
        </label>

        <button :disabled="loading || (mode === 'register' && !canRegister)">
          {{
            loading
              ? mode === "login" ? "Входим..." : "Регистрируем..."
              : mode === "login" ? "Войти" : "Зарегистрироваться"
          }}
        </button>
      </form>
    </section>
  </main>
</template>
