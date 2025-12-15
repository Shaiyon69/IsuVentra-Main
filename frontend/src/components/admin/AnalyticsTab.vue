<template>
    <div v-if="isLoading" class="global-loading">
        <div class="loading-content">
            <ProgressSpinner
                style="width: 50px; height: 50px"
                strokeWidth="4"
                animationDuration=".5s"
            />
            <p>Generating Forecast models...</p>
        </div>
    </div>

    <div v-else class="view-panel">
        <div class="view-header">
            <div class="title-group">
                <h3>
                    <i
                        class="pi pi-bolt"
                        style="color: #064e3b; margin-right: 8px"
                    ></i>
                    Predictive Analytics
                </h3>
            </div>
            <div class="action-group">
                <Button
                    label="Refresh Data"
                    icon="pi pi-refresh"
                    size="small"
                    outlined
                    @click="fetchForecastData"
                />
            </div>
        </div>

        <div class="analytics-container">
            <Accordion :activeIndex="0">
                <AccordionTab
                    v-for="(eventData, baseName) in forecast.events"
                    :key="baseName"
                >
                    <template #header>
                        <div class="accordion-custom-head">
                            <span class="event-title">{{ baseName }}</span>
                            <Tag
                                v-if="eventData.analysis"
                                :value="eventData.analysis.label"
                                :severity="getSeverity(eventData.analysis.type)"
                            />
                        </div>
                    </template>

                    <div v-if="eventData.message" class="no-data-text">
                        {{ eventData.message }}
                    </div>

                    <div v-else class="content-wrapper">
                        <div
                            class="insight-container"
                            :class="eventData.analysis.type"
                        >
                            <i class="pi pi-lightbulb"></i>
                            <p>
                                <strong>Analysis:</strong>
                                {{ eventData.analysis.text }}
                            </p>
                        </div>

                        <div class="forecast-chart-container">
                            <canvas
                                :ref="(el) => setForecastRef(el, baseName)"
                            ></canvas>
                        </div>

                        <DataTable
                            :value="eventData.rows"
                            size="small"
                            stripedRows
                            class="forecast-table"
                        >
                            <Column field="year" header="Year"></Column>
                            <Column field="actual" header="Actual"></Column>
                            <Column
                                field="ma"
                                header="3-Pt Moving Avg"
                            ></Column>
                            <Column field="es" header="Exp. Smoothing">
                                <template #body="slotProps">
                                    <span
                                        :class="{
                                            'font-bold text-green-600':
                                                slotProps.data.year.includes(
                                                    'Proj'
                                                ),
                                        }"
                                    >
                                        {{ slotProps.data.es }}
                                    </span>
                                </template>
                            </Column>
                        </DataTable>
                    </div>
                </AccordionTab>
            </Accordion>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from "vue";
import Chart from "chart.js/auto";
import api from "@/services/api";
import Accordion from "primevue/accordion";
import AccordionTab from "primevue/accordiontab";
import Tag from "primevue/tag";
import DataTable from "primevue/datatable";
import Column from "primevue/column";
import Button from "primevue/button";
import ProgressSpinner from "primevue/progressspinner";

// State
const isLoading = ref(true);
const forecast = ref({ events: {} });

// Charts
const forecastRefs = {};
const forecastChartInstances = {};

const getSeverity = (type) => {
    if (type === "positive") return "success";
    if (type === "negative") return "danger";
    return "info";
};

const formatRows = (eventData) => {
    const rows = [];
    eventData.years.forEach((y, i) => {
        rows.push({
            year: String(y),
            actual: eventData.actual[i],
            ma:
                eventData.moving_average[i] !== null
                    ? Number(eventData.moving_average[i]).toFixed(2)
                    : "-",
            es: Number(eventData.exponential_smoothing[i]).toFixed(2),
        });
    });
    eventData.forecast_years.forEach((y, i) => {
        rows.push({
            year: String(y) + " (Proj)",
            actual: "-",
            ma: Number(eventData.forecast_moving_average[i]).toFixed(2),
            es: Number(eventData.forecast_exponential[i]).toFixed(2),
        });
    });
    return rows;
};

