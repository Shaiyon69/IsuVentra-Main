import { createRouter, createWebHistory } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import api from "@/services/api";

// 1. Pages (Lazy Loading)
const LoginPage = () => import("@/views/LoginPage.vue");
const RegisterPage = () => import("@/views/RegisterPage.vue");
const UserDashboard = () => import("@/views/UserDashboard.vue");
const JoinPage = () => import("@/views/JoinPage.vue");

// 2. Admin Components
const AdminPanel = () => import("@/views/admin/AdminPanel.vue"); // Your main layout
const OverviewTab = () => import("@/components/admin/OverviewTab.vue");
const StudentsTab = () => import("@/components/admin/StudentsTab.vue");
const EventsTab = () => import("@/components/admin/EventsTab.vue");
const ParticipationTab = () => import("@/components/admin/ParticipationTab.vue");

const routes = [
  // --- Public Routes ---
  { path: "/", name: "login", component: LoginPage },
  { path: "/register", name: "register", component: RegisterPage },

  // --- User Routes ---
  {
    path: "/dashboard",
    name: "dashboard",
    component: UserDashboard,
    meta: { requiresAuth: true, role: "user" },
  },
  {
    path: "/join",
    name: "join",
    component: JoinPage,
    meta: { requiresAuth: true, role: "user" },
  },

  // --- Admin Routes (Nested) ---
  {
    path: "/admin",
    name: "admin",
    component: AdminPanel,
    meta: { requiresAuth: true, role: "admin" },
    redirect: { name: 'admin-dashboard' }, // Redirect /admin to /admin/overview
    children: [
      {
        path: "dashboard",
        name: "admin-dashboard",
        component: OverviewTab
      },
      {
        path: "students",
        name: "admin-students",
        component: StudentsTab
      },
      {
        path: "events",
        name: "admin-events",
        component: EventsTab
      },
      {
        path: "participation",
        name: "admin-participation",
        component: ParticipationTab
      },
    ]
  },

  // --- Catch All ---
  { path: "/:pathMatch(.*)*", redirect: "/" }
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

// --- Navigation Guards ---
router.beforeEach(async (to, from, next) => {
  const auth = useAuthStore();

  // 1. Login/Register Access Check
  if (["login", "register"].includes(to.name)) {
    if (auth.token) {
      return auth.isAdmin
        ? next({ name: "admin" })
        : next({ name: "dashboard" });
    }
    return next();
  }

  // 2. Protected Routes Check
  if (to.meta.requiresAuth) {
    if (!auth.token) return next({ name: "login" });

    // Validate Token if we don't have user ID yet (e.g. on refresh)
    if (!auth.user?.id) {
      try {
        const response = await api.get("/validate-token");
        auth.setAuth(response.data.user, auth.token);
      } catch (err) {
        auth.logout();
        return next({ name: "login" });
      }
    }

    // Role Check
    if (to.meta.role && to.meta.role !== auth.role) {
      return auth.isAdmin
        ? next({ name: "admin" })
        : next({ name: "dashboard" });
    }
  }

  next();
});

export default router;