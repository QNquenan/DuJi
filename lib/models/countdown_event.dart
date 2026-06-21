import '../utils/lunar_calendar.dart';

/// 倒数事件类型
enum CountdownType {
  days,        // 倒/正数日
  anniversary, // 纪念日
}

/// 重复周期
enum RepeatCycle {
  none,
  weekly,
  monthly,
  yearly,
}

/// 倒数日计算结果（供缩略和详情页统一使用）
class CountdownStatus {
  final int diff;         // 天数差（正=未来，0=今天，负=过去）
  final String dateStr;   // 日期文案
  final String statusText;// 状态文案（"还有3天"/"就是今天！"/"已经5天"/"已经2周年"）

  const CountdownStatus(this.diff, this.dateStr, this.statusText);
}

/// 统一计算倒数日状态
CountdownStatus computeCountdownStatus(CountdownEvent event) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(
    event.targetDate.year,
    event.targetDate.month,
    event.targetDate.day,
  );

  // 纪念日
  if (event.type == CountdownType.anniversary) {
    final years = today.year - targetDay.year;
    final m = today.month - targetDay.month;
    final d = today.day - targetDay.day;
    final y = (m < 0 || (m == 0 && d < 0)) ? years - 1 : years;
    return CountdownStatus(y, event.targetDateFormatted, '已经 $y 周年');
  }

  // 每周重复
  if (event.repeatCycle == RepeatCycle.weekly && event.weekDays.isNotEmpty) {
    final wkToday = now.weekday == 7 ? 6 : now.weekday - 1;
    for (int offset = 0; offset < 7; offset++) {
      final day = (wkToday + offset) % 7;
      if (event.weekDays.contains(day)) {
        final nextDate = now.add(Duration(days: offset));
        final ds = '${nextDate.year}-${_p2(nextDate.month)}-${_p2(nextDate.day)}';
        if (offset == 0) return CountdownStatus(0, ds, '就是今天！');
        return CountdownStatus(offset, ds, '还有 $offset 天');
      }
    }
  }

  // 每月重复
  if (event.repeatCycle == RepeatCycle.monthly && event.monthDays.isNotEmpty) {
    final todayDay = now.day;
    final sorted = List.of(event.monthDays)..sort();
    for (final d in sorted) {
      if (d > todayDay) {
        final nextDate = DateTime(now.year, now.month, d);
        final ds = '${nextDate.year}-${_p2(nextDate.month)}-${_p2(nextDate.day)}';
        return CountdownStatus(d - todayDay, ds, '还有 ${d - todayDay} 天');
      }
      if (d == todayDay) {
        final ds = '${now.year}-${_p2(now.month)}-${_p2(now.day)}';
        return CountdownStatus(0, ds, '就是今天！');
      }
    }
    final firstNext = sorted.first;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final clamped = firstNext > daysInMonth ? daysInMonth : firstNext;
    final total = daysInMonth - todayDay + clamped;
    final nextDate = DateTime(now.year, now.month + 1, clamped);
    final ds = '${nextDate.year}-${_p2(nextDate.month)}-${_p2(nextDate.day)}';
    return CountdownStatus(total, ds, '还有 $total 天');
  }

  // 农历每年重复
  if (event.isLunar && event.repeatCycle == RepeatCycle.yearly) {
    final lunar = solarToLunar(
      event.targetDate.year,
      event.targetDate.month,
      event.targetDate.day,
    );
    if (lunar != null) {
      final label = '农历 ${lunar.monthName}月${lunar.dayName}';
      final thisSolar = lunarToSolar(now.year, lunar.month, lunar.day);
      if (thisSolar != null && !thisSolar.isBefore(today)) {
        final diff = thisSolar.difference(today).inDays;
        if (diff == 0) {
          return CountdownStatus(0, '$label · 今天', '就是今天！');
        }
        return CountdownStatus(diff, '$label · ${
          '${thisSolar.year}-${_p2(thisSolar.month)}-${_p2(thisSolar.day)}'
        }', '还有 $diff 天');
      }
      final nextSolar = lunarToSolar(now.year + 1, lunar.month, lunar.day);
      if (nextSolar != null) {
        final diff = nextSolar.difference(today).inDays;
        return CountdownStatus(diff, '$label · ${
          '${nextSolar.year}-${_p2(nextSolar.month)}-${_p2(nextSolar.day)}'
        }', '还有 $diff 天');
      }
    }
  }

  // 不重复 / 每年
  final raw = targetDay.difference(today).inDays;
  if (raw > 0) return CountdownStatus(raw, event.targetDateFormatted, '还有 $raw 天');
  if (raw == 0) return CountdownStatus(0, event.targetDateFormatted, '就是今天！');
  return CountdownStatus(raw, event.targetDateFormatted, '已经 ${-raw} 天');
}

