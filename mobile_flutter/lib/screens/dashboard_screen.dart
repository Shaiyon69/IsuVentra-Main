import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import 'view_event.dart';
import '../models/event_model.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      context.read<DashboardProvider>().loadDashboardData(
        userId: user?.id,
        role: user?.role,
        refresh: true,
      );
    });
  }

  /// Calculates how many active events fall on "Today"
  int _getEventsTodayCount(List<Event> events) {
    final now = DateTime.now();
    return events.where((event) {
      return event.timeStart.year == now.year &&
          event.timeStart.month == now.month &&
          event.timeStart.day == now.day;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final provider = context.watch<DashboardProvider>();
    final user = context.watch<AuthProvider>().user;

    // Use the recent list (which is already top 5 from provider)
    // But we need the full list to count "Events Today" correctly if provider truncates it.
    // NOTE: Provider currently truncates _recentEvents to 5.
    // To get an accurate "Events Today" count if there are >5 events,
    // we rely on the list we have. If exact count > 5 is critical,
    // we'd need a separate "eventsToday" counter in provider.
    // For now, calculating based on visible recents or provider count.

    final eventsTodayCount = _getEventsTodayCount(provider.recentEvents);
    final top5Events = provider.recentEvents;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadDashboardData(
            userId: user?.id,
            role: user?.role,
            refresh: true,
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- STATS CARD ---
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Events Today',
                              '$eventsTodayCount',
                              Icons.calendar_today,
                              colorScheme.primary,
                            ),
                          ),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Joined Today',
                              // Provider calculates "Joined Today" for students
                              provider.participationsCount.toString(),
                              Icons.check_circle_outline,
                              colorScheme.tertiary,
                            ),
                          ),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Scans Today',
                              // Provider calculates "Scans Today" for students
                              provider.scansCount.toString(),
                              Icons.qr_code_scanner,
                              colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Upcoming & Ongoing',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // --- EVENTS LIST ---
              if (provider.isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  ),
                )
              else if (top5Events.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "No active events at the moment.",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildUpcomingEvents(context, top5Events),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: iconColor),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          title,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEvents(BuildContext context, List<Event> events) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.event,
                color: colorScheme.onSecondaryContainer,
                size: 24,
              ),
            ),
            title: Text(
              event.title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM d, yyyy').format(event.timeStart),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (event.location != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.location!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.outline,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewEventScreen(event: event),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
