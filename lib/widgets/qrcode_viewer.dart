import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '/theme/style.dart';

class QrcodeBottomSheet extends StatelessWidget {
  final String qrData;
  final String visitorName;
  final Map<String, dynamic>? specs;

  const QrcodeBottomSheet({
    super.key,
    required this.qrData,
    required this.visitorName,
    this.specs,
  });

  @override
  Widget build(BuildContext context) {
    GlobalKey globalKey = GlobalKey();

    Future<void> shareQrCode() async {
      try {
        RenderRepaintBoundary boundary =
            globalKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/qrcode.png').create();
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'access_pass_generated'.tr + ' $visitorName');
      } catch (e) {
        print("Erreur partage QR: $e");
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5)),
            ),
            Text(
              "access_pass_generated".tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.indigo),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: globalKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: qrData,
                      size: 260, // Taille augmentée pour une meilleure densité de pixels
                      version: QrVersions.auto,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      gapless: true,
                      embeddedImage: const AssetImage("assets/images/mamba_bg.png"),
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(46, 46), // Taille calculée pour ne pas gêner les modules
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      visitorName.toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Ubuntu'),
                    ),
                    if (specs != null) ...[
                       const SizedBox(height: 8),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(_getModeIcon(specs!["mode"]), size: 14, color: Colors.grey),
                           const SizedBox(width: 5),
                           Text(
                             _getModeLabel(specs!["mode"]),
                             style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600, fontFamily: 'Ubuntu'),
                           ),
                         ],
                       ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: shareQrCode,
                icon: const Icon(Icons.share, color: Colors.white),
                label: Text("share_pass".tr, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontFamily: 'Ubuntu')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  IconData _getModeIcon(String? mode) {
    switch (mode) {
      case "car": return Icons.directions_car;
      case "taxi": return Icons.local_taxi;
      default: return Icons.directions_walk;
    }
  }

  String _getModeLabel(String? mode) {
    switch (mode) {
      case "car": return "car".tr;
      case "taxi": return "taxi".tr;
      default: return "foot".tr;
    }
  }
}
