# Provider State Management Implementation

## Overview

This document details the implementation of **Provider** state management pattern in the IsuVentra Flutter application. The implementation follows the architectural pattern from [this reference repository](https://github.com/johnfacun2014/my_project).

## Table of Contents

1. [What Was Added](#what-was-added)
2. [What Was Changed](#what-was-changed)
3. [How It Works](#how-it-works)
4. [Architecture Overview](#architecture-overview)
5. [Usage Examples](#usage-examples)
6. [Benefits](#benefits)

---

## What Was Added

### 1. New Dependencies

**File: `pubspec.yaml`**
```yaml
dependencies:
  provider: ^6.0.5  # ✅ Added
```

### 2. New Provider Files

All providers extend `ChangeNotifier` to enable reactive state management.

#### **`lib/providers/auth_provider.dart`** ✅ NEW
Manages authentication state throughout the app.

**Key Features:**
- Tracks authentication status (`isAuthenticated`, `isLoading`)
- Handles login/logout operations
- Provides error messages
- Auto-checks authentication on initialization

**Properties:**
```dart
bool _isAuthenticated      // User login status
bool _isLoading           // Loading state
String? _errorMessage     // Error messages
```

**Methods:**
```dart
Future<bool> login(String email, String password)
Future<bool> register(String name, String email, String password, String confirmPassword)
Future<void> logout()
void clearError()
```

---

#### **`lib/providers/user_provider.dart`** ✅ NEW
Manages current user data and profile information.

**Key Features:**
- Stores user data from API
- Provides convenient getters for user fields
- Loads user data from SharedPreferences
- Manages loading states

**Properties:**
```dart
Map<String, dynamic>? _currentUser
bool _isLoading
```

**Getters:**
```dart
String get name
String get email
String get studentId
String get course
String get yearLevel
String get campus
```

**Methods:**
```dart
Future<void> loadUser()
Future<void> refreshUser()
void clearUser()
```

---

#### **`lib/providers/event_provider.dart`** ✅ NEW
Manages event data with full CRUD operations.

**Key Features:**
- Fetches events from API
- Create, Read, Update, Delete operations
- Error handling with retry capability
- Loading state management

**Properties:**
```dart
List<Event> events
bool isLoading
String? errorMessage
```

**Methods:**
```dart
Future<void> loadEvents()
Future<void> createEvent(Event event)
Future<void> updateEvent(Event event)
Future<void> deleteEvent(int id)
void clearError()
```

---

### 3. New Service Layer

#### **`lib/services/event_service.dart`** ✅ NEW
Handles all event-related API calls.

**Methods:**
```dart
Future<List<Event>> getEvents()           // GET /events
Future<Event?> getEvent(int id)          // GET /events/:id
Future<bool> createEvent(Event event)    // POST /events
Future<bool> updateEvent(Event event)    // PUT /events/:id
Future<bool> deleteEvent(int id)         // DELETE /events/:id
```

---

### 4. New Wrapper Component

#### **`lib/app_providers_wrapper.dart`** ✅ NEW
Wraps the authenticated portion of the app with all providers.

**Purpose:**
- Provides all providers to authenticated screens
- Only initialized after successful login
- Contains `MultiProvider` with all app providers

**Structure:**
```dart
class AppProvidersWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: const HomeScreen(),
    );
  }
}
```

---

## What Was Changed

### 1. **`lib/main.dart`** - Simplified Entry Point

**Before:**
```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

// Had complex AuthProvider consumer logic
```

**After:**
```dart
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const Login(),  // Simple login screen
    );
  }
}
```

**Changes:**
- ✅ Removed `MultiProvider` from main (providers now loaded after login)
- ✅ Simplified to just show login screen
- ✅ No authentication checking at app startup

---

### 2. **`lib/users/login.dart`** - Updated Login Flow

**Before:**
```dart
// Used AuthProvider directly in login screen
// Complex provider usage
```

**After:**
```dart
class _LoginState extends State<Login> {
  bool isLoading = false;

  void login() async {
    setState(() { isLoading = true; });

    bool success = await AuthService.login(email, password);

    if (success) {
      // Navigate to AppProvidersWrapper (loads all providers)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppProvidersWrapper()),
      );
    }

    setState(() { isLoading = false; });
  }
}
```

**Changes:**
- ✅ Uses `AuthService` directly (no provider on login screen)
- ✅ Navigates to `AppProvidersWrapper` after successful login
- ✅ Local loading state instead of provider
- ✅ Cleaner, simpler implementation

---

### 3. **`lib/screens/event_list.dart`** - Now Uses EventProvider

**Before:**
```dart
class EventListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5, // Hardcoded placeholder
      itemBuilder: (context, index) {
        return Card(
          child: Text('Event ${index + 1}'),  // Fake data
        );
      },
    );
  }
}
```

**After:**
```dart
class EventListScreen extends StatefulWidget {
  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  @override
  void initState() {
    super.initState();
    // Load events when screen opens
    Future.microtask(() {
      Provider.of<EventProvider>(context, listen: false).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventProvider>(context);
    final events = provider.events;

    return Scaffold(
      body: provider.isLoading
          ? CircularProgressIndicator()  // Loading state
          : provider.errorMessage != null
              ? ErrorView()                // Error state
              : events.isEmpty
                  ? EmptyState()           // Empty state
                  : RefreshIndicator(      // Data loaded
                      onRefresh: () => provider.loadEvents(),
                      child: ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return Card(
                            // Real event data from API
                            child: Text(event.title),
                          );
                        },
                      ),
                    ),
    );
  }
}
```

**Changes:**
- ✅ Changed from `StatelessWidget` to `StatefulWidget`
- ✅ Loads real data from API in `initState`
- ✅ Uses `Provider.of<EventProvider>()` for state access
- ✅ Shows loading, error, and empty states
- ✅ Pull-to-refresh functionality
- ✅ Displays actual event data

---

### 4. **`lib/screens/profile_screen.dart`** - Now Uses UserProvider

**Before:**
```dart
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Name: John Doe'),        // Hardcoded
        Text('Email: john@example.com'), // Hardcoded
        // ... more hardcoded data
      ],
    );
  }
}
```

**After:**
```dart
class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load user data when screen opens
    Future.microtask(() {
      Provider.of<UserProvider>(context, listen: false).loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return CircularProgressIndicator();
        }

        return Column(
          children: [
            // Dynamic avatar with user's initial
            CircleAvatar(
              child: Text(userProvider.name[0].toUpperCase()),
            ),

            // Real user data
            _buildInfoCard(
              icon: Icons.person,
              label: 'Name',
              value: userProvider.name,  // From API
            ),
            _buildInfoCard(
              icon: Icons.email,
              label: 'Email',
              value: userProvider.email,  // From API
            ),

            // Logout button with provider integration
            ElevatedButton.icon(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                userProvider.clearUser();
                Navigator.pushReplacement(context, Login());
              },
              icon: Icon(Icons.logout),
              label: Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
```

**Changes:**
- ✅ Changed from `StatelessWidget` to `StatefulWidget`
- ✅ Loads user data in `initState`
- ✅ Uses `Consumer<UserProvider>` for reactive UI
- ✅ Displays real user data from API
- ✅ Beautiful card-based UI design
- ✅ Integrated logout functionality
- ✅ Loading state management

---

### 5. **`lib/services/auth_service.dart`** - Removed AuthCheck Widget

**Before:**
```dart
class AuthCheck extends StatefulWidget {
  // Complex authentication checking widget
  // Used in main.dart
}
```

**After:**
```dart
// AuthCheck widget completely removed
// Auth checking now handled by providers
```

**Changes:**
- ✅ Removed `AuthCheck` widget (no longer needed)
- ✅ Removed Flutter imports (now just a service class)
- ✅ Cleaner, simpler service file

---

## How It Works

### 1. Application Flow

```
┌─────────────────┐
│   App Startup   │
│   (main.dart)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Login Screen   │
│  (login.dart)   │
└────────┬────────┘
         │
         │ User logs in
         ▼
┌──────────────────────────┐
│  AppProvidersWrapper     │
│  Initializes Providers:  │
│  • AuthProvider          │
│  • UserProvider          │
│  • EventProvider         │
└────────┬─────────────────┘
         │
         ▼
┌─────────────────┐
│   HomeScreen    │
│  (with NavBar)  │
└────────┬────────┘
         │
         ├─► Profile Screen (uses UserProvider)
         ├─► Events Screen (uses EventProvider)
         └─► Scanner Screen
```

### 2. Provider Pattern

#### **Creating a Provider**
```dart
class MyProvider extends ChangeNotifier {
  // 1. Private state
  bool _isLoading = false;

  // 2. Public getters
  bool get isLoading => _isLoading;

  // 3. Methods that modify state
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();  // UI rebuilds

    // ... fetch data

    _isLoading = false;
    notifyListeners();  // UI rebuilds again
  }
}
```

#### **Providing to Widget Tree**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MyProvider()),
  ],
  child: MyApp(),
)
```

#### **Consuming in Widgets**

**Method 1: Provider.of (manual)**
```dart
final provider = Provider.of<MyProvider>(context);
print(provider.isLoading);
```

**Method 2: Consumer (reactive)**
```dart
Consumer<MyProvider>(
  builder: (context, provider, _) {
    return Text(provider.isLoading ? 'Loading...' : 'Done');
  },
)
```

**Method 3: Provider.of with listen: false (one-time)**
```dart
void initState() {
  super.initState();
  Provider.of<MyProvider>(context, listen: false).loadData();
}
```

### 3. Data Flow

```
┌──────────────┐
│   Screen     │
│              │
│  initState() │────┐
└──────────────┘    │
                    │ 1. Calls provider method
                    ▼
              ┌──────────────┐
              │   Provider   │
              │              │
              │  loadData()  │
              └──────┬───────┘
                     │ 2. Calls service
                     ▼
              ┌──────────────┐
              │   Service    │
              │              │
              │  API.get()   │
              └──────┬───────┘
                     │ 3. Returns data
                     ▼
              ┌──────────────┐
              │   Provider   │
              │              │
              │ notifyListeners() │ ← 4. Triggers rebuild
              └──────┬───────┘
                     │
                     ▼
              ┌──────────────┐
              │   Screen     │  ← 5. UI updates automatically
              │  (rebuilds)  │
              └──────────────┘
```

### 4. Lifecycle Example: Event List Screen

**Step-by-Step:**

1. **Screen Initializes**
```dart
void initState() {
  super.initState();
  Future.microtask(() {
    Provider.of<EventProvider>(context, listen: false).loadEvents();
  });
}
```

2. **Provider Loads Data**
```dart
Future<void> loadEvents() async {
  isLoading = true;
  notifyListeners();  // Screen shows loading indicator

  events = await _service.getEvents();  // API call

  isLoading = false;
  notifyListeners();  // Screen shows event list
}
```

3. **UI Reacts to Changes**
```dart
Widget build(BuildContext context) {
  final provider = Provider.of<EventProvider>(context);

  // Automatically rebuilds when provider calls notifyListeners()
  return provider.isLoading
    ? CircularProgressIndicator()
    : ListView.builder(itemCount: provider.events.length);
}
```

### 5. State Management Flow

```
User Action
    │
    ▼
Widget calls Provider method
    │
    ▼
Provider updates private state
    │
    ▼
Provider calls notifyListeners()
    │
    ▼
All listening widgets rebuild
    │
    ▼
UI reflects new state
```

---

## Architecture Overview

### Layer Structure

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Screens/Widgets)                  │
│  • event_list.dart                  │
│  • profile_screen.dart              │
└──────────────┬──────────────────────┘
               │ Uses
               ▼
┌─────────────────────────────────────┐
│         State Management Layer      │
│  (Providers)                        │
│  • event_provider.dart              │
│  • user_provider.dart               │
│  • auth_provider.dart               │
└──────────────┬──────────────────────┘
               │ Calls
               ▼
┌─────────────────────────────────────┐
│         Business Logic Layer        │
│  (Services)                         │
│  • event_service.dart               │
│  • auth_service.dart                │
│  • api_service.dart                 │
└──────────────┬──────────────────────┘
               │ Makes HTTP requests
               ▼
┌─────────────────────────────────────┐
│            Backend API              │
└─────────────────────────────────────┘
```

### File Organization

```
lib/
├── main.dart                    # App entry point
├── app_providers_wrapper.dart   # Provider initialization
│
├── providers/                   # State management
│   ├── auth_provider.dart      # Authentication state
│   ├── user_provider.dart      # User data state
│   └── event_provider.dart     # Event data & CRUD
│
├── services/                    # Business logic & API
│   ├── api_service.dart        # Base API client
│   ├── auth_service.dart       # Auth operations
│   └── event_service.dart      # Event API operations
│
├── screens/                     # UI screens
│   ├── home_screen.dart
│   ├── event_list.dart
│   ├── profile_screen.dart
│   └── qr_scanner_screen.dart
│
├── users/                       # User-related screens
│   └── login.dart
│
└── models/                      # Data models
    ├── event.dart
    ├── user.dart
    └── ...
```

---

## Usage Examples

### Example 1: Accessing User Data

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get user provider
    final userProvider = Provider.of<UserProvider>(context);

    return Column(
      children: [
        Text('Welcome, ${userProvider.name}!'),
        Text('Email: ${userProvider.email}'),
        Text('Student ID: ${userProvider.studentId}'),
      ],
    );
  }
}
```

### Example 2: Loading Events

```dart
class EventsWidget extends StatefulWidget {
  @override
  State<EventsWidget> createState() => _EventsWidgetState();
}

class _EventsWidgetState extends State<EventsWidget> {
  @override
  void initState() {
    super.initState();
    // Load events when widget initializes
    Future.microtask(() {
      Provider.of<EventProvider>(context, listen: false).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return CircularProgressIndicator();
        }

        return ListView.builder(
          itemCount: provider.events.length,
          itemBuilder: (context, index) {
            final event = provider.events[index];
            return ListTile(
              title: Text(event.title),
              subtitle: Text(event.location),
            );
          },
        );
      },
    );
  }
}
```

### Example 3: Creating a New Event

```dart
class CreateEventButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final provider = Provider.of<EventProvider>(context, listen: false);

        final newEvent = Event(
          title: 'New Event',
          description: 'Event description',
          timeStart: '2024-12-20 14:00',
          timeEnd: '2024-12-20 16:00',
          location: 'Main Hall',
        );

        // Create event - provider will automatically refresh list
        await provider.createEvent(newEvent);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event created!')),
        );
      },
      child: Text('Create Event'),
    );
  }
}
```

### Example 4: Logout with Provider

```dart
class LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Get providers
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        // Logout
        await authProvider.logout();
        userProvider.clearUser();

        // Navigate to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      },
      child: Text('Logout'),
    );
  }
}
```

### Example 5: Handling Errors

```dart
Widget build(BuildContext context) {
  final provider = Provider.of<EventProvider>(context);

  if (provider.errorMessage != null) {
    return Column(
      children: [
        Text(
          provider.errorMessage!,
          style: TextStyle(color: Colors.red),
        ),
        ElevatedButton(
          onPressed: () {
            provider.clearError();
            provider.loadEvents();
          },
          child: Text('Retry'),
        ),
      ],
    );
  }

  // ... normal UI
}
```

---

## Benefits

### 1. **Centralized State Management**
- All app state in one place (providers)
- Easy to track and debug state changes
- Single source of truth for data

### 2. **Reactive UI**
- UI automatically updates when data changes
- No manual setState() in screens
- Cleaner, more maintainable code

### 3. **Better Performance**
- Only widgets listening to changes rebuild
- Efficient update mechanism
- Reduced unnecessary rebuilds

### 4. **Separation of Concerns**
```
Screens       → Handle UI only
Providers     → Manage state & business logic
Services      → Handle API calls
Models        → Define data structure
```

### 5. **Easier Testing**
```dart
// Mock providers for testing
testWidgets('Profile shows user name', (tester) async {
  final mockProvider = MockUserProvider();
  when(mockProvider.name).thenReturn('John Doe');

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: mockProvider,
      child: ProfileScreen(),
    ),
  );

  expect(find.text('John Doe'), findsOneWidget);
});
```

### 6. **Scalability**
- Easy to add new providers
- Clean architecture supports growth
- Modular and maintainable

### 7. **Code Reusability**
- Providers can be used across multiple screens
- Share state without passing props
- Consistent data access patterns

### 8. **Developer Experience**
- IntelliSense support for provider methods
- Type-safe state access
- Clear data flow

---

## Key Patterns Used

### 1. **Future.microtask Pattern**
Used in `initState` to avoid BuildContext issues:
```dart
void initState() {
  super.initState();
  Future.microtask(() {
    Provider.of<EventProvider>(context, listen: false).loadEvents();
  });
}
```

**Why?**
- Defers execution until after build completes
- Avoids "BuildContext across async gaps" warnings
- Clean way to trigger initial data load

### 2. **listen: false Pattern**
Used when you don't need to rebuild:
```dart
Provider.of<EventProvider>(context, listen: false).loadEvents();
```

**Why?**
- Prevents widget from rebuilding when provider changes
- Use when just calling methods, not reading state
- More efficient for one-time operations

### 3. **Consumer Pattern**
Used for reactive UI updates:
```dart
Consumer<EventProvider>(
  builder: (context, provider, _) {
    return Text(provider.events.length.toString());
  },
)
```

**Why?**
- Only rebuilds the Consumer widget
- More granular control over rebuilds
- Cleaner than wrapping entire build method

### 4. **Service Layer Pattern**
Providers call services, services call API:
```dart
// In Provider
Future<void> loadEvents() async {
  events = await _service.getEvents();  // Calls service
  notifyListeners();
}

