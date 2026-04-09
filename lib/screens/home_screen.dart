import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/services/api_manager.dart';
import '/utils/controllers.dart';
import '/widgets/costum_field.dart';
import '/widgets/qrcode_viewer.dart';
import '/widgets/user_status.dart';
import '../models/qrcode.dart';
import '/theme/style.dart';
import '/models/history.dart';
import '/widgets/history_card.dart';
import '/screens/auth/login2.dart';
import '/utils/store.dart';
import '/components/kiosk_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _homeScrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();
  final ScrollController _memberScrollController = ScrollController();
  final ScrollController _profileScrollController = ScrollController();
  
  int _activeIndex = 0;

  List<Scan> histories = [];
  int currentHistoryPage = 1;
  int lastHistoryPage = 1;
  bool isLoadingMoreHistory = false;

  final Color primaryColor = const Color(0xFF0B2D7A); 
  final Color secondaryColor = const Color(0xFF0F4ACF); 
  final Color bgColor = const Color(0xFFF5F7FB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });

    _historyScrollController.addListener(() {
      if (_activeIndex == 2 && _historyScrollController.position.pixels >= _historyScrollController.position.maxScrollExtent - 150) {
        if (!isLoadingMoreHistory && currentHistoryPage < lastHistoryPage) {
          _loadHistory(page: currentHistoryPage + 1);
        }
      }
    });
  }

  void _loadInitialData() {
    dataController.refreshPendingData();
    dataController.refreshMember();
    _loadHistory(page: 1);
  }

  Future<void> _loadHistory({required int page}) async {
    if (page == 1) {
      histories.clear();
      dataController.isDataLoading.value = true;
    } else {
      setState(() => isLoadingMoreHistory = true);
    }

    var response = await ApiManager().getResidentHistory(page: page);
    dataController.isDataLoading.value = false;
    isLoadingMoreHistory = false;

    if (response != null && response.visits != null) {
      setState(() {
        currentHistoryPage = response.visits!.currentPage!;
        lastHistoryPage = response.visits!.lastPage!;
        histories.addAll(response.visits!.data!);
      });
    }
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _historyScrollController.dispose();
    _memberScrollController.dispose();
    _profileScrollController.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE CRÉATION ---

  void _showAddBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 45, height: 5, margin: const EdgeInsets.only(bottom: 30), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              _buildActionMenuBtn(
                title: 'create_visitor'.tr,
                subtitle: 'my_visitors'.tr,
                icon: Icons.person_add_rounded,
                color: primaryColor,
                onTap: () { Navigator.pop(context); _showCreationBottomSheet("visitor"); },
              ),
              const SizedBox(height: 16),
              _buildActionMenuBtn(
                title: 'create_member'.tr,
                subtitle: 'family_employees'.tr,
                icon: Icons.group_add_rounded,
                color: secondaryColor,
                onTap: () { Navigator.pop(context); _showCreationBottomSheet("worker"); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenuBtn({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.12))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: color, fontFamily: 'Ubuntu')),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: color.withOpacity(0.6), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.3), size: 16),
          ],
        ),
      ),
    );
  }

  void _showCreationBottomSheet(String type) {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController plateController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    final TextEditingController personCountController = TextEditingController(text: "1");

    String arrivalMode = "foot";
    List<String> selectedTags = [];
    DateTime? selectedDate;
    String dateTimeVisite = "";

    final List<Map<String, dynamic>> quickTags = [
      {"id": "delivery", "label": 'delivery'.tr, "icon": Icons.inventory_2_outlined},
      {"id": "work", "label": 'work'.tr, "icon": Icons.handyman_outlined},
      {"id": "reunion", "label": 'reunion'.tr, "icon": Icons.groups_outlined},
      {"id": "family", "label": 'family'.tr, "icon": Icons.favorite_border},
      {"id": "urgent", "label": 'urgent'.tr, "icon": Icons.notification_important_outlined},
      {"id": "other", "label": 'other'.tr, "icon": Icons.more_horiz_outlined},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setInternalState) {
          Widget buildModeItem(String id, String label, IconData icon) {
            bool isSelected = arrivalMode == id;
            return Expanded(
              child: GestureDetector(
                onTap: () => setInternalState(() => arrivalMode = id),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600, size: 20),
                      const SizedBox(height: 4),
                      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            );
          }

          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    Center(child: Text(type == 'visitor' ? 'new_visitor'.tr : 'new_member'.tr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Ubuntu'))),
                    const SizedBox(height: 24),
                    CustomField(controller: nomController, hintText: 'full_name'.tr, iconPath: 'user-1'),
                    if (type == "visitor") ...[
                      const SizedBox(height: 16),
                      CustomDateTimeField(
                        hintText: 'visit_date_time'.tr,
                        iconPath: "calendar-time",
                        selectedDateTime: selectedDate,
                        onChanged: (DateTime dt) {
                          setInternalState(() {
                            selectedDate = dt;
                            dateTimeVisite = DateFormat('yyyy-MM-dd HH:mm').format(dt);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Text('number_of_persons'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13))),
                          SizedBox(width: 120, child: CustomField(controller: personCountController, hintText: "1", iconPath: 'user', inputType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('arrival_mode'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          buildModeItem("foot", 'foot'.tr, Icons.directions_walk),
                          const SizedBox(width: 8),
                          buildModeItem("car", 'car'.tr, Icons.directions_car),
                          const SizedBox(width: 8),
                          buildModeItem("taxi", 'taxi'.tr, Icons.local_taxi),
                        ],
                      ),
                      if (arrivalMode != "foot") ...[
                        const SizedBox(height: 16),
                        CustomField(controller: plateController, hintText: 'plate_hint'.tr, iconPath: 'settings-2'),
                      ],
                      const SizedBox(height: 20),
                      Text('precisions'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 0,
                        children: quickTags.map((tag) {
                          bool isSelected = selectedTags.contains(tag["id"]);
                          return FilterChip(
                            label: Text(tag["label"]),
                            avatar: Icon(tag["icon"], size: 14, color: isSelected ? Colors.white : primaryColor),
                            selected: isSelected,
                            onSelected: (bool value) {
                              setInternalState(() {
                                if (value) { selectedTags.add(tag["id"]); } else { selectedTags.remove(tag["id"]); }
                              });
                            },
                            selectedColor: primaryColor, checkmarkColor: Colors.white,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      CustomField(controller: noteController, hintText: 'note_instruction'.tr, iconPath: 'email'),
                    ],
                    const SizedBox(height: 32),
                    Obx(() => SizedBox(
                      width: double.infinity, height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 8, shadowColor: primaryColor.withOpacity(0.4)),
                        onPressed: dataController.isLoading.value ? null : () async {
                          if (nomController.text.isEmpty) { EasyLoading.showToast('name_required'.tr); return; }
                          if (type == "visitor" && dateTimeVisite.isEmpty) { EasyLoading.showToast('date_required'.tr); return; }

                          Map<String, dynamic>? specs;
                          if (type == "visitor") {
                            specs = {"mode": arrivalMode, "plate": plateController.text.isNotEmpty ? plateController.text : null, "tags": selectedTags, "note": noteController.text.isNotEmpty ? noteController.text : null, "person_count": int.tryParse(personCountController.text) ?? 1};
                          }

                          var res = await ApiManager().createVisitor(name: nomController.text, dateTime: dateTimeVisite, type: type, specifications: specs);
                          if (res is! String) {
                            Navigator.pop(sheetContext);
                            showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, useSafeArea: true, builder: (context) => QrcodeBottomSheet(qrData: res["qrcode"], visitorName: res["visitor"]["name"], specs: specs));
                            _loadInitialData();
                          }
                        },
                        child: dataController.isLoading.value ? const CircularProgressIndicator(color: Colors.white) : Text('generate_qr'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light, statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        floatingActionButton: _buildFloatingAddButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomBar(),
        body: IndexedStack(
          index: _activeIndex,
          children: [
            _buildHomeTab(),
            _buildMembersTab(),
            _buildHistoryTab(),
            _buildProfileTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingAddButton() {
    return Container(
      height: 70, width: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [secondaryColor, primaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(70.0)
        ),
        onPressed: _showAddBottomSheet,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      padding: EdgeInsets.zero, height: 70, color: Colors.white,
      shape: const CircularNotchedRectangle(), notchMargin: 10, elevation: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.grid_view_rounded, 'home'.tr),
          _buildNavItem(1, Icons.people_alt_rounded, 'members'.tr),
          const SizedBox(width: 70),
          _buildNavItem(2, Icons.history_rounded, 'history'.tr),
          _buildNavItem(3, Icons.person_rounded, 'profile'.tr),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = _activeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? primaryColor : Colors.grey.shade300, size: 24),
            Text(label, maxLines: 1, style: TextStyle(color: isActive ? primaryColor : Colors.grey.shade400, fontSize: 10, fontWeight: isActive ? FontWeight.w900 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      controller: _homeScrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        _buildSectionHeader('my_visits'.tr, 'pending_visits'.tr, onRefresh: () async {
          EasyLoading.show(status: 'refreshing'.tr);
          await dataController.refreshPendingData();
          EasyLoading.dismiss();
        }),
        Obx(() {
          if (dataController.isDataLoading.value && dataController.pendingVisits.isEmpty) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
          if (dataController.pendingVisits.isEmpty) return _buildEmptyState(CupertinoIcons.tickets, 'none_visits'.tr);
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTimelineItem(dataController.pendingVisits[index], index == dataController.pendingVisits.length - 1),
                childCount: dataController.pendingVisits.length,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMembersTab() {
    return CustomScrollView(
      controller: _memberScrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        _buildSectionHeader('members'.tr, 'permanent_members'.tr, onRefresh: () async {
          EasyLoading.show(status: 'refreshing'.tr);
          await dataController.refreshMember();
          EasyLoading.dismiss();
        }),
        Obx(() {
          if (dataController.isDataLoading.value && dataController.members.isEmpty) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
          if (dataController.members.isEmpty) return _buildEmptyState(CupertinoIcons.group, 'none_visits'.tr);
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMemberCardItem(dataController.members[index]),
                childCount: dataController.members.length,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMemberCardItem(Qrcode data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(18), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.person_pin_rounded, color: primaryColor, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.visitor?.name ?? 'unknown'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, fontFamily: 'Ubuntu')),
          const SizedBox(height: 4),
          Text('unlimited_duration'.tr, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w700)),
        ])),
        _buildVisitMenu(data),
      ]),
    );
  }

  Widget _buildHistoryTab() {
    return CustomScrollView(
      controller: _historyScrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        _buildSectionHeader('history'.tr, 'all_validated_visits'.tr, onRefresh: () async {
          EasyLoading.show(status: 'refreshing'.tr);
          await _loadHistory(page: 1);
          EasyLoading.dismiss();
        }),
        if (dataController.isDataLoading.value && histories.isEmpty)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (histories.isEmpty)
          _buildEmptyState(Icons.history_rounded, 'none_visits'.tr)
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < histories.length) return _buildHistoryTimelineItem(histories[index], index == histories.length - 1);
                  return isLoadingMoreHistory ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())) : const SizedBox.shrink();
                },
                childCount: histories.length + 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileTab() {
    final user = authController.user.value;
    if (user == null) return _buildEmptyState(Icons.person_off, 'not_connected'.tr);

    return CustomScrollView(
      controller: _profileScrollController,
      slivers: [
        _buildSliverAppBar(),
        _buildSectionHeader('my_profile'.tr, 'manage_info'.tr, onRefresh: () async {
          EasyLoading.show(status: 'refreshing'.tr);
          await authController.refreshUser();
          EasyLoading.dismiss();
        }),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Resident Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Text(
                          (user.nom ?? "U").substring(0, 1).toUpperCase(),
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Ubuntu'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(user.nom ?? 'unknown'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryColor, fontFamily: 'Ubuntu')),
                      Text(user.email ?? 'not_provided'.tr, style: TextStyle(fontSize: 14, color: Colors.grey.shade500))
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Actions Menu Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      _buildProfileMenuItem(Icons.language_rounded, 'language'.tr, () {
                        _showLanguageDialog(context);
                      }),
                      _buildProfileMenuItem(Icons.help_outline_rounded, 'help_support'.tr, () {}),
                      _buildProfileMenuItem(Icons.logout_rounded, 'logout'.tr, () { _showLogoutConfirmation(context); }, color: Colors.red, isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        )
      ],
    );
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true, toolbarHeight: 80, backgroundColor: primaryColor, elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [secondaryColor, primaryColor]), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text("S", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Salama Access", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, fontFamily: "Ubuntu")),
            Text('terminal_resident'.tr, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.1)),
          ])),
          const UserStatus(name: ""),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(background: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [primaryColor, primaryColor.withOpacity(0.9)])))),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, {required Future<void> Function() onRefresh}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, fontFamily: 'Ubuntu', color: primaryColor)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ])),
            IconButton(onPressed: onRefresh, icon: Icon(Icons.refresh_rounded, color: secondaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Qrcode data, bool isLast) {
    String displayDate = data.validTo ?? "";
    try { displayDate = DateFormat('dd/MM à HH:mm').format(DateTime.parse(displayDate)); } catch (_) {}

    return Stack(children: [
      if (!isLast) Positioned(left: 19, top: 24, bottom: 0, child: Container(width: 1.5, color: secondaryColor.withOpacity(0.15))),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, alignment: Alignment.center, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: secondaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
          Expanded(child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: secondaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Icon(data.type == "visitor" ? Icons.person_outline_rounded : Icons.badge_outlined, color: secondaryColor, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.visitor?.name ?? 'unknown'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, fontFamily: 'Ubuntu')),
                const SizedBox(height: 4),
                Text("${'expires_at'.tr} : $displayDate", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
              ])),
              _buildVisitMenu(data),
            ]),
          )),
        ]),
      ),
    ]);
  }

  Widget _buildHistoryTimelineItem(Scan data, bool isLast) {
    String displayDate = data.createdAt ?? "";
    try { displayDate = DateFormat('dd/MM à HH:mm').format(DateTime.parse(displayDate)); } catch (_) {}
    Color statusColor = data.result == 'accepted' ? Colors.green : Colors.red;

    return Stack(children: [
      if (!isLast) Positioned(left: 19, top: 24, bottom: 0, child: Container(width: 1.5, color: secondaryColor.withOpacity(0.15))),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, alignment: Alignment.center, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
          Expanded(child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: statusColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Icon(data.type == "visitor" ? Icons.person_outline_rounded : Icons.badge_outlined, color: statusColor, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.visitor?.name ?? 'unknown'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, fontFamily: 'Ubuntu')),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(displayDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(data.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ])),
            ]),
          )),
        ]),
      ),
    ]);
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return SliverFillRemaining(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 70, color: Colors.grey.shade300), const SizedBox(height: 16), Text(message, style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.bold))]));
  }

  Widget _buildVisitMenu(Qrcode data) {
    return Material(color: Colors.transparent, child: InkWell(onTap: () => _showVisitActions(data), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(8), child: Icon(CupertinoIcons.ellipsis_vertical, color: primaryColor, size: 18))));
  }

  void _showVisitActions(Qrcode data) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
      _buildActionItem(icon: Icons.qr_code_2_rounded, label: 'show_qr'.tr, color: primaryColor, onTap: () { Navigator.pop(context); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => QrcodeBottomSheet(qrData: data.token!, visitorName: data.visitor!.name!)); }),
      const SizedBox(height: 12),
      _buildActionItem(icon: Icons.delete_outline_rounded, label: 'delete_access'.tr, color: Colors.red, onTap: () { Navigator.pop(context); _showDeleteConfirmation(data, "visitor"); }),
    ]))));
  }

  void _showDeleteConfirmation(Qrcode data, String type) {
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
              Container(width: 56 * scale, height: 56 * scale, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 28)),
              const SizedBox(height: 18),
              Text('confirm_title'.tr, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black87, fontFamily: 'Ubuntu')),
              const SizedBox(height: 8),
              Text(type == "member" ? 'confirm_delete_member'.tr : 'confirm_delete_access'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Ubuntu', height: 1.4)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700, fontFamily: 'Ubuntu')))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () async { 
                    Get.back();
                    EasyLoading.show();
                    await ApiManager().deleteData(table: "visitors", id: data.visitorId!);
                    _loadInitialData();
                    EasyLoading.dismiss();
                    EasyLoading.showSuccess('deleted_success'.tr);
                  }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text('delete'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Ubuntu')))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ListTile(onTap: onTap, leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)), title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), tileColor: Colors.grey.shade50);
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'Ubuntu')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String label, VoidCallback onTap, {Color? color, bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: (color ?? primaryColor).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color ?? primaryColor, size: 20),
          ),
          title: Text(label, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w600, fontSize: 15, fontFamily: 'Ubuntu')),
          trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        if (!isLast) Padding(
          padding: const EdgeInsets.only(left: 56),
          child: Divider(color: Colors.grey.shade100, height: 1),
        ),
      ],
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
