import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';
import 'admin_qr_scanner_screen.dart';
import 'event_creation_screen.dart';
import 'event_attendees_screen.dart';
import '../screens/view_event.dart';

class AdminEventManagementScreen extends StatefulWidget {
  final bool limitTo10;

  const AdminEventManagementScreen({super.key, this.limitTo10 = false});

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
    final provider = Provider.of<EventProvider>(context, listen: false);
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const EventCreationScreen()),
        )
        .then((result) {
          if (result == true) {
            provider.fetchEvents();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventProvider>(context);
    final allEvents = provider.searchAndSortEvents(_searchQuery);
    final events = widget.limitTo10 ? allEvents.take(10).toList() : allEvents;
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
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
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
                _searchQuery.isEmpty
                    ? 'Tap the "New Event" button to get started.'
                    : 'No events found for "$_searchQuery".',
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
          return _buildEventCard(theme, event, context);
        },
      ),
    );
  }

  Widget _buildEventCard(ThemeData theme, dynamic event, BuildContext context) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isUpcoming = event.timeStart.isAfter(DateTime.now());
    final statusColor = isUpcoming
        ? colorScheme.secondary
        : colorScheme.outline;

    return Card(
      elevation: 2,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            if (event.description != null) ...[
              Text(
                event.description!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM d, yyyy').format(event.timeStart),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  "${DateFormat('h:mm a').format(event.timeStart)} - ${DateFormat('h:mm a').format(event.timeEnd)}",
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            if (event.location != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EventAttendeesScreen(event: event as Event),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'View',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminQRScannerScreen(event: event),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Scan Attendance',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
