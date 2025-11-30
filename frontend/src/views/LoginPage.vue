<template>
  <div class="auth-page">
    <h2>Login</h2>
    <form @submit.prevent="doLogin">
      <input v-model="email" type="email" placeholder="Email" required />
      <input v-model="password" type="password" placeholder="Password" required />
      <br/>
      <button type="submit">Login</button>
    </form>

    <p v-if="error" class="error">{{ error }}</p>
    <router-link to="/register">Register</router-link>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';

const email = ref('');
const password = ref('');
const error = ref(null);
const router = useRouter();
const auth = useAuthStore();



async function doLogin() {
  error.value = null;
  try {
    await auth.login({ 
      email: email.value, 
      password: password.value 
    });

    if (auth.isAdmin) router.push('/admin');
    else router.push('/dashboard');
  } catch (e) {
    console.error(e);
    error.value = e.response?.data?.message || e.message || 'Login failed';
  }
}
</script>

<style scoped>
.auth-page {
  max-width: 400px;
  margin: 40px auto;
  padding: 40px 32px;
  background-color: var(--secondary-bg);
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12);
  display: flex;
  flex-direction: column;
  gap: 20px;
  border: 1px solid var(--border-color);
}

.auth-page h2 {
  color: var(--text-color);
  margin-bottom: 20px;
}

.auth-page input {
  padding: 12px;
  border: 1px solid var(--border-color);
  border-radius: 4px;
  background-color: var(--primary-bg);
  color: var(--text-color);
  font-size: 16px;
}

.auth-page input::placeholder {
  color: var(--light-accent);
}

.auth-page input:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 2px rgba(102, 187, 106, 0.2);
}

.auth-page button {
  padding: 12px;
  background-color: var(--accent);
  color: var(--primary-bg);
  border: none;
  border-radius: 4px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  transition: background-color 0.3s;
}

.auth-page button:hover {
  background-color: var(--light-accent);
}

.error {
  color: var(--error-color);
  background-color: rgba(255, 138, 128, 0.1);
  padding: 8px;
  border-radius: 4px;
  border: 1px solid var(--error-color);
}

.auth-page a {
  color: var(--accent);
  text-decoration: none;
}

.auth-page a:hover {
  text-decoration: underline;
}
</style>
