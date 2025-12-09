<template>
  <div v-if="isLoading" class="global-loading">
    <div class="loading-content">
      <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" animationDuration=".5s" />
      <p>Generating Forecast models...</p>
    </div>
  </div>

  <div v-else class="view-panel">
    <div class="view-header">
      <div class="title-group">
        <h3><i class="pi pi-bolt" style="color: #064e3b; margin-right: 8px"></i> Predictive Analytics</h3>
      </div>
      <div class="action-group">
        <Button label="Refresh Data" icon="pi pi-refresh" size="small" outlined @click="fetchForecastData" />
      </div>
    </div>

    <div class="analytics-container">
      <Accordion :activeIndex="0">
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

          <div v-else class="content-wrapper">

            <div v-if="eventData.descriptive" class="descriptive-section">
                <h4 class="section-label"><i class="pi pi-history"></i> Historical Performance</h4>
                <div class="stats-grid">
                    <div class="stat-card">
                        <span class="stat-label">Avg. Attendance</span>
                        <span class="stat-value">{{ eventData.descriptive.average_attendance }}</span>
                    </div>
                    <div class="stat-card">
                        <span class="stat-label">Peak Year</span>
                        <span class="stat-value highlight">{{ eventData.descriptive.peak_year }}</span>
                        <span class="stat-sub">({{ eventData.descriptive.peak_attendance }} students)</span>
                    </div>
                    <div class="stat-card">
                        <span class="stat-label">Historical Trend</span>
                        <span class="stat-value" :class="getTrendColor(eventData.descriptive.trend_label)">
                            {{ eventData.descriptive.trend_label }}
                        </span>
                    </div>
                </div>
                <p class="descriptive-text">{{ eventData.descriptive.summary }}</p>
            </div>

            <div class="divider"></div>

            <div class="insight-container" :class="eventData.analysis.type">
              <i class="pi pi-lightbulb"></i>
              <div>
                 <span class="insight-title">Future Outlook: </span>
                 <span>{{ eventData.analysis.text }}</span>
              </div>
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
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from "vue";
import Chart from "chart.js/auto";
import api from '@/services/api';
import Accordion from 'primevue/accordion';
import AccordionTab from 'primevue/accordiontab';
import Tag from 'primevue/tag';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import ProgressSpinner from 'primevue/progressspinner';

// State
const isLoading = ref(true);
const forecast = ref({ events: {} });

// Charts
const forecastRefs = {};
const forecastChartInstances = {};

const getSeverity = (type) => {
  if (type === 'positive') return 'success';
  if (type === 'negative') return 'danger';
  return 'info';
};

const getTrendColor = (label) => {
    if(label.includes('Upward')) return 'text-green-600';
    if(label.includes('Downward')) return 'text-red-600';
    return 'text-gray-600';
}

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

// --- HELPER: Destroy charts to prevent duplicates/ghosting ---
function cleanupCharts() {
  for (const key in forecastChartInstances) {
    if (forecastChartInstances[key]) {
      forecastChartInstances[key].destroy();
      delete forecastChartInstances[key];
    }
  }
}

// --- DATA FETCHING ---
async function fetchForecastData() {
  cleanupCharts();
  isLoading.value = true;
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
    isLoading.value = false;
  }
}

// --- CHART RENDERING ---
function setForecastRef(el, key) {
  if (el) {
    forecastRefs[key] = el;
    // Because we deleted the key in cleanupCharts(), this check will now pass correctly
    if (!forecastChartInstances[key]) {
      nextTick(() => renderSingleForecastChart(key));
    }
  }
}

function renderSingleForecastChart(baseName) {
  const data = forecast.value.events[baseName];
  if (!data || !forecastRefs[baseName]) return;

  const ctx = forecastRefs[baseName].getContext('2d');

  // Double check to ensure we don't layer charts
  if (forecastChartInstances[baseName]) {
      forecastChartInstances[baseName].destroy();
  }

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
  cleanupCharts();
});

onMounted(() => {
  fetchForecastData();
});
</script>

<style scoped>
.global-loading { display: flex; justify-content: center; align-items: center; height: 60vh; width: 100%; }
.loading-content { text-align: center; color: #64748b; display: flex; flex-direction: column; gap: 1rem; font-weight: 500; }
.view-panel { background: white; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); display: flex; flex-direction: column; height: 100%; overflow: hidden; }
.view-header { padding: 1.5rem; border-bottom: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; background-color: #f8fafc; }
.analytics-container { padding: 2rem; overflow-y: auto; flex: 1; }
.accordion-custom-head { width: 100%; display: flex; justify-content: space-between; align-items: center; padding-right: 1rem; }
.event-title { font-weight: 600; color: #334155; }
.no-data-text { color: #94a3b8; font-style: italic; padding: 1rem; }

/* Insight / Future Outlook */
.insight-container { padding: 1rem; border-radius: 8px; margin-bottom: 1.5rem; display: flex; align-items: flex-start; gap: 12px; border: 1px solid transparent; }
.insight-container i { margin-top: 3px; }
.insight-title { font-weight: 700; display: block; margin-bottom: 2px; }
.insight-container.positive { background: #ecfdf5; border-color: #a7f3d0; color: #065f46; }
.insight-container.negative { background: #fef2f2; border-color: #fecaca; color: #991b1b; }
.insight-container.neutral { background: #fffbeb; border-color: #fde68a; color: #92400e; }

.forecast-chart-container { height: 350px; position: relative; width: 100%; margin-bottom: 2rem; }

/* --- Descriptive Section (New) --- */
.descriptive-section { margin-bottom: 1.5rem; }
.section-label { font-size: 0.9rem; text-transform: uppercase; letter-spacing: 0.5px; color: #64748b; margin-bottom: 1rem; display: flex; align-items: center; gap: 0.5rem; }
.stats-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-bottom: 1rem; }
.stat-card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 1rem; display: flex; flex-direction: column; align-items: center; text-align: center; }
.stat-label { font-size: 0.75rem; color: #64748b; font-weight: 600; text-transform: uppercase; margin-bottom: 4px; }
.stat-value { font-size: 1.25rem; font-weight: 700; color: #1e293b; }
.stat-value.highlight { color: #0f172a; }
.stat-sub { font-size: 0.8rem; color: #64748b; margin-top: 2px; }
.descriptive-text { font-size: 0.95rem; color: #475569; line-height: 1.5; background: #f1f5f9; padding: 0.75rem; border-radius: 6px; border-left: 4px solid #cbd5e1; }

.divider { height: 1px; background: #e2e8f0; margin: 1.5rem 0; }

.text-green-600 { color: #16a34a; }
.text-red-600 { color: #dc2626; }
.text-gray-600 { color: #4b5563; }
</style>
