<template>
  <div class="admin-layout">
    <aside class="sidebar">
      <div class="sidebar-header">
        <h2>ISUVentra</h2>
        <span class="version">v1.1 Admin</span>
      </div>

      <nav class="sidebar-nav">
        <button
          :class="{ active: currentPage === 'overview' }"
          @click="currentPage = 'overview'">
          <span class="icon">📊</span>
          <span class="label">Overview</span>
        </button>
        <button
          :class="{ active: currentPage === 'students' }"
          @click="currentPage = 'students'">
          <span class="icon">👥</span>
          <span class="label">Students</span>
        </button>
        <button
          :class="{ active: currentPage === 'events' }"
          @click="currentPage = 'events'">
          <span class="icon">📅</span>
          <span class="label">Events</span>
        </button>
        <button
          :class="{ active: currentPage === 'participation' }"
          @click="currentPage = 'participation'">
          <span class="icon">📋</span>
          <span class="label">Participation</span>
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

      <div class="content-scroll-area">

        <section v-if="currentPage === 'overview'" class="dashboard-view">
          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-icon students-icon">🎓</div>
              <div class="stat-info">
                <span class="stat-label">Total Students</span>
                <span class="stat-value">{{ stats.students }}</span>
              </div>
            </div>
            <div class="stat-card">
              <div class="stat-icon events-icon">🎉</div>
              <div class="stat-info">
                <span class="stat-label">Total Events</span>
                <span class="stat-value">{{ stats.events }}</span>
              </div>
            </div>
            <div class="stat-card">
              <div class="stat-icon part-icon">✅</div>
              <div class="stat-info">
                <span class="stat-label">Participations</span>
                <span class="stat-value">{{ stats.participation }}</span>
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
              <div
                class="accordion-header"
                :class="{ 'open': eventData.isOpen }"
                @click="toggleForecast(baseName)"
              >
                <div class="header-content">
                  <span class="event-name">{{ baseName }}</span>
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
                    <div>
                      <strong>Analysis:</strong> {{ eventData.analysis.text }}
                    </div>
                  </div>

                  <div class="forecast-chart-wrapper">
                    <canvas :ref="(el) => setForecastRef(el, baseName)"></canvas>
                  </div>

                  <table class="data-table">
                    <thead>
                      <tr>
                        <th>Year</th>
                        <th>Actual</th>
                        <th>3-Point MA</th>
                        <th>Forecast (α=0.4)</th>
                      </tr>
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
                    <strong>{{ e.title }}</strong>
                    <small>{{ e.location }}</small>
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
                    <strong>{{ p.student_name }}</strong>
                    <small>Checked into {{ p.event_name }}</small>
                  </div>
                  <small class="time">{{ new Date(p.time_in).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) }}</small>
                </li>
              </ul>
            </div>
          </div>

        </section>

        <section v-if="currentPage === 'students'">
          <div class="panel-card">
            <table class="data-table full-width">
              <thead><tr><th>Name</th><th>Email</th><th>Role</th></tr></thead>
              <tbody>
                <tr v-for="s in students" :key="s.id">
                  <td>{{ s.name }}</td>
                  <td>{{ s.email }}</td>
                  <td><span class="role-badge" :class="s.is_admin ? 'admin' : 'user'">{{ s.is_admin ? 'Admin' : 'Student' }}</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section v-if="currentPage === 'events'">
          <div class="panel-card">
            <table class="data-table full-width">
              <thead><tr><th>Title</th><th>Location</th><th>Status</th></tr></thead>
              <tbody>
                <tr v-for="e in events" :key="e.id">
                  <td>{{ e.title }}</td>
                  <td>{{ e.location }}</td>
                  <td><span class="status-badge" :class="e.is_ongoing ? 'active' : 'closed'">{{ e.is_ongoing ? 'Active' : 'Closed' }}</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section v-if="currentPage === 'participation'">
          <div class="panel-card">
            <table class="data-table full-width">
              <thead><tr><th>Student</th><th>Event</th><th>In</th><th>Out</th></tr></thead>
              <tbody>
                <tr v-for="p in participation" :key="p.id">
                  <td>{{ p.student_name }}</td>
                  <td>{{ p.event_name }}</td>
                  <td>{{ new Date(p.time_in).toLocaleString() }}</td>
                  <td>{{ p.time_out ? new Date(p.time_out).toLocaleString() : '-' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from "vue";
import api from "@/services/api";
import Chart from "chart.js/auto";

const currentPage = ref("overview");
const students = ref([]);
const events = ref([]);
const participation = ref([]);
const stats = ref({ students: 0, events: 0, participation: 0 });
const ongoingEvents = ref([]);
const latestParticipation = ref([]);
const forecast = ref({ events: {} });
const chartCanvas = ref(null);
let chartInstance;

const forecastRefs = {};
const forecastChartInstances = {};

const pageTitle = computed(() => {
  return currentPage.value.charAt(0).toUpperCase() + currentPage.value.slice(1);
});

function setForecastRef(el, key) {
  if (el) forecastRefs[key] = el;
}

async function toggleForecast(baseName) {
  const eventData = forecast.value.events[baseName];
  eventData.isOpen = !eventData.isOpen;
  if (eventData.isOpen) {
    await nextTick();
    renderSingleForecastChart(baseName);
  }
}

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

  if (diffPercent > 10) {
    return {
      type: "positive",
      label: "Growth 📈",
      text: `ISUVentra predicts a +${diffPercent.toFixed(1)}% surge. Recommendation: Prepare to use a larger venue to accommodate students. Make sure students and facilitators are accomodated.`
    };
  } else if (diffPercent < -5) {
    return {
      type: "negative",
      label: "Decline 📉",
      text: `ISUVentra predicts a ${diffPercent.toFixed(1)}% drop. Recommendation: Check for academic conflicts (exams). Consider better dissemination methods of event details.`
    };
  } else {
    return {
      type: "neutral",
      label: "Stable ➖",
      text: `Attendance stable. Recommendation: Maintain current event standards. Focus on engagement quality.`
    };
  }
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

    // Calculations
    const ma = calculateMovingAverage(actual, 3);
    const es = calculateExponentialSmoothing(actual, 0.4);

    const forecastYears = [+(years[years.length-1])+1, +(years[years.length-1])+2, +(years[years.length-1])+3].map(String);

    // Generate Forecasts for both methods
    const forecastEs = generateForecasts(es, 3);
    const forecastMa = generateForecasts(ma.filter(v=>v!==null), 3);

    eventsForecast[base] = {
      years,
      actual,
      moving_average: ma, // Store MA history
      exponential_smoothing: es,
      forecast_years: forecastYears,
      forecast_exponential: forecastEs,
      forecast_moving_average: forecastMa, // Store MA forecast
      isOpen: false,
      analysis: generatePrescriptiveAnalysis(actual, forecastEs)
    };
  }
  return { events: eventsForecast };
}

