<template>
  <div class="admin-layout">
    <aside class="sidebar">
      <div class="brand-section">
        <div class="logo-icon">
          <i class="pi pi-box"></i>
        </div>
        <div class="brand-info">
          <h2 class="brand-name">ISUVentra</h2>
          <span class="brand-badge">ADMIN v1.1</span>
        </div>
      </div>

      <nav class="nav-menu">
        <router-link :to="{ name: 'admin-dashboard' }" class="nav-item" active-class="active">
          <i class="pi pi-chart-bar"></i>
          <span>Dashboard</span>
        </router-link>

        <div class="nav-divider">MANAGEMENT</div>

        <router-link :to="{ name: 'admin-students' }" class="nav-item" active-class="active">
          <i class="pi pi-users"></i>
          <span>Students</span>
        </router-link>

        <router-link :to="{ name: 'admin-events' }" class="nav-item" active-class="active">
          <i class="pi pi-calendar"></i>
          <span>Events</span>
        </router-link>

        <router-link :to="{ name: 'admin-participation' }" class="nav-item" active-class="active">
          <i class="pi pi-list"></i>
          <span>Participation</span>
        </router-link>
      </nav>

      <div class="user-footer">
        <div class="user-card">
          <Avatar label="A" class="user-avatar" shape="circle" />
          <div class="user-meta">
            <span class="user-name">Administrator</span>
            <span class="logout-link" @click="handleLogout">Sign Out</span>
          </div>
        </div>
      </div>
    </aside>

    <main class="main-wrapper">
      <header class="top-header">
        <h1 class="page-title">{{ pageTitle }}</h1>
        <div class="header-right">
          <div class="date-badge">
            <i class="pi pi-calendar"></i>
            {{ new Date().toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' }) }}
          </div>
        </div>
      </header>

      <div class="content-area">
        <div v-if="isLoading" class="loading-overlay">
          <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" />
          <p>Syncing Data...</p>
        </div>

        <div v-else class="router-view-container">
          <router-view
            :students="students"
            :events="events"
            :participation="participation"
            @refresh="loadAdminData"
          ></router-view>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import api from "@/services/api";

// PrimeVue Component Imports
import Avatar from 'primevue/avatar';
import ProgressSpinner from 'primevue/progressspinner';

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();

const isLoading = ref(true);
const students = ref([]);
const events = ref([]);
const participation = ref([]);

// Compute page title from route name
const pageTitle = computed(() => {
  if (!route.name) return 'Dashboard';
  const name = route.name.toString().replace('admin-', '');
  return name.charAt(0).toUpperCase() + name.slice(1);
});

async function loadAdminData() {
  // Only show full loading spinner if we have NO data
  if (students.value.length === 0) isLoading.value = true;

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

<style scoped>
/* --- LAYOUT STRUCTURE --- */
.admin-layout {
  display: flex;
  height: 100vh;
  width: 100%;
  background-color: #f8fafc; /* Light Slate Background */
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  overflow: hidden;
}

/* --- SIDEBAR STYLING --- */
.sidebar {
  width: 260px;
  min-width: 260px;
  background-color: #064e3b; /* Dark Emerald Green */
  color: white;
  display: flex;
  flex-direction: column;
  box-shadow: 4px 0 15px rgba(0, 0, 0, 0.1);
  z-index: 50;
}

.brand-section {
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 12px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.logo-icon {
  width: 40px;
  height: 40px;
  background: #34d399; /* Light Emerald */
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #064e3b;
  font-size: 1.25rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.2);
}

.brand-info {
  display: flex;
  flex-direction: column;
}

.brand-name {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 700;
  letter-spacing: 0.5px;
}

.brand-badge {
  font-size: 0.7rem;
  opacity: 0.8;
  letter-spacing: 1px;
}

.nav-menu {
  flex: 1;
  padding: 1.5rem 1rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.nav-divider {
  font-size: 0.75rem;
  color: #6ee7b7; /* Soft Green */
  font-weight: 700;
  margin: 1.5rem 0 0.5rem 0.8rem;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  color: #d1fae5;
  text-decoration: none;
  border-radius: 8px;
  transition: all 0.2s ease;
  font-size: 0.95rem;
}

.nav-item:hover {
  background-color: rgba(255, 255, 255, 0.1);
  color: white;
}

.nav-item.active {
  background-color: #10b981; /* Primary Green */
  color: white;
  font-weight: 600;
  box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
}

.nav-item i {
  font-size: 1.1rem;
}

.user-footer {
  padding: 1.5rem;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  background-color: rgba(0, 0, 0, 0.1);
}

.user-card {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-avatar {
  background-color: #34d399 !important;
  color: #064e3b !important;
  font-weight: bold;
}

.user-meta {
  display: flex;
  flex-direction: column;
}

.user-name {
  font-weight: 600;
  font-size: 0.9rem;
}

.logout-link {
  font-size: 0.8rem;
  color: #fca5a5; /* Light Red */
  cursor: pointer;
  transition: color 0.2s;
}

.logout-link:hover {
  color: #f87171;
  text-decoration: underline;
}

/* --- MAIN CONTENT AREA --- */
.main-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.top-header {
  height: 70px;
  background: white;
  border-bottom: 1px solid #e2e8f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 2rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.02);
}

.page-title {
  margin: 0;
  font-size: 1.5rem;
  color: #1e293b;
  font-weight: 700;
}

.date-badge {
  background-color: #f1f5f9;
  padding: 8px 16px;
  border-radius: 20px;
  color: #64748b;
  font-size: 0.9rem;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 8px;
}

.content-area {
  flex: 1;
  overflow-y: auto;
  padding: 2rem;
  position: relative;
}

.loading-overlay {
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #64748b;
}

.router-view-container {
  max-width: 1600px;
  margin: 0 auto;
}
</style>