// (Helper) Destroy charts to prevent duplicates/ghosting ---
function cleanupCharts() {
    for (const key in forecastChartInstances) {
        if (forecastChartInstances[key]) {
            forecastChartInstances[key].destroy();
            delete forecastChartInstances[key]; // Remove the reference so setForecastRef knows to recreate it
        }
    }
}

// Data Fetching
async function fetchForecastData() {
    // Clean up old charts before the DOM is destroyed by v-if="isLoading"
    cleanupCharts();

    isLoading.value = true;
    try {
        const res = await api.get("/analytics/forecast");
        const data = res.data;
        for (const key in data.events) {
            if (!data.events[key].message) {
                data.events[key].rows = formatRows(data.events[key]);
            }
        }
        forecast.value = data;
    } catch (e) {
        console.error("Forecast Error:", e);
    } finally {
        isLoading.value = false;
    }
}

// Chart Rendering
function setForecastRef(el, key) {
    if (el) {
        forecastRefs[key] = el;
        if (!forecastChartInstances[key]) {
            nextTick(() => renderSingleForecastChart(key));
        }
    }
}

function renderSingleForecastChart(baseName) {
    const data = forecast.value.events[baseName];
    if (!data || !forecastRefs[baseName]) return;

    const ctx = forecastRefs[baseName].getContext("2d");

    // Double check for no layered charts
    if (forecastChartInstances[baseName]) {
        forecastChartInstances[baseName].destroy();
    }

    forecastChartInstances[baseName] = new Chart(ctx, {
        type: "line",
        data: {
            labels: [...data.years, ...data.forecast_years],
            datasets: [
                {
                    label: "Actual",
                    data: [
                        ...data.actual,
                        ...data.forecast_years.map(() => null),
                    ],
                    borderColor: "#064e3b",
                    backgroundColor: "#064e3b",
                    tension: 0.1,
                },
                {
                    label: "Exp Smoothing",
                    data: [
                        ...data.exponential_smoothing,
                        ...data.forecast_exponential,
                    ],
                    borderColor: "#f59e0b",
                    borderDash: [5, 5],
                    tension: 0.3,
                },
                {
                    label: "Moving Avg",
                    data: [
                        ...data.moving_average,
                        ...data.forecast_moving_average,
                    ],
                    borderColor: "#3b82f6",
                    borderDash: [2, 2],
                    tension: 0.3,
                },
            ],
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: "top" } },
        },
    });
}

onBeforeUnmount(() => {
    cleanupCharts();
});

onMounted(() => {
    fetchForecastData();
});
</script>

<style scoped>
.global-loading {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 60vh;
    width: 100%;
}
.loading-content {
    text-align: center;
    color: #64748b;
    display: flex;
    flex-direction: column;
    gap: 1rem;
    font-weight: 500;
}
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
.analytics-container {
    padding: 2rem;
    overflow-y: auto;
    flex: 1;
}
.accordion-custom-head {
    width: 100%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-right: 1rem;
}
.event-title {
    font-weight: 600;
    color: #334155;
}
.no-data-text {
    color: #94a3b8;
    font-style: italic;
    padding: 1rem;
}
.insight-container {
    padding: 1rem;
    border-radius: 8px;
    margin-bottom: 1.5rem;
    display: flex;
    align-items: center;
    gap: 12px;
    border: 1px solid transparent;
}
.insight-container.positive {
    background: #ecfdf5;
    border-color: #a7f3d0;
    color: #065f46;
}
.insight-container.negative {
    background: #fef2f2;
    border-color: #fecaca;
    color: #991b1b;
}
.insight-container.neutral {
    background: #fffbeb;
    border-color: #fde68a;
    color: #92400e;
}
.forecast-chart-container {
    height: 350px;
    position: relative;
    width: 100%;
    margin-bottom: 2rem;
}
</style>
