import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // REQUIRES: qr_flutter in pubspec.yaml
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  Event? selectedEvent;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final theme = Theme.of(context);

    return Scaffold(
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

            // Dropdown to select event
            DropdownButtonFormField<Event>(
              decoration: const InputDecoration(
                labelText: 'Select Event',
                border: OutlineInputBorder(),
              ),
              value: selectedEvent,
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
                            data: selectedEvent!.id
                                .toString(), // The data hidden in the QR
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
