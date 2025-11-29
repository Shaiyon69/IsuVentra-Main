import { createRouter, createWebHistory } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import api from "@/services/api";

// 1. Pages (Using Lazy Loading for better performance)
const LoginPage = () => import("@/views/LoginPage.vue");
const RegisterPage = () => import("@/views/RegisterPage.vue");
const UserDashboard = () => import("@/views/UserDashboard.vue");
const JoinPage = () => import("@/views/JoinPage.vue");

// 2. Updated Path for AdminPanel
// (Assuming you moved the parent file to src/views/AdminPanel.vue)
const AdminDashboard = () => import("@/views/admin/AdminPanel.vue");

const routes = [
  { path: "/", name: "login", component: LoginPage },
  { path: "/register", name: "register", component: RegisterPage },
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
  {
    path: "/admin",
    component: AdminDashboard,
    meta: { requiresAuth: true, role: "admin" },
    children: [
      { path: "", name: "admin-overview", component: () => import("@/components/admin/OverviewTab.vue") },
      { path: "students", name: "admin-students", component: () => import("@/components/admin/StudentsTab.vue") },
      { path: "events", name: "admin-events", component: () => import("@/components/admin/EventsTab.vue") },
      { path: "participation", name: "admin-participation", component: () => import("@/components/admin/ParticipationTab.vue") },
    ]
  },
  { path: "/:pathMatch(.*)*", redirect: "/" }
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

// 🔐 Global Route Guard
router.beforeEach(async (to, from, next) => {
  const auth = useAuthStore();

  // 1. Prevent infinite loops if token is invalid
  // If user is going to login/register, let them pass unless they are already logged in
  if (["login", "register"].includes(to.name)) {
    if (auth.token) {
      return auth.isAdmin
        ? next({ name: "admin" })
        : next({ name: "dashboard" });
    }
    return next();
  }

  // 2. Check for Protected Routes
  if (to.meta.requiresAuth) {
    // A. No Token? Kick them out immediately.
    if (!auth.token) return next({ name: "login" });

    // B. Performance Fix: Only validate with API if we don't have user details (e.g., Page Refresh)
    // If we already have auth.user.id, we assume the session is valid to save time.
    if (!auth.user?.id) {
      try {
        const response = await api.get("/validate-token");
        auth.setAuth(response.data.user, auth.token);
      } catch (err) {
        auth.logout();
        return next({ name: "login" });
      }
    }

    // C. Role Check
    if (to.meta.role && to.meta.role !== auth.role) {
      // If a user tries to access admin, or admin tries to access user page
      return auth.isAdmin
        ? next({ name: "admin" })
        : next({ name: "dashboard" });
    }
  }

  next();
});

export default router;