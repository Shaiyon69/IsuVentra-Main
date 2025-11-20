import axios from 'axios';

const api = axios.create({
    baseURL: 'http://127.0.0.1:8000/api', //backend base URL
    headers: {
        'Accept': 'application/json',
    },
});

// attach token automatically if present
api.interceptors.request.use((req) => {
    const token = localStorage.getItem('token');
    if (token) {
        req.headers.Authorization = `Bearer ${token}`
    }
    return req;
});

// handle token expiration
api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response && error.response.status === 401) {
            localStorage.removeItem('token');
        }
        return Promise.reject(error);
    }
);

export default api;
