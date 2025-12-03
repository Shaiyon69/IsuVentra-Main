<template>
  <div class="app-container">
    <Menubar 
      v-if="!isAdminRoute" 
      :model="menuItems" 
      class="app-menubar border-none border-noround shadow-2"
    >
      <template #start>
        <div class="flex align-items-center gap-2 cursor-pointer" @click="router.push('/')">
          <i class="pi pi-box text-2xl text-primary"></i>
          <span class="font-bold text-xl text-900">ISUVentra</span>
        </div>
      </template>

      <template #end>
        <div v-if="auth.isAuthenticated" class="flex align-items-center gap-2">
          <span class="hidden md:inline-block text-sm font-medium text-700 mr-2">
            {{ auth.user?.name || 'User' }}
          </span>
          <Button 
            label="Logout" 
            icon="pi pi-power-off" 
            severity="danger" 
            text 
            size="small"
            @click="logout" 
          />
        </div>
        <div v-else class="flex gap-2">
          <Button label="Login" text size="small" @click="router.push('/login')" />
          <Button label="Register" severity="primary" size="small" @click="router.push('/register')" />
        </div>
      </template>
    </Menubar>

    <main :class="isAdminRoute ? 'admin-view' : 'scrollable-view'">
      <router-view v-slot="{ Component }">
        <transition name="fade" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </main>
  </div>
</template>

<script setup>
import { computed, onMounted } from "vue";
import { useRouter, useRoute } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import api from "@/services/api";

// Manual Imports to ensure stability
import Menubar from 'primevue/menubar';
import Button from 'primevue/button';

const auth = useAuthStore();
const router = useRouter();
const route = useRoute();

// Detect Admin Route to toggle layout modes
const isAdminRoute = computed(() => {
  return route.path.startsWith('/admin');
});

const menuItems = computed(() => {
  if (!auth.isAuthenticated) return [];
  // Only Student items here. Admin nav is inside AdminPanel.vue
  if (auth.role === 'user') {
    return [
      { label: 'Dashboard', icon: 'pi pi-home', command: () => router.push('/dashboard') },
      { label: 'Scan QR', icon: 'pi pi-qrcode', command: () => router.push('/join') }
    ];
  }
  return [];
});

const logout = () => {
  auth.logout();
  router.push("/login");
};

onMounted(async () => {
  if (auth.token) {
    try {
      const response = await api.get('/validate-token');
      if (response.data.user) auth.setAuth(response.data.user, auth.token);
    } catch (e) {
      auth.logout();
      if (router.currentRoute.value.meta.requiresAuth) router.push("/login");
    }
  }
});
</script>

<style>
/* --- GLOBAL RESET (The "Squashed" Fix) --- */
html, body {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  box-sizing: border-box;
  overflow: hidden; /* KILL SWITCH: Prevents window scrollbars entirely */
  background-color: var(--surface-ground, #f8f9fa);
  color: var(--text-color, #2d4a22);
  font-family: var(--font-family, Avenir, Helvetica, Arial, sans-serif);
  -webkit-font-smoothing: antialiased;
}

#app {
  width: 100%;
  height: 100%;
}

*, *:before, *:after {
  box-sizing: inherit;
}

/* --- APP LAYOUT --- */
.app-container {
  display: flex;
  flex-direction: column;
  height: 100vh; /* Force app to exactly fill screen */
  width: 100vw;
}

/* Menubar: Fixed at top, z-index ensures it floats above content */
.app-menubar {
  background-color: var(--surface-card, #ffffff) !important;
  padding: 0.5rem 1.5rem;
  border-bottom: 1px solid #e5e7eb;
  z-index: 999;
  flex-shrink: 0; /* Prevents navbar from shrinking if content is huge */
}

/* --- VIEW MODES --- */

/* 1. Student View (needs to scroll) */
.scrollable-view {
  flex: 1;
  overflow-y: auto; /* Adds scrollbar ONLY to content area */
  overflow-x: hidden;
  position: relative;
  width: 100%;
}

/* 2. Admin View (locks scroll, passes control to child) */
.admin-view {
  flex: 1;
  overflow: hidden; /* No scroll here, AdminPanel.vue handles it */
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}

/* Transitions */
.fade-enter-active, .fade-leave-active { transition: opacity 0.2s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>