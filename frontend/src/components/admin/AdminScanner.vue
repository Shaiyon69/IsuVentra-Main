<template>
  <div class="scanner-wrapper">
    <div class="scanner-card">
      <div class="header">
        <h3><i class="pi pi-camera"></i> Admin Event Scanner</h3>
      </div>

      <div class="controls">
        <div class="field">
          <label>Select Event to Scan For:</label>
          <Dropdown 
            v-model="selectedEventId" 
            :options="events" 
            optionLabel="title" 
            optionValue="id" 
            placeholder="Choose an Event" 
            class="w-full"
            :disabled="isScanning"
          />
        </div>
      </div>

      <div v-if="selectedEventId" class="camera-section">
        <div class="viewport-container" v-show="isScanning">
          <video ref="video" class="camera-feed" muted playsinline></video>
          <div class="overlay">
            <div class="scan-frame"></div>
          </div>
        </div>

        <div class="viewport-placeholder" v-if="!isScanning">
          <i class="pi pi-camera" style="font-size: 3rem; color: #cbd5e1;"></i>
          <p>Camera Paused</p>
        </div>

        <div class="camera-controls">
          <Button 
            :label="isScanning ? 'Stop Camera' : 'Start Scanning'" 
            :icon="isScanning ? 'pi pi-stop' : 'pi pi-play'" 
            :severity="isScanning ? 'danger' : 'success'"
            @click="toggleCamera" 
          />
        </div>

        <div v-if="error" class="error-banner">
          <i class="pi pi-exclamation-triangle"></i> {{ error }}
        </div>
      </div>

      <div v-else class="placeholder-box">
        <i class="pi pi-calendar" style="font-size: 2rem; margin-bottom: 10px; color: #94a3b8;"></i>
        <p>Please select an event to start scanning.</p>
      </div>

      <div class="logs-section" v-if="logs.length > 0">
        <h4>Recent Activity</h4>
        <div class="log-list">
          <div v-for="(log, index) in logs" :key="index" class="log-item" :class="log.status">
            <div class="log-content">
              <span class="log-id">{{ log.student_id }}</span>
              <span class="log-msg">{{ log.message }}</span>
            </div>
            <span class="log-time">{{ log.time }}</span>
          </div>
        </div>
      </div>
    </div>

    <Dialog 
      v-model:visible="showConfirmModal" 
      modal 
      :header="modalHeader" 
      :style="{ width: '90vw', maxWidth: '400px' }"
      :closable="false"
    >
      <div class="confirmation-content" v-if="studentDetails">
        <div class="student-avatar">
          <img v-if="studentDetails.profile_url" :src="studentDetails.profile_url" alt="Student" />
          <i v-else class="pi pi-user"></i>
        </div>

        <div class="student-details-grid">
            <div class="detail-row full-width">
                <label>Student Name</label>
                <div class="value highlight">{{ studentDetails.name }}</div>
            </div>
            
            <div class="detail-row">
                <label>ID Number</label>
                <div class="value">{{ scannedStudentId }}</div>
            </div>

            <div class="detail-row">
                <label>Year Level</label>
                <div class="value">{{ studentDetails.year }}</div>
            </div>

            <div class="detail-row full-width" v-if="currentParticipationStatus === 'active'">
                <div class="status-badge active">
                    <i class="pi pi-clock"></i> Currently Timed In
                </div>
            </div>
            <div class="detail-row full-width" v-if="currentParticipationStatus === 'completed'">
                <div class="status-badge completed">
                   <i class="pi pi-check-circle"></i> Event Completed
                </div>
            </div>

            <div class="detail-row full-width">
                <label>Course</label>
                <div class="value">{{ studentDetails.course }}</div>
            </div>

            <div class="detail-row full-width">
                <label>Department</label>
                <div class="value">{{ studentDetails.department }}</div>
            </div>
        </div>
      </div>
      
      <div v-else class="loading-state">
        <i class="pi pi-spin pi-spinner"></i> Checking details...
      </div>

      <template #footer>
        <div class="dialog-actions">
          <Button label="Cancel" icon="pi pi-times" text severity="secondary" @click="cancelScan" />
          
          <Button 
            v-if="currentParticipationStatus === 'none' || currentParticipationStatus === 'not_found'"
            label="Confirm Time In" 
            icon="pi pi-check" 
            severity="success" 
            @click="executeAction" 
          />
          
          <Button 
            v-else-if="currentParticipationStatus === 'active'"
            label="Confirm Time Out" 
            icon="pi pi-sign-out" 
            severity="warning" 
            @click="executeAction" 
          />
          
          <Button 
             v-else
             label="Already Completed" 
             icon="pi pi-lock" 
             severity="secondary" 
             disabled
          />
        </div>
      </template>
    </Dialog>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from "vue";
