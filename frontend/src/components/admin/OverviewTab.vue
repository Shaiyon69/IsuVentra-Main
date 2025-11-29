<template>
  <div class="dashboard-view">
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon students-icon">🎓</div>
        <div class="stat-info">
          <span class="stat-label">Total Students</span>
          <span class="stat-value">{{ students.length }}</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon events-icon">🎉</div>
        <div class="stat-info">
          <span class="stat-label">Total Events</span>
          <span class="stat-value">{{ events.length }}</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon part-icon">✅</div>
        <div class="stat-info">
          <span class="stat-label">Participations</span>
          <span class="stat-value">{{ participation.length }}</span>
        </div>
      </div>
    </div>

    <div class="panel-card chart-panel">
      <h3>Event Popularity Overview</h3>
      <div class="chart-container">
        <canvas ref="chartCanvas"></canvas>
      </div>
    </div>

    <div class="forecast-section">
      <h2 class="section-title">AI Predictive Analytics</h2>

      <div v-for="(eventData, baseName) in forecast.events" :key="baseName" class="forecast-accordion">
        <div class="accordion-header" :class="{ 'open': eventData.isOpen }" @click="toggleForecast(baseName)">
          <div class="header-content">
            <span class="event-name">{{ baseName }}:</span>
            <span v-if="eventData.analysis" class="trend-tag" :class="eventData.analysis.type">
              {{ eventData.analysis.label }}
            </span>
          </div>
          <span class="arrow">{{ eventData.isOpen ? '▲' : '▼' }}</span>
        </div>

        <div v-if="eventData.isOpen" class="accordion-body">
          <p v-if="eventData.message">{{ eventData.message }}</p>
          <div v-else>
            <div class="insight-box" :class="eventData.analysis.type">
              <div class="insight-icon">💡</div>
              <div><strong>Analysis:</strong> {{ eventData.analysis.text }}</div>
            </div>

            <div class="forecast-chart-wrapper">
              <canvas :ref="(el) => setForecastRef(el, baseName)"></canvas>
            </div>

            <table class="data-table">
              <thead>
                <tr><th>Year</th><th>Actual</th><th>3-Point MA</th><th>Exp. Smoothing</th></tr>
              </thead>
              <tbody>
                <tr v-for="(year, index) in eventData.years" :key="year">
                  <td>{{ year }}</td>
                  <td>{{ eventData.actual[index] }}</td>
                  <td>{{ eventData.moving_average[index] !== null ? eventData.moving_average[index].toFixed(2) : '-' }}</td>
                  <td>{{ eventData.exponential_smoothing[index].toFixed(2) }}</td>
                </tr>
                <tr v-for="(year, index) in eventData.forecast_years" :key="year" class="forecast-row">
                  <td>{{ year }} (Proj.)</td>
                  <td>-</td>
                  <td>{{ eventData.forecast_moving_average[index].toFixed(2) }}</td>
                  <td><strong>{{ eventData.forecast_exponential[index].toFixed(2) }}</strong></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <div class="split-grid">
      <div class="panel-card">
        <h3>🔴 Ongoing Events</h3>
        <ul class="activity-list">
          <li v-for="e in ongoingEvents" :key="e.id">
            <div class="activity-item">
              <strong>{{ e.title }}</strong><small>{{ e.location }}</small>
            </div>
            <span class="status-badge active">Live</span>
          </li>
          <li v-if="ongoingEvents.length === 0" class="empty-msg">No active events.</li>
        </ul>
      </div>

      <div class="panel-card">
        <h3>🕒 Recent Activity</h3>
        <ul class="activity-list">
          <li v-for="p in latestParticipation" :key="p.id">
            <div class="activity-item">
              <strong>{{ p.student_name }}</strong><small>Checked into {{ p.event_name }}</small>
            </div>
            <small class="time">{{ new Date(p.time_in).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) }}</small>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick, computed } from "vue";
import Chart from "chart.js/auto";

const props = defineProps(['students', 'events', 'participation']);

const forecast = ref({ events: {} });
const chartCanvas = ref(null);
const forecastRefs = {};
let chartInstance = null;
const forecastChartInstances = {};

const ongoingEvents = computed(() => props.events.filter(e => e.is_ongoing));
const latestParticipation = computed(() => props.participation.slice(0,5));

// --- HELPER FUNCTIONS ---
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
  events.forEach(e => { eventMap[e.id] = { title: e.title, baseName: getBaseEventName(e.title) }; });
  const grouped = {};
  participations.forEach(p => {
    if (!p.time_in || !p.event_id) return;
    const ev = eventMap[p.event_id]; if (!ev) return;
    const base = ev.baseName;
    const year = new Date(p.time_in).getFullYear().toString();
    if (!grouped[base]) grouped[base] = {};
    if (!grouped[base][year]) grouped[base][year] = 0;
    grouped[base][year]++;
  });

  const eventsForecast = {};
  for (const base in grouped) {
    const yearly = grouped[base];
    const years = Object.keys(yearly).sort();
    const actual = years.map(y=>yearly[y]);
    if (actual.length < 2) {
      eventsForecast[base] = { message: 'Insufficient data.', isOpen: false };
      continue;
    }
    const ma = calculateMovingAverage(actual, 3);
    const es = calculateExponentialSmoothing(actual, 0.4);
    const forecastYears = [+(years[years.length-1])+1, +(years[years.length-1])+2, +(years[years.length-1])+3].map(String);
    const forecastEs = generateForecasts(es, 3);
    const forecastMa = generateForecasts(ma.filter(v=>v!==null), 3);
    eventsForecast[base] = {
      years, actual, moving_average: ma, exponential_smoothing: es,
      forecast_years: forecastYears, forecast_exponential: forecastEs, forecast_moving_average: forecastMa,
      isOpen: false, analysis: generatePrescriptiveAnalysis(actual, forecastEs)
    };
  }
  return { events: eventsForecast };
}

