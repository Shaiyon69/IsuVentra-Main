<template>
  <div class="overview-grid">
    <div class="stats-row">
      <div class="stat-card blue">
        <div class="icon-box"><i class="pi pi-users"></i></div>
        <div class="stat-content">
          <span class="stat-label">Total Students</span>
          <span class="stat-value">{{ students.length }}</span>
        </div>
      </div>
      
      <div class="stat-card purple">
        <div class="icon-box"><i class="pi pi-calendar"></i></div>
        <div class="stat-content">
          <span class="stat-label">Total Events</span>
          <span class="stat-value">{{ events.length }}</span>
        </div>
      </div>

      <div class="stat-card green">
        <div class="icon-box"><i class="pi pi-check-circle"></i></div>
        <div class="stat-content">
          <span class="stat-label">Participations</span>
          <span class="stat-value">{{ participation.length }}</span>
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
      
      <Accordion :activeIndex="null">
        <AccordionTab v-for="(eventData, baseName) in forecast.events" :key="baseName">
          <template #header>
            <div class="accordion-custom-head">
              <span class="event-title">{{ baseName }}</span>
              <Tag v-if="eventData.analysis" :value="eventData.analysis.label" :severity="getSeverity(eventData.analysis.type)" />
            </div>
          </template>

          <div v-if="eventData.message" class="no-data-text">{{ eventData.message }}</div>
          
          <div v-else>
            <div class="insight-container" :class="eventData.analysis.type">
              <i class="pi pi-lightbulb"></i>
              <p><strong>Analysis:</strong> {{ eventData.analysis.text }}</p>
            </div>

            <div class="forecast-chart-container">
              <canvas :ref="(el) => setForecastRef(el, baseName)"></canvas>
            </div>

            <DataTable :value="getForecastTableData(eventData)" size="small" stripedRows class="forecast-table">
              <Column field="year" header="Year"></Column>
              <Column field="actual" header="Actual"></Column>
              <Column field="ma" header="3-Pt Moving Avg"></Column>
              <Column field="es" header="Exp. Smoothing">
                <template #body="slotProps">
                  <span :style="slotProps.data.year.includes('Proj') ? 'font-weight:bold; color:#10b981' : ''">
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
          <li v-if="ongoingEvents.length === 0" class="empty-list">No active events right now.</li>
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
            <span class="time-stamp">{{ new Date(p.time_in).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) }}</span>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, nextTick } from "vue";
import Chart from "chart.js/auto";
import Accordion from 'primevue/accordion';
import AccordionTab from 'primevue/accordiontab';
import Tag from 'primevue/tag';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';

const props = defineProps(['students', 'events', 'participation']);

const forecast = ref({ events: {} });
const chartCanvas = ref(null);
const forecastRefs = {};
let chartInstance = null;
const forecastChartInstances = {};

const ongoingEvents = computed(() => props.events.filter(e => e.is_ongoing));
const latestParticipation = computed(() => props.participation.slice(0,5));

// --- STYLE HELPERS ---
const getSeverity = (type) => {
  if (type === 'positive') return 'success';
  if (type === 'negative') return 'danger';
  return 'info';
};

// --- DATA PROCESSING HELPERS ---
const getForecastTableData = (eventData) => {
  const rows = [];
  eventData.years.forEach((y, i) => {
    rows.push({
      year: y,
      actual: eventData.actual[i],
      ma: eventData.moving_average[i]?.toFixed(2) || '-',
      es: eventData.exponential_smoothing[i]?.toFixed(2)
    });
  });
  eventData.forecast_years.forEach((y, i) => {
    rows.push({
      year: y + ' (Proj)',
      actual: '-',
      ma: eventData.forecast_moving_average[i]?.toFixed(2),
      es: eventData.forecast_exponential[i]?.toFixed(2)
    });
  });
  return rows;
};

function getBaseEventName(title) {
  const parts = title.split(" ");
  const lastPart = parts[parts.length - 1];
  if (/^\d{4}$/.test(lastPart)) parts.pop();
  return parts.join(" ");
}

function calculateMovingAverage(data, window = 3) {
  const result = [];
  for (let i = 0; i < data.length; i++) {
    if (i < window - 1) { result.push(null); continue; }
    const slice = data.slice(i - window + 1, i + 1);
    result.push(slice.reduce((a,b)=>a+b,0)/window);
  }
  return result;
}