// In Service
Future<List<Event>> getEvents() async {
  final response = await ApiService.get('/events');  // API call
  return parseEvents(response);
}
```

**Why?**
- Separation of state management and API logic
- Services can be reused by multiple providers
- Easier to test and maintain

---

## Common Patterns

### Pattern 1: Loading State
```dart
if (provider.isLoading) {
  return CircularProgressIndicator();
}
```

### Pattern 2: Error State
```dart
if (provider.errorMessage != null) {
  return ErrorWidget(message: provider.errorMessage!);
}
```

### Pattern 3: Empty State
```dart
if (provider.events.isEmpty) {
  return Text('No events available');
}
```

### Pattern 4: Pull to Refresh
```dart
RefreshIndicator(
  onRefresh: () => provider.loadEvents(),
  child: ListView(...),
)
```

---

## Troubleshooting

### Issue: "BuildContext across async gaps"
**Solution:** Use `Future.microtask` or check `mounted`:
```dart
// Option 1: Future.microtask
Future.microtask(() {
  Provider.of<MyProvider>(context, listen: false).load();
});

// Option 2: Check mounted
if (!mounted) return;
Navigator.push(...);
```

### Issue: Widget not rebuilding
**Solution:** Make sure you're not using `listen: false`:
```dart
// Wrong
final provider = Provider.of<MyProvider>(context, listen: false);

