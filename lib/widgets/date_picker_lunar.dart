import 'package:flutter/material.dart';
import '../utils/lunar_calendar.dart';

/// 日期选择结果
class DatePickerResult {
  final DateTime solarDate;
  final bool isLunar;
  final String? lunarLabel; // 农历显示文字

  DatePickerResult({
    required this.solarDate,
    this.isLunar = false,
    this.lunarLabel,
  });
}

/// 弹出公历日期选择器（公历/农历双 tab，支持到 2099 年）
Future<DatePickerResult?> showLunarDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  bool initialIsLunar = false,
}) {
  return showDialog<DatePickerResult>(
    context: context,
    builder: (_) => _LunarDatePickerDialog(
      initialDate: initialDate ?? DateTime.now(),
      initialIsLunar: initialIsLunar,
    ),
  );
}

/// 弹出每周选择器（底部抽屉多选）
Future<List<int>?> showWeekDaysPicker(
  BuildContext context, {
  List<int> initial = const [],
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _WeekDaysSheet(initial: initial),
  );
}

/// 弹出每月选择器（底部抽屉 1-31 多选）
Future<List<int>?> showMonthDayPicker(
  BuildContext context, {
  List<int> initial = const [],
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _MonthDaySheet(initial: initial),
  );
}

// ═══════════════════════════════════════════════════
//  公历/农历 双 tab 日期选择器
// ═══════════════════════════════════════════════════

class _LunarDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final bool initialIsLunar;
  const _LunarDatePickerDialog({
    required this.initialDate,
    required this.initialIsLunar,
  });

  @override
  State<_LunarDatePickerDialog> createState() => _LunarDatePickerDialogState();
}

class _LunarDatePickerDialogState extends State<_LunarDatePickerDialog> {
  int _tabIndex = 0; // 0=公历 1=农历

  // 公历
  late int _sYear, _sMonth, _sDay;
  late FixedExtentScrollController _sYearCtrl;
  late FixedExtentScrollController _sMonthCtrl;
  late FixedExtentScrollController _sDayCtrl;

  // 农历
  late int _lYear, _lMonth, _lDay;
  late FixedExtentScrollController _lYearCtrl;
  late FixedExtentScrollController _lMonthCtrl;
  late FixedExtentScrollController _lDayCtrl;

  static const _minSolarYear = 2000;
  static const _maxSolarYear = 2099;
  static const _minLunarYear = 1901;
  static const _maxLunarYear = 2100;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialIsLunar ? 1 : 0;

    _sYear = widget.initialDate.year.clamp(_minSolarYear, _maxSolarYear);
    _sMonth = widget.initialDate.month;
    _sDay = widget.initialDate.day;

    _sYearCtrl = FixedExtentScrollController(initialItem: _sYear - _minSolarYear);
    _sMonthCtrl = FixedExtentScrollController(initialItem: _sMonth - 1);
    _sDayCtrl = FixedExtentScrollController(initialItem: _sDay - 1);

    // 农历初始值
    final lunar = solarToLunar(_sYear, _sMonth, _sDay);
    if (lunar != null) {
      _lYear = lunar.year;
      _lMonth = lunar.month; // 保留符号（闰月为负）
      _lDay = lunar.day;
    } else {
      _lYear = _sYear;
      _lMonth = _sMonth;
      _lDay = _sDay;
    }