function calculateExponentialSmoothing(data, alpha = 0.4) {
  if (!data.length) return [];
  const result = [data[0]];
  for (let i = 1; i < data.length; i++) {
    result.push(alpha*data[i] + (1-alpha)*result[i-1]);
  }
  return result;
}

function generateForecasts(smoothedData, horizon = 3) {
  if (!smoothedData.length || smoothedData.length < 2) return Array(horizon).fill(null);
  const lastValue = smoothedData[smoothedData.length - 1];
  const trend = lastValue - smoothedData[smoothedData.length - 2];
  return Array.from({length: horizon}, (_, i) => Math.max(0, +(lastValue + trend*(i+1)).toFixed(2)));
}

function generatePrescriptiveAnalysis(actualData, forecastData) {
  if (!actualData.length || !forecastData.length) return { text: "Insufficient data.", type: "neutral", label: "Unknown" };
  const recentActual = actualData.slice(-3).reduce((a, b) => a + b, 0) / Math.min(3, actualData.length);
  const avgForecast = forecastData.reduce((a, b) => a + b, 0) / forecastData.length;
  const diffPercent = ((avgForecast - recentActual) / recentActual) * 100;

  if (diffPercent > 10) return { type: "positive", label: "Growth 📈", text: `ISUVentra predicts a +${diffPercent.toFixed(1)}% surge.` };
  else if (diffPercent < -5) return { type: "negative", label: "Decline 📉", text: `ISUVentra predicts a ${diffPercent.toFixed(1)}% drop.` };
  else return { type: "neutral", label: "Stable ➖", text: `Attendance stable.` };
}

function processForecastData(participations, events) {
  const eventMap = {};
  const grouped = {};
  events.forEach(e => { 
    const base = getBaseEventName(e.title);
    eventMap[e.id] = base; 
    if (!grouped[base]) grouped[base] = {}; 
  });
  participations.forEach(p => {
    if (!p.time_in || !p.event_id) return;
    const base = eventMap[p.event_id]; 
    if (!base) return;
    const year = new Date(p.time_in).getFullYear().toString();
    if (!grouped[base][year]) grouped[base][year] = 0;
    grouped[base][year]++;
  });
  const eventsForecast = {};
  for (const base in grouped) {
    const yearly = grouped[base];
    const years = Object.keys(yearly).sort();
    const actual = years.map(y => yearly[y]);
    if (actual.length < 2) {
      eventsForecast[base] = { 
        message: actual.length === 0 ? 'No participation data recorded yet.' : 'Insufficient historical data for prediction (Needs at least 2 years).', 
        isOpen: false 
      };
      continue;
    }
    const ma = calculateMovingAverage(actual, 3);
    const es = calculateExponentialSmoothing(actual, 0.4);
    const lastYearInt = parseInt(years[years.length - 1]);
    const forecastYears = [lastYearInt + 1, lastYearInt + 2, lastYearInt + 3].map(String);
    const forecastEs = generateForecasts(es, 3);
    const forecastMa = generateForecasts(ma.filter(v => v !== null), 3);
    eventsForecast[base] = {
      years, actual, moving_average: ma, exponential_smoothing: es,
      forecast_years: forecastYears, forecast_exponential: forecastEs, forecast_moving_average: forecastMa,
      isOpen: false, analysis: generatePrescriptiveAnalysis(actual, forecastEs)
    };
  }
  return { events: eventsForecast };
}

// --- RENDERING ---
function renderMainChart() {
  if (!chartCanvas.value) return;
  if (chartInstance) chartInstance.destroy();
  const counts = props.events.map(e => props.participation.filter(p => p.event_id === e.id).length);
  chartInstance = new Chart(chartCanvas.value, {
    type: 'bar',
    data: {
      labels: props.events.map(e => e.title),
      datasets: [{ label: 'Participants', data: counts, backgroundColor: '#10b981', borderRadius: 4 }]
    },
    options: { responsive: true, maintainAspectRatio: false }
  });
}

function setForecastRef(el, key) {
  // PrimeVue Accordion lazy loads DOM. This captures it when opened.
  if (el) {
    forecastRefs[key] = el;
    renderSingleForecastChart(key);
  }
}

