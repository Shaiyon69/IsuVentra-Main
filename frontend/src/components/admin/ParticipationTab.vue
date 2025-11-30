<template>
  <div class="panel-card">
    <table class="data-table full-width">
      <thead>
        <tr>
          <th>Student</th>
          <th>Event</th>
          <th>In</th>
          <th>Out</th>
        </tr>
      </thead>
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
</template>

<script setup>
defineProps(['participation']);
</script>

<style scoped>
.panel-card { background: white; padding: 24px; border-radius: 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
.data-table { width: 100%; border-collapse: collapse; font-size: 0.95rem; }
.data-table th { text-align: left; padding: 12px; background: #f8f9fa; color: #7f8c8d; font-weight: 600; border-bottom: 2px solid #eaeaea; }
.data-table td { padding: 12px; border-bottom: 1px solid #f1f1f1; color: #2c3e50; }
</style>