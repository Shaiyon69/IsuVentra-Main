import { defineStore } from 'pinia';
import api from '@/services/api';

export const useAuthStore = defineStore('auth', {
    state: () => ({
        token: localStorage.getItem('token') || '',
        user: JSON.parse(localStorage.getItem('user_data')) || null,
    }),

    getters: {
        isAuthenticated: (state) => !!state.token,
        isAdmin: (state) => !!state.user?.is_admin,
        // role: (state) => state.user?.is_admin ? 'admin' : 'user',
        role: (state) => {
            if (state.user.is_admin == 0) return 'user';
            else if (state.user.is_admin == 1) return 'admin';
            else return 'sub-admin';
        }
    },

    actions: {
        setAuth(user, token) {
            this.token = token;
            this.user = user;
            localStorage.setItem('token', token);
            localStorage.setItem('user_data', JSON.stringify(user));
        },

        logout() {
            this.token = '';
            this.user = null;
            localStorage.removeItem('token');
            localStorage.removeItem('user_data');

            // Optional: Call API to revoke token on server too
            api.post('/logout').catch(() => { });
        },

        async login(credentials) {
            try {
                const response = await api.post('/login', credentials);
                this.setAuth(response.data.user, response.data.access_token);

                return true;
            } catch (error) {
                console.error("Login failed:", error);
                throw error;
            }
        }
    }
});