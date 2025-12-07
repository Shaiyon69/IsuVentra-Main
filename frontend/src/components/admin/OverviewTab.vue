<template>
  <div v-if="isLoading" class="global-loading">
    <div class="loading-content">
      <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" animationDuration=".5s" />
      <p>Loading Dashboard...</p>
    </div>
  </div>

  <div v-else class="overview-grid">
    <div class="stats-row">
      <div class="stat-card blue">
        <div class="icon-box"><i class="pi pi-users"></i></div>
        <div class="stat-content">
          <span class="stat-label">Total Students</span>
          <span class="stat-value">{{ stats.students }}</span>
        </div>
      </div>
      
      <div class="stat-card purple">
        <div class="icon-box"><i class="pi pi-calendar"></i></div>
        <div class="stat-content">
          <span class="stat-label">Total Events</span>
          <span class="stat-value">{{ stats.events }}</span>
        </div>
      </div>

      <div class="stat-card green">
        <div class="icon-box"><i class="pi pi-check-circle"></i></div>
        <div class="stat-content">
          <span class="stat-label">Participations</span>
          <span class="stat-value">{{ stats.participations }}</span>
        </div>
      </div>
    </div>

    <div class="dashboard-card chart-card">
      <div class="card-header">
        <h3>Event Popularity Overview</h3>
      </div>
      <div class="chart-wrapper">
        <canvas ref="chartCanvas"></canvas>
      </div>
    </div>

    <div class="split-row">
      <div class="dashboard-card">
        <div class="card-header">
          <h3>🔴 Ongoing Events</h3>
        </div>
        <ul class="activity-list">
          <li v-for="e in ongoingEvents" :key="e.id">
            <div class="activity-detail">
              <strong>{{ e.title }}</strong>
              <small>{{ e.location }}</small>
            </div>
            <Tag value="LIVE" severity="danger" />
          </li>
          <li v-if="ongoingEvents.length === 0" class="empty-list">No active events.</li>
        </ul>
      </div>

      <div class="dashboard-card">
        <div class="card-header">
          <h3>🕒 Recent Activity</h3>
        </div>
        <ul class="activity-list">
          <li v-for="p in latestParticipation" :key="p.id">
            <div class="activity-detail">
              <strong>{{ p.student_name }}</strong>
              <small>Checked into {{ p.event_name }}</small>
            </div>
            <span class="time-stamp">
              {{ new Date(p.time_in).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) }}
            </span>
          </li>
          <li v-if="latestParticipation.length === 0" class="empty-list">No recent activity.</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, computed, nextTick } from "vue";
import Chart from "chart.js/auto";
import api from '@/services/api'; 
import Tag from 'primevue/tag';
import ProgressSpinner from 'primevue/progressspinner';

const props = defineProps(['students', 'events', 'participation']);

// State
const isLoading = ref(true);
const stats = ref({ students: 0, events: 0, participations: 0 });
const chartCanvas = ref(null);

let mainChartInstance = null;
let chartDataTemp = null; 

const ongoingEvents = computed(() => props.events.filter(e => e.is_ongoing));
const latestParticipation = computed(() => props.participation.slice(0, 5));

// --- DATA LOGIC ---
async function fetchDashboardStats() {
  const res = await api.get('/analytics/stats');
  stats.value = res.data.counts;
  chartDataTemp = res.data.chart_data; 
}

// --- CHART RENDERING ---
function renderMainChart(chartData) {
  if (!chartCanvas.value || !chartData) return;
  if (mainChartInstance) mainChartInstance.destroy();

  const labels = chartData.map(item => item.title);
  const counts = chartData.map(item => item.total);
  
  mainChartInstance = new Chart(chartCanvas.value, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [{ 
        label: 'Participants', 
        data: counts, 
        backgroundColor: '#10b981', 
        borderRadius: 4 
      }]
    },
    options: { 
      responsive: true, 
      maintainAspectRatio: false,
      scales: { y: { beginAtZero: true } }
    }
  });
}

onBeforeUnmount(() => {
  if (mainChartInstance) mainChartInstance.destroy();
});

onMounted(async () => {
  isLoading.value = true;
  try {
    await fetchDashboardStats();
  } catch (e) {
    console.error("Dashboard Load Error:", e);
  } finally {
    isLoading.value = false;
    nextTick(() => {
      if (chartDataTemp) renderMainChart(chartDataTemp);
    });
  }
});
</script>

<style scoped>
/* Only Dashboard specific styles kept */
.global-loading { display: flex; justify-content: center; align-items: center; height: 60vh; width: 100%; }
.loading-content { text-align: center; color: #64748b; display: flex; flex-direction: column; gap: 1rem; font-weight: 500; }
.overview-grid { display: flex; flex-direction: column; gap: 2rem; width: 100%; }
.stats-row { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; }
.stat-card { background: white; border-radius: 16px; padding: 1.5rem; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); display: flex; align-items: center; gap: 1.5rem; border-left: 5px solid transparent; transition: transform 0.2s; }
.stat-card:hover { transform: translateY(-3px); }
.stat-card.blue { border-left-color: #3b82f6; }
.stat-card.purple { border-left-color: #a855f7; }
.stat-card.green { border-left-color: #10b981; }
.icon-box { width: 60px; height: 60px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; }
.blue .icon-box { background: #eff6ff; color: #3b82f6; }
.purple .icon-box { background: #faf5ff; color: #a855f7; }
.green .icon-box { background: #ecfdf5; color: #10b981; }
.stat-content { display: flex; flex-direction: column; }
.stat-label { font-size: 0.8rem; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; }
.stat-value { font-size: 2rem; font-weight: 800; color: #1e293b; line-height: 1.1; }
.dashboard-card { background: white; border-radius: 16px; padding: 1.5rem; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); display: flex; flex-direction: column; }
.card-header { margin-bottom: 1.5rem; border-bottom: 1px solid #f1f5f9; padding-bottom: 1rem; }
.card-header h3 { margin: 0; font-size: 1.25rem; color: #1e293b; font-weight: 700; }
.chart-wrapper { height: 350px; position: relative; width: 100%; }
.split-row { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 1.5rem; }
.activity-list { list-style: none; padding: 0; margin: 0; }
.activity-list li { display: flex; justify-content: space-between; align-items: center; padding: 1rem 0; border-bottom: 1px solid #f1f5f9; }
.activity-detail { display: flex; flex-direction: column; }
.activity-detail strong { font-size: 0.95rem; color: #334155; }
.activity-detail small { color: #64748b; }
.time-stamp { color: #94a3b8; font-size: 0.85rem; }
.empty-list { color: #94a3b8; padding: 1rem 0; font-style: italic; }
</style>