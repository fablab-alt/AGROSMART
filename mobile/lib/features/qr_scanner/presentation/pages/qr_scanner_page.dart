import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  String? _scannedCode;
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() {
      _scannedCode = barcode.rawValue;
      _isProcessing = true;
    });

    // Process the scanned code
    _processScannedCode(barcode);
  }

  Future<void> _processScannedCode(Barcode barcode) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Show result dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code scanné'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${barcode.format.name}'),
            const SizedBox(height: 8),
            Text('Valeur: ${barcode.rawValue}'),
            const SizedBox(height: 16),
            const Text(
              'Que souhaitez-vous faire ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchProduct();
            },
            child: const Text('Rechercher produit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addToStock();
            },
            child: const Text('Ajouter au stock'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
                _scannedCode = null;
              });
            },
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _searchProduct() {
    // TODO: Implement product search
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recherche du produit: $_scannedCode')),
    );
    setState(() {
      _isProcessing = false;
      _scannedCode = null;
    });
  }

  void _addToStock() {
    // TODO: Navigate to stock add page with scanned code
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Ajout au stock: $_scannedCode')));
    setState(() {
      _isProcessing = false;
      _scannedCode = null;
    });
  }

  void _toggleTorch() {
    controller.toggleTorch();
  }

  void _switchCamera() {
    controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR/Code-barres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_off),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          // Scanning overlay
          CustomPaint(painter: ScannerOverlay(), child: Container()),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scannedCode != null)
                    Text(
                      'Code scanné: $_scannedCode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    const Text(
                      'Placez le code QR ou code-barres dans le cadre',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
          // Controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.image, size: 32),
                  color: Colors.white,
                  onPressed: () {
                    // TODO: Pick image from gallery
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Sélection depuis la galerie en développement',
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.history, size: 32),
                  color: Colors.white,
                  onPressed: () {
                    // TODO: Show scan history
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Historique des scans en développement'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(scanArea),
      ),
      paint,
    );

    // Draw corners
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(0, cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(0, -cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
