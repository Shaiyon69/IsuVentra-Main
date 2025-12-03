<template>
  <div class="dashboard-container">
    <header class="page-header">
      <h1>Student Dashboard</h1>
      <p class="subtitle">Welcome to ISUVentra</p>
    </header>

    <div class="action-bar">
      <button @click="$router.push('/join')" class="scan-btn">
        <span class="icon"></span> Scan QR to Join
      </button>
    </div>

    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>Loading events...</p>
    </div>

    <div v-else-if="events.length" class="events-grid">
      <div v-for="e in events" :key="e.id" class="event-card">
        
        <div class="card-top">
          <span 
            class="status-badge" 
            :class="e.is_ongoing ? 'status-live' : 'status-default'"
          >
            {{ e.is_ongoing ? '🔴 LIVE NOW' : '📅 EVENT' }}
          </span>
        </div>

        <h3 class="event-title">{{ e.title || e.name }}</h3>

        <div class="event-meta">
          <div class="meta-item">
            <span class="meta-icon">📍</span>
            <span>{{ e.location }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-icon">🕒</span>
            <span>{{ formatDate(e.time_start) }}</span>
          </div>
        </div>

        <p class="event-desc">{{ truncate(e.description, 100) }}</p>

        <div class="card-footer">
          <span class="footer-text">View Details →</span>
        </div>
      </div>
    </div>

    <div v-else class="empty-state">
      <div class="empty-icon">📅</div>
      <h3>No Events Found</h3>
      <p>Check back later for upcoming campus activities.</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import api from "@/services/api";

const events = ref([]);
const loading = ref(true);

async function fetchEvents() {
  try {
    const res = await api.get("/events");
    events.value = res.data.events ?? res.data;
  } catch (err) {
    console.error("Error fetching events:", err);
  } finally {
    loading.value = false;
  }
}

// Helper: Format Date nicely (e.g., "Oct 25, 2:00 PM")
function formatDate(dateString) {
  if (!dateString) return "TBA";
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', { 
    month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' 
  });
}

// Helper: Truncate long descriptions
function truncate(text, length) {
  if (!text) return "No description provided.";
  return text.length > length ? text.substring(0, length) + "..." : text;
}

onMounted(() => {
  fetchEvents();
});
</script>

<style scoped>
.dashboard-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px 20px;
}

/* Header Styling */
.page-header {
  text-align: center;
  margin-bottom: 40px;
}

h1 {
  color: var(--text-color);
  font-size: 2.5rem;
  font-weight: 700;
  margin: 0;
  letter-spacing: -0.5px;
}

.subtitle {
  color: #7f8c8d;
  font-size: 1.1rem;
  margin-top: 8px;
}

/* Action Bar */
.action-bar {
  display: flex;
  justify-content: center;
  margin-bottom: 50px;
}

.scan-btn {
  padding: 16px 32px;
  background-color: var(--accent);
  color: white;
  border: none;
  border-radius: 50px; /* Pill shape */
  font-size: 1.1rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 4px 15px rgba(39, 174, 96, 0.3); /* Green shadow */
  display: flex;
  align-items: center;
  gap: 10px;
}

.scan-btn:hover {
  background-color: var(--light-accent);
  transform: translateY(-3px);
  box-shadow: 0 8px 25px rgba(39, 174, 96, 0.4);
}

/* Grid Layout */
.events-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); /* Responsive columns */
  gap: 30px;
}

/* Event Card Design */
.event-card {
  background-color: white;
  border-radius: 16px;
  border: 1px solid var(--border-color);
  padding: 24px;
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
}

.event-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 12px 30px rgba(0, 0, 0, 0.08);
  border-color: var(--light-accent);
}

.card-top {
  margin-bottom: 12px;
}

.status-badge {
  font-size: 0.75rem;
  font-weight: 800;
  padding: 4px 12px;
  border-radius: 20px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.status-live {
  background-color: #ffebee;
  color: #c62828;
}

.status-default {
  background-color: #f1f8e9;
  color: var(--text-color);
}

.event-title {
  font-size: 1.4rem;
  color: var(--text-color);
  margin: 0 0 16px 0;
  line-height: 1.3;
}

.event-meta {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 20px;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #546e7a;
  font-size: 0.95rem;
}

.event-desc {
  color: #78909c;
  font-size: 0.95rem;
  line-height: 1.6;
  margin-bottom: 20px;
  flex-grow: 1; /* Pushes footer down */
}

.card-footer {
  padding-top: 16px;
  border-top: 1px solid #f0f0f0;
}

.footer-text {
  color: var(--accent);
  font-weight: 600;
  font-size: 0.9rem;
}

/* Empty & Loading States */
.loading-state, .empty-state {
  text-align: center;
  padding: 60px 0;
  color: #90a4ae;
}

.spinner {
  width: 40px; height: 40px; border: 4px solid #eceff1; border-top: 4px solid var(--accent); border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 20px;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 16px;
  opacity: 0.5;
}

@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
</style>