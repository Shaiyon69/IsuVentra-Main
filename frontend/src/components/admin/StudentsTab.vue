<template>
  <div class="view-panel">
    <div class="view-header">
      <div class="title-group">
        <h3>Student Directory</h3>
        <span class="count-badge">{{ students.length }} records</span>
      </div>
      <div class="action-group">
        <input type="file" ref="fileInput" accept=".csv" style="display: none" @change="handleFileUpload" />
        <Button label="Import CSV" icon="pi pi-upload" severity="secondary" outlined size="small" @click="triggerFileInput" />
        <Button label="Add Student" icon="pi pi-user-plus" severity="success" size="small" @click="showModal = true" />
      </div>
    </div>

    <div class="table-container">
      <DataTable 
        :value="students" 
        paginator 
        :rows="8" 
        stripedRows 
        class="custom-table"
        scrollable 
        scrollHeight="flex"
      >
        <template #empty><div class="empty-msg">No students found.</div></template>
        
        <Column field="student_id" header="ID" sortable style="width: 20%"></Column>
        <Column field="name" header="Full Name" sortable style="width: 30%" class="font-bold"></Column>
        <Column field="course" header="Course" sortable style="width: 20%"></Column>
        <Column field="year_lvl" header="Year" sortable style="width: 15%">
          <template #body="slotProps">
            <span class="year-badge">Year {{ slotProps.data.year_lvl }}</span>
          </template>
        </Column>
        <Column field="Department" header="Department" sortable style="width: 15%"></Column>
      </DataTable>
    </div>

    <Dialog v-model:visible="showModal" modal header="Add New Student" :style="{ width: '450px' }" class="p-fluid">
      <form @submit.prevent="submitStudent" class="form-container">
        <div class="field">
          <label>Student ID</label>
          <InputText v-model="form.student_id" placeholder="ID" required />
        </div>

        <div class="field">
          <label>Student ID</label>
          <InputText v-model="form.lrn" placeholder="LRN" required />
        </div>
        
        <div class="field">
          <label>Full Name</label>
          <InputText v-model="form.name" placeholder="Name" required />
        </div>

        <div class="form-row">
          <div class="field">
            <label>Course</label>
            <InputText v-model="form.course" placeholder="Course" required />
          </div>
          <div class="field">
            <label>Year Level</label>
            <Dropdown v-model="form.year_lvl" :options="[1,2,3,4]" placeholder="Select" />
          </div>
        </div>

        <div class="field">
          <label>Department</label>
          <InputText v-model="form.department" placeholder="Department" required />
        </div>

        <div class="dialog-footer">
          <Button label="Cancel" text severity="secondary" @click="showModal = false" />
          <Button type="submit" label="Save Student" icon="pi pi-check" :loading="isSubmitting" />
        </div>
      </form>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';
import api from '@/services/api';
import Papa from 'papaparse';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Dialog from 'primevue/dialog';
import Dropdown from 'primevue/dropdown';

const props = defineProps(['students']);
const emit = defineEmits(['refresh']);
const showModal = ref(false);
const isSubmitting = ref(false);
const fileInput = ref(null);
const form = reactive({ student_id: '', name: '', course: '', year_lvl: 1, department: '' });

async function submitStudent() {
  isSubmitting.value = true;
  try {
    await api.post('/students', form);
    Object.assign(form, { student_id: '', lrn: '', name: '', course: '', year_lvl: 1, department: '' });
    showModal.value = false;
    emit('refresh');
    alert('Student added successfully!');
  } catch (error) {
    const responseData = error.response?.data;
    if (responseData?.errors) {
      alert(`Error: ${Object.values(responseData.errors)[0][0]}`);
    } else {
      alert(responseData?.message || 'Failed to add student.');
    }
  } finally {
    isSubmitting.value = false;
  }
}

const triggerFileInput = () => fileInput.value.click();
const handleFileUpload = (event) => {
  const file = event.target.files[0];
  if (!file) return;
  Papa.parse(file, {
    header: true, skipEmptyLines: true, dynamicTyping: true, transformHeader: (h) => h.trim(),
    complete: async (results) => {
      if (!results.data[0].student_id) { alert("Invalid CSV. First column must be 'student_id'."); return; }
      if (confirm(`Ready to import ${results.data.length} students?`)) {
        try {
          await api.post('/students/import', { data: results.data });
          alert('Import Successful!'); emit('refresh');
        } catch (error) { alert('Import failed.'); }
      }
      event.target.value = '';
    }
  });
};
</script>

<style scoped>
/* Card & Header */
.view-panel {
  background: white; border-radius: 12px;
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
  display: flex; flex-direction: column; height: 100%;
  overflow: hidden;
}

.view-header {
  padding: 1.5rem; border-bottom: 1px solid #e2e8f0;
  display: flex; justify-content: space-between; align-items: center;
  background-color: #f8fafc;
}

.title-group h3 { margin: 0; font-size: 1.25rem; color: #1e293b; }
.count-badge { background: #e2e8f0; color: #475569; font-size: 0.8rem; padding: 2px 8px; border-radius: 12px; margin-left: 10px; }
.action-group { display: flex; gap: 10px; }

/* Table */
.table-container { flex: 1; overflow: hidden; display: flex; flex-direction: column; }
.custom-table { flex: 1; }
.empty-msg { text-align: center; padding: 2rem; color: #94a3b8; }
.year-badge { background: #e0f2fe; color: #0369a1; padding: 4px 10px; border-radius: 6px; font-weight: 600; font-size: 0.85rem; }
.font-bold { font-weight: 600; color: #0f172a; }

/* Form Styles */
.form-container { display: flex; flex-direction: column; gap: 1rem; margin-top: 0.5rem; }
.field { display: flex; flex-direction: column; gap: 0.5rem; }
.field label { font-size: 0.875rem; font-weight: 600; color: #475569; }
.form-row { display: flex; gap: 1rem; }
.form-row > * { flex: 1; }
.dialog-footer { display: flex; justify-content: flex-end; gap: 10px; margin-top: 1.5rem; }
</style>