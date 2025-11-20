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

        <div class="chart-container">
          <h3>Moving Average (7-day)</h3>
          <canvas ref="maChartCanvas"></canvas>
        </div>

        <div class="chart-container">
          <h3>Exponential Smoothing (α=0.3)</h3>
          <canvas ref="esChartCanvas"></canvas>
        </div>

        <div class="widgets">
          <div class="widget">
            <h3>Ongoing Events</h3>
            <ul>
              <li v-for="e in ongoingEvents" :key="e.id">
                {{ e.name }} ({{ e.location }})
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
      </section>

      <!-- Students Page -->
      <section v-if="currentPage === 'students'">
        <h1>Students</h1>

        <button @click="showAddStudent = true">Add Student</button>

        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Is Admin</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="s in students" :key="s.id">
              <td>{{ s.name }}</td>
              <td>{{ s.email }}</td>
              <td>{{ s.is_admin }}</td>
              <td>
                <button @click="editStudent(s)">Edit</button>
                <button @click="deleteStudent(s.id)">Delete</button>
              </td>
            </tr>
          </tbody>
        </table>
      </section>

      <!-- Events Page -->
      <section v-if="currentPage === 'events'">
        <h1>Events</h1>

        <button @click="showAddEvent = true">Add Event</button>

        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Location</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="e in events" :key="e.id">
              <td>{{ e.name }}</td>
              <td>{{ e.location }}</td>
              <td>{{ e.is_ongoing ? "Ongoing" : "Closed" }}</td>
              <td>
                <button @click="editEvent(e)">Edit</button>
                <button @click="deleteEvent(e.id)">Delete</button>
              </td>
            </tr>
          </tbody>
        </table>
      </section>

      <!-- Participation Page -->
      <section v-if="currentPage === 'participation'">
        <h1>Participation Records</h1>

        <table>
          <thead>
            <tr>
              <th>Student</th>
              <th>Event</th>
              <th>Time-in</th>
              <th>Time-out</th>
            </tr>
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

const stats = ref({
  students: 0,
  events: 0,
  participation: 0,
});

const ongoingEvents = ref([]);
const latestParticipation = ref([]);
const participationStats = ref([]);

const chartCanvas = ref(null);
const maChartCanvas = ref(null);
const esChartCanvas = ref(null);
let chartInstance;
let maChartInstance;
let esChartInstance;

// Load all data
async function loadAdminData() {
  const [stuRes, eveRes, partRes, statsRes] = await Promise.all([
    api.get("/students"),
    api.get("/events"),
    api.get("/participation"),
    api.get("/participation/stats"),
  ]);

  students.value = stuRes.data;
  events.value = eveRes.data;
  participation.value = partRes.data;
  participationStats.value = statsRes.data;

  stats.value = {
    students: students.value.length,
    events: events.value.length,
    participation: participation.value.length,
  };

  ongoingEvents.value = events.value.filter((e) => e.is_ongoing === 1);
  latestParticipation.value = participation.value.slice(0, 5);

  renderChart();
  renderMAChart();
  renderESChart();
}

function renderChart() {
  if (!chartCanvas.value) return;

  if (chartInstance) chartInstance.destroy();

  const counts = events.value.map((e) => {
    return participation.value.filter((p) => p.event_id === e.id).length;
  });

  chartInstance = new Chart(chartCanvas.value, {
    type: "bar",
    data: {
      labels: events.value.map((e) => e.name),
      datasets: [
        {
          label: "Participation Count",
          data: counts,
        },
      ],
    },
  });
}

function renderMAChart() {
  if (!maChartCanvas.value) return;

  if (maChartInstance) maChartInstance.destroy();

  if (!Array.isArray(participationStats.value) || participationStats.value.length === 0) {
    console.warn('No participation stats data available for moving average chart');
    return;
  }

  const data = participationStats.value.map(stat => stat.count);
  const labels = participationStats.value.map(stat => stat.date);

  // Compute 7-day moving average
  const maData = [];
  for (let i = 0; i < data.length; i++) {
    const start = Math.max(0, i - 6);
    const sum = data.slice(start, i + 1).reduce((a, b) => a + b, 0);
    maData.push(sum / (i - start + 1));
  }

  maChartInstance = new Chart(maChartCanvas.value, {
    type: "line",
    data: {
      labels: labels,
      datasets: [
        {
          label: "7-Day Moving Average",
          data: maData,
          borderColor: "rgba(75, 192, 192, 1)",
          backgroundColor: "rgba(75, 192, 192, 0.2)",
          fill: true,
        },
      ],
    },
    options: {
      responsive: true,
      scales: {
        x: {
          display: true,
          title: {
            display: true,
            text: 'Date'
          }
        },
        y: {
          display: true,
          title: {
            display: true,
            text: 'Participation Count'
          }
        }
      }
    }
  });
}

