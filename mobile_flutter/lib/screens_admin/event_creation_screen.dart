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
        SnackBar(content: Text('Failed to create event: ${e.toString()}')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Event',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  prefixIcon: Icon(Icons.event_note),
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
                decoration: const InputDecoration(
                  labelText: 'Location (e.g., Auditorium B)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                onSaved: (value) {
                  _location = value;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                onSaved: (value) {
                  _description = value;
                },
              ),
              const SizedBox(height: 24),

              Text(
                'Event Schedule',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              _buildDateTimePicker(
                context,
                'Start Time',
                Icons.calendar_today,
                _timeStart,
                () => _pickDateTime(true),
              ),
              const SizedBox(height: 12),

              _buildDateTimePicker(
                context,
                'End Time',
                Icons.schedule,
                _timeEnd,
                () => _pickDateTime(false),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
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
                  label: Text(_isSaving ? 'Creating Event...' : 'Create Event'),
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
    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          DateFormat('EEEE, MMM d, yyyy \n(h:mm a)').format(dateTime),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
