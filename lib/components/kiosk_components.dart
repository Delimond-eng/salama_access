import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../screens/auth/login.dart';
import '../screens/home_screen.dart';
import '../pages/member_page.dart';
import '../pages/history_page.dart';
import '../theme/style.dart';
import '../utils/controllers.dart';
import '../utils/store.dart';
import '../widgets/user_status.dart';

class KioskColors {
  static const Color surface = Colors.white;
  static const Color outline = Color(0xFFD3DEEE);
  static const Color textHigh = Color(0xFF0B1220);
  static const Color textMid = Color(0xFF4D5B78);
  static const Color textLow = Color(0xFF8A96AE);
  static const Color success = Color(0xFF0F9D74);
  static const Color danger = Color(0xFFE03131);
}

double kioskScale(BuildContext context) =>
    (MediaQuery.of(context).size.width / 390).clamp(0.82, 1.2).toDouble();

TextStyle kioskSubtitle(BuildContext context) => TextStyle(
  fontSize: 19 * kioskScale(context),
  fontWeight: FontWeight.w700,
  color: KioskColors.textHigh,
  fontFamily: 'Ubuntu',
  letterSpacing: 0.1,
);

class KioskBrandHeader extends StatelessWidget {
  const KioskBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F4ACF), Color(0xFF0B2D7A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              "S",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'Ubuntu',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "Salama Access",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            fontFamily: "Ubuntu",
          ),
        ),
        const Spacer(),
        const UserStatus(name: ""),
      ],
    );
  }
}

class KioskBottomBar extends StatelessWidget {
  final int activeIndex;
  final bool showAddButton;
  const KioskBottomBar({
    super.key,
    required this.activeIndex,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 14,
      shadowColor: Colors.black.withOpacity(0.12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 82,
          child: Row(
            children: [
              Expanded(
                child: _buildNavIcon(Icons.home_outlined, Icons.home_rounded, activeIndex == 0, () {
                  if (activeIndex != 0) Get.offAll(() => const HomeScreen(), transition: Transition.noTransition);
                }),
              ),
              Expanded(
                child: _buildNavIcon(Icons.people_outline, Icons.people_rounded, activeIndex == 1, () {
                  if (activeIndex != 1) Get.to(() => const MemberPage(), transition: Transition.noTransition);
                }),
              ),
              Expanded(
                child: showAddButton
                    ? Center(
                        child: GestureDetector(
                          onTap: () => _showActionSelection(context),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0B2D7A), Color(0xFF0F4ACF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F4ACF).withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: _buildNavIcon(Icons.history_outlined, Icons.history_rounded, activeIndex == 2, () {
                  if (activeIndex != 2) Get.to(() => const HistoryPage(), transition: Transition.noTransition);
                }),
              ),
              Expanded(
                child: _buildNavIcon(
                  CupertinoIcons.square_grid_2x2,
                  CupertinoIcons.square_grid_2x2_fill,
                  activeIndex == 3,
                  () => _showProfileMenu(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, IconData activeIcon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? primaryColor : Colors.grey.shade400,
          size: 27,
        ),
      ),
    );
  }

  void _showActionSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
            Text("selection_action".tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Ubuntu')),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionCircle(
                  icon: Icons.person_add_alt_1_rounded,
                  label: "creer_visiteur".tr,
                  color: Colors.blue,
                  onTap: () {

                  }
                ),
                _buildActionCircle(
                  icon: Icons.group_add_rounded,
                  label: "creer_membre".tr,
                  color: Colors.orange,
                  onTap: () {

                  }
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCircle({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'Ubuntu',
              color: Colors.black87
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    // Existing profile menu logic but maybe use UserStatus popup instead if it's already there?
    // UserStatus is in the AppBar now. This Nav icon could just be a shortcut or repeat.
  }
}
