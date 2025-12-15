<template>
    <div class="admin-layout">
        <aside class="sidebar">
            <div class="brand-section">
                <div class="logo-icon"><i class="pi pi-box"></i></div>
                <div class="brand-info">
                    <h2 class="brand-name">ISUVentra</h2>
                    <span class="brand-badge">ADMIN v1.1</span>
                </div>
            </div>

            <nav class="nav-menu">
                <router-link
                    :to="{ name: 'admin-dashboard' }"
                    class="nav-item"
                    active-class="active"
                >
                    <i class="pi pi-chart-bar"></i><span>Dashboard</span>
                </router-link>

                <router-link
                    :to="{ name: 'admin-analytics' }"
                    class="nav-item"
                    active-class="active"
                >
                    <i class="pi pi-bolt"></i><span>Analytics</span>
                </router-link>

                <router-link :to="{ name: 'admin-scan' }" class="nav-item">
                    <i class="pi pi-camera"></i>
                    <span>Scanner</span>
                </router-link>

                <div class="nav-divider">MANAGEMENT</div>
                <router-link
                    :to="{ name: 'admin-students' }"
                    class="nav-item"
                    active-class="active"
                >
                    <i class="pi pi-users"></i><span>Students</span>
                </router-link>
                <router-link
                    :to="{ name: 'admin-events' }"
                    class="nav-item"
                    active-class="active"
                >
                    <i class="pi pi-calendar"></i><span>Events</span>
                </router-link>
                <router-link
                    :to="{ name: 'admin-participation' }"
                    class="nav-item"
                    active-class="active"
                >
                    <i class="pi pi-list"></i><span>Participation</span>
                </router-link>
            </nav>

            <div class="user-footer">
                <div class="user-card">
                    <Avatar label="A" class="user-avatar" shape="circle" />
                    <div class="user-meta">
                        <span class="user-name">Administrator</span>
                        <span class="logout-link" @click="handleLogout"
                            >Sign Out</span
                        >
                    </div>
                </div>
            </div>
        </aside>

        <main class="main-wrapper">
            <header class="top-header">
                <h1 class="page-title">{{ pageTitle }}</h1>
                <div class="header-right">
                    <div class="date-badge">
                        <i class="pi pi-calendar"></i>
                        {{
                            new Date().toLocaleDateString("en-US", {
                                weekday: "short",
                                month: "short",
                                day: "numeric",
                            })
                        }}
                    </div>
                </div>
            </header>

            <div class="content-area">
                <div v-if="isGlobalLoading" class="loading-overlay">
                    <ProgressSpinner
                        style="width: 50px; height: 50px"
                        strokeWidth="4"
                    />
                    <p>Syncing Data...</p>
                </div>

                <div v-else class="router-view-container">
                    <router-view
                        v-slot="{ Component }"
                        :students="students"
                        :events="events"
                        :participation="participation"
                        :totalRecords="currentTotalRecords"
                        :loading="currentLoading"
                        :currentPage="currentPage"
                        @page-change="handlePageChange"
                        @search="handleSearch"
                        @refresh="refreshCurrentTab"
                    >
                        <component :is="Component" :key="route.fullPath" />
                    </router-view>
                </div>
            </div>
        </main>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import api from "@/services/api";
import Avatar from "primevue/avatar";
import ProgressSpinner from "primevue/progressspinner";

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();
const PER_PAGE = 15;
const isGlobalLoading = ref(false);

const students = ref([]);
const events = ref([]);
const participation = ref([]);

const eventsPage = ref(1);
const studentsPage = ref(1);
const participationPage = ref(1);
const currentSearch = ref("");

const totalStudents = ref(0);
const totalEvents = ref(0);
const totalParticipation = ref(0);

const loadingStudents = ref(false);
const loadingEvents = ref(false);
const loadingParticipation = ref(false);

const pageTitle = computed(() => {
    if (!route.name) return "Dashboard";
    const name = route.name.toString().replace("admin-", "");
    return name.charAt(0).toUpperCase() + name.slice(1);
});

const currentTotalRecords = computed(() => {
    if (route.name === "admin-events") return totalEvents.value;
    if (route.name === "admin-students") return totalStudents.value;
    if (route.name === "admin-participation") return totalParticipation.value;
    return 0;
});

const currentLoading = computed(() => {
    if (route.name === "admin-events") return loadingEvents.value;
    if (route.name === "admin-students") return loadingStudents.value;
    if (route.name === "admin-participation") return loadingParticipation.value;
    return false;
});

const currentPage = computed(() => {
    if (route.name === "admin-events") return eventsPage.value;
    if (route.name === "admin-students") return studentsPage.value;
    if (route.name === "admin-participation") return participationPage.value;
    return 1;
});

async function fetchEvents(page = 1) {
    loadingEvents.value = true;
    eventsPage.value = page;
    try {
        const res = await api.get(
            `/events?page=${page}&per_page=${PER_PAGE}&search=${currentSearch.value}`
        );
        events.value = res.data.data;
        totalEvents.value = res.data.total;
    } catch (err) {
        console.error(err);
    } finally {
        loadingEvents.value = false;
    }
}

