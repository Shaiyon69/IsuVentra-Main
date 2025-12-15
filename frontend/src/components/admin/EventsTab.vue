<template>
    <div class="view-panel">
        <div class="view-header">
            <div class="title-group">
                <h3>Event Management</h3>
            </div>
            <div class="action-group">
                <span class="p-input-icon-left">
                    <i class="pi pi-search" />
                    <InputText
                        v-model="searchQuery"
                        placeholder="Search events..."
                        class="p-inputtext-sm search-input"
                        @keydown.enter="triggerSearch"
                    />
                </span>

                <input
                    type="file"
                    ref="fileInput"
                    accept=".csv"
                    style="display: none"
                    @change="handleFileUpload"
                />
                <Button
                    label="Import CSV"
                    icon="pi pi-upload"
                    severity="secondary"
                    outlined
                    size="small"
                    @click="triggerFileInput"
                />
                <Button
                    label="New Event"
                    icon="pi pi-plus"
                    size="small"
                    @click="showModal = true"
                />
            </div>
        </div>

        <div class="table-container">
            <DataTable
                :value="events"
                :loading="loading"
                stripedRows
                class="custom-table"
                scrollable
                scrollHeight="flex"
            >
                <template #empty
                    ><div class="empty-msg">No events found.</div></template
                >

                <Column field="title" header="Title" class="font-bold"></Column>
                <Column header="Date & Time" field="time_start">
                    <template #body="slotProps">
                        <div class="datetime-cell">
                            <span class="date">{{
                                new Date(
                                    slotProps.data.time_start
                                ).toLocaleDateString()
                            }}</span>
                            <span class="time">{{
                                new Date(
                                    slotProps.data.time_start
                                ).toLocaleTimeString([], {
                                    hour: "2-digit",
                                    minute: "2-digit",
                                })
                            }}</span>
                        </div>
                    </template>
                </Column>
                <Column field="location" header="Location"></Column>
                <Column header="Created By" field="creator.name">
                    <template #body="slotProps">
                        <span>{{
                            slotProps.data.creator
                                ? slotProps.data.creator.name
                                : "N/A"
                        }}</span>
                    </template>
                </Column>
                <Column header="Status">
                    <template #body="slotProps">
                        <span
                            class="status-pill"
                            :class="
                                slotProps.data.is_ongoing ? 'live' : 'closed'
                            "
                        >
                            {{
                                slotProps.data.is_ongoing ? "Active" : "Closed"
                            }}
                        </span>
                    </template>
                </Column>
            </DataTable>
        </div>

        <div class="pagination-footer">
            <span class="page-info">
                Showing {{ events.length }} records on Page {{ currentPage }}
            </span>
            <div class="page-buttons">
                <Button
                    icon="pi pi-chevron-left"
                    label="Prev"
                    @click="changePage(currentPage - 1)"
                    :disabled="currentPage <= 1 || loading"
                    outlined
                    size="small"
                />
                <Button
                    label="Next"
                    icon="pi pi-chevron-right"
                    iconPos="right"
                    @click="changePage(currentPage + 1)"
                    :disabled="!hasNextPage || loading"
                    outlined
                    size="small"
                />
            </div>
        </div>

        <Dialog
            v-model:visible="showModal"
            modal
            header="Create Event"
            :style="{ width: '500px' }"
            class="p-fluid"
        >
            <form @submit.prevent="submitEvent" class="form-container">
                <div class="field">
                    <label>Event Title</label>
                    <InputText v-model="form.title" required />
                </div>
                <div class="form-row">
                    <div class="field">
                        <label>Start Time</label>
                        <input
                            type="datetime-local"
                            v-model="form.time_start"
                            class="p-inputtext w-full"
                            required
                        />
                    </div>
                    <div class="field">
                        <label>End Time</label>
                        <input
                            type="datetime-local"
                            v-model="form.time_end"
                            class="p-inputtext w-full"
                            required
                        />
                    </div>
                </div>
                <div class="field">
                    <label>Location</label>
                    <InputText v-model="form.location" required />
                </div>
                <div class="field">
                    <label>Description</label>
                    <Textarea v-model="form.description" rows="3" autoResize />
                </div>
                <div class="dialog-footer">
                    <Button
                        label="Cancel"
                        text
                        severity="secondary"
                        @click="showModal = false"
                    />
                    <Button
                        type="submit"
                        label="Create Event"
                        icon="pi pi-check"
                        :loading="isSubmitting"
                    />
                </div>
            </form>
        </Dialog>
    </div>
</template>

