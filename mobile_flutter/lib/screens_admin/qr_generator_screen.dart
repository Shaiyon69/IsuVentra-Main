import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';

class QRGeneratorScreen extends StatefulWidget {
  final Event? initialEvent;

  const QRGeneratorScreen({super.key, this.initialEvent});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  Event? selectedEvent;

  @override
  void initState() {
    super.initState();
    if (widget.initialEvent != null) {
      selectedEvent = widget.initialEvent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final theme = Theme.of(context);

    if (selectedEvent != null && provider.events.isNotEmpty) {
      try {
        selectedEvent = provider.events.firstWhere(
          (e) => e.id == selectedEvent!.id,
        );
      } catch (e) {
        selectedEvent = null;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("QR Code Generator")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Select an event to generate its check-in code.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<Event>(
              decoration: const InputDecoration(
                labelText: 'Select Event',
                border: OutlineInputBorder(),
              ),
              initialValue: selectedEvent,
              items: provider.events.map((event) {
                return DropdownMenuItem(
                  value: event,
                  child: Text(event.title, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedEvent = value;
                });
              },
            ),

            const SizedBox(height: 40),

            // QR Code Display
            Expanded(
              child: Center(
                child: selectedEvent == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 100,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text("No event selected"),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          QrImageView(
                            data: selectedEvent!.id.toString(),
                            version: QrVersions.auto,
                            size: 250.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            selectedEvent!.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Chip(label: Text("Scan to Check-in")),
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
