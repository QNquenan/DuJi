import 'package:flutter/material.dart';
import '../models/countdown_event.dart';
import '../widgets/emoji_picker_sheet.dart' show countdownPresetEmojis, showEmojiPicker;
import '../widgets/date_picker_lunar.dart';
import '../utils/lunar_calendar.dart';
import '../widgets/form_helpers.dart';

/// 添加倒数日页面（全屏页面）
Future<CountdownEvent?> pushAddCountdownPage(BuildContext context) {
  return Navigator.push<CountdownEvent>(
    context,
    MaterialPageRoute(builder: (_) => const _CountdownFormPage()),
  );
}

/// 编辑倒数日页面（全屏页面）
Future<CountdownEvent?> pushEditCountdownPage(
  BuildContext context,
  CountdownEvent event,
) {
  return Navigator.push<CountdownEvent>(
    context,
    MaterialPageRoute(builder: (_) => _CountdownFormPage(existingEvent: event)),
  );
}

class _CountdownFormPage extends StatefulWidget {
  final CountdownEvent? existingEvent;
  const _CountdownFormPage({this.existingEvent});

  @override
  State<_CountdownFormPage> createState() => _CountdownFormPageState();
}

class _CountdownFormPageState extends State<_CountdownFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late DateTime _targetDate;
  late String _emoji;
  late String _emojiName;
  late CountdownType _type;
  late RepeatCycle _repeatCycle;
  late List<int> _weekDays;
  late List<int> _monthDays;
  late bool _isLunar;
  bool _isPinned = false;
  bool _datePicked = false;

  bool get _isEditing => widget.existingEvent != null;

  static const _typeOptions = [
    CountdownType.days,
    CountdownType.anniversary,
    CountdownType.birthday,
  ];

  static const _repeatOptions = [
    RepeatCycle.none,
    RepeatCycle.weekly,
    RepeatCycle.monthly,
    RepeatCycle.yearly,
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existingEvent;
    if (e != null) {
      _titleCtrl.text = e.title;
      _notesCtrl.text = e.notes;
      _targetDate = e.targetDate;
      _emoji = e.emoji;
      _emojiName = e.emojiName;
      _type = e.type;
      _repeatCycle = e.repeatCycle;
      _weekDays = List.of(e.weekDays);
      _monthDays = List.of(e.monthDays);
      _isLunar = e.isLunar;
      _isPinned = e.isPinned;
    } else {
      _targetDate = DateTime.now();
      _emoji = '📅';
      _emojiName = '日历';
      _type = CountdownType.days;
      _repeatCycle = RepeatCycle.none;
      _weekDays = [];
      _monthDays = [];
      _isLunar = false;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (_type == CountdownType.birthday) {
      final result = await showLunarDatePicker(context, initialDate: _targetDate, initialIsLunar: _isLunar);
      if (result != null && mounted) {
        setState(() {
          _targetDate = result.solarDate;
          _isLunar = result.isLunar;
          _datePicked = true;
        });
      }
    } else if (_repeatCycle == RepeatCycle.weekly) {
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
      showStyledSnackBar(context, '请至少选择一天');
      return;
    }
    if (_repeatCycle == RepeatCycle.monthly && _monthDays.isEmpty) {
      showStyledSnackBar(context, '请至少选择一天');
      return;
    }
    if (_repeatCycle != RepeatCycle.weekly &&
        _repeatCycle != RepeatCycle.monthly &&
        !_datePicked) {
      showStyledSnackBar(context, '请选择日期');
      return;
    }
    if (_repeatCycle == RepeatCycle.none &&
        _type == CountdownType.days &&
        _targetDate.isBefore(DateTime(1900, 1, 1))) {
      showStyledSnackBar(context, '选择的日期有误，请重新选择');
      return;
    }

    final event = CountdownEvent(
      id: _isEditing ? widget.existingEvent!.id : DateTime.now().millisecondsSinceEpoch.toString(),
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

  String get _dateLabel {
    if (_type == CountdownType.birthday) {
      if (_isLunar) {
        final lunar = solarToLunar(_targetDate.year, _targetDate.month, _targetDate.day);
        if (lunar != null) return '每年 农历${lunar.monthName}${lunar.dayName}';
      }
      return '每年 ${_targetDate.month}月${_targetDate.day}日';
    }
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
    final cardColor = Theme.of(context).cardColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? '编辑日子' : '添加日子',
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
                        color: cardColor,
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
            buildLabel(context, '事件名称'),
            const SizedBox(height: 8),
            buildFormField(
              context: context,
              controller: _titleCtrl,
              hint: '请输入事件名称',
              validator: (v) => v == null || v.trim().isEmpty ? '请输入名称' : null,
            ),
            const SizedBox(height: 20),

            // ── 类型 ──
            buildLabel(context, '类型'),
            const SizedBox(height: 8),
            _buildDropdown<CountdownType>(
              value: _type,
              items: _typeOptions,
              labelFn: (t) => switch (t) {
                CountdownType.days => '倒/正数日',
                CountdownType.anniversary => '纪念日',
                CountdownType.birthday => '生日',
              },
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _type = v;
                    if (v == CountdownType.birthday) {
                      _repeatCycle = RepeatCycle.yearly;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // ── 重复周期（仅倒/正数日，生日固定每年） ──
            if (_type == CountdownType.days) ...[
              buildLabel(context, '重复周期'),
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
                      if (v != RepeatCycle.weekly) _weekDays = [];
                      if (v != RepeatCycle.monthly) _monthDays = [];
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
            ],

            // ── 日期 ──
            buildLabel(context, '日期'),
            const SizedBox(height: 8),
            buildDateField(context, _dateLabel, _pickDate),
            const SizedBox(height: 20),

            // ── 备注 ──
            buildLabel(context, '备注'),
            const SizedBox(height: 8),
            buildFormField(context: context, controller: _notesCtrl, hint: '选填，备注信息', maxLines: 3),
            const SizedBox(height: 20),

            // ── 置顶 ──
            Row(
              children: [
                Icon(Icons.push_pin_outlined, size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('置顶', style: TextStyle(fontSize: 15, color: cs.onSurface)),
                const Spacer(),
                Switch(
                  value: _isPinned,
                  onChanged: (v) => setState(() => _isPinned = v),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── 按钮 ──
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
                child: Text(
                  _isEditing ? '保存修改' : '添加',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelFn,
    required ValueChanged<T?> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;
    return InkWell(
      onTap: () async {
        final result = await showPickerSheet<T>(
          context,
          items: items.map((e) => (e, labelFn(e))).toList(),
          currentValue: value,
        );
        if (result != null) onChanged(result);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(labelFn(value), style: TextStyle(fontSize: 15, color: cs.onSurface)),
            ),
            Icon(Icons.arrow_drop_down, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
