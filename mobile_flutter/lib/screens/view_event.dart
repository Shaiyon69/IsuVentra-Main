import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class ViewEventScreen extends StatelessWidget {
  final Event event;

  const ViewEventScreen({super.key, required this.event});

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isUpcoming = event.timeStart.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Title
            Text(
              event.title,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Status Chip
            Chip(
              label: Text(isUpcoming ? 'UPCOMING' : 'PAST EVENT'),
              backgroundColor: isUpcoming
                  ? colorScheme.secondaryContainer
                  : colorScheme.surfaceVariant,
              labelStyle: textTheme.labelLarge?.copyWith(
                color: isUpcoming
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
            const SizedBox(height: 32),

            // Event Description
            if (event.description != null && event.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),

            // Event Details Card
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
                    Text(
                      'Schedule & Venue',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Divider(height: 28),

                    // Date
                    _buildInfoItem(
                      context,
                      Icons.calendar_month,
                      'Date',
                      DateFormat('EEEE, MMM d, yyyy').format(event.timeStart),
                      colorScheme.primary,
                    ),
                    const SizedBox(height: 20),

                    // Time
                    _buildInfoItem(
                      context,
                      Icons.schedule,
                      'Time',
                      '${DateFormat('h:mm a').format(event.timeStart)} - ${DateFormat('h:mm a').format(event.timeEnd)}',
                      colorScheme.secondary,
                    ),
                    const SizedBox(height: 20),

                    // Location
                    if (event.location != null && event.location!.isNotEmpty)
                      _buildInfoItem(
                        context,
                        Icons.location_on,
                        'Location',
                        event.location!,
                        colorScheme.tertiary,
                      ),
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
