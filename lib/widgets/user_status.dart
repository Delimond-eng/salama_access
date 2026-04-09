import 'dart:ui';
import 'package:taxenew/screens/auth/login2.dart';

import '../components/kiosk_components.dart';
import '/theme/style.dart';
import '/utils/controllers.dart';
import '/utils/store.dart';
import '/screens/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserStatus extends StatelessWidget {
  final String name;
  const UserStatus({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = authController.user.value;
      if (user == null) return const SizedBox.shrink();

      return PopupMenuButton<int>(
        elevation: 10,
        offset: const Offset(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),

        ),
        color: Colors.white,
        surfaceTintColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 28.0,
                width: 28.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (user.nom ?? "U").substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontFamily: "Staatliches",
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Colors.white.withOpacity(0.7),
              ),
            ],
          ),
        ),
        onSelected: (value) {
          if (value == 1) {
            _showLanguageDialog(context);
          } else if (value == 2) {
             _showLogoutConfirmation(context);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<int>(
            enabled: false,
            child: Container(
              width: 240,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined, size: 14, color: primaryColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "profil_resident".tr.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300, height: 24),
                  _buildInfoRow(Icons.person_outline, "nom".tr, user.nom ?? "N/A"),
                  _buildInfoRow(Icons.email_outlined, "email".tr, user.email ?? "N/A"),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem<int>(
            value: 1,
            child: Row(
              children: [
                const Icon(Icons.translate_rounded, size: 20, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Text(
                  'langue'.tr,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontFamily: "Ubuntu",
                  ),
                )
              ],
            ),
          ),
          PopupMenuItem<int>(
            value: 2,
            child: Row(
              children: [
                const Icon(Icons.power_settings_new_rounded, size: 20, color: Colors.redAccent),
                const SizedBox(width: 12),
                Text(
                  'deconnexion'.tr,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontFamily: "Ubuntu",
                  ),
                )
              ],
            ),
          ),
        ],
      );
    });
  }

  void _showLanguageDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "select_language".tr,
                style: const TextStyle(
                  fontFamily: "Staatliches",
                  fontSize: 20,
                  letterSpacing: 1,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 25),
              _buildLanguageItem("french".tr, const Locale('fr', 'FR')),
              _buildLanguageItem("english".tr, const Locale('en', 'US')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(String label, Locale locale) {
    bool isSelected = Get.locale?.languageCode == locale.languageCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? primaryColor.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: () {
          Get.updateLocale(locale);
          localStorage.write("language", locale.languageCode);
          Get.back();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Icon(
          Icons.language_rounded,
          color: isSelected ? primaryColor : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: "Ubuntu",
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black87 : Colors.black54,
          ),
        ),
        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Colors.green) : null,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.black45),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Ubuntu",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
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
              Text('logout'.tr, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black87, fontFamily: 'Ubuntu')),
              const SizedBox(height: 8),
              Text('logout_confirm_desc'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Ubuntu', height: 1.4)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700, fontFamily: 'Ubuntu')))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () { localStorage.erase(); Get.offAll(() => const Login2()); authController.refreshUser(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text('logout'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Ubuntu')))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
