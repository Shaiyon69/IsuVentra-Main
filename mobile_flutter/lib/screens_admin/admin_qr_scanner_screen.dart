import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/participation_provider.dart';
import '../providers/student_provider.dart';

class HollowCenterClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    const double scanAreaSize = 250;
    Rect centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    Path centerPath = Path()..addRect(centerRect);
    return Path.combine(PathOperation.difference, fullPath, centerPath);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class AdminQRScannerScreen extends StatefulWidget {
  final Event? event;

  const AdminQRScannerScreen({super.key, this.event});

  @override
  State<AdminQRScannerScreen> createState() => _AdminQRScannerScreenState();
}

class _AdminQRScannerScreenState extends State<AdminQRScannerScreen> {
  late MobileScannerController cameraController;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  bool _qrDetected = false;
  String? _lastScanned;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      torchEnabled: false,
      facing: CameraFacing.back,
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await cameraController.start();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize camera: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || widget.event == null) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code == null) continue;

      // Check for duplicate scan
      if (_lastScanned == code) return;

      setState(() {
        _qrDetected = true;
        _lastScanned = code;
      });

      // Show detection feedback briefly, then start processing
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isProcessing = true;
            _qrDetected = false;
          });
          _processScan(code);
        }
      });

      break; // Process only the first barcode
    }
  }

  Future<void> _processScan(String code) async {
    try {
      final studentProvider = Provider.of<StudentProvider>(
        context,
        listen: false,
      );
      final student = await studentProvider.fetchStudentByStudentId(code);

      if (student == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Student not found. Invalid ID scanned.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }

      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildConfirmationDialog(context, student),
        );

        if (confirmed == true) {
          final participationProvider = Provider.of<ParticipationProvider>(
            context,
            listen: false,
          );

          await participationProvider.adminRecordParticipation(
            student.id,
            widget.event!.id,
            studentName: student.name,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Attendance recorded for ${student.name}!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            Navigator.of(context).popUntil((route) {
              return route.settings.name == '/admin/event-management' ||
                  route.isFirst;
            });
          }
        } else {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } on FormatException {
      debugPrint('Invalid QR code format: $code');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid QR code format. Please scan a valid student ID.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Error recording participation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error recording participation: ${e.toString()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    cameraController.stop();
    cameraController.dispose();
    super.dispose();
  }

  Widget _buildConfirmationDialog(BuildContext context, dynamic student) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(
        'Confirm Attendance',
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            'Student Name:',
            student.name,
            textTheme,
            colorScheme,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Student ID:',
            student.studentId,
            textTheme,
            colorScheme,
          ),

          if (student.course != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow('Course:', student.course, textTheme, colorScheme),
          ],
          if (student.yearLevel != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              'Year Level:',
              student.yearLevel.toString(),
              textTheme,
              colorScheme,
            ),
          ],
          const Divider(height: 24),
          _buildDetailRow(
            'Event:',
            widget.event!.title,
            textTheme,
            colorScheme,
            isEvent: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm Check-in'),
          style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    TextTheme textTheme,
    ColorScheme colorScheme, {
    bool isEvent = false,
  }) {
    return RichText(
      text: TextSpan(
        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        children: [
          TextSpan(
            text: label,
            style: isEvent
                ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                : const TextStyle(fontWeight: FontWeight.w400),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: value,
            style: isEvent
                ? textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary,
                  )
                : const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Color color, bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isTop ? color : Colors.transparent, width: 4),
          bottom: BorderSide(
            color: isTop ? Colors.transparent : color,
            width: 4,
          ),
          left: BorderSide(
            color: isLeft ? color : Colors.transparent,
            width: 4,
          ),
          right: BorderSide(
            color: isLeft ? Colors.transparent : color,
            width: 4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.event?.title ?? 'QR Scanner'),
        backgroundColor: colorScheme.surface.withOpacity(0.5),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),

          ClipPath(
            clipper: HollowCenterClipper(),
            child: Container(color: colorScheme.scrim.withOpacity(0.6)),
          ),

          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCorner(colorScheme.primary, true, true),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildCorner(colorScheme.primary, true, false),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildCorner(colorScheme.primary, false, true),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildCorner(colorScheme.primary, false, false),
                  ),
                ],
              ),
            ),
          ),

          if (_qrDetected)
            Container(
              color: colorScheme.scrim.withOpacity(0.9),
              child: Center(
                child: Text(
                  'QR Code Detected!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    backgroundColor: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (_isProcessing)
            Container(
              color: colorScheme.scrim.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Processing QR Code...',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        backgroundColor: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: colorScheme.surface,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          await cameraController.toggleTorch();
                          setState(() {
                            _torchEnabled = !_torchEnabled;
                          });
                        },
                  icon: Icon(
                    _torchEnabled ? Icons.flash_on : Icons.flash_off,
                    color: _torchEnabled
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  label: Text(_torchEnabled ? 'Flash On' : 'Flash Off'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    foregroundColor: colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => cameraController.switchCamera(),
                  icon: Icon(Icons.cameraswitch, color: colorScheme.onPrimary),
                  label: Text(
                    'Switch',
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
