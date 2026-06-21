import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/equipment.dart';
import '../models/countdown_event.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/equipment_tile.dart';
import '../services/app_settings.dart';
import '../services/storage_service.dart';
import 'add_equipment_sheet.dart';
import 'equipment_detail_page.dart';
import 'settings_page.dart';
import 'countdown_page.dart';
import 'add_countdown_event_page.dart';
import 'countdown_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  List<Equipment> _equipmentList = [];
  List<CountdownEvent> _countdownList = [];
  bool _loaded = false;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  late AnimationController _searchAnimCtrl;
  late Animation<double> _titleFadeAnim;
  late Animation<Offset> _searchSlideAnim;

  // ── 缓存，避免每次 build 重复遍历 ──
  List<Equipment>? _cachedFiltered;
  String _prevQuery = '';
  SortMode _prevSort = SortMode.created;
  int _prevListHash = 0;
  double _cachedTotalValue = 0;
  double _cachedAveragePrice = 0;

  int _currentPageIndex = 0; // 0 = 我的物品, 1 = 倒数日

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
    _searchSlideAnim =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _searchAnimCtrl,
            curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _loadFromStorage();
    _loadCountdowns();
    _setupWidgetMethodHandler();
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
    final hash = Object.hashAll(_equipmentList);
    if (_cachedFiltered == null ||
        hash != _prevListHash ||
        _searchQuery != _prevQuery ||
        appSettings.value.sortMode != _prevSort) {
      _prevListHash = hash;
      _prevQuery = _searchQuery;
      _prevSort = appSettings.value.sortMode;
      _cachedFiltered = _computeFilteredList();
    }
    return _cachedFiltered!;
  }

  List<Equipment> _computeFilteredList() {
    var list = _equipmentList.toList();
    // 排序
    switch (appSettings.value.sortMode) {
      case SortMode.purchaseDate:
        list.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      case SortMode.created:
        list.sort((a, b) {
          final ai = int.tryParse(a.id) ?? 0;
          final bi = int.tryParse(b.id) ?? 0;
          return bi.compareTo(ai);
        });
    }
    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (e) =>
                e.emojiName.toLowerCase().contains(q) ||
                e.title.toLowerCase().contains(q) ||
                e.notes.toLowerCase().contains(q),
          )
          .toList();
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
    if (mounted) {
      setState(() {
        _equipmentList = list;
        _loaded = true;
      });
      _invalidateStats();
      _updateWidgets();
    }
  }

  Future<void> _save() async {
    await StorageService.save(_equipmentList);
    _updateWidgets();
  }

  Future<void> _loadCountdowns() async {
    final list = await StorageService.loadCountdowns();
    if (mounted) {
      setState(() => _countdownList = list);
      _updateWidgets();
    }
  }

  Future<void> _saveCountdowns() async {
    await StorageService.saveCountdowns(_countdownList);
    _updateWidgets();
  }

  Future<void> _addCountdownEvent() async {
    final event = await pushAddCountdownPage(context);
    if (event != null) {
      setState(() => _countdownList.add(event));
      await _saveCountdowns();
      if (mounted) _showToast('添加成功');
    }
  }

  Future<void> _openCountdownDetail(int index) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownDetailPage(event: _countdownList[index]),
      ),
    );
    if (result == true) {
      if (mounted) setState(() => _countdownList.removeAt(index));
      await _saveCountdowns();
      if (mounted) _showToast('删除成功');
    } else if (result is CountdownEvent) {
      if (mounted) setState(() => _countdownList[index] = result);
      await _saveCountdowns();
    }
  }

  void _invalidateStats() {
    _cachedTotalValue = _equipmentList.fold(0, (s, e) => s + e.price);
    if (_equipmentList.isEmpty) {
      _cachedAveragePrice = 0;
    } else {
      final totalDaily = _equipmentList.fold<double>(
        0,
        (s, e) => s + e.dailyAverage(),
      );
      _cachedAveragePrice = totalDaily / _equipmentList.length;
    }
  }

  double get _totalValue => _cachedTotalValue;

  double get _averagePrice => _cachedAveragePrice;

  /// 更新桌面小组件数据
  static const _widgetChannel = MethodChannel('cn.quenan.duji/widgets');

  Future<void> _updateWidgets() async {
    try {
      // 更新物品小组件
      await _widgetChannel.invokeMethod('updateEquipmentWidget', {
        'count': _equipmentList.length,
        'totalValue': _totalValue,
        'averagePrice': _averagePrice,
      });
      // 更新倒数日小组件
      final countdownJson = jsonEncode(
        _countdownList.map((e) => e.toJson()).toList(),
      );
      await _widgetChannel.invokeMethod('updateCountdownWidget', countdownJson);
    } catch (_) {
      // 小组件未添加时静默忽略
    }
  }

  /// 监听来自原生（MainActivity）的调用
  void _setupWidgetMethodHandler() {
    _widgetChannel.setMethodCallHandler((call) async {
      if (call.method == 'openCountdownTab') {
        if (mounted) {
          setState(() => _currentPageIndex = 1);
        }
      }
      return null;
    });
  }

  Future<void> _addEquipment() async {
    final equipment = await pushAddEquipmentPage(context);
    if (equipment != null) {
      setState(() => _equipmentList.add(equipment));
      _invalidateStats();
      await _save();
      if (mounted) _showToast('添加成功');
    }
  }

  Future<void> _openDetail(int index) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentDetailPage(equipment: _equipmentList[index]),
      ),
    );
    if (result == true) {
      if (mounted) setState(() => _equipmentList.removeAt(index));
      _invalidateStats();
      await _save();
      if (mounted) _showToast('删除成功');
    } else if (result is Equipment) {
      if (mounted) setState(() => _equipmentList[index] = result);
      _invalidateStats();
      await _save();
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  void _togglePage() {
    setState(() {
      _currentPageIndex = _currentPageIndex == 0 ? 1 : 0;
    });
  }

  String get _pageLabel => _currentPageIndex == 0 ? '我的装备' : '倒数日';

  void _onSettingsChanged() {
    setState(() {});
  }

  Widget _buildGridTile(Equipment equipment, int index) {
    return _GridTileWidget(
      equipment: equipment,
      onTap: () => _onItemTap(index),
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
                        Text(
                          '嘟迹',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _togglePage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _pageLabel,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
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
                          hintText: _currentPageIndex == 0 ? '搜索物品名称...' : '搜索倒数日...',
                          hintStyle: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
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
                Text(
                  '嘟迹',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _togglePage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _pageLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: cs.onSurfaceVariant,
              size: 24,
            ),
            onPressed: _toggleSearch,
          ),
          if (!_isSearching)
            IconButton(
              icon: Icon(Icons.settings, color: cs.onSurfaceVariant, size: 24),
              onPressed: _openSettings,
            ),
        ],
      ),
      body: _currentPageIndex == 1
          ? CountdownPage(
              events: _countdownList,
              onTap: (index) => _openCountdownDetail(index),
              searchQuery: _searchQuery,
              displayMode: appSettings.value.displayMode,
              sortMode: appSettings.value.countdownSortMode,
            )
          : !_loaded
              ? const Center(child: CircularProgressIndicator())
              : RepaintBoundary(
              child: Column(
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
                        Text(
                          '物品列表',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
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
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.inventory_2_outlined,
                              size: 48,
                              color: cs.outlineVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? '没有匹配的物品'
                                  : '还没有物品，点击右下角 + 添加',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 14,
                              ),
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
                              child: RepaintBoundary(
                                child: EquipmentTile(
                                  equipment: _filteredList[index],
                                  onTap: () => _onItemTap(index),
                                ),
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
                                RepaintBoundary(
                                  child: _buildGridTile(_filteredList[index], index),
                                ),
                          ),
                  ),
              ],
            ),
          ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _currentPageIndex == 0 ? _addEquipment : _addCountdownEvent,
            child: const Icon(Icons.add, size: 28, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// 网格视图的 GPU 按压力反馈卡片
class _GridTileWidget extends StatefulWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const _GridTileWidget({
    required this.equipment,
    required this.onTap,
  });

  @override
  State<_GridTileWidget> createState() => _GridTileWidgetState();
}

class _GridTileWidgetState extends State<_GridTileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) => _scaleCtrl.reverse(),
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.equipment.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const Spacer(),
              Text(
                widget.equipment.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '¥${widget.equipment.priceFormatted}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                widget.equipment.dailyAverageFormatted,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 10, color: cs.outlineVariant),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      widget.equipment.purchaseDateFormatted,
                      style: TextStyle(fontSize: 11, color: cs.outlineVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