function renderSingleForecastChart(baseName) {
  const data = forecast.value.events[baseName];
  if (!data || !forecastRefs[baseName]) return;
  if (forecastChartInstances[baseName]) { forecastChartInstances[baseName].destroy(); delete forecastChartInstances[baseName]; }

  forecastChartInstances[baseName] = new Chart(forecastRefs[baseName], {
    type: 'line',
    data: {
      labels: [...data.years, ...data.forecast_years],
      datasets: [
        { label: 'Actual', data: [...data.actual, ...data.forecast_years.map(()=>null)], borderColor: '#064e3b', backgroundColor: '#064e3b', tension: 0.1, borderWidth: 3 },
        { label: 'Exp Smoothing', data: [...data.exponential_smoothing, ...data.forecast_exponential], borderColor: '#f59e0b', borderDash: [5,5], tension: 0.3, borderWidth: 2 },
        { label: 'Moving Avg', data: [...data.moving_average, ...data.forecast_moving_average], borderColor: '#3b82f6', borderDash: [2,2], tension: 0.3, borderWidth: 2, pointRadius: 3 }
      ]
    },
    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'top' } } }
  });
}

onMounted(() => {
  forecast.value = processForecastData(props.participation, props.events);
  renderMainChart();
});
</script>

<style scoped>
.overview-grid {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

/* --- STATS CARDS --- */
.stats-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
}

.stat-card {
  background: white;
  border-radius: 16px;
  padding: 1.5rem;
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
  display: flex;
  align-items: center;
  gap: 1.5rem;
  border-left: 5px solid transparent;
  transition: transform 0.2s;
}
.stat-card:hover { transform: translateY(-3px); }
.stat-card.blue { border-left-color: #3b82f6; }
.stat-card.purple { border-left-color: #a855f7; }
.stat-card.green { border-left-color: #10b981; }

.icon-box {
  width: 60px; height: 60px; border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
  font-size: 1.5rem;
}
.blue .icon-box { background: #eff6ff; color: #3b82f6; }
.purple .icon-box { background: #faf5ff; color: #a855f7; }
.green .icon-box { background: #ecfdf5; color: #10b981; }

.stat-content { display: flex; flex-direction: column; }
.stat-label { font-size: 0.8rem; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; }
.stat-value { font-size: 2rem; font-weight: 800; color: #1e293b; line-height: 1.1; }

/* --- CONTENT CARDS --- */
.dashboard-card {
  background: white;
  border-radius: 16px;
  padding: 1.5rem;
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
}

.card-header { margin-bottom: 1.5rem; border-bottom: 1px solid #f1f5f9; padding-bottom: 1rem; }
.card-header h3 { margin: 0; font-size: 1.25rem; color: #1e293b; font-weight: 700; }
.chart-wrapper { height: 350px; position: relative; }

/* --- AI SECTION --- */
.ai-header h3 { color: #064e3b; display: flex; align-items: center; gap: 8px; }
.accordion-custom-head { width: 100%; display: flex; justify-content: space-between; align-items: center; padding-right: 1rem; }
.event-title { font-weight: 600; color: #334155; }
.no-data-text { color: #94a3b8; font-style: italic; padding: 1rem; }

.insight-container {
  padding: 1rem; border-radius: 8px; margin-bottom: 1.5rem;
  display: flex; align-items: center; gap: 12px;
  border: 1px solid transparent;
}
.insight-container.positive { background: #ecfdf5; border-color: #a7f3d0; color: #065f46; }
.insight-container.negative { background: #fef2f2; border-color: #fecaca; color: #991b1b; }
.insight-container.neutral { background: #fffbeb; border-color: #fde68a; color: #92400e; }

.forecast-chart-container { height: 300px; margin-bottom: 2rem; }

/* --- SPLIT ROW --- */
.split-row { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 1.5rem; }
.activity-list { list-style: none; padding: 0; margin: 0; }
.activity-list li { display: flex; justify-content: space-between; align-items: center; padding: 1rem 0; border-bottom: 1px solid #f1f5f9; }
.activity-detail { display: flex; flex-direction: column; }
.activity-detail strong { font-size: 0.95rem; color: #334155; }
.activity-detail small { color: #64748b; }
.time-stamp { color: #94a3b8; font-size: 0.85rem; }
.empty-list { color: #94a3b8; padding: 1rem 0; font-style: italic; }
</style>