async function loadAdminData() {
  try {
    const [stuRes, eveRes, partRes] = await Promise.all([api.get("/students"), api.get("/events"), api.get("/participation")]);
    students.value = stuRes.data;
    events.value = eveRes.data;
    participation.value = partRes.data;
    stats.value = { students: students.value.length, events: events.value.length, participation: participation.value.length };
    ongoingEvents.value = events.value.filter(e => e.is_ongoing);
    latestParticipation.value = participation.value.slice(0,5);
    forecast.value = processForecastData(participation.value, events.value);
    renderMainChart();
  } catch (err) { console.error(err); }
}

function renderMainChart() {
  if (!chartCanvas.value) return;
  if (chartInstance) chartInstance.destroy();
  const counts = events.value.map(e=>participation.value.filter(p=>p.event_id===e.id).length);
  chartInstance = new Chart(chartCanvas.value, {
    type: 'bar',
    data: {
      labels: events.value.map(e=>e.title),
      datasets: [{ label: 'Participants', data: counts, backgroundColor: '#27ae60', borderRadius: 4 }]
    },
    options: { responsive: true, maintainAspectRatio: false }
  });
}

function renderSingleForecastChart(baseName) {
  const data = forecast.value.events[baseName];
  if (!data || !forecastRefs[baseName]) return;
  if (forecastChartInstances[baseName]) forecastChartInstances[baseName].destroy();

  const labels = [...data.years, ...data.forecast_years];

  // Data Arrays
  const actual = [...data.actual, ...data.forecast_years.map(()=>null)];
  const forecastEsData = [...data.exponential_smoothing, ...data.forecast_exponential];
  const forecastMaData = [...data.moving_average, ...data.forecast_moving_average];

  forecastChartInstances[baseName] = new Chart(forecastRefs[baseName], {
    type: 'line',
    data: {
      labels,
      datasets: [
        {
          label: 'Actual',
          data: actual,
          borderColor: '#196f3d', // Dark Green
          backgroundColor: '#196f3d',
          tension: 0.1,
          borderWidth: 3
        },
        {
          label: 'Exp Smoothing (Forecast)',
          data: forecastEsData,
          borderColor: '#f39c12', // Orange
          borderDash: [5,5],
          tension: 0.3,
          borderWidth: 2
        },
        {
          label: 'Moving Average',
          data: forecastMaData,
          borderColor: '#2980b9', // Blue
          borderDash: [2,2], // Tighter dash to differentiate
          tension: 0.3,
          borderWidth: 2,
          pointRadius: 3
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'top'
        }
      }
    }
  });
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
.admin-layout {
  display: flex;
  flex-direction: row;
  height: 100vh;
  width: 100vw;
}

/* SIDEBAR STYLING */
.sidebar {
  width: 260px;
  min-width: 260px;
  background: #145A32; /* ISUVentra Green */
  color: white;
  display: flex;
  flex-direction: column;
  box-shadow: 4px 0 12px rgba(0,0,0,0.1);
  z-index: 100;
}

.sidebar-header {
  padding: 24px;
  background: rgba(0,0,0,0.1);
}
.sidebar-header h2 { margin: 0; font-size: 1.4rem; font-weight: 700; letter-spacing: 0.5px; }
.version { font-size: 0.75rem; opacity: 0.7; text-transform: uppercase; }

/* NAV - Tabs */
.sidebar-nav {
  display: flex;
  flex-direction: column;
  padding: 20px 10px;
  gap: 8px;
  flex: 1;
}

.sidebar-nav button {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  width: 100%;
  border: none;
  background: transparent;
  color: #a9dfbf;
  cursor: pointer;
  border-radius: 8px;
  transition: all 0.2s;
  font-size: 0.95rem;
  text-align: left;
}

.sidebar-nav button:hover, .sidebar-nav button.active {
  background: #27ae60;
  color: white;
  transform: translateX(5px);
}

.sidebar-footer {
  padding: 20px;
  border-top: 1px solid rgba(255,255,255,0.1);
}
.user-info { display: flex; align-items: center; gap: 10px; }
.avatar { width: 36px; height: 36px; background: #2ecc71; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; color: #0e3e23; }
.details { display: flex; flex-direction: column; }
.name { font-size: 0.9rem; font-weight: 600; }
.role { font-size: 0.75rem; opacity: 0.8; }

/* MAIN CONTENT AREA */
.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: #f4f6f8;
  height: 100%;
}

.top-bar {
  padding: 20px 32px;
  background: white;
  border-bottom: 1px solid #e0e0e0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.top-bar h1 { margin: 0; font-size: 1.5rem; color: #2c3e50; }
.date-display { color: #7f8c8d; font-size: 0.9rem; }

.content-scroll-area {
  padding: 32px;
  overflow-y: auto;
  flex: 1;
}

/* DASHBOARD WIDGETS */
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
.status-badge.closed { background: #fdedec; color: #c0392b; }

/* FORECAST ACCORDION */
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

/* DATA TABLES */
.data-table { width: 100%; border-collapse: collapse; font-size: 0.95rem; }
.data-table th { text-align: left; padding: 12px; background: #f8f9fa; color: #7f8c8d; font-weight: 600; border-bottom: 2px solid #eaeaea; }
.data-table td { padding: 12px; border-bottom: 1px solid #f1f1f1; color: #2c3e50; }
.forecast-row { background: #fafafa; color: #7f8c8d; font-style: italic; }
.role-badge.admin { background: #e8f8f5; color: #1abc9c; padding: 4px 8px; border-radius: 4px; font-weight: bold; font-size: 0.8rem; }
.role-badge.user { background: #f4f6f7; color: #7f8c8d; padding: 4px 8px; border-radius: 4px; font-weight: bold; font-size: 0.8rem; }

</style>
