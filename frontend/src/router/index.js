import { createRouter, createWebHistory } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import api from "@/services/api";

const LoginPage = () => import("@/views/LoginPage.vue");
const RegisterPage = () => import("@/views/RegisterPage.vue");
const UserDashboard = () => import("@/views/UserDashboard.vue");
const JoinPage = () => import("@/views/JoinPage.vue");
const AdminPanel = () => import("@/views/admin/AdminPanel.vue");
const OverviewTab = () => import("@/components/admin/OverviewTab.vue");
const AnalyticsTab = () => import("@/components/admin/AnalyticsTab.vue");
const StudentsTab = () => import("@/components/admin/StudentsTab.vue");
const EventsTab = () => import("@/components/admin/EventsTab.vue");
const ParticipationTab = () => import("@/components/admin/ParticipationTab.vue");
const AdminScanner = () => import("@/components/admin/AdminScanner.vue");

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

  // --- Admin Routes ---
  {
    path: "/admin",
    name: "admin",
    component: AdminPanel,
    meta: { requiresAuth: true, role: "admin" },
    redirect: { name: 'admin-dashboard' },
    children: [
      {
        path: "dashboard",
        name: "admin-dashboard",
        component: OverviewTab
      },
      {
        path: "analytics",
        name: "admin-analytics",
        component: AnalyticsTab
      },
      {
        path: "scan",
        name: "admin-scan",
        component: AdminScanner
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
        ? next({ name: "admin-dashboard" })
        : next({ name: "dashboard" });
    }
    return next();
  }

  if (to.meta.requiresAuth) {
    if (!auth.token) return next({ name: "login" });

    // Validate Token if missing user data
    if (!auth.user?.id) {
      try {
        const response = await api.get("/validate-token");
        auth.setAuth(response.data.user, auth.token);
      } catch (err) {
        auth.logout();
        return next({ name: "login" });
      }
    }

    // Role Check Logic
    const requiredRole = to.meta.role;
    const userRole = auth.role;

    // FIX 2: Handle Sub-Admin Logic
    // If the route requires 'admin', but the user is 'sub-admin', ALLOW IT.
    if (requiredRole === 'admin' && userRole === 'sub-admin') {
      return next();
    }

    // Standard Mismatch Check
    if (requiredRole && requiredRole !== userRole) {
      // FIX 3: Prevent infinite redirect by checking if we are already at the target
      if (auth.isAdmin) {
        if (to.name === 'admin-dashboard') return next(); // Already there, let it pass
        return next({ name: "admin-dashboard" });
      } else {
        if (to.name === 'dashboard') return next(); // Already there
        return next({ name: "dashboard" });
      }
    }
  }

  next();
});

export default router;