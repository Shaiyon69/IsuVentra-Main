<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <header class="modal-header">
        <h3>{{ title }}</h3>
        <button class="close-btn" @click="$emit('close')">×</button>
      </header>
      
      <div class="modal-body">
        <slot></slot>
      </div>

      <footer class="modal-footer">
        <slot name="footer"></slot>
        </footer>
    </div>
  </div>
</template>

<script setup>
defineProps(['title']);
defineEmits(['close']);
</script>

<style scoped>
.modal-overlay {
  position: fixed; top: 0; left: 0; width: 100%; height: 100%;
  background: rgba(0, 0, 0, 0.5);
  display: flex; justify-content: center; align-items: center;
  z-index: 1000;
}
.modal-content {
  background: white; width: 500px; max-width: 90%;
  border-radius: 12px; overflow: hidden;
  box-shadow: 0 4px 20px rgba(0,0,0,0.15);
  animation: slideIn 0.2s ease-out;
}
.modal-header {
  padding: 16px 24px; border-bottom: 1px solid #eee;
  display: flex; justify-content: space-between; align-items: center;
  background: #f8f9fa;
}
.modal-header h3 { margin: 0; color: #2c3e50; }
.close-btn { background: none; border: none; font-size: 1.5rem; cursor: pointer; color: #7f8c8d; }
.modal-body { padding: 24px; }
.modal-footer { padding: 16px 24px; border-top: 1px solid #eee; display: flex; justify-content: flex-end; gap: 12px; }

@keyframes slideIn {
  from { opacity: 0; transform: translateY(-20px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>