String _p2(int n) => n.toString().padLeft(2, '0');

/// 倒数日/纪念日数据模型
class CountdownEvent {
  final String id;
  final String emoji;
  final String emojiName;
  final String title;
  final CountdownType type;
  final RepeatCycle repeatCycle;
  final DateTime targetDate;
  final String notes;
  /// 每周重复：选中的星期几 (0=周一 … 6=周日)
  final List<int> weekDays;
  /// 每月重复：选中的日 (1-31)
  final List<int> monthDays;
  /// 是否使用农历
  final bool isLunar;
  /// 是否置顶
  final bool isPinned;

  CountdownEvent({
    required this.id,
    this.emoji = '📅',
    this.emojiName = '日历',
    required this.title,
    this.type = CountdownType.days,
    this.repeatCycle = RepeatCycle.none,
    required this.targetDate,
    this.notes = '',
    this.weekDays = const [],
    this.monthDays = const [],
    this.isLunar = false,
    this.isPinned = false,
  });

  String get targetDateFormatted {
    if (isLunar) {
      final lunar = solarToLunar(targetDate.year, targetDate.month, targetDate.day);
      if (lunar != null) return '农历 ${lunar.year}年${lunar.monthName}月${lunar.dayName}';
    }
    return '${targetDate.year}-${_pad(targetDate.month)}-${_pad(targetDate.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String get typeLabel => switch (type) {
    CountdownType.days => '倒/正数日',
    CountdownType.anniversary => '纪念日',
  };

  String get repeatLabel => switch (repeatCycle) {
    RepeatCycle.none => '不重复',
    RepeatCycle.weekly => '每周',
    RepeatCycle.monthly => '每月',
    RepeatCycle.yearly => '每年',
  };

  String get weekDaysLabel {
    if (weekDays.isEmpty) return '';
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekDays.map((d) => names[d]).join(' ');
  }

  String get monthDaysLabel {
    if (monthDays.isEmpty) return '';
    final sorted = List.of(monthDays)..sort();
    return sorted.map((d) => '$d 日').join(' ');
  }

  bool get isSolarDate => !isLunar;

  Map<String, dynamic> toJson() => {
    'id': id,
    'emoji': emoji,
    'emojiName': emojiName,
    'title': title,
    'type': type.name,
    'repeatCycle': repeatCycle.name,
    'targetDate': targetDate.toIso8601String(),
    'notes': notes,
    'weekDays': weekDays,
    'monthDays': monthDays,
    'isLunar': isLunar,
    'isPinned': isPinned,
  };

  factory CountdownEvent.fromJson(Map<String, dynamic> json) => CountdownEvent(
    id: json['id'] as String,
    emoji: json['emoji'] as String? ?? '📅',
    emojiName: json['emojiName'] as String? ?? '日历',
    title: json['title'] as String,
    type: CountdownType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => CountdownType.days,
    ),
    repeatCycle: RepeatCycle.values.firstWhere(
      (e) => e.name == (json['repeatCycle'] ?? 'none'),
      orElse: () => RepeatCycle.none,
    ),
    targetDate: DateTime.parse(json['targetDate'] as String),
    notes: json['notes'] as String? ?? '',
    weekDays: json['weekDays'] != null
        ? (json['weekDays'] as List).map((e) => e as int).toList()
        : const [],
    monthDays: json['monthDays'] != null
        ? (json['monthDays'] as List).map((e) => e as int).toList()
        : const [],
    isLunar: json['isLunar'] as bool? ?? false,
    isPinned: json['isPinned'] as bool? ?? false,
  );
}