// Correct
final provider = Provider.of<MyProvider>(context);
// or
Consumer<MyProvider>(builder: (context, provider, _) { ... })
```

### Issue: Too many rebuilds
**Solution:** Use `Consumer` for specific widgets or `Selector`:
```dart
// Only rebuild when specific field changes
Selector<EventProvider, int>(
  selector: (context, provider) => provider.events.length,
  builder: (context, length, _) => Text('$length events'),
)
```

---

## Next Steps

### Recommended Enhancements

1. **Add More Providers**
   - `StudentProvider` for student-specific data
   - `ParticipationProvider` for event participation
   - `NotificationProvider` for app notifications

2. **Implement Caching**
   ```dart
   Future<void> loadEvents() async {
     // Check cache first
     final cached = await _cacheService.getEvents();
     if (cached != null) {
       events = cached;
       notifyListeners();
     }

     // Then fetch fresh data
     events = await _service.getEvents();
     await _cacheService.saveEvents(events);
     notifyListeners();
   }
   ```

3. **Add Pagination**
   ```dart
   int _page = 1;
   Future<void> loadMore() async {
     _page++;
     final moreEvents = await _service.getEvents(page: _page);
     events.addAll(moreEvents);
     notifyListeners();
   }
   ```

4. **Add Search/Filter**
   ```dart
   String _searchQuery = '';
   List<Event> get filteredEvents {
     if (_searchQuery.isEmpty) return events;
     return events.where((e) =>
       e.title.toLowerCase().contains(_searchQuery.toLowerCase())
     ).toList();
   }
   ```

---

## References

- **Template Repository:** https://github.com/johnfacun2014/my_project
- **Provider Package:** https://pub.dev/packages/provider
- **Flutter Documentation:** https://docs.flutter.dev/development/data-and-backend/state-mgmt/simple

---

## Summary

This implementation successfully integrates Provider state management following professional patterns:

✅ Clean separation of concerns
✅ Reactive UI updates
✅ Centralized state management
✅ Full CRUD operations
✅ Error handling
✅ Loading states
✅ Pull-to-refresh
✅ Follows template architecture

The app is now more maintainable, scalable, and follows Flutter best practices for state management.
