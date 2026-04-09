import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/models/history.dart';
import '/services/api_manager.dart';
import '/theme/style.dart';
import '/utils/controllers.dart';
import '/widgets/user_status.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Scan> histories = [];
  int currentPage = 1;
  int lastPage = 1;
  bool isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  final Color primaryColor = const Color(0xFF0B2D7A); 
  final Color secondaryColor = const Color(0xFF0F4ACF); 
  final Color bgColor = const Color(0xFFF5F7FB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData(page: 1);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 120 &&
          !isLoadingMore &&
          currentPage < lastPage) {
        loadData(page: currentPage + 1);
      }
    });
  }

  Future<void> loadData({required int page}) async {
    var api = ApiManager();
    if (page == 1) {
      dataController.isDataLoading.value = true;
      histories.clear();
    } else {
      setState(() => isLoadingMore = true);
    }

    var response = await api.getResidentHistory(page: page);
    dataController.isDataLoading.value = false;
    isLoadingMore = false;

    if (response != null && response.visits != null) {
      setState(() {
        currentPage = response.visits!.currentPage!;
        lastPage = response.visits!.lastPage!;
        histories.addAll(response.visits!.data!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildSliverAppBar(),
          
          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 25, 24, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('history'.tr, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, fontFamily: 'Ubuntu', color: primaryColor)),
                        Text('all_validated_visits'.tr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => loadData(page: 1),
                    icon: Icon(Icons.refresh_rounded, color: secondaryColor),
                  ),
                ],
              ),
            ),
          ),

          // History List
          Obx(() {
            if (dataController.isDataLoading.value && histories.isEmpty) {
              return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
            }
            if (histories.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 70, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('none_visits'.tr, style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < histories.length) {
                      return _buildHistoryTimelineItem(histories[index], index == histories.length - 1);
                    }
                    return isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  },
                  childCount: histories.length + 1,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true, toolbarHeight: 80, backgroundColor: primaryColor, elevation: 0,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: Colors.white),
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
            Text("terminal_agent".tr, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.1)),
          ])),
          const UserStatus(name: ""),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(background: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [primaryColor, primaryColor.withOpacity(0.9)])))),
    );
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
                Text(data.visitor?.name ?? "Inconnu", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, fontFamily: 'Ubuntu')),
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
}
