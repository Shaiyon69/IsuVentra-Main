<template>
    <div class="dashboard-container">
        <header class="page-header">
            <h1>Student Dashboard</h1>
            <p class="subtitle">Welcome to ISUVentra</p>
        </header>

        <div class="action-bar">
            <button @click="goToPass" class="id-pass-btn">
                <i class="pi pi-id-card icon-left"></i>
                <span>View Digital ID</span>
            </button>
        </div>

        <div v-if="loading" class="loading-state">
            <div class="spinner"></div>
            <p>Loading upcoming events...</p>
        </div>

        <div v-else-if="sortedEvents.length" class="events-grid">
            <div v-for="e in sortedEvents" :key="e.id" class="event-card">
                <div class="card-top">
                    <span class="status-badge" :class="getEventStatus(e).class">
                        {{ getEventStatus(e).label }}
                    </span>
                </div>

                <h3 class="event-title">{{ e.title || e.name }}</h3>

                <div class="event-meta">
                    <div class="meta-item">
                        <span class="meta-icon">📍</span>
                        <span>{{ e.location }}</span>
                    </div>
                    <div class="meta-item">
                        <span class="meta-icon">🕒</span>
                        <span>{{ formatEventTime(e) }}</span>
                    </div>
                </div>

                <p class="event-desc">{{ truncate(e.description, 100) }}</p>

                <div class="card-footer">
                    <span class="footer-text">Event Details</span>
                </div>
            </div>
        </div>

        <div v-else class="empty-state">
            <div class="empty-icon">📅</div>
            <h3>No Events Found</h3>
            <p>Check back later for upcoming campus activities.</p>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, computed } from "vue";
import { useRouter } from "vue-router";
import api from "@/services/api";

const router = useRouter();
const events = ref([]);
const loading = ref(true);

const goToPass = () => {
    router.push({ name: "join" }); // Using named route is safer
};

// Data fetching
async function fetchEvents() {
    try {
        const res = await api.get("/events?per_page=50");
        events.value = res.data.data || res.data;
    } catch (err) {
        console.error("Error fetching events:", err);
    } finally {
        loading.value = false;
    }
}

// Status logic
const getEventStatus = (e) => {
    const now = new Date();
    const start = new Date(e.time_start);
    const end = new Date(e.time_end);

    if (now >= start && now <= end) {
        return { label: "🔴 LIVE NOW", class: "status-live" };
    } else if (now > end) {
        return { label: "🏁 ENDED", class: "status-ended" };
    } else {
        return { label: "📅 UPCOMING", class: "status-default" };
    }
};

// Computer sorting
const sortedEvents = computed(() => {
    return [...events.value].sort((a, b) => {
        const statusA = getEventStatus(a).label;
        const statusB = getEventStatus(b).label;
        if (statusA.includes("LIVE") && !statusB.includes("LIVE")) return -1;
        if (!statusA.includes("LIVE") && statusB.includes("LIVE")) return 1;
        return new Date(a.time_start) - new Date(b.time_start);
    });
});

// Formatters
function formatEventTime(e) {
    if (!e.time_start) return "TBA";
    const start = new Date(e.time_start);
    const dateStr = start.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
    });
    const timeStr = start.toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
    });
    return `${dateStr} • ${timeStr}`;
}

function truncate(text, length) {
    if (!text) return "No description provided.";
    return text.length > length ? text.substring(0, length) + "..." : text;
}

onMounted(() => {
    fetchEvents();
});
</script>

<style scoped>
.dashboard-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 40px 20px;
    font-family: "Inter", sans-serif;
}

/* Header */
.page-header {
    text-align: center;
    margin-bottom: 40px;
}
h1 {
    color: #1e293b;
    font-size: 2.5rem;
    font-weight: 800;
    margin: 0;
    letter-spacing: -1px;
}
.subtitle {
    color: #64748b;
    font-size: 1.1rem;
    margin-top: 8px;
}

/* Action Bar */
.action-bar {
    display: flex;
    justify-content: center;
    margin-bottom: 50px;
}

.id-pass-btn {
    padding: 16px 32px;
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    color: white;
    border: none;
    border-radius: 50px;
    font-size: 1.1rem;
    font-weight: 700;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 10px 20px -5px rgba(16, 185, 129, 0.4);
    display: flex;
    align-items: center;
    gap: 12px;
}
.id-pass-btn:hover {
    transform: translateY(-3px);
    box-shadow: 0 15px 30px -5px rgba(16, 185, 129, 0.5);
    filter: brightness(1.1);
}
.icon-left {
    font-size: 1.3rem;
}

/* Grid Layout */
.events-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 30px;
}

/* Event Card */
.event-card {
    background-color: white;
    border-radius: 20px;
    border: 1px solid #e2e8f0;
    padding: 24px;
    transition: all 0.3s ease;
    display: flex;
    flex-direction: column;
    position: relative;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
}
.event-card:hover {
    transform: translateY(-8px);
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1),
        0 10px 10px -5px rgba(0, 0, 0, 0.04);
    border-color: #10b981;
}

.card-top {
    margin-bottom: 16px;
}

.status-badge {
    font-size: 0.7rem;
    font-weight: 800;
    padding: 6px 12px;
    border-radius: 30px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}
.status-live {
    background-color: #fef2f2;
    color: #ef4444;
    border: 1px solid #fecaca;
}
.status-default {
    background-color: #f0fdf4;
    color: #15803d;
    border: 1px solid #bbf7d0;
}
.status-ended {
    background-color: #f1f5f9;
    color: #64748b;
    border: 1px solid #e2e8f0;
}

.event-title {
    font-size: 1.35rem;
    color: #1e293b;
    margin: 0 0 12px 0;
    line-height: 1.3;
    font-weight: 700;
}
.event-meta {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-bottom: 20px;
}
.meta-item {
    display: flex;
    align-items: center;
    gap: 10px;
    color: #475569;
    font-size: 0.9rem;
    font-weight: 500;
}
.meta-icon {
    font-size: 1rem;
}
.event-desc {
    color: #64748b;
    font-size: 0.95rem;
    line-height: 1.6;
    margin-bottom: 24px;
    flex-grow: 1;
}

.card-footer {
    padding-top: 16px;
    border-top: 1px solid #f1f5f9;
    display: flex;
    justify-content: flex-end;
}
.footer-text {
    color: #10b981;
    font-weight: 700;
    font-size: 0.9rem;
    cursor: pointer;
}

/* Loading & Empty */
.loading-state,
.empty-state {
    text-align: center;
    padding: 80px 0;
    color: #94a3b8;
}
.spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #e2e8f0;
    border-top: 4px solid #10b981;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto 20px;
}
.empty-icon {
    font-size: 4rem;
    margin-bottom: 16px;
    opacity: 0.5;
    filter: grayscale(100%);
}
@keyframes spin {
    0% {
        transform: rotate(0deg);
    }
    100% {
        transform: rotate(360deg);
    }
}
</style>