// --- CHART RENDERING ---
function renderMainChart() {
  if (!chartCanvas.value) return;
  if (chartInstance) chartInstance.destroy();
  const counts = props.events.map(e => props.participation.filter(p => p.event_id === e.id).length);
  chartInstance = new Chart(chartCanvas.value, {
    type: 'bar',
    data: {
      labels: props.events.map(e => e.title),
      datasets: [{ label: 'Participants', data: counts, backgroundColor: '#27ae60', borderRadius: 4 }]
    },
    options: { responsive: true, maintainAspectRatio: false }
  });
}

function setForecastRef(el, key) {
  if (el) forecastRefs[key] = el;
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
        { label: 'Actual', data: [...data.actual, ...data.forecast_years.map(()=>null)], borderColor: '#196f3d', backgroundColor: '#196f3d', tension: 0.1, borderWidth: 3 },
        { label: 'Exp Smoothing', data: [...data.exponential_smoothing, ...data.forecast_exponential], borderColor: '#f39c12', borderDash: [5,5], tension: 0.3, borderWidth: 2 },
        { label: 'Moving Avg', data: [...data.moving_average, ...data.forecast_moving_average], borderColor: '#2980b9', borderDash: [2,2], tension: 0.3, borderWidth: 2, pointRadius: 3 }
      ]
    },
    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'top' } } }
  });
}

async function toggleForecast(baseName) {
  const eventData = forecast.value.events[baseName];
  if (eventData.isOpen && forecastChartInstances[baseName]) { forecastChartInstances[baseName].destroy(); delete forecastChartInstances[baseName]; }
  eventData.isOpen = !eventData.isOpen;
  if (eventData.isOpen) { await nextTick(); renderSingleForecastChart(baseName); }
}

onMounted(() => {
  forecast.value = processForecastData(props.participation, props.events);
  renderMainChart();
});
</script>

<style scoped>
.stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 24px; margin-bottom: 24px; }
.stat-card { background: white; padding: 20px; border-radius: 12px; display: flex; align-items: center; gap: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); border-left: 4px solid transparent; }
.stat-card:nth-child(1) { border-color: #3498db; }
.stat-card:nth-child(2) { border-color: #9b59b6; }
.stat-card:nth-child(3) { border-color: #27ae60; }
.stat-icon { font-size: 2rem; }
.stat-info { display: flex; flex-direction: column; }
.stat-label { font-size: 0.85rem; color: #7f8c8d; text-transform: uppercase; font-weight: 600; }
.stat-value { font-size: 1.8rem; font-weight: 800; color: #2c3e50; }

.panel-card { background: white; padding: 24px; border-radius: 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); margin-bottom: 24px; }
.chart-panel { height: 400px; display: flex; flex-direction: column; }
.chart-container { flex: 1; position: relative; }

.split-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px; margin-bottom: 24px; }
.activity-list { list-style: none; padding: 0; margin: 0; }
.activity-list li { display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #f0f0f0; }
.activity-item { display: flex; flex-direction: column; }
.activity-item small { color: #95a5a6; }
.status-badge { padding: 4px 10px; border-radius: 20px; font-size: 0.75rem; font-weight: bold; }
.status-badge.active { background: #eafaf1; color: #27ae60; }

/* FORECAST ACCORDION CSS */
.forecast-section { margin-top: 40px; }
.section-title { color: #145A32; font-size: 1.25rem; margin-bottom: 16px; border-left: 5px solid #27ae60; padding-left: 12px; }
.forecast-accordion { margin-bottom: 16px; background: white; border-radius: 8px; border: 1px solid #e0e0e0; overflow: hidden; }
.accordion-header { padding: 16px 20px; display: flex; justify-content: space-between; align-items: center; cursor: pointer; background: #fdfdfd; transition: background 0.2s; }
.accordion-header:hover { background: #f4f6f6; }
.header-content { display: flex; align-items: center; gap: 12px; }
.event-name { font-weight: 600; color: #2c3e50; }
.trend-tag { font-size: 0.7rem; padding: 2px 8px; border-radius: 4px; font-weight: 700; text-transform: uppercase; }
.trend-tag.positive { background: #eafaf1; color: #27ae60; }
.trend-tag.negative { background: #fdedec; color: #c0392b; }
.trend-tag.neutral { background: #f4f6f7; color: #7f8c8d; }
.accordion-body { padding: 24px; border-top: 1px solid #f0f0f0; }
.insight-box { display: flex; gap: 12px; padding: 16px; border-radius: 8px; background: #fafafa; border-left: 4px solid #ccc; margin-bottom: 20px; }
.insight-box.positive { border-color: #27ae60; background: #eafaf1; }
.insight-box.negative { border-color: #e74c3c; background: #fdedec; }
.insight-box.neutral { border-color: #f39c12; background: #fef9e7; }
.forecast-chart-wrapper { height: 280px; margin-bottom: 24px; }
.data-table { width: 100%; border-collapse: collapse; font-size: 0.95rem; }
.data-table th { text-align: left; padding: 12px; background: #f8f9fa; color: #7f8c8d; font-weight: 600; border-bottom: 2px solid #eaeaea; }
.data-table td { padding: 12px; border-bottom: 1px solid #f1f1f1; color: #2c3e50; }
.forecast-row { background: #fafafa; color: #7f8c8d; font-style: italic; }
</style>