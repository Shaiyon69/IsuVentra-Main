<template>
  <div class="admin-container">
    <!-- Sidebar -->
    <aside class="sidebar">
      <h2>Admin Panel</h2>
      <nav>
        <button @click="currentPage = 'overview'">Overview</button>
        <button @click="currentPage = 'students'">Students</button>
        <button @click="currentPage = 'events'">Events</button>
        <button @click="currentPage = 'participation'">Participation</button>
      </nav>
    </aside>

    <!-- Main content -->
    <main class="content">
      <!-- Overview / Dashboard -->
      <section v-if="currentPage === 'overview'">
        <h1>Dashboard Overview</h1>

        <div class="grid">
          <div class="card">
            <h2>Total Students</h2>
            <p>{{ stats.students }}</p>
          </div>
          <div class="card">
            <h2>Total Events</h2>
            <p>{{ stats.events }}</p>
          </div>
          <div class="card">
            <h2>Participation Count</h2>
            <p>{{ stats.participation }}</p>
          </div>
        </div>

        <div class="chart-container">
          <h3>Participation Chart</h3>
          <canvas ref="chartCanvas"></canvas>
        </div>

        <div class="widgets">
          <div class="widget">
            <h3>Ongoing Events</h3>
            <ul>
              <li v-for="e in ongoingEvents" :key="e.id">
                {{ e.title }} ({{ e.location }})
              </li>
            </ul>
          </div>

          <div class="widget">
            <h3>Latest Participation</h3>
            <ul>
              <li v-for="p in latestParticipation" :key="p.id">
                {{ p.student_name }} → {{ p.event_name }}
              </li>
            </ul>
          </div>
        </div>

        <!-- Forecast tables per event type -->
        <div v-for="(eventData, baseName) in forecast.events" :key="baseName" class="forecast-table">
          <h3>{{ baseName }} Forecast</h3>
          <p v-if="eventData.message">{{ eventData.message }}</p>
          <table v-else>
            <thead>
              <tr>
                <th>Year</th>
                <th>Actual</th>
                <th>3-Point MA</th>
                <th>Exponential Smoothing</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(year, index) in eventData.years" :key="year">
                <td>{{ year }}</td>
                <td>{{ eventData.actual[index] }}</td>
                <td>{{ eventData.moving_average[index] !== null ? eventData.moving_average[index].toFixed(2) : '-' }}</td>
                <td>{{ eventData.exponential_smoothing[index].toFixed(2) }}</td>
              </tr>
              <tr v-for="(year, index) in eventData.forecast_years" :key="year + '-forecast'">
                <td>{{ year }} (Forecast)</td>
                <td>-</td>
                <td>{{ eventData.forecast_moving_average[index].toFixed(2) }}</td>
                <td>{{ eventData.forecast_exponential[index].toFixed(2) }}</td>
              </tr>
            </tbody>
          </table>
        </div>

      </section>

      <!-- Students Page -->
      <section v-if="currentPage === 'students'">
        <h1>Students</h1>
        <table>
          <thead>
            <tr><th>Name</th><th>Email</th><th>Is Admin</th></tr>
          </thead>
          <tbody>
            <tr v-for="s in students" :key="s.id">
              <td>{{ s.name }}</td>
              <td>{{ s.email }}</td>
              <td>{{ s.is_admin }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <!-- Events Page -->
      <section v-if="currentPage === 'events'">
        <h1>Events</h1>
        <table>
          <thead>
            <tr><th>Title</th><th>Location</th><th>Status</th></tr>
          </thead>
          <tbody>
            <tr v-for="e in events" :key="e.id">
              <td>{{ e.title }}</td>
              <td>{{ e.location }}</td>
              <td>{{ e.is_ongoing ? "Ongoing" : "Closed" }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <!-- Participation Page -->
      <section v-if="currentPage === 'participation'">
        <h1>Participation Records</h1>
        <table>
          <thead>
            <tr><th>Student</th><th>Event</th><th>Time-in</th><th>Time-out</th></tr>
          </thead>
          <tbody>
            <tr v-for="p in participation" :key="p.id">
              <td>{{ p.student_name }}</td>
              <td>{{ p.event_name }}</td>
              <td>{{ p.time_in }}</td>
              <td>{{ p.time_out }}</td>
            </tr>
          </tbody>
        </table>
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
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

function calculateExponentialSmoothing(data, alpha = 0.3) {
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
      eventsForecast[base] = { message: 'Not enough data', years, actual, moving_average: [], exponential_smoothing: [], forecast_years: [], forecast_moving_average: [], forecast_exponential: [] };
      continue;
    }
    const ma = calculateMovingAverage(actual,3);
    const es = calculateExponentialSmoothing(actual,0.3);
    const forecastYears = [+(years[years.length-1])+1, +(years[years.length-1])+2, +(years[years.length-1])+3].map(String);
    eventsForecast[base] = { years, actual, moving_average: ma, exponential_smoothing: es, forecast_years: forecastYears, forecast_moving_average: generateForecasts(ma.filter(v=>v!==null),3), forecast_exponential: generateForecasts(es,3) };
  }
  return { events: eventsForecast };
}

