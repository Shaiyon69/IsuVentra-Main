import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';

class EventCreationScreen extends StatefulWidget {
  const EventCreationScreen({super.key});

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String? _description;
  String? _location;
  DateTime _timeStart = DateTime.now().add(const Duration(hours: 1));
  DateTime _timeEnd = DateTime.now().add(const Duration(hours: 2));

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _timeStart = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    _timeEnd = _timeStart.add(const Duration(hours: 1));
  }

  Future<void> _pickDateTime(bool isStartTime) async {
    final now = DateTime.now();
    final initialDate = isStartTime ? _timeStart : _timeEnd;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (date == null) return;

    final initialTime = TimeOfDay.fromDateTime(initialDate);

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time == null) return;

    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStartTime) {
        _timeStart = newDateTime;
        if (_timeEnd.isBefore(_timeStart)) {
          _timeEnd = _timeStart.add(const Duration(hours: 1));
        }
      } else {
        if (newDateTime.isAfter(_timeStart)) {
          _timeEnd = newDateTime;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End time must be after start time.')),
          );
        }
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (_timeEnd.isBefore(_timeStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The event end time cannot be before the start time.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final newEvent = Event(
      id: DateTime.now().millisecondsSinceEpoch,
      title: _title,
      timeStart: _timeStart,
      timeEnd: _timeEnd,
      description: _description,
      location: _location,
      createdAt: DateTime.now(),
    );

    final eventProvider = context.read<EventProvider>();

    try {
      await eventProvider.createEvent(newEvent);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Event',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  prefixIcon: Icon(
                    Icons.event_note,
                    color: colorScheme.primary,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title for the event.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Location (e.g., Auditorium B)',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: colorScheme.secondary,
                  ),
                ),
                onSaved: (value) {
                  _location = value;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(
                    Icons.description,
                    color: colorScheme.tertiary,
                  ),
                ),
                maxLines: 3,
                onSaved: (value) {
                  _description = value;
                },
              ),
              const SizedBox(height: 32),

              Text(
                'Event Schedule',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              _buildDateTimePicker(
                context,
                'Start Time',
                Icons.calendar_today,
                _timeStart,
                () => _pickDateTime(true),
              ),
              const SizedBox(height: 16),

              _buildDateTimePicker(
                context,
                'End Time',
                Icons.schedule,
                _timeEnd,
                () => _pickDateTime(false),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _submitForm,
                  icon: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: colorScheme.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isSaving ? 'Creating Event...' : 'Create Event',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(
    BuildContext context,
    String label,
    IconData icon,
    DateTime dateTime,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
        ),
        child: Text(
          DateFormat('EEEE, MMM d, yyyy \n(h:mm a)').format(dateTime),
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
