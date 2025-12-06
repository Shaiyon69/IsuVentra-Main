import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import 'admin_qr_scanner_screen.dart';
import 'event_creation_screen.dart';

class AdminEventManagementScreen extends StatefulWidget {
  const AdminEventManagementScreen({super.key});

  @override
  State<AdminEventManagementScreen> createState() =>
      _AdminEventManagementScreenState();
}

class _AdminEventManagementScreenState
    extends State<AdminEventManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).fetchEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToCreateEvent() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const EventCreationScreen()),
        )
        .then((result) {
          if (result == true) {
            Provider.of<EventProvider>(context, listen: false).fetchEvents();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventProvider>(context);
    final events = provider.searchAndSortEvents(_searchQuery);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateEvent,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _buildBody(provider, events, theme, colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    EventProvider provider,
    List events,
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(provider.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchEvents(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'No Events Scheduled',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the "New Event" button below to get started.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchEvents(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(theme, event);
        },
      ),
    );
  }

  Widget _buildEventCard(ThemeData theme, dynamic event) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isUpcoming = event.timeStart.isAfter(DateTime.now());
    final statusColor = isUpcoming
        ? colorScheme.secondary
        : colorScheme.outline;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_month, size: 18, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(event.timeStart),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 18, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  "${DateFormat('h:mm a').format(event.timeStart)} - ${DateFormat('h:mm a').format(event.timeEnd)}",
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (event.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (event.description != null)
              Text(
                event.description!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminQRScannerScreen(event: event),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 20),
                    SizedBox(width: 8),
                    Text('Start Scanning Attendance'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