import { BrowserQRCodeReader } from "@zxing/browser";
import api from "@/services/api";
import Dropdown from 'primevue/dropdown';
import Button from 'primevue/button';
import Dialog from 'primevue/dialog';

// State
const events = ref([]);
const selectedEventId = ref(null);
const isScanning = ref(false);
const video = ref(null);
const error = ref(null);
const logs = ref([]);

// Modal & Student Data State
const showConfirmModal = ref(false);
const scannedStudentId = ref(null);
const studentDetails = ref(null);
const currentParticipationStatus = ref('none'); // 'none', 'active', 'completed'

// Computed Header Title
const modalHeader = computed(() => {
    if (currentParticipationStatus.value === 'active') return 'Confirm Time Out';
    if (currentParticipationStatus.value === 'completed') return 'Event Completed';
    return 'Confirm Time In';
});

// Scanning Logic
let codeReader = null;
let controls = null; 

onMounted(async () => {
  try {
    const res = await api.get('/list/events', { 
        params: { ongoing: true } 
    });
    
    events.value = res.data;
  } catch (e) {
    error.value = "Failed to load active events list.";
  }
});

const toggleCamera = () => {
  if (isScanning.value) stopCamera();
  else startCamera();
};

const startCamera = async () => {
  if (!selectedEventId.value) return;
  error.value = null;
  codeReader = new BrowserQRCodeReader();
  isScanning.value = true;

  try {
    controls = await codeReader.decodeFromVideoDevice(undefined, video.value, (result, err) => {
      if (!isScanning.value) return;
      if (result) {
        const rawId = result.getText().trim();
        prepareConfirmation(rawId);
      }
    });
  } catch (err) {
    console.error(err);
    error.value = "Camera access denied.";
    isScanning.value = false;
  }
};

const stopCamera = () => {
  isScanning.value = false;
  if (controls) {
    controls.stop();
    controls = null;
  }
  if (video.value && video.value.srcObject) {
    video.value.srcObject.getTracks().forEach(track => track.stop());
    video.value.srcObject = null;
  }
};

// 1. Fetch Data & Status
const prepareConfirmation = async (studentId) => {
  stopCamera(); 
  scannedStudentId.value = studentId;
  studentDetails.value = null; 
  currentParticipationStatus.value = 'none';
  showConfirmModal.value = true; 

  try {
    // Parallel Request: Get Student Info AND Participation Status
    const [studentRes, statusRes] = await Promise.all([
        api.get(`/students/${studentId}`),
        api.get(`/participations/status`, { 
            params: { student_id: studentId, event_id: selectedEventId.value } 
        })
    ]);
    
    // Set Student Data
    studentDetails.value = {
        name: studentRes.data.name,        
        year: studentRes.data.year_lvl,  
        course: studentRes.data.course,    
        department: studentRes.data.department,
        profile_url: studentRes.data.profile_url || null
    };

    // Set Status ('active', 'none', 'completed')
    currentParticipationStatus.value = statusRes.data.status;

  } catch (e) {
    console.error(e);
    // If student fetch fails (404), likely student doesn't exist
    if (e.response && e.response.status === 404) {
         error.value = `Student ID ${studentId} not found in database.`;
         showConfirmModal.value = false;
    } else {
         error.value = "Network error checking student data.";
    }
  }
};

// 2. Cancel
const cancelScan = () => {
  showConfirmModal.value = false;
  scannedStudentId.value = null;
  studentDetails.value = null;
};

// 3. Execute Action based on Status
const executeAction = async () => {
  showConfirmModal.value = false; 
  const studentId = scannedStudentId.value;
  const status = currentParticipationStatus.value;

  try {
    let res;
    
    if (status === 'none' || status === 'not_found') {
        // --- TIME IN ---
        res = await api.post("/participations/scan", {
            event_id: selectedEventId.value,
            student_id: studentId
        });
        addLog(studentId, "Checked In", "success");
    } 
    else if (status === 'active') {
        // --- TIME OUT ---
        res = await api.post("/participations/out", { 
            event_id: selectedEventId.value, 
            student_id: studentId 
        });
        addLog(studentId, "Timed Out", "warning");
    }

  } catch (err) {
    let errorMsg = "Action Failed";
    if (err.response && err.response.data && err.response.data.message) {
      errorMsg = err.response.data.message;
    }
    addLog(studentId, errorMsg, "error");
  }
};