async function loadAdminData() {
  const [stuRes, eveRes, partRes] = await Promise.all([api.get("/students"), api.get("/events"), api.get("/participation")]);
  students.value = stuRes.data;
  events.value = eveRes.data;
  participation.value = partRes.data;
  stats.value = { students: students.value.length, events: events.value.length, participation: participation.value.length };
  ongoingEvents.value = events.value.filter(e => e.is_ongoing);
  latestParticipation.value = participation.value.slice(0,5);
  forecast.value = processForecastData(participation.value, events.value);
  renderChart();
}

function renderChart() {
  if (!chartCanvas.value) return;
  if (chartInstance) chartInstance.destroy();
  const counts = events.value.map(e=>participation.value.filter(p=>p.event_id===e.id).length);
  chartInstance = new Chart(chartCanvas.value, { type: 'bar', data: { labels: events.value.map(e=>e.title), datasets: [{ label: 'Participation Count', data: counts }] } });
}

onMounted(loadAdminData);
</script>

<style scoped>
.admin-container { display: flex; min-height: 100vh; }
.sidebar { width: 260px; background: #2c3e50; padding: 24px; color: #ecf0f1; }
.sidebar h2 { margin-bottom: 24px; }
.sidebar button { width: 100%; margin-bottom: 8px; padding: 12px; background: #34495e; color: #ecf0f1; border: none; cursor: pointer; }
.sidebar button:hover { background: #1abc9c; }
.content { flex:1; padding: 32px; background: #ecf0f1; overflow-y: auto; }
.grid { display: grid; grid-template-columns: repeat(auto-fit,minmax(200px,1fr)); gap:24px; margin-bottom:32px; }
.card { background: #fff; padding:24px; border-radius:12px; box-shadow:0 2px 8px rgba(0,0,0,0.1); }
.card h2 { margin-bottom:16px; font-weight:600; }
.card p { font-size:24px; font-weight:bold; }
.chart-container { background:#fff; padding:24px; border-radius:12px; margin-bottom:32px; }
.widget { background:#fff; padding:16px; border-radius:12px; margin-bottom:24px; }
.forecast-table { background:#fff; padding:16px; border-radius:12px; margin-bottom:32px; }
.forecast-table table { width:100%; border-collapse:collapse; margin-top:8px; }
.forecast-table th, .forecast-table td { padding:8px; text-align:center; border:1px solid #bdc3c7; }
.forecast-table th { background:#ecf0f1; }
table { width:100%; border-collapse:collapse; margin-top:16px; background:#fff; border-radius:8px; overflow:hidden; }
th, td { padding:12px; text-align:left; border-bottom:1px solid #bdc3c7; }
tr:hover { background:#ecf0f1; }
</style>