<script setup>
import { ref, reactive, computed } from "vue";
import api from "@/services/api";
import Papa from "papaparse";
import DataTable from "primevue/datatable";
import Column from "primevue/column";
import Button from "primevue/button";
import InputText from "primevue/inputtext";
import Textarea from "primevue/textarea";
import Dialog from "primevue/dialog";

const props = defineProps(["events", "totalRecords", "loading", "currentPage"]);
const emit = defineEmits(["refresh", "page-change", "search"]);

const searchQuery = ref("");
const PER_PAGE = 15;

// Computed and methods
const hasNextPage = computed(() => {
    const maxPages = Math.ceil(props.totalRecords / PER_PAGE);
    return props.currentPage < maxPages;
});

const changePage = (newPage) => {
    emit("page-change", newPage);
};

const triggerSearch = () => {
    emit("search", searchQuery.value);
};

// Form and upload logic
const showModal = ref(false);
const isSubmitting = ref(false);
const fileInput = ref(null);
const form = reactive({
    title: "",
    time_start: "",
    time_end: "",
    location: "",
    description: "",
});
const formatToBackend = (val) => val.replace("T", " ") + ":00";

async function submitEvent() {
    isSubmitting.value = true;
    try {
        const payload = {
            ...form,
            time_start: formatToBackend(form.time_start),
            time_end: formatToBackend(form.time_end),
        };
        await api.post("/events", payload);
        Object.assign(form, {
            title: "",
            time_start: "",
            time_end: "",
            location: "",
            description: "",
        });
        showModal.value = false;
        emit("refresh");
        alert("Event created successfully!");
    } catch (error) {
        alert("Failed to create event.");
    } finally {
        isSubmitting.value = false;
    }
}

const triggerFileInput = () => fileInput.value.click();
const handleFileUpload = (event) => {
    const file = event.target.files[0];
    if (!file) return;
    Papa.parse(file, {
        header: true,
        skipEmptyLines: true,
        complete: async (results) => {
            if (confirm(`Import ${results.data.length} events?`)) {
                try {
                    await api.post("/events/import", { data: results.data });
                    alert("Import Successful!");
                    emit("refresh");
                } catch (e) {
                    alert("Import failed.");
                }
            }
            event.target.value = "";
        },
    });
};
</script>

<style scoped>
.view-panel {
    background: white;
    border-radius: 12px;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    display: flex;
    flex-direction: column;
    height: 100%;
    overflow: hidden;
}
.view-header {
    padding: 1.5rem;
    border-bottom: 1px solid #e2e8f0;
    display: flex;
    justify-content: space-between;
    align-items: center;
    background-color: #f8fafc;
}
.title-group h3 {
    margin: 0;
    font-size: 1.25rem;
    color: #1e293b;
}
.action-group {
    display: flex;
    gap: 10px;
    align-items: center;
}

.p-input-icon-left {
    position: relative;
    display: inline-block;
}
.p-input-icon-left > i {
    position: absolute;
    top: 50%;
    margin-top: -0.5rem;
    left: 0.75rem;
    color: #94a3b8;
}
.search-input {
    padding-left: 2.5rem;
    width: 240px;
}

.table-container {
    flex: 1;
    overflow: hidden;
    display: flex;
    flex-direction: column;
}
.custom-table {
    flex: 1;
}
.empty-msg {
    text-align: center;
    padding: 2rem;
    color: #94a3b8;
}
.font-bold {
    font-weight: 600;
    color: #0f172a;
}

.datetime-cell {
    display: flex;
    flex-direction: column;
}
.datetime-cell .time {
    font-size: 0.8rem;
    color: #64748b;
}
.status-pill {
    padding: 4px 12px;
    border-radius: 20px;
    font-weight: 600;
    font-size: 0.85rem;
}
.status-pill.live {
    background: #dcfce7;
    color: #15803d;
}
.status-pill.closed {
    background: #f1f5f9;
    color: #64748b;
}

.pagination-footer {
    padding: 1rem 1.5rem;
    border-top: 1px solid #e2e8f0;
    display: flex;
    justify-content: space-between;
    align-items: center;
    background-color: #f8fafc;
}
.page-info {
    font-size: 0.85rem;
    color: #64748b;
    font-weight: 500;
}
.page-buttons {
    display: flex;
    gap: 10px;
}

.form-container {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    margin-top: 0.5rem;
}
.field {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}
.field label {
    font-size: 0.875rem;
    font-weight: 600;
    color: #475569;
}
.form-row {
    display: flex;
    gap: 1rem;
}
.form-row > * {
    flex: 1;
}
.dialog-footer {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    margin-top: 1.5rem;
}
</style>
