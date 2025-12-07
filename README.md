# 🎉 IsuVentra: University Event Management System

> **Note:** This project is a work in progress.

IsuVentra is a full-stack system designed to streamline event management and student participation within a university setting. It provides comprehensive capabilities across web and mobile platforms.

---

## 🎯 Overview

IsuVentra operates across three main components: a **Laravel backend API**, a **Vue.js web application**, and a **Flutter mobile app**. The architecture ensures that all frontends communicate with the Laravel API for seamless data synchronization.

### 🏛️ Architecture
* **Backend (Laravel)**: Handles business logic, data persistence, and API services.
* **Frontend-Vite (Vue.js)**: Provides the web-based admin/student interface.
* **Mobile\_Flutter**: Offers a native mobile experience for iOS/Android.

---

## 💻 Components in Detail

### 1. Backend (Laravel)

The Laravel component provides RESTful API endpoints and is responsible for data management.

* **Framework**: Laravel (PHP).
* **Database**: Uses models for Users, Events, Students, and Participations.
* **Key Features**: User authentication/authorization, Event CRUD operations, Student profile management, and Participation tracking.

### 2. Frontend (Vue.js Web Application)

This is the web interface for administrators and students.

* **Framework**: Vue.js 3 with TypeScript.
* **State Management**: Pinia.
* **Features**: Event listing, user dashboards, admin panels, and a responsive web UI.

### 3. Mobile\_Flutter (Flutter Mobile App)

The mobile application allows students and administrators to manage events and participation on the go.

* **Framework**: Flutter (Dart).
* **Purpose**: Students can access event information, scan QR codes for participation, and manage profiles.
* **State Management**: Uses the **Provider pattern** with AuthProvider, UserProvider, and EventProvider.
* **UI**: Material Design with custom green-themed Material 3 layouts.

---

## 📱 Mobile App Features (Visual Guide)

The Flutter app provides distinct interfaces for **Students** and **Admins**, unified by the same green theme.

### A. Student Interface
Students use the app for quick participation and information access.

| Feature | Description | Screenshot |
| :--- | :--- | :--- |
| **Student QR Code** | Displays the student's unique green QR code and ID for event check-in. |  |
| **Event List** | Allows students to browse available events and use the prominent **"Participate"** button to jump directly to their QR code. |  |
| **Dashboard** | Shows a summary of personal stats (Events, Joined, Scans) and upcoming events. |  |
| **Profile** | Detailed view of the student's ID and Details. |  |

### B. Admin Interface
Administrators access tools for event creation and attendance tracking.

| Feature | Description | Screenshot |
| :--- | :--- | :--- |
| **Admin Dashboard** | High-level summary of system metrics (Total Events, Participations, Active Scans). |  |
| **Event Management** | Lists events with a dominant **"Scan Attendance"** button to start checking participants in. Includes a FAB for quick event creation. |  |
| **Create New Event** | Form-based interface for administrators to schedule and detail new events. |  |
| **QR Scanner** | Activates the camera to scan student QR codes for rapid attendance recording. |  |
