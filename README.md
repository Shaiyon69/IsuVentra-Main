# IsuVentra

> **Note:** This project is a work in progress.

A full-stack event management system designed for university students to manage and participate in events.

## Overview

IsuVentra consists of three main components: a Laravel backend API, a Vue.js web application, and a Flutter mobile app, providing comprehensive event management capabilities across web and mobile platforms.

## Components

### Backend (Laravel)
- **Framework**: Laravel (PHP)
- **Purpose**: Provides RESTful API endpoints for user authentication, event management, student data, and participation tracking
- **Key Features**:
  - User authentication and authorization
  - Event CRUD operations
  - Student profile management
  - Participation tracking
  - Database migrations and seeders
- **Database**: Models for Users, Events, Students, and Participations

### Frontend-Vite (Vue.js Web Application)
- **Framework**: Vue.js 3 with TypeScript
- **Build Tool**: Vite
- **State Management**: Pinia
- **Routing**: Vue Router
- **Purpose**: Web interface for administrators and students to interact with the system
- **Key Dependencies**: Vue 3.5.25, TypeScript, ESLint, Prettier
- **Features**: Event listing, user dashboards, admin panels, and responsive web UI

### Mobile_Flutter (Flutter Mobile App)
- **Framework**: Flutter (Dart)
- **Purpose**: Mobile application for students to access event information, scan QR codes for participation, and manage profiles on-the-go
- **Key Features**:
  - User authentication (login/logout)
  - Event browsing and details
  - QR code scanning for event check-in
  - User profile management
  - Dashboard with navigation (Dashboard, Events, Scanner)
- **State Management**: Provider pattern with AuthProvider, UserProvider, EventProvider
- **UI**: Material Design with custom themes and responsive layouts

## Architecture

- **Backend**: Handles business logic, data persistence, and API services
- **Frontend-Vite**: Web-based admin/student interface
- **Mobile_Flutter**: Native mobile experience for iOS/Android
- **Integration**: All frontends communicate with the Laravel API for data synchronization

This setup provides a comprehensive event management platform with web and mobile access for university event coordination.
