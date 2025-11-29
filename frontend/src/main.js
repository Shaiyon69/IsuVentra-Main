import { createApp } from 'vue';
import App from './App.vue';
import router from './router';
import { createPinia } from 'pinia';

// 1. Change to Named Imports (Required for Vite/ESM)
import { QrcodeStream, QrcodeDropZone, QrcodeCapture } from "vue-qrcode-reader";

// Note: I removed 'setZXingModuleOverrides' and 'import * as ZXing'. 
// These are typically legacy Webpack workarounds and are not needed 
// or supported in the modern vue-qrcode-reader v5+ with Vite.

const app = createApp(App);

// 2. Register the components globally
// Since there is no default export, we cannot use app.use(VueQrcodeReader)
app.component('QrcodeStream', QrcodeStream);
app.component('QrcodeDropZone', QrcodeDropZone);
app.component('QrcodeCapture', QrcodeCapture);

app.use(createPinia());
app.use(router);
app.mount('#app');