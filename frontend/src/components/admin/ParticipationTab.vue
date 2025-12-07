<template>
  <div class="view-panel">
    <div class="view-header">
      <div class="title-group">
        <h3>Participation Logs</h3>
      </div>
      <div class="action-group">
        <input type="file" ref="fileInput" accept=".csv" style="display: none" @change="handleFileUpload" />
        <Button label="Import CSV" icon="pi pi-upload" severity="secondary" outlined size="small" @click="triggerFileInput" />
        <Button label="Record Entry" icon="pi pi-plus" size="small" @click="openModal" />
      </div>
    </div>

    <div class="table-container">
      <DataTable 
        :value="participation" 
        paginator 
        :rows="10" 
        stripedRows 
        class="custom-table" 
        scrollable 
        scrollHeight="flex"
      >
        <template #empty><div class="empty-msg">No records found.</div></template>
        
        <Column field="student_name" header="Student" sortable class="font-bold"></Column>
        <Column field="event_name" header="Event" sortable></Column>
        
        <Column header="Time In" sortable field="time_in">
          <template #body="slotProps">
            {{ new Date(slotProps.data.time_in).toLocaleString() }}
          </template>
        </Column>
        
        <Column header="Time Out" sortable field="time_out">
          <template #body="slotProps">
            <span v-if="slotProps.data.time_out">{{ new Date(slotProps.data.time_out).toLocaleString() }}</span>
            <span v-else class="ongoing-tag">Ongoing</span>
          </template>
        </Column>
      </DataTable>
    </div>

    <Dialog v-model:visible="showModal" modal header="Manual Entry" :style="{ width: '450px' }" class="p-fluid">
      <form @submit.prevent="submitParticipation" class="form-container">
        
        <div class="field">
          <label>Select Event</label>
          <Dropdown 
            v-model="form.event_id" 
            :options="localEvents" 
            optionLabel="title" 
            optionValue="id" 
            placeholder="Choose Event" 
            class="w-full"
            filter
            required
          />
        </div>

        <div class="field">
          <label>Select Student</label>
          <AutoComplete 
            v-model="selectedStudent" 
            :suggestions="filteredStudents" 
            optionLabel="name" 
            placeholder="Search Name or ID" 
            @complete="searchStudent" 
            forceSelection
            dropdown
            class="w-full"
            required
          >
            <template #option="slotProps">
              <div class="autocomplete-item">
                <span class="name">{{ slotProps.option.name }}</span>
                <span class="id">({{ slotProps.option.student_id }})</span>
              </div>
            </template>
          </AutoComplete>
        </div>

        <div class="form-row">
          <div class="field">
            <label>Time In</label>
            <input type="datetime-local" v-model="form.time_in" class="p-inputtext w-full" required />
          </div>
          <div class="field">
            <label>Time Out</label>
            <input type="datetime-local" v-model="form.time_out" class="p-inputtext w-full" />
          </div>
        </div>

        <div class="dialog-footer">
          <Button label="Cancel" text severity="secondary" @click="showModal = false" />
          <Button type="submit" label="Save Record" icon="pi pi-check" :loading="isSubmitting" />
        </div>
      </form>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import api from '@/services/api';
import Papa from 'papaparse';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import Dialog from 'primevue/dialog';
import Dropdown from 'primevue/dropdown';
import AutoComplete from 'primevue/autocomplete';

const props = defineProps(['participation']);
const emit = defineEmits(['refresh']);

const showModal = ref(false);
const isSubmitting = ref(false);
const fileInput = ref(null);

// Data for dropdowns
const localStudents = ref([]);
const localEvents = ref([]);
const filteredStudents = ref([]);
const selectedStudent = ref(null);

const form = reactive({ event_id: '', time_in: '', time_out: '' });

// --- Autocomplete Logic ---
const searchStudent = (event) => {
  const query = event.query.toLowerCase();
  filteredStudents.value = localStudents.value.filter(s => 
    s.name.toLowerCase().includes(query) || s.student_id.toLowerCase().includes(query)
  );
};

