<template>
  <div class="pass-container">
    <div class="digital-id-card">
      <div class="card-header">
        <div class="logo-icon"><i class="pi pi-id-card"></i></div>
        <h3>Event Pass</h3>
      </div>

      <div v-if="studentId" class="qr-section">
        <div class="qr-wrapper">
          <QrcodeVue 
            :value="studentId" 
            :size="220" 
            level="H" 
            background="#ffffff" 
            foreground="#000000"
            render-as="svg"
          />
        </div>
        
        <div class="student-details">
          <h2 class="student-name">{{ auth.user.name }}</h2>
          <div class="id-badge">
            <span class="label">ID NO.</span>
            <span class="value">{{ studentId }}</span>
          </div>
          <p class="course-info">{{ auth.user.student?.course || 'Student' }}</p>
        </div>
      </div>

      <div v-else class="error-state">
        <i class="pi pi-exclamation-circle"></i>
        <p>No Student ID found associated with this account.</p>
      </div>

      <div class="card-footer">
        <p>Show this code to an Admin to check in.</p>
        <Button label="Back to Dashboard" icon="pi pi-arrow-left" text @click="$router.push('/dashboard')" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from "vue"; 
import { useAuthStore } from "@/stores/auth";
import api from "@/services/api"; 
import QrcodeVue from 'qrcode.vue';
import Button from 'primevue/button';

const auth = useAuthStore();

// Safely access student ID
const studentId = computed(() => {
  return auth.user?.student?.student_id || auth.user?.student_id || null;
});

onMounted(async () => {
  if (!studentId.value) {
    try {
      const res = await api.get('/user');
      auth.setAuth(res.data, auth.token);
    } catch (e) {
      console.error("Failed to refresh user profile", e);
    }
  }
});
</script>

<style scoped>
.pass-container {
  min-height: 100vh;
  background-color: #f1f5f9; 
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.digital-id-card {
  background: white;
  width: 100%;
  max-width: 360px;
  border-radius: 24px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  overflow: hidden;
  text-align: center;
  position: relative;
}


.card-header {
  background: #064e3b;
  color: white;
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.logo-icon {
  font-size: 2rem;
  background: rgba(255, 255, 255, 0.2);
  width: 50px;
  height: 50px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.card-header h3 {
  margin: 0;
  font-weight: 600;
  letter-spacing: 1px;
  text-transform: uppercase;
  font-size: 0.9rem;
}


.qr-section {
  padding: 2rem 1.5rem;
  background: white;
}

.qr-wrapper {
  background: white;
  padding: 15px;
  border: 2px dashed #e2e8f0;
  border-radius: 12px;
  display: inline-block;
  margin-bottom: 1.5rem;
}

.student-name {
  margin: 0 0 0.5rem 0;
  color: #1e293b;
  font-size: 1.25rem;
  font-weight: 700;
}

.id-badge {
  background: #ecfdf5;
  color: #047857;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 16px;
  border-radius: 20px;
  font-family: monospace;
  font-size: 1.1rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
  border: 1px solid #a7f3d0;
}

.id-badge .label {
  font-size: 0.7rem;
  opacity: 0.7;
}

.course-info {
  color: #64748b;
  font-size: 0.9rem;
  margin: 0;
}

/* Footer */
.card-footer {
  background: #f8fafc;
  padding: 1.5rem;
  border-top: 1px solid #e2e8f0;
}

.card-footer p {
  color: #94a3b8;
  font-size: 0.8rem;
  margin-top: 0;
  margin-bottom: 1rem;
}

/* Error State */
.error-state {
  padding: 3rem;
  color: #ef4444;
}
.error-state i {
  font-size: 2rem;
  margin-bottom: 1rem;
}
</style>