<template>
  <div class="panel-card">
    <div class="header-action">
      <h3>All Students</h3>
      <div class="action-buttons">
        <input 
          type="file" 
          ref="fileInput" 
          accept=".csv" 
          style="display: none" 
          @change="handleFileUpload" 
        />
        
        <button class="btn-secondary" @click="triggerFileInput">
          📂 Import CSV
        </button>

        <button class="btn-primary" @click="showModal = true">+ Add Student</button>
      </div>
    </div>

    <table class="data-table full-width">
      <thead>
        <tr>
          <th>ID</th>
          <th>Name</th>
          <th>Course</th>
          <th>Year</th>
          <th>Campus</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="s in students" :key="s.id">
          <td>{{ s.student_id }}</td>
          <td class="font-bold">{{ s.name }}</td>
          <td>{{ s.course }}</td>
          <td>{{ s.year_lvl }}</td>
          <td>{{ s.campus }}</td>
        </tr>
      </tbody>
    </table>

    <BaseModal v-if="showModal" title="Add New Student" @close="showModal = false">
      <form id="studentForm" @submit.prevent="submitStudent">
        <div class="form-group">
          <label>Student ID</label>
          <input v-model="form.student_id" type="text" required placeholder="e.g. 21-12345" />
        </div>
        <div class="form-group">
          <label>Full Name</label>
          <input v-model="form.name" type="text" required placeholder="John Doe" />
        </div>
        <div class="row">
          <div class="form-group half">
            <label>Course</label>
            <input v-model="form.course" type="text" required placeholder="BSCS" />
          </div>
          <div class="form-group half">
            <label>Year Level</label>
            <select v-model="form.year_lvl" required>
              <option v-for="n in 5" :key="n" :value="n">{{ n }}</option>
            </select>
          </div>
        </div>
        <div class="form-group">
          <label>Campus</label>
          <input v-model="form.campus" type="text" required placeholder="Main Campus" />
        </div>
      </form>

      <template #footer>
        <button type="button" class="btn-secondary" @click="showModal = false">Cancel</button>
        <button type="submit" form="studentForm" class="btn-primary" :disabled="isSubmitting">
          {{ isSubmitting ? 'Saving...' : 'Save Student' }}
        </button>
      </template>
    </BaseModal>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';
import api from '@/services/api';
import BaseModal from '@/components/common/BaseModal.vue';
import Papa from 'papaparse'; // Import PapaParse

const props = defineProps({
  students: { type: Array, required: true }
});

const emit = defineEmits(['refresh']);

const showModal = ref(false);
const isSubmitting = ref(false);
const fileInput = ref(null); // Reference to the hidden input

const form = reactive({
  student_id: '',
  name: '',
  course: '',
  year_lvl: 1,
  campus: ''
});

async function submitStudent() {
  isSubmitting.value = true;
  try {
    await api.post('/students', form);
    Object.assign(form, { student_id: '', name: '', course: '', year_lvl: 1, campus: '' });
    showModal.value = false;
    emit('refresh'); 
    alert('Student added successfully!');
  } catch (error) {
    console.error(error);
    alert('Failed to add student. Check console for details.');
  } finally {
    isSubmitting.value = false;
  }
}

// --- CSV IMPORT LOGIC ---
const triggerFileInput = () => {
  fileInput.value.click();
};

const handleFileUpload = (event) => {
  const file = event.target.files[0];
  if (!file) return;

  Papa.parse(file, {
    header: true,
    skipEmptyLines: true,
    complete: async (results) => {
      // Basic validation: check for first column header
      if (!results.data[0].student_id) {
        alert("Invalid CSV Format. Please ensure the first column is 'student_id'.");
        return;
      }

      if (confirm(`Ready to import ${results.data.length} students?`)) {
        try {
          // Send the parsed array to the Laravel endpoint we created
          await api.post('/students/import', { data: results.data });
          alert('Import Successful!');
          emit('refresh'); // Refresh the table
        } catch (error) {
          console.error(error);
          alert(error.response?.data?.message || 'Import failed.');
        } finally {
          event.target.value = ''; // Reset input to allow re-uploading same file
        }
      } else {
        event.target.value = '';
      }
    }
  });
};
</script>

<style scoped>
.panel-card { background: white; padding: 24px; border-radius: 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
.header-action { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
.header-action h3 { margin: 0; color: #2c3e50; }

/* Wrapper for the buttons */
.action-buttons { display: flex; gap: 10px; }

.data-table { width: 100%; border-collapse: collapse; font-size: 0.95rem; }
.data-table th { text-align: left; padding: 12px; background: #f8f9fa; color: #7f8c8d; font-weight: 600; border-bottom: 2px solid #eaeaea; }
.data-table td { padding: 12px; border-bottom: 1px solid #f1f1f1; color: #2c3e50; vertical-align: middle; }
.font-bold { font-weight: 600; color: #2c3e50; }

.btn-primary { background: #27ae60; color: white; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; font-weight: 600; transition: background 0.2s; }
.btn-primary:hover { background: #219150; }
.btn-primary:disabled { opacity: 0.7; cursor: not-allowed; }
.btn-secondary { background: #ecf0f1; color: #7f8c8d; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; font-weight: 600; }
.btn-secondary:hover { background: #bdc3c7; }

.form-group { margin-bottom: 16px; display: flex; flex-direction: column; gap: 6px; }
.form-group label { font-size: 0.85rem; font-weight: 600; color: #34495e; }
.form-group input, .form-group select { padding: 10px; border: 1px solid #dfe6e9; border-radius: 6px; font-size: 0.95rem; }
.row { display: flex; gap: 16px; }
.half { flex: 1; }
</style>