import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '/services/api_manager.dart';
import '../components/kiosk_components.dart';
import '../pages/history_page.dart';
import '../utils/controllers.dart';
import '../utils/store.dart';
import '/theme/style.dart';
import 'auth/login2.dart';
import '../widgets/scanner_overlay.dart';

class MainScreenAgent extends StatefulWidget {
  const MainScreenAgent({super.key});

  @override
  State<MainScreenAgent> createState() => _MainScreenAgentState();
}

class _MainScreenAgentState extends State<MainScreenAgent> with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool isLight = false;
  QRViewController? controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (dataController.isScanned.value == false) {
        processScan(scanData.code!);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (GetPlatform.isAndroid) {
        controller!.pauseCamera();
      }
      controller!.resumeCamera();
    }
  }

  Future<void> processScan(String token) async {
    dataController.isScanned.value = true;
    controller?.pauseCamera();
    
    EasyLoading.show(status: "checking_code".tr);
    
    try {
      final res = await ApiManager().getScanInfos(token: token);
      
      if (res is Map && res.containsKey("qrcode")) {
        bool expired = res["status"] != "accepted";
        
        Map<String, dynamic>? specs;
        if (res["qrcode"]["specifications"] != null) {
           try {
             specs = Map<String, dynamic>.from(res["qrcode"]["specifications"]);
           } catch(e) {
             print("Erreur parsing specs: $e");
           }
        }

        showScanInfos(
          qrcode: res["qrcode"]["token"],
          valideTo: res["qrcode"]["valid_to"] ?? "",
          resident: res["qrcode"]["unit"]?['resident']?['name'] ?? "N/A",
          visitor: res["qrcode"]["visitor"]?['name'] ?? "unknown".tr,
          unit: res["qrcode"]["unit"]?['name'] ?? "N/A",
          isExpired: expired,
          errorMessage: expired ? (res["message"] ?? "qr_invalid".tr) : null,
          specifications: specs,
        );
      } else {
        dataController.isScanned.value = false;
        EasyLoading.showInfo(res is String ? res : "qr_invalid".tr);
        controller?.resumeCamera();
      }
    } catch (e) {
      dataController.isScanned.value = false;
      EasyLoading.showError("network_error".tr);
      controller?.resumeCamera();
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> validateAccess(String token) async {
    EasyLoading.show(status: "granting_access".tr);
    
    try {
      var res = await ApiManager().scanQrcode(token: token);
      if (res is String) {
        EasyLoading.showError(res);
      } else {
        EasyLoading.showSuccess("access_granted_success".tr);
      }
    } catch (e) {
      EasyLoading.showError("network_error".tr);
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
            
            Obx(() => ScannerOverlay(
              isScanned: dataController.isScanned.value,
              onRestarted: () {
                dataController.isScanned.value = false;
                controller?.resumeCamera();
              },
            )),

            // Header Section (Glassmorphism)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
                    color: Colors.black.withOpacity(0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => _showLogoutConfirmation(),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                            _buildAgentAvatar(),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "identification".tr,
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white54, 
                            fontFamily: 'Ubuntu', 
                            letterSpacing: 2
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "scan_code".tr,
                          style: const TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.w900, 
                            color: Colors.white, 
                            fontFamily: 'Ubuntu'
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Controls Section (Positionné au bas du scanner)
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlBtn(
                    icon: isLight ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded,
                    onTap: () {
                      controller?.toggleFlash();
                      setState(() => isLight = !isLight);
                    },
                  ),
                  const SizedBox(width: 32),
                  _buildControlBtn(
                    icon: Icons.history_rounded,
                    onTap: () => Get.to(() => const HistoryPage()),
                  ),
                  const SizedBox(width: 32),
                  _buildControlBtn(
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      dataController.isScanned.value = false;
                      controller?.resumeCamera();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentAvatar() {
    final user = authController.user.value;
    return GestureDetector(
      onTap: showProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Text(
              user?.nom ?? "Agent",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundImage: AssetImage("assets/images/male.jpg"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  void showProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                Obx(() {
                  final user = authController.user.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: secondary.withOpacity(0.1),
                      child: Text(user?.nom.substring(0, 1).toUpperCase() ?? "A", style: TextStyle(color: secondary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(user?.nom ?? "Agent", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Ubuntu')),
                    subtitle: Text(user?.email ?? "", style: const TextStyle(fontSize: 12, fontFamily: 'Ubuntu')),
                  );
                }),
                const Divider(height: 32),
                _buildActionItem(
                  icon: Icons.history_rounded,
                  title: "visit_history".tr,
                  subtitle: "view_all_scans".tr,
                  color: secondary,
                  onTap: () { Get.back(); Get.to(() => const HistoryPage()); },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  icon: Icons.logout_rounded,
                  title: "logout".tr,
                  subtitle: "close_session_desc".tr,
                  color: Colors.red.shade700,
                  onTap: () { Get.back(); _showLogoutConfirmation(); },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    final scale = kioskScale(context);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28 * scale),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 56 * scale, height: 56 * scale, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.logout_rounded, color: Colors.red, size: 28)),
              const SizedBox(height: 18),
              Text("logout".tr, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black87, fontFamily: 'Ubuntu')),
              const SizedBox(height: 8),
              Text("logout_confirm_desc".tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Ubuntu', height: 1.4)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Get.back(), child: Text("cancel".tr, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700, fontFamily: 'Ubuntu')))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () { localStorage.erase(); Get.offAll(() => const Login2()); authController.refreshUser(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text("logout".tr, style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Ubuntu')))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
        title: Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontFamily: 'Ubuntu', fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Ubuntu')),
        trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void showScanInfos({required String qrcode, required String visitor, required String valideTo, required String resident, required String unit, bool isExpired = false, String? errorMessage, Map<String, dynamic>? specifications}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QrModal(
        qrData: qrcode,
        visitorName: visitor,
        dateTime: valideTo,
        resident: resident,
        unit: unit,
        isExpired: isExpired,
        errorMessage: errorMessage,
        specifications: specifications,
        onCancel: () { Navigator.pop(context); },
        onConfirm: () { Navigator.pop(context); validateAccess(qrcode); },
      ),
    );
  }
}

class QrModal extends StatelessWidget {
  final String qrData;
  final String visitorName;
  final String resident;
  final String dateTime;
  final String unit;
  final bool isExpired;
  final String? errorMessage;
  final Map<String, dynamic>? specifications;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const QrModal({super.key, required this.qrData, required this.visitorName, required this.dateTime, required this.resident, required this.unit, required this.onConfirm, required this.onCancel, this.isExpired = false, this.errorMessage, this.specifications});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12))]),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 60, height: 60, decoration: BoxDecoration(color: (isExpired ? Colors.red : Colors.green).withOpacity(0.1), shape: BoxShape.circle), child: Icon(isExpired ? Icons.error_outline_rounded : Icons.verified_rounded, color: isExpired ? Colors.red : Colors.green.shade700, size: 32)),
                const SizedBox(height: 16),
                Text(isExpired ? "qr_invalid".tr : "verification_validated".tr, textAlign: TextAlign.center, style: TextStyle(color: isExpired ? Colors.red : secondary, fontWeight: FontWeight.w800, fontFamily: 'Ubuntu', fontSize: 20)),
                if (isExpired && errorMessage != null) ...[const SizedBox(height: 12), Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Ubuntu'))],
                if (!isExpired) ...[
                  const SizedBox(height: 20),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200)), child: QrImageView(data: qrData, size: 142, gapless: true, backgroundColor: Colors.white, embeddedImage: const AssetImage("assets/images/mamba.png"), embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(25, 25)))),
                  const SizedBox(height: 16),
                  Text(visitorName.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: secondary, fontSize: 18, fontFamily: 'Ubuntu', fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _ScanInfoTile(icon: Icons.person_rounded, label: "resident_visited".tr, value: resident),
                        const SizedBox(height: 12),
                        _ScanInfoTile(icon: Icons.apartment_rounded, label: "unit_box".tr, value: unit),
                        const SizedBox(height: 12),
                        _ScanInfoTile(icon: Icons.event_available_rounded, label: "scheduled_time".tr, value: dateTime.isEmpty ? "permanent_access".tr : dateTime),
                        if (specifications != null) ...[
                          const Divider(height: 24),
                          _ScanInfoTile(icon: _getModeIcon(specifications!["mode"]), label: "arrival_mode".tr, value: _getModeLabel(specifications!["mode"])),
                          if (specifications!["plate"] != null) ...[const SizedBox(height: 12), _ScanInfoTile(icon: Icons.confirmation_number_outlined, label: "plate".tr, value: specifications!["plate"])],
                          if (specifications!["note"] != null) ...[const SizedBox(height: 12), _ScanInfoTile(icon: Icons.note_outlined, label: "note_speciale".tr, value: specifications!["note"])],
                        ]
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                if (isExpired)
                  SizedBox(width: 140, child: ElevatedButton(onPressed: onCancel, style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text("close".tr, style: const TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.bold))))
                else
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: onCancel, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: secondary.withOpacity(0.3))), child: Text("cancel".tr, style: TextStyle(color: secondary, fontFamily: 'Ubuntu')))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: onConfirm, style: ElevatedButton.styleFrom(backgroundColor: secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text("validate".tr, style: const TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.bold)))),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getModeIcon(String? mode) { switch (mode) { case "car": return Icons.directions_car; case "taxi": return Icons.local_taxi; default: return Icons.directions_walk; } }
  String _getModeLabel(String? mode) { switch (mode) { case "car": return "car".tr; case "taxi": return "taxi".tr; default: return "foot".tr; } }
}

class _ScanInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ScanInfoTile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: secondary, size: 19)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)), const SizedBox(height: 2), Text(value, style: TextStyle(color: secondary, fontWeight: FontWeight.w600, fontSize: 14))])),
      ],
    );
  }
}