const openModal = () => {
  form.event_id = ''; 
  form.time_in = ''; 
  form.time_out = ''; 
  selectedStudent.value = null; 
  showModal.value = true;
};

// --- DATA FETCHING (Corrected for Non-Paginated Lists) ---
async function loadDropdowns() {
  try {
    // We call the special "list" endpoints that return full arrays [ ... ]
    // instead of paginated objects { data: [ ... ], ... }
    const [stuRes, eveRes] = await Promise.all([
      api.get('/list/students'), 
      api.get('/list/events')
    ]);
    
    // Assign directly because these endpoints return the array root
    localStudents.value = stuRes.data; 
    localEvents.value = eveRes.data;
    
  } catch(e) { 
    console.error("Failed to load dropdown options:", e); 
  }
}

const formatToBackend = (val) => val ? val.replace('T', ' ') + ':00' : null;

async function submitParticipation() {
  if (!selectedStudent.value) { alert("Please select a student."); return; }
  
  isSubmitting.value = true;
  try {
    const payload = {
      student_id: selectedStudent.value.id,
      event_id: form.event_id,
      time_in: formatToBackend(form.time_in),
      time_out: formatToBackend(form.time_out),
    };
    await api.post('/participations', payload);
    showModal.value = false;
    emit('refresh');
    alert('Record added successfully!');
  } catch (error) { 
    alert(error.response?.data?.message || 'Failed.'); 
  } finally { 
    isSubmitting.value = false; 
  }
}

const triggerFileInput = () => fileInput.value.click();

const handleFileUpload = (event) => {
  const file = event.target.files[0];
  if (!file) return;
  Papa.parse(file, {
    header: true, 
    skipEmptyLines: true, 
    complete: async (results) => {
      if (confirm(`Import ${results.data.length} records?`)) {
        let success = 0;
        // Simple loop for now; bulk import endpoint is better for large files
        for (const row of results.data) {
          try { 
            await api.post('/participations', { 
              student_id: row.student_id, // Ensure your CSV matches backend expectation (ID vs String)
              event_id: row.event_id,
              time_in: row.time_in,
              time_out: row.time_out 
            }); 
            success++; 
          } catch(e){}
        }
        alert(`Imported ${success} records.`);
        emit('refresh');
      }
      event.target.value = '';
    }
  });
};

onMounted(loadDropdowns);
</script>

<style scoped>
/* Reuse styles from EventsTab/StudentsTab */
.view-panel { background: white; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); display: flex; flex-direction: column; height: 100%; overflow: hidden; }
.view-header { padding: 1.5rem; border-bottom: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; background-color: #f8fafc; }
.title-group h3 { margin: 0; font-size: 1.25rem; color: #1e293b; }
.action-group { display: flex; gap: 10px; }
.table-container { flex: 1; overflow: hidden; display: flex; flex-direction: column; }
.custom-table { flex: 1; }
.empty-msg { text-align: center; padding: 2rem; color: #94a3b8; }
.font-bold { font-weight: 600; color: #0f172a; }

.ongoing-tag { background: #dcfce7; color: #166534; padding: 4px 10px; border-radius: 12px; font-size: 0.85rem; font-weight: 600; }
.autocomplete-item { display: flex; justify-content: space-between; width: 100%; }
.autocomplete-item .id { color: #64748b; font-size: 0.85rem; }

/* Forms */
.form-container { display: flex; flex-direction: column; gap: 1rem; margin-top: 0.5rem; }
.field { display: flex; flex-direction: column; gap: 0.5rem; }
.field label { font-size: 0.875rem; font-weight: 600; color: #475569; }
.form-row { display: flex; gap: 1rem; }
.form-row > * { flex: 1; }
.dialog-footer { display: flex; justify-content: flex-end; gap: 10px; margin-top: 1.5rem; }
</style>