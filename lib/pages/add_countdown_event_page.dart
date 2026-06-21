import 'package:flutter/material.dart';
import '../models/countdown_event.dart';
import '../widgets/emoji_picker_sheet.dart' show countdownPresetEmojis, showEmojiPicker;
import '../widgets/date_picker_lunar.dart';
import '../utils/lunar_calendar.dart';

/// 添加倒数日页面（全屏页面）
Future<CountdownEvent?> pushAddCountdownPage(BuildContext context) {
  return Navigator.push<CountdownEvent>(
    context,
    MaterialPageRoute(builder: (_) => const _AddCountdownPage()),
  );
}

class _AddCountdownPage extends StatefulWidget {
  const _AddCountdownPage();

  @override
  State<_AddCountdownPage> createState() => _AddCountdownPageState();
}

class _AddCountdownPageState extends State<_AddCountdownPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _targetDate = DateTime.now();
  String _emoji = '📅';
  String _emojiName = '日历';
  CountdownType _type = CountdownType.days;
  RepeatCycle _repeatCycle = RepeatCycle.none;
  List<int> _weekDays = [];
  List<int> _monthDays = [];
  bool _isLunar = false;
  bool _isPinned = false;
  bool _datePicked = false; // 用户是否主动选择了日期

  static const _typeOptions = [
    CountdownType.days,
    CountdownType.anniversary,
  ];

  static const _repeatOptions = [
    RepeatCycle.none,
    RepeatCycle.weekly,
    RepeatCycle.monthly,
    RepeatCycle.yearly,
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (_repeatCycle == RepeatCycle.weekly) {
      final result = await showWeekDaysPicker(context, initial: _weekDays);
      if (result != null && mounted) setState(() => _weekDays = result);
    } else if (_repeatCycle == RepeatCycle.monthly) {
      final result = await showMonthDayPicker(context, initial: _monthDays);
      if (result != null && mounted) setState(() => _monthDays = result);
    } else {
      final result = await showLunarDatePicker(
        context,
        initialDate: _targetDate,
        initialIsLunar: _isLunar,
      );
      if (result != null && mounted) {
        setState(() {
          _targetDate = result.solarDate;
          _isLunar = result.isLunar;
          _datePicked = true;
        });
      }
    }
  }

  Future<void> _pickEmoji() async {
    final option = await showEmojiPicker(context, emojis: countdownPresetEmojis);
    if (option != null && mounted) {
      setState(() {
        _emoji = option.emoji;
        _emojiName = option.name;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_repeatCycle == RepeatCycle.weekly && _weekDays.isEmpty) {
      _showToast('请至少选择一天');
      return;
    }
    if (_repeatCycle == RepeatCycle.monthly && _monthDays.isEmpty) {
      _showToast('请至少选择一天');
      return;
    }
    // 当为非周/月重复时，确保用户主动点击过日期选择器
    if (_repeatCycle != RepeatCycle.weekly &&
        _repeatCycle != RepeatCycle.monthly &&
        !_datePicked) {
      _showToast('请选择日期');
      return;
    }

    // 校验日期是否过于离谱（允许过去日期，仅阻挡明显无效的选择）
    if (_repeatCycle == RepeatCycle.none &&
        _type == CountdownType.days &&
        _targetDate.isBefore(DateTime(1900, 1, 1))) {
      _showToast('选择的日期有误，请重新选择');
      return;
    }

    final event = CountdownEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      targetDate: _targetDate,
      notes: _notesCtrl.text.trim(),
      emoji: _emoji,
      emojiName: _emojiName,
      type: _type,
      repeatCycle: _repeatCycle,
      weekDays: _repeatCycle == RepeatCycle.weekly ? _weekDays : [],
      monthDays: _repeatCycle == RepeatCycle.monthly ? _monthDays : [],
      isLunar: _isLunar,
      isPinned: _isPinned,
    );
    Navigator.pop(context, event);
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

  String get _dateLabel {
    if (_repeatCycle == RepeatCycle.weekly) {
      if (_weekDays.isEmpty) return '请选择';
      const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return _weekDays.map((d) => names[d]).join(' ');
    }
    if (_repeatCycle == RepeatCycle.monthly) {
      if (_monthDays.isEmpty) return '请选择';
      final sorted = List.of(_monthDays)..sort();
      final labels = sorted.map((d) => '$d 日').join(' ');
      return '每月 $labels';
    }
    if (_isLunar) {
      final lunar = solarToLunar(_targetDate.year, _targetDate.month, _targetDate.day);
      if (lunar != null) return '农历 ${lunar.year}年${lunar.monthName}月${lunar.dayName}';
    }
    return '${_targetDate.year}-${_targetDate.month.toString().padLeft(2, '0')}-${_targetDate.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '添加日子',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // ── 图标 ──
            Center(
              child: GestureDetector(
                onTap: _pickEmoji,
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      alignment: Alignment.center,
                      child: Text(_emoji, style: const TextStyle(fontSize: 38)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _emojiName,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── 事件名称 ──
            _label('事件名称'),
            const SizedBox(height: 8),
            _buildField(
              controller: _titleCtrl,
              hint: '请输入事件名称',
              validator: (v) => v == null || v.trim().isEmpty ? '请输入名称' : null,
            ),
            const SizedBox(height: 20),

            // ── 类型 ──
            _label('类型'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _type,
              items: _typeOptions,
              labelFn: (t) => t == CountdownType.days ? '倒/正数日' : '纪念日',
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 20),

            // ── 重复周期（仅倒/正数日） ──
            if (_type == CountdownType.days) ...[
              _label('重复周期'),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _repeatCycle,
                items: _repeatOptions,
                labelFn: (r) => switch (r) {
                  RepeatCycle.none => '不重复',
                  RepeatCycle.weekly => '每周',
                  RepeatCycle.monthly => '每月',
                  RepeatCycle.yearly => '每年',
                },
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _repeatCycle = v;
                      if (v != RepeatCycle.weekly) {
                        _weekDays = [];
                      }
                      if (v != RepeatCycle.monthly) {
                        _monthDays = [];
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
            ],

            // ── 日期 ──
            _label('日期'),
            const SizedBox(height: 8),
            _buildDateField(),
            const SizedBox(height: 20),

            // ── 备注 ──
            _label('备注'),
            const SizedBox(height: 8),
            _buildField(controller: _notesCtrl, hint: '选填，备注信息', maxLines: 3),
            const SizedBox(height: 20),

            // ── 置顶 ──
            Row(
              children: [
                Icon(Icons.push_pin_outlined, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('置顶', style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                const Spacer(),
                Switch(
                  value: _isPinned,
                  onChanged: (v) => setState(() => _isPinned = v),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── 添加按钮 ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('添加', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
    );
  }

  /// 弹出底部抽屉选择器
  Future<T?> _showPickerSheet<T>({
    required List<T> items,
    required String Function(T) labelFn,
    required T currentValue,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final dcs = Theme.of(ctx).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: dcs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: dcs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: items.map((item) {
                    final selected = item == currentValue;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? dcs.primary.withValues(alpha: 0.12)
                                : dcs.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(color: dcs.primary.withValues(alpha: 0.3))
                                : null,
                          ),
                          child: Text(
                            labelFn(item),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              color: selected ? dcs.primary : dcs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelFn,
    required ValueChanged<T?> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final currentLabel = labelFn(value);
    return InkWell(
      onTap: () async {
        final result = await _showPickerSheet(
          items: items,
          labelFn: labelFn,
          currentValue: value,
        );
        if (result != null) onChanged(result);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(currentLabel, style: TextStyle(fontSize: 15, color: cs.onSurface)),
            ),
            Icon(Icons.arrow_drop_down, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _dateLabel,
                style: TextStyle(fontSize: 15, color: cs.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: cs.onSurface, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
