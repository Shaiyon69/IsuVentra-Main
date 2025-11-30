<template>
  <div id="app">
    <nav v-if="auth.isAuthenticated">
      
      <router-link to="/dashboard" v-if="auth.role === 'user'">Dashboard</router-link>
      <router-link to="/join" v-if="auth.role === 'user'">Join Event</router-link>
      
      <router-link to="/admin" v-if="auth.role === 'admin'">Admin Dashboard</router-link>
      
      <button @click="logout">Logout</button>
    </nav>

    <nav v-else>
      <router-link to="/">Login</router-link>
      <router-link to="/register">Register</router-link>
    </nav>

    <router-view />
  </div>
</template>

<script setup>
import { useAuthStore } from "@/stores/auth";
import { onMounted } from "vue";
import { useRouter } from "vue-router";
import api from "@/services/api";

const auth = useAuthStore();
const router = useRouter();

const logout = () => {
  auth.logout();
  router.push({ name: "login" });
};

onMounted(async () => {
  if (auth.token) {
    try {
      const response = await api.get('/validate-token');
      if (response.data.user) {
        // Match the response structure from your backend
        auth.setAuth(response.data.user, auth.token);
      }
    } catch (e) {

      auth.logout();
      if (router.currentRoute.value.meta.requiresAuth) {
        router.push({ name: "login" });
      }
    }
  }
});
</script>

<style>
:root {
  --primary-bg: #ffffff;
  --secondary-bg: #f5f5f5;
  --accent: #4caf50;
  --light-accent: #81c784;
  --outline-accent: #81c784;
  --text-color: #2d4a22;
  --error-color: #ef5350;
  --success-color: #81c784;
  --border-color: #e0e0e0;
}

#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: var(--text-color);
  background-color: var(--primary-bg);
  min-height: 100vh;
}

nav {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 15px;
  padding: 15px;
  margin-bottom: 20px;
  background-color: var(--secondary-bg);
  border-bottom: 1px solid var(--border-color);
}

nav a {
  font-weight: bold;
  color: var(--text-color);
  text-decoration: none;
  position: relative;
  padding: 0 10px;
}

nav a + a::before {
  content: "|";
  position: absolute;
  left: 0;
  color: var(--outline-accent);
}

nav a.router-link-exact-active {
  color: var(--accent);
}

nav button {
  cursor: pointer;
  font-weight: bold;
  background: var(--error-color);
  color: var(--primary-bg);
  border: none;
  padding: 5px 10px;
  border-radius: 3px;
}

nav button:hover {
  background: #e57373;
}
</style>