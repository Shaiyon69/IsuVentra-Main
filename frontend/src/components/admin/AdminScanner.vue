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
        <div class="viewport-container">
          <video ref="video" class="camera-feed" muted playsinline></video>
          <div class="overlay">
            <div class="scan-frame"></div>
          </div>
        </div>

        <div class="camera-controls">
          <Button 
            :label="isScanning ? 'Stop Camera' : 'Start Scanning'" 
            :icon="isScanning ? 'pi pi-stop' : 'pi pi-camera'" 
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
            <span class="log-id">{{ log.student_id }}</span>
            <span class="log-msg">{{ log.message }}</span>
            <span class="log-time">{{ log.time }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from "vue";
import { BrowserQRCodeReader } from "@zxing/browser";
import api from "@/services/api";
import Dropdown from 'primevue/dropdown';
import Button from 'primevue/button';

// State
const events = ref([]);
const selectedEventId = ref(null);
const isScanning = ref(false);
const video = ref(null);
const error = ref(null);
const logs = ref([]);

// Scanning Logic
let codeReader = null;
const lastScannedCode = ref(null);
let scanCooldown = false;

// Load Events for Dropdown
onMounted(async () => {
  try {
    const res = await api.get('/list/events');
    events.value = res.data;
  } catch (e) {
    error.value = "Failed to load events list.";
  }
});

const toggleCamera = () => {
  if (isScanning.value) {
    stopCamera();
  } else {
    startCamera();
  }
};

const startCamera = async () => {
  if (!selectedEventId.value) return;
  error.value = null;
  codeReader = new BrowserQRCodeReader();
  
  try {
    isScanning.value = true;
    await codeReader.decodeFromVideoDevice(undefined, video.value, (result, err) => {
      if (result) {
        const studentId = result.getText().trim();
        processScan(studentId);
      }
      if (err && err.name !== "NotFoundException") {
        // console.warn(err); // Optional: Suppress noise
      }
    });
  } catch (err) {
    error.value = "Camera access denied or missing.";
    isScanning.value = false;
  }
};

const stopCamera = () => {
  if (codeReader) {
    // There is no direct .reset() in some versions of @zxing/browser, 
    // but stopping the tracks works reliably.
    const stream = video.value?.srcObject;
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
    }
    video.value.srcObject = null;
  }
  isScanning.value = false;
  lastScannedCode.value = null;
};

const processScan = async (studentId) => {
  // 1. Cooldown Check (Prevents double scanning the same QR in 1 second)
  if (scanCooldown || lastScannedCode.value === studentId) return;
  
  scanCooldown = true;
  lastScannedCode.value = studentId;

  // 2. Play Beep (Optional UX)
  // playBeep(); 

  try {
    const res = await api.post("/participations/scan", {
      event_id: selectedEventId.value,
      student_id: studentId // We now send the scanned code as student_id
    });

    const status = res.data.status; // 'joined', 'already_in', 'error'

    // 3. Handle Already In Logic
    if (status === 'already_in') {
      // Auto-ask to time out or just log it
      const confirmOut = confirm(`Student ${studentId} is already in. Time them out?`);
      if (confirmOut) {
        await api.post("/participations/out", { 
          event_id: selectedEventId.value, 
          student_id: studentId 
        });
        addLog(studentId, "Timed Out", "warning");
      } else {
        addLog(studentId, "Duplicate Scan Ignored", "neutral");
      }
    } else {
      addLog(studentId, "Checked In", "success");
    }

  } catch (err) {
    const msg = err.response?.data?.message || "Scan Failed";
    addLog(studentId, msg, "error");
  } finally {
    // Reset cooldown after 2.5 seconds so they can scan next person
    setTimeout(() => {
      scanCooldown = false;
      lastScannedCode.value = null; // Allow scanning same person again after delay if needed
    }, 2500);
  }
};

const addLog = (id, msg, status) => {
  logs.value.unshift({
    student_id: id,
    message: msg,
    status: status,
    time: new Date().toLocaleTimeString()
  });
  if (logs.value.length > 10) logs.value.pop(); // Keep list short
};

onBeforeUnmount(() => {
  stopCamera();
});
</script>

<style scoped>
.scanner-wrapper {
  display: flex;
  justify-content: center;
  padding: 20px;
}

.scanner-card {
  width: 100%;
  max-width: 500px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.header {
  background: #064e3b;
  color: white;
  padding: 1rem;
  text-align: center;
}
.header h3 { margin: 0; font-size: 1.1rem; }

.controls {
  padding: 1.5rem;
  border-bottom: 1px solid #e2e8f0;
}

.field label {
  display: block;
  font-weight: 600;
  margin-bottom: 0.5rem;
  color: #334155;
}

/* Camera Area */
.camera-section {
  position: relative;
  background: #000;
}

.viewport-container {
  position: relative;
  width: 100%;
  height: 300px;
  overflow: hidden;
}

.camera-feed {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.overlay {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none;
}

.scan-frame {
  width: 200px;
  height: 200px;
  border: 4px solid rgba(16, 185, 129, 0.7);
  border-radius: 12px;
  box-shadow: 0 0 0 9999px rgba(0, 0, 0, 0.5); /* Dim surrounding area */
}

.camera-controls {
  padding: 1rem;
  background: white;
  display: flex;
  justify-content: center;
}

.placeholder-box {
  padding: 3rem;
  text-align: center;
  color: #64748b;
  background: #f8fafc;
}

.error-banner {
  background: #fee2e2;
  color: #991b1b;
  padding: 0.75rem;
  text-align: center;
  font-size: 0.9rem;
}

/* Logs */
.logs-section {
  padding: 1rem;
  background: #f8fafc;
  border-top: 1px solid #e2e8f0;
  max-height: 250px;
  overflow-y: auto;
}

.logs-section h4 {
  margin: 0 0 0.5rem 0;
  font-size: 0.9rem;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.log-item {
  display: flex;
  justify-content: space-between;
  padding: 8px 12px;
  background: white;
  border-radius: 6px;
  margin-bottom: 6px;
  font-size: 0.85rem;
  border-left: 4px solid #94a3b8;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.log-item.success { border-left-color: #10b981; }
.log-item.warning { border-left-color: #f59e0b; }
.log-item.error { border-left-color: #ef4444; }

.log-id { font-weight: 700; color: #1e293b; }
.log-msg { flex: 1; margin: 0 10px; color: #475569; }
.log-time { color: #94a3b8; font-size: 0.75rem; }
</style>