import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/equipment_tile.dart';
import '../services/app_settings.dart';
import '../services/storage_service.dart';
import 'add_equipment_sheet.dart';
import 'equipment_detail_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Equipment> _equipmentList = [];
  bool _loaded = false;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  late AnimationController _searchAnimCtrl;
  late Animation<double> _titleFadeAnim;
  late Animation<Offset> _searchSlideAnim;

  @override
  void initState() {
    super.initState();
    appSettings.addListener(_onSettingsChanged);
    _searchAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _titleFadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _searchAnimCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _searchSlideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _searchAnimCtrl,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _loadFromStorage();
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    _searchAnimCtrl.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Equipment> get _filteredList {
    var list = _equipmentList.toList();
    // 排序
    switch (appSettings.value.sortMode) {
      case SortMode.purchaseDate:
        list.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      case SortMode.created:
        list.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
    }
    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) =>
        e.emojiName.toLowerCase().contains(q) ||
        e.title.toLowerCase().contains(q) ||
        e.notes.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  void _toggleSearch() {
    if (_searchAnimCtrl.isAnimating) return;
    if (_isSearching) {
      _searchAnimCtrl.reverse();
      _searchAnimCtrl.addStatusListener(_onSearchAnimEnd);
    } else {
      setState(() => _isSearching = true);
      _searchAnimCtrl.forward();
      _searchFocusNode.requestFocus();
    }
  }

  void _onSearchAnimEnd(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _searchAnimCtrl.removeStatusListener(_onSearchAnimEnd);
      setState(() {
        _isSearching = false;
        _searchController.clear();
        _searchQuery = '';
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _onItemTap(int filteredIndex) {
    final equipment = _filteredList[filteredIndex];
    final originalIndex = _equipmentList.indexOf(equipment);
    _openDetail(originalIndex);
  }

  Future<void> _loadFromStorage() async {
    final list = await StorageService.load();
    if (mounted) setState(() { _equipmentList = list; _loaded = true; });
  }

  Future<void> _save() async => StorageService.save(_equipmentList);

  double get _totalValue => _equipmentList.fold(0, (s, e) => s + e.price);

  double get _averagePrice {
    if (_equipmentList.isEmpty) return 0;
    final totalDaily = _equipmentList.fold<double>(0, (s, e) => s + e.dailyAverage());
    return totalDaily / _equipmentList.length;
  }

  Future<void> _addEquipment() async {
    final equipment = await pushAddEquipmentPage(context);
    if (equipment != null) {
      setState(() => _equipmentList.add(equipment));
      await _save();
      if (mounted) _showToast('添加成功');
    }
  }

  Future<void> _openDetail(int index) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => EquipmentDetailPage(equipment: _equipmentList[index])),
    );
    if (result == true) {
      if (mounted) setState(() => _equipmentList.removeAt(index));
      await _save();
      if (mounted) _showToast('删除成功');
    } else if (result is Equipment) {
      if (mounted) setState(() => _equipmentList[index] = result);
      await _save();
    }
  }

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  void _onSettingsChanged() => setState(() {});

  Widget _buildGridTile(Equipment equipment, int index) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _onItemTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 表情图标 ──
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(equipment.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const Spacer(),
            // ── 名称（主要） ──
            Text(
              equipment.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // ── 价格（次要） ──
            Text(
              '¥${equipment.priceFormatted}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 1),
            // ── 日均 ──
            Text(
              equipment.dailyAverageFormatted,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            // ── 日期 ──
            Row(
              children: [
                Icon(Icons.calendar_today, size: 10, color: cs.outlineVariant),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    equipment.purchaseDateFormatted,
                    style: TextStyle(fontSize: 11, color: cs.outlineVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _searchAnimCtrl,
          builder: (context, _) {
            if (_isSearching) {
              return Stack(
                children: [
                  Opacity(
                    opacity: _titleFadeAnim.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🐷', style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text('嘟迹', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  SlideTransition(
                    position: _searchSlideAnim,
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        focusNode: _searchFocusNode,
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: TextStyle(fontSize: 16, color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: '搜索装备名称...',
                          hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🐷', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text('嘟迹', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface, letterSpacing: 0.5)),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: cs.onSurfaceVariant, size: 24),
            onPressed: _toggleSearch,
          ),
          if (!_isSearching)
            IconButton(icon: Icon(Icons.settings, color: cs.onSurfaceVariant, size: 24), onPressed: _openSettings),
        ],
      ),
      body: !_loaded
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatsCardWidget(
                      equipmentCount: _equipmentList.length,
                      totalValue: _totalValue,
                      averagePrice: _averagePrice,
                    ),
                    const SizedBox(height: 20),
                    if (_searchQuery.isEmpty) ...[
                      Text('装备列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              if (_filteredList.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
                            size: 48,
                            color: cs.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? '没有匹配的装备' : '还没有装备，点击右下角 + 添加',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: appSettings.value.displayMode == DisplayMode.list
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: EquipmentTile(
                              equipment: _filteredList[index],
                              onTap: () => _onItemTap(index),
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) =>
                              _buildGridTile(_filteredList[index], index),
                        ),
                ),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEquipment,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
