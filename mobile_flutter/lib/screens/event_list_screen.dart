import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import 'student_qr_code_screen.dart';

class EventListScreen extends StatefulWidget {
  final VoidCallback? onSwitchToQR;

  const EventListScreen({super.key, this.onSwitchToQR});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventProvider>(context);
    final events = provider.events;
    final filteredEvents =
        events
            .where(
              (event) => event.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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

    return Scaffold(
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
            child: provider.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : provider.errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(provider.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.fetchEvents(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : filteredEvents.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No events available'
                          : 'No events found',
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.fetchEvents(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredEvents.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];

                        return Card(
                          elevation: 0,
                          color: colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${DateFormat('MMM d, h:mm a').format(event.timeStart)} - ${DateFormat('h:mm a').format(event.timeEnd)}",
                                      style: textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (event.location != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        event.location!,
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          colorScheme.secondaryContainer,
                                      foregroundColor:
                                          colorScheme.onSecondaryContainer,
                                    ),
                                    onPressed: () {
                                      widget.onSwitchToQR?.call();
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.qr_code, size: 20),
                                        SizedBox(width: 8),
                                        Text('Participate'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
