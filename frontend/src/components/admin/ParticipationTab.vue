<template>
  <div class="panel-card">
    <div class="header-action">
      <h3>Participation Records</h3>
      <div class="action-buttons">
        <input type="file" ref="fileInput" accept=".csv" style="display: none" @change="handleFileUpload" />
        <button class="btn-secondary" @click="triggerFileInput">📂 Import CSV</button>
        <button class="btn-primary" @click="openModal">+ Record Participation</button>
      </div>
    </div>

    <div class="table-wrapper">
      <table class="data-table full-width">
        <thead>
          <tr>
            <th>Student</th>
            <th>Event</th>
            <th>Time In</th>
            <th>Time Out</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in participation" :key="p.id">
            <td class="font-bold">{{ p.student_name }}</td>
            <td>{{ p.event_name }}</td>
            <td>
              <div class="date-col">
                <span>{{ new Date(p.time_in).toLocaleDateString() }}</span>
                <small>{{ new Date(p.time_in).toLocaleTimeString() }}</small>
              </div>
            </td>
            <td>
              <div v-if="p.time_out" class="date-col">
                <span>{{ new Date(p.time_out).toLocaleDateString() }}</span>
                <small>{{ new Date(p.time_out).toLocaleTimeString() }}</small>
              </div>
              <span v-else class="status-badge active">Ongoing</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <BaseModal v-if="showModal" title="Manual Entry" @close="showModal = false">
      <form id="partForm" @submit.prevent="submitParticipation">

        <div class="form-group">
          <label>Select Event</label>
          <select v-model="form.event_id" required>
            <option value="" disabled>-- Choose Event --</option>
            <option v-for="e in localEvents" :key="e.id" :value="e.id">
              {{ e.title }}
            </option>
          </select>
        </div>

        <div class="form-group relative">
          <label>Select Student</label>
          <input
            type="text"
            v-model="searchQuery"
            placeholder="Type name or ID..."
            @focus="showSuggestions = true"
            @input="filterList"
            class="search-input"
            required
          />

          <ul v-if="showSuggestions && filteredStudents.length > 0" class="suggestions-list">
            <li
              v-for="s in filteredStudents"
              :key="s.id"
              @click="selectStudent(s)"
            >
              <strong>{{ s.name }}</strong> <small>({{ s.student_id }})</small>
            </li>
          </ul>
          <ul v-if="showSuggestions && filteredStudents.length === 0 && searchQuery" class="suggestions-list">
            <li class="no-result">No student found</li>
          </ul>
        </div>

        <div class="row">
          <div class="form-group half">
            <label>Time In</label>
            <input v-model="form.time_in" type="datetime-local" required />
          </div>
          <div class="form-group half">
            <label>Time Out (Optional)</label>
            <input v-model="form.time_out" type="datetime-local" />
          </div>
        </div>
      </form>

      <template #footer>
        <button type="button" class="btn-secondary" @click="showModal = false">Cancel</button>
        <button type="submit" form="partForm" class="btn-primary" :disabled="isSubmitting">
          {{ isSubmitting ? 'Saving...' : 'Save Record' }}
        </button>
      </template>
    </BaseModal>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue';
import api from '@/services/api';
import BaseModal from '@/components/common/BaseModal.vue';
import Papa from 'papaparse';

const props = defineProps(['participation']);
const emit = defineEmits(['refresh']);

const showModal = ref(false);
const isSubmitting = ref(false);
const fileInput = ref(null);

// Local lists
const localStudents = ref([]);
const localEvents = ref([]);

// Autocomplete State
const searchQuery = ref('');
const showSuggestions = ref(false);

const form = reactive({
  student_id: '', // This stores the actual database ID (hidden)
  event_id: '',
  time_in: '',
  time_out: ''
});

// --- AUTOCOMPLETE LOGIC ---
// Filter students based on name OR student_id
const filteredStudents = computed(() => {
  if (!searchQuery.value) return localStudents.value.slice(0, 5); // Show top 5 if empty
  const term = searchQuery.value.toLowerCase();
  return localStudents.value.filter(s =>
    s.name.toLowerCase().includes(term) ||
    s.student_id.toLowerCase().includes(term)
  );
});

function filterList() {
  showSuggestions.value = true;
  // Clear the actual ID if the user changes the text (forces re-selection)
  form.student_id = '';
}

function selectStudent(student) {
  form.student_id = student.id; // Store DB ID
  searchQuery.value = `${student.name} (${student.student_id})`; // Show nice text
  showSuggestions.value = false; // Hide list
}

// Reset everything when opening modal
function openModal() {
  form.student_id = '';
  form.event_id = '';
  form.time_in = '';
  form.time_out = '';
  searchQuery.value = '';
  showSuggestions.value = false;
  showModal.value = true;
}

// Close suggestions when clicking outside (Simple implementation)
// Note: In production, consider using @click-outside directive
window.addEventListener('click', (e) => {
  if (!e.target.closest('.relative')) {
    showSuggestions.value = false;
  }
});

