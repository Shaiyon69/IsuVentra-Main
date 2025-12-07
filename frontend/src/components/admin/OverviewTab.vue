<template>
  <div class="overview-grid">
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

    <div class="dashboard-card">
      <div class="card-header ai-header">
        <h3><i class="pi pi-bolt"></i> AI Predictive Analytics</h3>
      </div>
      
      <div v-if="loadingForecast" class="loading-state">
        <i class="pi pi-spin pi-spinner text-2xl"></i>
        <p>Crunching numbers...</p>
      </div>

      <Accordion v-else :activeIndex="null">
        <AccordionTab v-for="(eventData, baseName) in forecast.events" :key="baseName">
          <template #header>
            <div class="accordion-custom-head">
              <span class="event-title">{{ baseName }}</span>
              <Tag 
                v-if="eventData.analysis" 
                :value="eventData.analysis.label" 
                :severity="getSeverity(eventData.analysis.type)" 
              />
            </div>
          </template>

          <div v-if="eventData.message" class="no-data-text">
            {{ eventData.message }}
          </div>
          
          <div v-else>
            <div class="insight-container" :class="eventData.analysis.type">
              <i class="pi pi-lightbulb"></i>
              <p><strong>Analysis:</strong> {{ eventData.analysis.text }}</p>
            </div>

            <div class="forecast-chart-container">
              <canvas :ref="(el) => setForecastRef(el, baseName)"></canvas>
            </div>

            <DataTable :value="eventData.rows" size="small" stripedRows class="forecast-table">
              <Column field="year" header="Year"></Column>
              <Column field="actual" header="Actual"></Column>
              <Column field="ma" header="3-Pt Moving Avg"></Column>
              <Column field="es" header="Exp. Smoothing">
                <template #body="slotProps">
                  <span :class="{'font-bold text-green-600': slotProps.data.year.includes('Proj')}">
                    {{ slotProps.data.es }}
                  </span>
                </template>
              </Column>
            </DataTable>
          </div>
        </AccordionTab>
      </Accordion>
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
import Accordion from 'primevue/accordion';
import AccordionTab from 'primevue/accordiontab';
import Tag from 'primevue/tag';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';

// Props passed from AdminPanel.vue (These contain PAGINATED data, Page 1 only)
const props = defineProps(['students', 'events', 'participation']);

// State
const stats = ref({ students: 0, events: 0, participations: 0 });
const forecast = ref({ events: {} });
const loadingForecast = ref(true);
const chartCanvas = ref(null);

// Non-reactive storage
const forecastRefs = {};
const forecastChartInstances = {};
let mainChartInstance = null;

// Computed (These are fine to rely on props because "Ongoing" and "Latest" 
// usually appear on the first page of results anyway)
const ongoingEvents = computed(() => props.events.filter(e => e.is_ongoing));
const latestParticipation = computed(() => props.participation.slice(0, 5));

const getSeverity = (type) => {
  if (type === 'positive') return 'success';
  if (type === 'negative') return 'danger';
  return 'info';
};

// --- DATA PROCESSING ---
const formatRows = (eventData) => {
  const rows = [];
  eventData.years.forEach((y, i) => {
    rows.push({
      year: String(y),
      actual: eventData.actual[i],
      ma: eventData.moving_average[i] !== null ? Number(eventData.moving_average[i]).toFixed(2) : '-',
      es: Number(eventData.exponential_smoothing[i]).toFixed(2)
    });
  });
  eventData.forecast_years.forEach((y, i) => {
    rows.push({
      year: String(y) + ' (Proj)',
      actual: '-',
      ma: Number(eventData.forecast_moving_average[i]).toFixed(2),
      es: Number(eventData.forecast_exponential[i]).toFixed(2)
    });
  });
  return rows;
};

// --- API FETCHES ---

// 1. Fetch Forecast (AI)
async function fetchForecastData() {
  try {
    const res = await api.get('/analytics/forecast');
    const data = res.data;
    for (const key in data.events) {
      if (!data.events[key].message) {
        data.events[key].rows = formatRows(data.events[key]);
      }
    }
    forecast.value = data;
  } catch (e) {
    console.error("Forecast Error:", e);
  } finally {
    loadingForecast.value = false;
  }
}