function renderESChart() {
  if (!esChartCanvas.value) return;

  if (esChartInstance) esChartInstance.destroy();

  if (!Array.isArray(participationStats.value) || participationStats.value.length === 0) {
    console.warn('No participation stats data available for exponential smoothing chart');
    return;
  }

  const data = participationStats.value.map(stat => stat.count);
  const labels = participationStats.value.map(stat => stat.date);

  // Compute exponential smoothing with alpha=0.3
  const alpha = 0.3;
  const esData = [];
  let smoothed = data[0] || 0;
  esData.push(smoothed);
  for (let i = 1; i < data.length; i++) {
    smoothed = alpha * data[i] + (1 - alpha) * smoothed;
    esData.push(smoothed);
  }

  esChartInstance = new Chart(esChartCanvas.value, {
    type: "line",
    data: {
      labels: labels,
      datasets: [
        {
          label: "Exponential Smoothing (α=0.3)",
          data: esData,
          borderColor: "rgba(255, 99, 132, 1)",
          backgroundColor: "rgba(255, 99, 132, 0.2)",
          fill: true,
        },
      ],
    },
    options: {
      responsive: true,
      scales: {
        x: {
          display: true,
          title: {
            display: true,
            text: 'Date'
          }
        },
        y: {
          display: true,
          title: {
            display: true,
            text: 'Participation Count'
          }
        }
      }
    }
  });
}


onMounted(() => {
  loadAdminData();
});
</script>

<style scoped>
.admin-container {
  display: flex;
  min-height: 100vh;
  background-color: var(--primary-bg);
}

.sidebar {
  width: 260px;
  background: var(--secondary-bg);
  padding: 24px;
  color: var(--text-color);
  border-right: 2px solid var(--outline-accent);
  box-shadow: 2px 0 4px rgba(0, 0, 0, 0.1);
}

.sidebar h2 {
  color: var(--accent);
  margin-bottom: 24px;
  font-size: 1.2em;
  font-weight: bold;
}

.sidebar nav {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sidebar button {
  width: 100%;
  margin-bottom: 0;
  padding: 12px 16px;
  background-color: transparent;
  color: var(--accent);
  border: 2px solid var(--outline-accent);
  border-radius: 6px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: left;
}

.sidebar button:hover {
  background-color: var(--accent);
  color: var(--primary-bg);
  transform: translateX(2px);
}

.content {
  flex: 1;
  padding: 32px;
  background-color: var(--primary-bg);
  color: var(--text-color);
  overflow-y: auto;
}

.content h1 {
  color: var(--text-color);
  margin-bottom: 32px;
  font-size: 2em;
  font-weight: 300;
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 24px;
  margin-bottom: 40px;
}

.card {
  background: rgba(102, 187, 106, 0.05);
  padding: 24px;
  border-radius: 12px;
  border: 2px solid var(--outline-accent);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: transform 0.2s ease, box-shadow 0.2s ease, background-color 0.3s ease;
}

.card:hover {
  background: rgba(102, 187, 106, 0.1);
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
}

.card h2 {
  color: var(--accent);
  margin-bottom: 16px;
  font-size: 1.1em;
  font-weight: 600;
}

.card p {
  color: var(--text-color);
  font-size: 28px;
  font-weight: bold;
  margin: 0;
}

.chart-container {
  max-width: 100%;
  margin-bottom: 40px;
  background: var(--secondary-bg);
  padding: 24px;
  border-radius: 12px;
  border: 1px solid var(--border-color);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.chart-container h3 {
  color: var(--text-color);
  margin-bottom: 20px;
  font-size: 1.2em;
  font-weight: 600;
}

.widget {
  background: rgba(102, 187, 106, 0.05);
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 24px;
  border: 2px solid var(--outline-accent);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.widget h3 {
  color: var(--accent);
  margin-bottom: 16px;
  font-size: 1.1em;
  font-weight: 600;
}

.widget ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.widget li {
  color: var(--text-color);
  padding: 8px 0;
  border-bottom: 1px solid var(--outline-accent);
  font-size: 0.95em;
}

.widget li:last-child {
  border-bottom: none;
}

table {
  width: 100%;
  border-collapse: collapse;
  background: rgba(102, 187, 106, 0.05);
  border-radius: 12px;
  overflow: hidden;
  border: 2px solid var(--outline-accent);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  margin-top: 16px;
}

th, td {
  padding: 16px;
  text-align: left;
  border-bottom: 1px solid var(--outline-accent);
}

th {
  background: rgba(102, 187, 106, 0.1);
  color: var(--text-color);
  font-weight: 600;
  font-size: 0.95em;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

td {
  color: var(--text-color);
  font-size: 0.95em;
}

tr:hover {
  background: rgba(102, 187, 106, 0.15);
  transition: background-color 0.2s ease;
}

button {
  padding: 10px 16px;
  background-color: transparent;
  color: var(--accent);
  border: 2px solid var(--outline-accent);
  border-radius: 6px;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.9em;
  transition: all 0.3s ease;
  margin-right: 8px;
}

button:hover {
  background-color: var(--accent);
  color: var(--primary-bg);
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

button:last-child {
  margin-right: 0;
}
</style>