const addLog = (id, msg, status) => {
  logs.value.unshift({
    student_id: id,
    message: msg,
    status: status,
    time: new Date().toLocaleTimeString()
  });
  if (logs.value.length > 10) logs.value.pop();
};

onBeforeUnmount(() => {
  stopCamera();
});
</script>

<style scoped>
.scanner-wrapper { display: flex; justify-content: center; padding: 20px; }
.scanner-card { width: 100%; max-width: 500px; background: white; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; display: flex; flex-direction: column; }
.header { background: #064e3b; color: white; padding: 1rem; text-align: center; }
.header h3 { margin: 0; font-size: 1.1rem; }
.controls { padding: 1.5rem; border-bottom: 1px solid #e2e8f0; }
.field label { display: block; font-weight: 600; margin-bottom: 0.5rem; color: #334155; }
.camera-section { position: relative; background: #000; display: flex; flex-direction: column; }
.viewport-container { position: relative; width: 100%; height: 300px; overflow: hidden; }
.viewport-placeholder { height: 300px; display: flex; flex-direction: column; align-items: center; justify-content: center; background: #f1f5f9; color: #64748b; }
.camera-feed { width: 100%; height: 100%; object-fit: cover; }
.overlay { position: absolute; top: 0; left: 0; right: 0; bottom: 0; display: flex; align-items: center; justify-content: center; pointer-events: none; }
.scan-frame { width: 200px; height: 200px; border: 4px solid rgba(16, 185, 129, 0.7); border-radius: 12px; box-shadow: 0 0 0 9999px rgba(0, 0, 0, 0.5); }
.camera-controls { padding: 1rem; background: white; display: flex; justify-content: center; border-bottom: 1px solid #e2e8f0; }
.placeholder-box { padding: 3rem; text-align: center; color: #64748b; background: #f8fafc; }
.error-banner { background: #fee2e2; color: #991b1b; padding: 0.75rem; text-align: center; font-size: 0.9rem; }
.logs-section { padding: 1rem; background: #f8fafc; flex: 1; min-height: 200px; max-height: 400px; overflow-y: auto; }
.logs-section h4 { margin: 0 0 0.5rem 0; font-size: 0.9rem; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.log-item { display: flex; justify-content: space-between; align-items: center; padding: 10px 12px; background: white; border-radius: 6px; margin-bottom: 8px; font-size: 0.85rem; border-left: 4px solid #94a3b8; box-shadow: 0 1px 2px rgba(0,0,0,0.05); }
.log-item.success { border-left-color: #10b981; }
.log-item.warning { border-left-color: #f59e0b; }
.log-item.error { border-left-color: #ef4444; }
.log-item.neutral { border-left-color: #94a3b8; }
.log-content { display: flex; flex-direction: column; }
.log-id { font-weight: 700; color: #1e293b; font-size: 0.9rem; }
.log-msg { color: #475569; }
.log-time { color: #94a3b8; font-size: 0.75rem; white-space: nowrap; }

/* Confirmation Dialog */
.confirmation-content { display: flex; flex-direction: column; align-items: center; width: 100%; }
.student-avatar { width: 90px; height: 90px; background-color: #f1f5f9; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-bottom: 1.5rem; overflow: hidden; border: 3px solid #fff; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
.student-avatar img { width: 100%; height: 100%; object-fit: cover; }
.student-avatar i { font-size: 3rem; color: #94a3b8; }
.student-details-grid { display: flex; flex-wrap: wrap; gap: 12px; width: 100%; background-color: #f8fafc; padding: 15px; border-radius: 8px; text-align: left; }
.detail-row { flex: 1 1 40%; display: flex; flex-direction: column; }
.detail-row.full-width { flex: 1 1 100%; }
.detail-row label { font-size: 0.7rem; color: #64748b; text-transform: uppercase; font-weight: 700; margin-bottom: 2px; }
.detail-row .value { font-size: 0.95rem; color: #334155; font-weight: 600; word-break: break-word; }
.detail-row .value.highlight { color: #064e3b; font-size: 1.1rem; font-weight: 800; }
.loading-state { padding: 2rem; text-align: center; color: #64748b; }
.dialog-actions { display: flex; justify-content: flex-end; gap: 0.5rem; width: 100%; margin-top: 10px; }

/* Status Badges */
.status-badge { padding: 8px; border-radius: 4px; text-align: center; font-weight: bold; font-size: 0.9rem; }
.status-badge.active { background: #fff7ed; color: #c2410c; border: 1px solid #fdba74; }
.status-badge.completed { background: #f0fdf4; color: #15803d; border: 1px solid #86efac; }
</style>