async function fetchStudents(page = 1) {
    loadingStudents.value = true;
    studentsPage.value = page;
    try {
        const res = await api.get(
            `/students?page=${page}&per_page=${PER_PAGE}&search=${currentSearch.value}`
        );
        students.value = res.data.data;
        totalStudents.value = res.data.total;
    } catch (err) {
        console.error(err);
    } finally {
        loadingStudents.value = false;
    }
}

async function fetchParticipation(page = 1) {
    loadingParticipation.value = true;
    participationPage.value = page;
    try {
        const res = await api.get(
            `/participations?page=${page}&per_page=${PER_PAGE}&search=${currentSearch.value}`
        );
        participation.value = res.data.data;
        totalParticipation.value = res.data.total;
    } catch (err) {
        console.error(err);
    } finally {
        loadingParticipation.value = false;
    }
}

function handlePageChange(page) {
    if (route.name === "admin-events") fetchEvents(page);
    else if (route.name === "admin-students") fetchStudents(page);
    else if (route.name === "admin-participation") fetchParticipation(page);
}

function handleSearch(query) {
    currentSearch.value = query;
    handlePageChange(1);
}

function refreshCurrentTab() {
    handlePageChange(1);
}

function handleLogout() {
    auth.logout();
    router.push("/");
}

watch(
    () => route.name,
    () => {
        currentSearch.value = "";
        if (!isGlobalLoading.value) {
            handlePageChange(1);
        }
    }
);

async function loadInitialData() {
    isGlobalLoading.value = true;
    try {
        await Promise.all([
            fetchStudents(1),
            fetchEvents(1),
            fetchParticipation(1),
        ]);
    } catch (err) {
        console.error(err);
    } finally {
        isGlobalLoading.value = false;
    }
}

onMounted(loadInitialData);
</script>

<style scoped>
.admin-layout {
    display: flex;
    height: 100vh;
    width: 100%;
    background-color: #f8fafc;
    font-family: "Inter", sans-serif;
    overflow: hidden;
}
.sidebar {
    width: 260px;
    min-width: 260px;
    background-color: #064e3b;
    color: white;
    display: flex;
    flex-direction: column;
    box-shadow: 4px 0 15px rgba(0, 0, 0, 0.1);
    z-index: 50;
}
.brand-section {
    padding: 1.5rem;
    display: flex;
    align-items: center;
    gap: 12px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}
.logo-icon {
    width: 40px;
    height: 40px;
    background: #34d399;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #064e3b;
    font-size: 1.25rem;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.2);
}
.brand-info {
    display: flex;
    flex-direction: column;
}
.brand-name {
    margin: 0;
    font-size: 1.1rem;
    font-weight: 700;
    letter-spacing: 0.5px;
}
.brand-badge {
    font-size: 0.7rem;
    opacity: 0.8;
    letter-spacing: 1px;
}
.nav-menu {
    flex: 1;
    padding: 1.5rem 1rem;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}
.nav-divider {
    font-size: 0.75rem;
    color: #6ee7b7;
    font-weight: 700;
    margin: 1.5rem 0 0.5rem 0.8rem;
    letter-spacing: 0.05em;
    text-transform: uppercase;
}
.nav-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
    color: #d1fae5;
    text-decoration: none;
    border-radius: 8px;
    transition: all 0.2s ease;
    font-size: 0.95rem;
}
.nav-item:hover {
    background-color: rgba(255, 255, 255, 0.1);
    color: white;
}
.nav-item.active {
    background-color: #10b981;
    color: white;
    font-weight: 600;
    box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
}
.nav-item i {
    font-size: 1.1rem;
}
.user-footer {
    padding: 1.5rem;
    border-top: 1px solid rgba(255, 255, 255, 0.1);
    background-color: rgba(0, 0, 0, 0.1);
}
.user-card {
    display: flex;
    align-items: center;
    gap: 12px;
}
.user-avatar {
    background-color: #34d399 !important;
    color: #064e3b !important;
    font-weight: bold;
}
.user-meta {
    display: flex;
    flex-direction: column;
}
.user-name {
    font-weight: 600;
    font-size: 0.9rem;
}
.logout-link {
    font-size: 0.8rem;
    color: #fca5a5;
    cursor: pointer;
    transition: color 0.2s;
}
.logout-link:hover {
    color: #f87171;
    text-decoration: underline;
}
.main-wrapper {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-width: 0;
}
.top-header {
    height: 70px;
    background: white;
    border-bottom: 1px solid #e2e8f0;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0 2rem;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.02);
}
.page-title {
    margin: 0;
    font-size: 1.5rem;
    color: #1e293b;
    font-weight: 700;
}
.date-badge {
    background-color: #f1f5f9;
    padding: 8px 16px;
    border-radius: 20px;
    color: #64748b;
    font-size: 0.9rem;
    font-weight: 500;
    display: flex;
    align-items: center;
    gap: 8px;
}
.content-area {
    flex: 1;
    overflow-y: auto;
    padding: 2rem;
    position: relative;
}
.loading-overlay {
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: #64748b;
}
.router-view-container {
    max-width: 1600px;
    margin: 0 auto;
}
</style>
