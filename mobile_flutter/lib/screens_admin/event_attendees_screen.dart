import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/participation_provider.dart';
import '../models/event_model.dart';
import '../models/participation_model.dart';
import '../screens_admin/admin_qr_scanner_screen.dart';

class EventAttendeesScreen extends StatefulWidget {
  final Event event;
  const EventAttendeesScreen({super.key, required this.event});

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshList();
    });
    _searchController.addListener(() {
      if (mounted)
        setState(
          () => _searchQuery = _searchController.text.trim().toLowerCase(),
        );
    });
  }

  Future<void> _refreshList() async {
    await Provider.of<ParticipationProvider>(
      context,
      listen: false,
    ).fetchParticipations();
  }

  Future<void> _handleScan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminQRScannerScreen(event: widget.event),
      ),
    );
    // Refresh list when scanner closes
    if (mounted) _refreshList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendees', style: TextStyle(fontSize: 16)),
            Text(
              widget.event.title,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleScan,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Student'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Consumer<ParticipationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading)
            return const Center(child: CircularProgressIndicator());

          // Filter participants by this event ID
          final eventParticipations = provider.getParticipationsForEvent(
            widget.event.id,
          );

          final filtered = _searchQuery.isEmpty
              ? eventParticipations
              : eventParticipations
                    .where(
                      (p) =>
                          p.studentName.toLowerCase().contains(_searchQuery) ||
                          p.studentId.toString().contains(_searchQuery),
                    )
                    .toList();

          // Sort by latest activity
          filtered.sort((a, b) {
            final aTime = a.timeOut ?? a.timeIn ?? DateTime(2000);
            final bTime = b.timeOut ?? b.timeIn ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                'No Attendees Yet',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshList,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = filtered[index];
                String initials = 'S';
                if (p.studentName.isNotEmpty)
                  initials = p.studentName[0].toUpperCase();

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(initials)),
                    title: Text(
                      p.studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('ID: ${p.studentId}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (p.timeIn != null)
                          Text(
                            'IN: ${DateFormat("h:mm a").format(p.timeIn!)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (p.timeOut != null)
                          Text(
                            'OUT: ${DateFormat("h:mm a").format(p.timeOut!)}',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
