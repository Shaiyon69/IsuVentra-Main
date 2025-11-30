<template>
  <div class="panel-card">
    <div class="header-action">
      <h3>All Events</h3>
      <button class="btn-primary" @click="showModal = true">+ Add Event</button>
    </div>

    <table class="data-table full-width">
      <thead>
        <tr>
          <th>Title</th>
          <th>Date & Time</th>
          <th>Location</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="e in events" :key="e.id">
          <td class="font-bold">{{ e.title }}</td>
          <td>
            <div class="date-col">
              <span>{{ new Date(e.time_start).toLocaleDateString() }}</span>
              <small>{{ new Date(e.time_start).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'}) }}</small>
            </div>
          </td>
          <td>{{ e.location }}</td>
          <td>
            <span class="status-badge" :class="e.is_ongoing ? 'active' : 'closed'">
              {{ e.is_ongoing ? 'Active' : 'Closed' }}
            </span>
          </td>
        </tr>
      </tbody>
    </table>

    <BaseModal v-if="showModal" title="Create New Event" @close="showModal = false">
      <form id="eventForm" @submit.prevent="submitEvent">
        <div class="form-group">
          <label>Event Title</label>
          <input v-model="form.title" type="text" required />
        </div>
        <div class="row">
          <div class="form-group half">
            <label>Start Time</label>
            <input v-model="form.time_start" type="datetime-local" required />
          </div>
          <div class="form-group half">
            <label>End Time</label>
            <input v-model="form.time_end" type="datetime-local" required />
          </div>
        </div>
        <div class="form-group">
          <label>Location</label>
          <input v-model="form.location" type="text" required />
        </div>
        <div class="form-group">
          <label>Description (Optional)</label>
          <textarea v-model="form.description" rows="3"></textarea>
        </div>
      </form>

      <template #footer>
        <button type="button" class="btn-secondary" @click="showModal = false">Cancel</button>
        <button type="submit" form="eventForm" class="btn-primary" :disabled="isSubmitting">
          {{ isSubmitting ? 'Creating...' : 'Create Event' }}
        </button>
      </template>
    </BaseModal>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';
import api from '@/services/api';
import BaseModal from '@/components/common/BaseModal.vue';

defineProps(['events']);
const emit = defineEmits(['refresh']);

const showModal = ref(false);
const isSubmitting = ref(false);

const form = reactive({
  title: '',
  time_start: '',
  time_end: '',
  location: '',
  description: ''
});

// Helper to format datetime-local string to Laravel format (Y-m-d H:i:s)
const formatToBackend = (val) => val.replace('T', ' ') + ':00';

async function submitEvent() {
  isSubmitting.value = true;
  try {
    const payload = {
      ...form,
      time_start: formatToBackend(form.time_start),
      time_end: formatToBackend(form.time_end),
    };

    await api.post('/events', payload);
    
    // Reset & Close
    Object.assign(form, { title: '', time_start: '', time_end: '', location: '', description: '' });
    showModal.value = false;
    emit('refresh');
    alert('Event created successfully!');
  } catch (error) {
    console.error(error);
    alert('Failed to create event.');
  } finally {
    isSubmitting.value = false;
  }
}
</script>

<style scoped>
/* Same CSS as StudentsTab + textarea specific */
.panel-card { background: white; padding: 24px; border-radius: 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
.header-action { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
.header-action h3 { margin: 0; color: #2c3e50; }

.data-table { width: 100%; border-collapse: collapse; font-size: 0.95rem; }
.data-table th { text-align: left; padding: 12px; background: #f8f9fa; color: #7f8c8d; font-weight: 600; border-bottom: 2px solid #eaeaea; }
.data-table td { padding: 12px; border-bottom: 1px solid #f1f1f1; color: #2c3e50; vertical-align: middle; }
.font-bold { font-weight: 600; color: #2c3e50; }
.date-col { display: flex; flex-direction: column; line-height: 1.2; }
.date-col small { color: #95a5a6; font-size: 0.8em; }

.status-badge { padding: 4px 10px; border-radius: 20px; font-size: 0.75rem; font-weight: bold; }
.status-badge.active { background: #eafaf1; color: #27ae60; }
.status-badge.closed { background: #fdedec; color: #c0392b; }

.btn-primary { background: #27ae60; color: white; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; font-weight: 600; transition: background 0.2s; }
.btn-primary:hover { background: #219150; }
.btn-secondary { background: #ecf0f1; color: #7f8c8d; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; font-weight: 600; }

.form-group { margin-bottom: 16px; display: flex; flex-direction: column; gap: 6px; }
.form-group label { font-size: 0.85rem; font-weight: 600; color: #34495e; }
.form-group input, .form-group select, .form-group textarea { padding: 10px; border: 1px solid #dfe6e9; border-radius: 6px; font-size: 0.95rem; font-family: inherit; }
.row { display: flex; gap: 16px; }
.half { flex: 1; }
</style>