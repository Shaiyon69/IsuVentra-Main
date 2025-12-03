import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'

// PrimeVue Imports
import PrimeVue from 'primevue/config';
import Aura from '@primevue/themes/aura';
import 'primeicons/primeicons.css'; // Mandatory for icons

// QR Code Reader Imports
import { QrcodeStream, QrcodeDropZone, QrcodeCapture } from "vue-qrcode-reader";

const app = createApp(App)

// Register QR components globally
app.component('QrcodeStream', QrcodeStream);
app.component('QrcodeDropZone', QrcodeDropZone);
app.component('QrcodeCapture', QrcodeCapture);

app.use(createPinia())
app.use(router)

// Initialize PrimeVue with Aura Theme
app.use(PrimeVue, {
    theme: {
        preset: Aura,
        options: {
            darkModeSelector: '.my-app-dark', // Disable auto dark mode for consistency
        }
    }
});

app.mount('#app')