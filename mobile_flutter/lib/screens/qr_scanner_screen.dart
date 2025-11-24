import 'package:flutter/material.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final placeholderColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 80, color: placeholderColor),
          const SizedBox(height: 20),
          Text(
            'QR Scanner Placeholder',
            style: TextStyle(fontSize: 18, color: placeholderColor),
          ),
          const SizedBox(height: 10),
          Text(
            'Camera view will be displayed here',
            style: TextStyle(fontSize: 14, color: placeholderColor),
          ),
        ],
      ),
    );
  }
}
