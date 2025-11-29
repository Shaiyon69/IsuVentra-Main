<template>
  <div class="admin-layout">
    <aside class="sidebar">
      <div class="sidebar-header">
        <h2>ISUVentra</h2>
        <span class="version">v1.1 Admin</span>
      </div>

      <nav class="sidebar-nav">
        <button :class="{ active: currentPage === 'overview' }" @click="currentPage = 'overview'">
          <span class="icon">📊</span> <span class="label">Overview</span>
        </button>
        <button :class="{ active: currentPage === 'students' }" @click="currentPage = 'students'">
          <span class="icon">👥</span> <span class="label">Students</span>
        </button>
        <button :class="{ active: currentPage === 'events' }" @click="currentPage = 'events'">
          <span class="icon">📅</span> <span class="label">Events</span>
        </button>
        <button :class="{ active: currentPage === 'participation' }" @click="currentPage = 'participation'">
          <span class="icon">📋</span> <span class="label">Participation</span>
        </button>
      </nav>

      <div class="sidebar-footer">
        <div class="user-info">
          <div class="avatar">A</div>
          <div class="details">
            <span class="name">Administrator</span>
            <span class="role">ISU Campus</span>
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
        <OverviewTab 
          v-if="currentPage === 'overview'" 
          :students="students" 
          :events="events" 
          :participation="participation" 
        />

        <StudentsTab 
          v-if="currentPage === 'students'" 
          :students="students" 
        />

        <EventsTab 
          v-if="currentPage === 'events'" 
          :events="events" 
        />

        <ParticipationTab 
          v-if="currentPage === 'participation'" 
          :participation="participation" 
        />
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from "vue";
import api from "@/services/api";

// Import your sub-components
import OverviewTab from "@/components/admin/OverviewTab.vue";
import StudentsTab from "@/components/admin/StudentsTab.vue";
import EventsTab from "@/components/admin/EventsTab.vue";
import ParticipationTab from "@/components/admin/ParticipationTab.vue";

const currentPage = ref("overview");
const isLoading = ref(true); // Default to true so we don't show empty charts
const students = ref([]);
const events = ref([]);
const participation = ref([]);

const pageTitle = computed(() => {
  return currentPage.value.charAt(0).toUpperCase() + currentPage.value.slice(1);
});

async function loadAdminData() {
  isLoading.value = true; // Start Loading
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
    isLoading.value = false; // Stop Loading (Render the tabs now)
  }
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
.sidebar-nav button { display: flex; align-items: center; gap: 12px; padding: 14px 16px; width: 100%; border: none; background: transparent; color: #a9dfbf; cursor: pointer; border-radius: 8px; transition: all 0.2s; font-size: 0.95rem; text-align: left; }
.sidebar-nav button:hover, .sidebar-nav button.active { background: #27ae60; color: white; transform: translateX(5px); }

.sidebar-footer { padding: 20px; border-top: 1px solid rgba(255,255,255,0.1); }
.user-info { display: flex; align-items: center; gap: 10px; }
.avatar { width: 36px; height: 36px; background: #2ecc71; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; color: #0e3e23; }
.details { display: flex; flex-direction: column; }
.name { font-size: 0.9rem; font-weight: 600; }
.role { font-size: 0.75rem; opacity: 0.8; }

/* MAIN CONTENT AREA */
.main-content { flex: 1; display: flex; flex-direction: column; background: #f4f6f8; height: 100%; }
.top-bar { padding: 20px 32px; background: white; border-bottom: 1px solid #e0e0e0; display: flex; justify-content: space-between; align-items: center; }
.top-bar h1 { margin: 0; font-size: 1.5rem; color: #2c3e50; }
.date-display { color: #7f8c8d; font-size: 0.9rem; }
.content-scroll-area { padding: 32px; overflow-y: auto; flex: 1; }

/* LOADING SPINNER STYLES */
.loading-container {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height: 100%;
  color: #7f8c8d;
}
.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #e0e0e0;
  border-top: 4px solid #27ae60;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 16px;
}
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>