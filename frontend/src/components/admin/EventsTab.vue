<template>
  <div class="panel-card">
    <table class="data-table full-width">
      <thead>
        <tr>
          <th>Title</th>
          <th>Location</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="e in events" :key="e.id">
          <td>{{ e.title }}</td>
          <td>{{ e.location }}</td>
          <td>
            <span class="status-badge" :class="e.is_ongoing ? 'active' : 'closed'">
              {{ e.is_ongoing ? 'Active' : 'Closed' }}
            </span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
defineProps(['events']);
</script>

<style scoped>
.panel-card { background: white; padding: 24px; border-radius: 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
.data-table { width: 100%; border-collapse: collapse; font-size: 0.95rem; }
.data-table th { text-align: left; padding: 12px; background: #f8f9fa; color: #7f8c8d; font-weight: 600; border-bottom: 2px solid #eaeaea; }
.data-table td { padding: 12px; border-bottom: 1px solid #f1f1f1; color: #2c3e50; }
.status-badge { padding: 4px 10px; border-radius: 20px; font-size: 0.75rem; font-weight: bold; }
.status-badge.active { background: #eafaf1; color: #27ae60; }
.status-badge.closed { background: #fdedec; color: #c0392b; }
</style>