// --- DATA LOADING ---
async function loadDropdowns() {
  try {
    const [stuRes, eveRes] = await Promise.all([
      api.get('/students'),
      api.get('/events')
    ]);
    localStudents.value = stuRes.data;
    localEvents.value = eveRes.data;
  } catch (error) {
    console.error("Failed to load dropdown options:", error);
  }
}

const formatToBackend = (val) => val ? val.replace('T', ' ') + ':00' : null;

async function submitParticipation() {
  if (!form.student_id) {
    alert("Please select a valid student from the list.");
    return;
  }

  isSubmitting.value = true;
  try {
    const payload = {
      student_id: form.student_id,
      event_id: form.event_id,
      time_in: formatToBackend(form.time_in),
      time_out: formatToBackend(form.time_out),
    };

    await api.post('/participations', payload);
    openModal(); // Reset form
    showModal.value = false;
    emit('refresh');
    alert('Record added successfully!');
  } catch (error) {
    console.error(error);
    const msg = error.response?.data?.message || 'Failed to add record.';
    alert(msg);
  } finally {
    isSubmitting.value = false;
  }
}

// --- CSV LOGIC ---
const triggerFileInput = () => fileInput.value.click();
const handleFileUpload = (event) => {
  const file = event.target.files[0];
  if (!file) return;

  Papa.parse(file, {
    header: true,
    skipEmptyLines: true,
    complete: async (results) => {
      if (!results.data[0].event_id || !results.data[0].student_id) {
        alert("Invalid CSV. Required headers: student_id, event_id, time_in");
        return;
      }
      if (confirm(`Ready to import ${results.data.length} records?`)) {
        let successCount = 0;
        for (const row of results.data) {
          try {
            await api.post('/participations', {
              student_id: row.student_id,
              event_id: row.event_id,
              time_in: row.time_in,
              time_out: row.time_out || null
            });
            successCount++;
          } catch (e) { console.error("Failed row", row, e); }
        }
        alert(`Imported ${successCount} / ${results.data.length} records.`);
        emit('refresh');
      }
      event.target.value = '';
    }
  });
};

onMounted(() => {
  loadDropdowns();
});
</script>

<style scoped>
/* Main Layout Styles */
.panel-card { background: white; padding: 24px; border-radius: 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); display: flex; flex-direction: column; height: 100%; max-height: 80vh; }
.header-action { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; flex-shrink: 0; }
.header-action h3 { margin: 0; color: #2c3e50; }
.action-buttons { display: flex; gap: 10px; }
.table-wrapper { flex: 1; overflow-y: auto; border: 1px solid #eaeaea; border-radius: 8px; }

/* Table Styles */
.data-table { width: 100%; border-collapse: separate; border-spacing: 0; font-size: 0.95rem; }
.data-table th { text-align: left; padding: 12px; background: #f8f9fa; color: #7f8c8d; font-weight: 600; border-bottom: 2px solid #eaeaea; position: sticky; top: 0; z-index: 10; }
.data-table td { padding: 12px; border-bottom: 1px solid #f1f1f1; color: #2c3e50; vertical-align: middle; }
.font-bold { font-weight: 600; color: #2c3e50; }
.date-col { display: flex; flex-direction: column; line-height: 1.2; }
.date-col small { color: #95a5a6; font-size: 0.8em; }
.status-badge { padding: 4px 10px; border-radius: 20px; font-size: 0.75rem; font-weight: bold; }
.status-badge.active { background: #eafaf1; color: #27ae60; }

/* Buttons */
.btn-primary { background: #27ae60; color: white; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; font-weight: 600; transition: background 0.2s; }
.btn-secondary { background: #ecf0f1; color: #7f8c8d; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; font-weight: 600; }

/* Form Group */
.form-group { margin-bottom: 16px; display: flex; flex-direction: column; gap: 6px; }
.form-group label { font-size: 0.85rem; font-weight: 600; color: #34495e; }
.form-group input, .form-group select { padding: 10px; border: 1px solid #dfe6e9; border-radius: 6px; font-size: 0.95rem; }
.row { display: flex; gap: 16px; }
.half { flex: 1; }

/* --- AUTOCOMPLETE STYLES --- */
.relative { position: relative; }

.search-input {
  width: 100%;
  box-sizing: border-box; /* Ensure padding doesn't break width */
}

.suggestions-list {
  position: absolute;
  top: 100%; /* Right below the input */
  left: 0;
  width: 100%;
  background: white;
  border: 1px solid #dfe6e9;
  border-top: none;
  border-radius: 0 0 6px 6px;
  max-height: 200px;
  overflow-y: auto;
  z-index: 100;
  list-style: none;
  padding: 0;
  margin: 0;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}

.suggestions-list li {
  padding: 10px 12px;
  cursor: pointer;
  border-bottom: 1px solid #f1f1f1;
  font-size: 0.95rem;
  color: #2c3e50;
}

.suggestions-list li:hover {
  background-color: #f8f9fa;
  color: #27ae60;
}

.suggestions-list li:last-child {
  border-bottom: none;
}

.no-result {
  color: #7f8c8d;
  cursor: default;
  font-style: italic;
}
</style>
