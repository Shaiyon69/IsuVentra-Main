<template>
  <div class="admin-layout">
    <aside class="sidebar">
      <div class="sidebar-header">
        <h2>ISUVentra</h2>
        <span class="version">v1.1 Admin</span>
      </div>

      <nav class="sidebar-nav">
        <router-link :to="{ name: 'admin-overview' }" active-class="active" class="nav-item">
          <span class="icon">📊</span> <span class="label">Overview</span>
        </router-link>

        <router-link :to="{ name: 'admin-students' }" active-class="active" class="nav-item">
          <span class="icon">👥</span> <span class="label">Students</span>
        </router-link>

        <router-link :to="{ name: 'admin-events' }" active-class="active" class="nav-item">
          <span class="icon">📅</span> <span class="label">Events</span>
        </router-link>

        <router-link :to="{ name: 'admin-participation' }" active-class="active" class="nav-item">
          <span class="icon">📋</span> <span class="label">Participation</span>
        </router-link>
      </nav>

      <div class="sidebar-footer">
        <div class="user-info">
          <div class="avatar">A</div>
          <div class="details">
            <span class="name">Administrator</span>
            <button @click="handleLogout" class="logout-btn">Logout</button>
          </div>
        </div>
      </div>
    </aside>

    <main class="main-content">
      <header class="top-bar">
        <h1>{{ pageTitle }}</h1>
        <div class="date-display">{{ new Date().toLocaleDateString() }}</div>
      </header>

      <div v-if="isLoading" class="loading-container">
        <div class="spinner"></div>
        <p>Loading Dashboard Data...</p>
      </div>

      <div v-else class="content-scroll-area">
        <router-view
          :students="students"
          :events="events"
          :participation="participation"
          @refresh="loadAdminData"
        ></router-view>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import api from "@/services/api";

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();

const isLoading = ref(true);
const students = ref([]);
const events = ref([]);
const participation = ref([]);

// Compute title based on the current Route Name
const pageTitle = computed(() => {
  const name = route.name ? route.name.toString().replace('admin-', '') : 'overview';
  return name.charAt(0).toUpperCase() + name.slice(1);
});

async function loadAdminData() {
  // If we already have data, don't show the full spinner, just refresh silently
  // unless the array is empty (first load)
  if(students.value.length === 0) isLoading.value = true;

  try {
    const [stuRes, eveRes, partRes] = await Promise.all([
      api.get("/students"),
      api.get("/events"),
      api.get("/participation")
    ]);
    students.value = stuRes.data;
    events.value = eveRes.data;
    participation.value = partRes.data;
  } catch (err) {
    console.error("Failed to load admin data:", err);
  } finally {
    isLoading.value = false;
  }
}

function handleLogout() {
  auth.logout();
  router.push("/");
}

onMounted(loadAdminData);
</script>

<style>
/* GLOBAL RESET */
html, body {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  font-family: 'Segoe UI', sans-serif;
  background-color: #f4f6f8;
  height: 100vh;
  overflow: hidden;
}
*, *:before, *:after { box-sizing: inherit; }
</style>

<style scoped>
/* MAIN LAYOUT */
.admin-layout { display: flex; flex-direction: row; height: 100vh; width: 100vw; }

/* SIDEBAR STYLING */
.sidebar { width: 260px; min-width: 260px; background: #145A32; color: white; display: flex; flex-direction: column; box-shadow: 4px 0 12px rgba(0,0,0,0.1); z-index: 100; }
.sidebar-header { padding: 24px; background: rgba(0,0,0,0.1); }
.sidebar-header h2 { margin: 0; font-size: 1.4rem; font-weight: 700; letter-spacing: 0.5px; }
.version { font-size: 0.75rem; opacity: 0.7; text-transform: uppercase; }

.sidebar-nav { display: flex; flex-direction: column; padding: 20px 10px; gap: 8px; flex: 1; }

.nav-item {
  display: flex; align-items: center; gap: 12px; padding: 14px 16px;
  width: 100%; border: none; background: transparent;
  color: #a9dfbf; cursor: pointer; border-radius: 8px;
  transition: all 0.2s; font-size: 0.95rem; text-align: left;
  text-decoration: none;
}

.nav-item:hover, .nav-item.active {
  background: #27ae60; color: white; transform: translateX(5px);
}

.sidebar-footer { padding: 20px; border-top: 1px solid rgba(255,255,255,0.1); }
.user-info { display: flex; align-items: center; gap: 10px; }
.avatar { width: 36px; height: 36px; background: #2ecc71; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; color: #0e3e23; }
.details { display: flex; flex-direction: column; }
.name { font-size: 0.9rem; font-weight: 600; }
.logout-btn { background: none; border: none; color: #fab1a0; cursor: pointer; padding: 0; text-align: left; font-size: 0.75rem; margin-top: 2px;}
.logout-btn:hover { text-decoration: underline; }

/* MAIN CONTENT */
.main-content { flex: 1; display: flex; flex-direction: column; background: #f4f6f8; height: 100%; }
.top-bar { padding: 20px 32px; background: white; border-bottom: 1px solid #e0e0e0; display: flex; justify-content: space-between; align-items: center; }
.top-bar h1 { margin: 0; font-size: 1.5rem; color: #2c3e50; }
.date-display { color: #7f8c8d; font-size: 0.9rem; }
.content-scroll-area { padding: 32px; overflow-y: auto; flex: 1; }

/* SPINNER */
.loading-container {
  display: flex; flex-direction: column; justify-content: center; align-items: center; height: 100%; color: #7f8c8d;
}
.spinner {
  width: 40px; height: 40px; border: 4px solid #e0e0e0; border-top: 4px solid #27ae60; border-radius: 50%; animation: spin 1s linear infinite; margin-bottom: 16px;
}
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
</style>
