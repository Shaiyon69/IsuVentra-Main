<template>
  <div class="panel-card">
    <table class="data-table full-width">
      <thead>
        <tr>
          <th>Name</th>
          <th>Course</th>
          <th>Year</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="s in students" :key="s.id">
          <td class="font-bold">{{ s.name }}</td>
          <td>{{ s.course || 'N/A' }}</td>
          <td>{{ s.year_lvl || 'N/A' }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
defineProps({
  students: {
    type: Array,
    required: true
  }
});
</script>

<style scoped>
.panel-card { 
  background: white; 
  padding: 24px; 
  border-radius: 12px; 
  box-shadow: 0 2px 4px rgba(0,0,0,0.05); 
}

.data-table { 
  width: 100%; 
  border-collapse: collapse; 
  font-size: 0.95rem; 
}

.data-table th { 
  text-align: left; 
  padding: 12px; 
  background: #f8f9fa; 
  color: #7f8c8d; 
  font-weight: 600; 
  border-bottom: 2px solid #eaeaea; 
}

.data-table td { 
  padding: 12px; 
  border-bottom: 1px solid #f1f1f1; 
  color: #2c3e50; 
  vertical-align: middle;
}

.font-bold {
  font-weight: 600;
  color: #2c3e50;
}

.text-muted {
  color: #7f8c8d;
  font-family: 'Segoe UI', sans-serif; /* Ensures font consistency */
}
</style>