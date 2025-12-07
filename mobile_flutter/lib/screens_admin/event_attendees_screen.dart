import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/participation_provider.dart';
import '../models/event_model.dart';
import '../models/participation_model.dart';

class EventAttendeesScreen extends StatefulWidget {
  final Event event;

  const EventAttendeesScreen({super.key, required this.event});

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ParticipationProvider>(
        context,
        listen: false,
      ).fetchParticipations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendees - ${widget.event.title}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Consumer<ParticipationProvider>(
        builder: (context, provider, child) {
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
                    onPressed: () => provider.fetchParticipations(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final eventParticipations = provider.getParticipationsForEvent(
            widget.event.id,
          );

          if (eventParticipations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Attendees Yet',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No students have checked in for this event.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchParticipations(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: eventParticipations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final participation = eventParticipations[index];
                return _buildAttendeeCard(
                  theme,
                  participation,
                  colorScheme,
                  textTheme,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendeeCard(
    ThemeData theme,
    Participation participation,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 1,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person,
                color: colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participation.studentName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (participation.timeIn != null)
                    Text(
                      'Checked in: ${DateFormat('MMM d, h:mm a').format(participation.timeIn!)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (participation.timeOut != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Checked out: ${DateFormat('MMM d, h:mm a').format(participation.timeOut!)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: participation.timeOut != null
                    ? colorScheme.tertiaryContainer
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                participation.timeOut != null ? 'Completed' : 'Checked In',
                style: textTheme.labelSmall?.copyWith(
                  color: participation.timeOut != null
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