// 2. Fetch Dashboard Stats (For Main Chart & Cards)
// This fixes the "Only 15 events" issue by fetching aggregates from backend
async function fetchDashboardStats() {
  try {
    const res = await api.get('/analytics/stats');
    
    // Update top cards
    stats.value = res.data.counts;

    // Update Main Chart
    renderMainChart(res.data.chart_data);
  } catch (e) {
    console.error("Stats Error:", e);
  }
}

// --- MAIN CHART RENDERING ---
function renderMainChart(chartData) {
  if (!chartCanvas.value || !chartData) return;
  
  if (mainChartInstance) mainChartInstance.destroy();

  // Extract data from the new backend response
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

// --- AI CHART RENDERING ---
function setForecastRef(el, key) {
  if (el) {
    forecastRefs[key] = el;
    if (!forecastChartInstances[key]) {
      nextTick(() => renderSingleForecastChart(key));
    }
  }
}

function renderSingleForecastChart(baseName) {
  const data = forecast.value.events[baseName];
  if (!data || !forecastRefs[baseName]) return;

  const ctx = forecastRefs[baseName].getContext('2d');
  if (forecastChartInstances[baseName]) forecastChartInstances[baseName].destroy();

  forecastChartInstances[baseName] = new Chart(ctx, {
    type: 'line',
    data: {
      labels: [...data.years, ...data.forecast_years],
      datasets: [
        { label: 'Actual', data: [...data.actual, ...data.forecast_years.map(()=>null)], borderColor: '#064e3b', backgroundColor: '#064e3b', tension: 0.1 },
        { label: 'Exp Smoothing', data: [...data.exponential_smoothing, ...data.forecast_exponential], borderColor: '#f59e0b', borderDash: [5,5], tension: 0.3 },
        { label: 'Moving Avg', data: [...data.moving_average, ...data.forecast_moving_average], borderColor: '#3b82f6', borderDash: [2,2], tension: 0.3 }
      ]
    },
    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'top' } } }
  });
}

onBeforeUnmount(() => {
  if (mainChartInstance) mainChartInstance.destroy();
  for (const key in forecastChartInstances) {
    if (forecastChartInstances[key]) forecastChartInstances[key].destroy();
  }
});

onMounted(() => {
  // We no longer rely on props for the chart or stats. 
  // We fetch fresh aggregates.
  fetchForecastData();
  fetchDashboardStats();
});
</script>

<style scoped>
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
.ai-header h3 { color: #064e3b; display: flex; align-items: center; gap: 8px; }
.loading-state { text-align: center; padding: 2rem; color: #64748b; }
.accordion-custom-head { width: 100%; display: flex; justify-content: space-between; align-items: center; padding-right: 1rem; }
.event-title { font-weight: 600; color: #334155; }
.no-data-text { color: #94a3b8; font-style: italic; padding: 1rem; }
.insight-container { padding: 1rem; border-radius: 8px; margin-bottom: 1.5rem; display: flex; align-items: center; gap: 12px; border: 1px solid transparent; }
.insight-container.positive { background: #ecfdf5; border-color: #a7f3d0; color: #065f46; }
.insight-container.negative { background: #fef2f2; border-color: #fecaca; color: #991b1b; }
.insight-container.neutral { background: #fffbeb; border-color: #fde68a; color: #92400e; }
.forecast-chart-container { height: 300px; position: relative; width: 100%; margin-bottom: 2rem; }
.split-row { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 1.5rem; }
.activity-list { list-style: none; padding: 0; margin: 0; }
.activity-list li { display: flex; justify-content: space-between; align-items: center; padding: 1rem 0; border-bottom: 1px solid #f1f5f9; }
.activity-detail { display: flex; flex-direction: column; }
.activity-detail strong { font-size: 0.95rem; color: #334155; }
.activity-detail small { color: #64748b; }
.time-stamp { color: #94a3b8; font-size: 0.85rem; }
.empty-list { color: #94a3b8; padding: 1rem 0; font-style: italic; }
</style>