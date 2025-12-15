<template>
    <div class="login-wrapper">
        <div class="bg-shape shape-1"></div>
        <div class="bg-shape shape-2"></div>

        <div class="login-card fade-in-up">
            <div class="header-section">
                <div class="logo-container">
                    <i class="pi pi-box text-5xl text-primary"></i>
                </div>
                <h1>ISUVentra</h1>
                <p>Event Participation Management System</p>
            </div>

            <form @submit.prevent="doLogin" class="form-content">
                <div class="field">
                    <label for="identifier">Email or Student ID</label>
                    <IconField class="w-full">
                        <InputIcon class="pi pi-user" />
                        <InputText
                            id="identifier"
                            v-model="loginIdentifier"
                            type="text"
                            placeholder="e.g. 20-0001"
                            class="w-full"
                            required
                        />
                    </IconField>
                </div>

                <div class="field">
                    <label for="password">Password</label>
                    <Password
                        id="password"
                        v-model="password"
                        :feedback="false"
                        toggleMask
                        placeholder="Password"
                        class="w-full"
                        inputClass="w-full"
                        required
                    />
                    <div class="text-right mt-1">
                        <span
                            class="text-sm text-secondary cursor-pointer hover:text-primary transition-colors"
                            >Forgot Password?</span
                        >
                    </div>
                </div>

                <Button
                    label="Sign In"
                    icon="pi pi-sign-in"
                    type="submit"
                    class="w-full mt-3 shadow-2"
                    :loading="loading"
                />
            </form>

            <transition name="fade">
                <Message
                    v-if="error"
                    severity="error"
                    :closable="false"
                    class="mt-4 w-full shadow-1"
                >
                    {{ error }}
                </Message>
            </transition>

            <div class="footer-section">
                <span class="text-secondary">New to ISUVentra? </span>
                <router-link to="/register" class="link-primary"
                    >Create an account</router-link
                >
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref } from "vue";
import { useRouter } from "vue-router";
import { useAuthStore } from "../stores/auth";

// --- MANUAL IMPORTS (Fixes "Broken" Components) ---
import InputText from "primevue/inputtext";
import Password from "primevue/password";
import Button from "primevue/button";
import Message from "primevue/message";
import IconField from "primevue/iconfield";
import InputIcon from "primevue/inputicon";

const loginIdentifier = ref("");
const password = ref("");
const error = ref(null);
const loading = ref(false);
const router = useRouter();
const auth = useAuthStore();

async function doLogin() {
    error.value = null;
    loading.value = true;
    try {
        await auth.login({
            email: loginIdentifier.value,
            password: password.value,
        });

        if (auth.isAdmin) router.push("/admin");
        else router.push("/dashboard");
    } catch (e) {
        console.error(e);
        error.value = e.response?.data?.message || e.message || "Login failed";
    } finally {
        loading.value = false;
    }
}
</script>

<style scoped>
.login-wrapper {
    min-height: 100vh;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(
        135deg,
        var(--surface-ground, #f8f9fa) 0%,
        #e0e7ff 100%
    );
    overflow: hidden;
    padding: 20px;
}

.bg-shape {
    position: absolute;
    border-radius: 50%;
    filter: blur(80px);
    z-index: 0;
    opacity: 0.6;
}
.shape-1 {
    top: -100px;
    left: -100px;
    width: 400px;
    height: 400px;
    background: rgba(16, 185, 129, 0.3);
}
.shape-2 {
    bottom: -100px;
    right: -100px;
    width: 300px;
    height: 300px;
    background: rgba(59, 130, 246, 0.3);
}

.login-card {
    position: relative;
    z-index: 10;
    background-color: rgba(255, 255, 255, 0.9);
    border-radius: 24px;
    box-shadow: 0 20px 50px rgba(0, 0, 0, 0.1);
    padding: 3rem;
    width: 100%;
    max-width: 420px;
    border: 1px solid rgba(255, 255, 255, 0.5);
    backdrop-filter: blur(10px);
}

.header-section {
    text-align: center;
    margin-bottom: 2.5rem;
}
.header-section h1 {
    font-size: 1.75rem;
    font-weight: 800;
    color: var(--text-color, #1f2937);
    margin: 0 0 0.5rem 0;
}
.header-section p {
    color: var(--text-color-secondary, #6b7280);
    margin: 0;
}

.logo-container {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 64px;
    height: 64px;
    background: var(--surface-ground, #f1f5f9);
    border-radius: 16px;
    margin-bottom: 1rem;
    color: var(--primary-color, #10b981);
}

/* 5. Inputs */
.form-content {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
}
.field {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    text-align: left;
}
.field label {
    font-size: 0.9rem;
    font-weight: 600;
    color: var(--text-color, #374151);
    margin-left: 4px;
}
.w-full {
    width: 100%;
}

/* 6. Footer */
.footer-section {
    text-align: center;
    margin-top: 2rem;
    padding-top: 1.5rem;
    border-top: 1px solid var(--surface-border, #e5e7eb);
    font-size: 0.9rem;
}
.link-primary {
    color: var(--primary-color, #10b981);
    text-decoration: none;
    font-weight: 700;
}
.link-primary:hover {
    text-decoration: underline;
}

/* 7. Animation */
.fade-in-up {
    animation: fadeInUp 0.6s cubic-bezier(0.16, 1, 0.3, 1);
}
@keyframes fadeInUp {
    from {
        opacity: 0;
        transform: translateY(20px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}
</style>