    _lYearCtrl = FixedExtentScrollController(initialItem: _lYear - _minLunarYear);
    // 月份索引 = 在 lunarMonthList 中的位置
    final initMonths = lunarMonthList(_lYear);
    final initMonthIdx = initMonths.indexWhere((m) => m.$1 == _lMonth);
    _lMonthCtrl = FixedExtentScrollController(
      initialItem: initMonthIdx < 0 ? 0 : initMonthIdx,
    );
    _lDayCtrl = FixedExtentScrollController(initialItem: _lDay - 1);
  }

  @override
  void dispose() {
    _sYearCtrl.dispose();
    _sMonthCtrl.dispose();
    _sDayCtrl.dispose();
    _lYearCtrl.dispose();
    _lMonthCtrl.dispose();
    _lDayCtrl.dispose();
    super.dispose();
  }

  int _solarDaysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;
  int _lunarDaysInMonth(int y, int m) => lunarMonthDayCount(y, m);

  void _onSubmit() {
    if (_tabIndex == 0) {
      final d = DateTime(_sYear, _sMonth, _sDay);
      Navigator.pop(context, DatePickerResult(solarDate: d));
    } else {
      final solar = lunarToSolar(_lYear, _lMonth, _lDay);
      if (solar != null) {
        final lunarDate = LunarDate(_lYear, _lMonth, _lDay);
        Navigator.pop(context, DatePickerResult(
          solarDate: solar,
          isLunar: true,
          lunarLabel: lunarDate.formatted,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor ?? cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Tab 切换 ──
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _tabBtn('公历', 0),
                  const SizedBox(width: 3),
                  _tabBtn('农历', 1),
                ],
              ),
            ),
            const SizedBox(height: 16),
            IndexedStack(
              index: _tabIndex,
              children: [
                _buildSolarPicker(cs),
                _buildLunarPicker(cs),
              ],
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest,
                  foregroundColor: cs.onSurfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('取消', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('确定', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tabBtn(String label, int idx) {
    final cs = Theme.of(context).colorScheme;
    final selected = _tabIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? cs.onSurface : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  // ── 公历滚轮 ──
  Widget _buildSolarPicker(ColorScheme cs) {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _highlightBar(cs),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildWheel(
                  _sYearCtrl,
                  _maxSolarYear - _minSolarYear + 1,
                  (i) => '${_minSolarYear + i}',
                  (i) => setState(() {
                    _sYear = _minSolarYear + i;
                    if (_sDay > _solarDaysInMonth(_sYear, _sMonth)) {
                      _sDay = _solarDaysInMonth(_sYear, _sMonth);
                    }
                  }),
                ),
              ),
              Expanded(
                flex: 1,
                child: _buildWheel(
                  _sMonthCtrl, 12,
                  (i) => '${i + 1}月',
                  (i) => setState(() {
                    _sMonth = i + 1;
                    if (_sDay > _solarDaysInMonth(_sYear, _sMonth)) {
                      _sDay = _solarDaysInMonth(_sYear, _sMonth);
                    }
                  }),
                ),
              ),
              Expanded(
                flex: 1,
                child: _buildWheel(
                  _sDayCtrl,
                  _solarDaysInMonth(_sYear, _sMonth),
                  (i) => '${i + 1}日',
                  (i) => setState(() => _sDay = i + 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 农历滚轮 ──
  Widget _buildLunarPicker(ColorScheme cs) {
    final months = lunarMonthList(_lYear);
    final dayCount = _lunarDaysInMonth(_lYear, _lMonth);
    final currentMonth = months.length;

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _highlightBar(cs),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildWheel(
                  _lYearCtrl,
                  _maxLunarYear - _minLunarYear + 1,
                  (i) => '${_minLunarYear + i}',
                  (i) => setState(() {
                    _lYear = _minLunarYear + i;
                    final ml = lunarMonthList(_lYear);
                    // 检查当前月份值在新年份中是否存在（如闰月不存在则回退到第一个月）
                    if (!ml.any((m) => m.$1 == _lMonth)) {
                      _lMonth = ml.first.$1;
                    }
                    // 修正日上限
                    final dc = _lunarDaysInMonth(_lYear, _lMonth);
                    if (_lDay > dc) _lDay = dc;
                  }),
                ),
              ),
              Expanded(
                flex: 1,
                child: _buildWheel(
                  _lMonthCtrl,
                  currentMonth,
                  (i) => months[i].$2,
                  (i) => setState(() {
                    _lMonth = months[i].$1; // 保留符号（闰月为负）
                    final dc = _lunarDaysInMonth(_lYear, _lMonth);
                    if (_lDay > dc) _lDay = dc;
                  }),
                ),
              ),
              Expanded(
                flex: 1,
                child: _buildWheel(
                  _lDayCtrl, dayCount,
                  (i) => LunarDate(0, 0, i + 1).dayName,
                  (i) => setState(() => _lDay = i + 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _highlightBar(ColorScheme cs) => IgnorePointer(
    child: Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.symmetric(
          horizontal: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
    ),
  );

  Widget _buildWheel(
    FixedExtentScrollController ctrl,
    int count,
    String Function(int) label,
    ValueChanged<int> onChanged,
  ) {
    return ListWheelScrollView.useDelegate(
      controller: ctrl,
      itemExtent: 40,
      perspective: 0.002,
      diameterRatio: 1.6,
      squeeze: 1.15,
      overAndUnderCenterOpacity: 0.3,
      useMagnifier: true,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (_, i) => Center(
          child: Text(
            label(i),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  每周选择器（底部抽屉）
// ═══════════════════════════════════════════════════

class _WeekDaysSheet extends StatefulWidget {
  final List<int> initial;
  const _WeekDaysSheet({required this.initial});

  @override
  State<_WeekDaysSheet> createState() => _WeekDaysSheetState();
}

class _WeekDaysSheetState extends State<_WeekDaysSheet> {
  late Set<int> _selected;

  static const _names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '选择重复日',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 12,
              children: List.generate(7, (i) {
                final selected = _selected.contains(i);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selected.remove(i);
                      } else {
                        _selected.add(i);
                      }
                    });
                  },
                  child: Container(
                    width: 64,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _names[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHighest,
                      foregroundColor: cs.onSurfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('取消', style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('确定', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  每月选择器（底部抽屉）
// ═══════════════════════════════════════════════════

class _MonthDaySheet extends StatefulWidget {
  final List<int> initial;
  const _MonthDaySheet({this.initial = const []});

  @override
  State<_MonthDaySheet> createState() => _MonthDaySheetState();
}

class _MonthDaySheetState extends State<_MonthDaySheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '选择日期',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 260,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: 31,
              itemBuilder: (_, i) {
                final day = i + 1;
                final selected = _selected.contains(day);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selected.remove(day);
                      } else {
                        _selected.add(day);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selected ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHighest,
                      foregroundColor: cs.onSurfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('取消', style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('确定', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
