import '../utils/lunar_calendar.dart';

enum CountdownType { days, anniversary }
enum RepeatCycle { none, weekly, monthly, yearly }

class CountdownStatus {
  final int diff;
  final String dateStr;
  final String statusText;
  const CountdownStatus(this.diff, this.dateStr, this.statusText);
}

CountdownStatus computeCountdownStatus(CountdownEvent event) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(event.targetDate.year, event.targetDate.month, event.targetDate.day);

  if (event.type == CountdownType.anniversary) {
    final years = today.year - targetDay.year;
    final m = today.month - targetDay.month;
    final d = today.day - targetDay.day;
    final y = (m < 0 || (m == 0 && d < 0)) ? years - 1 : years;
    return CountdownStatus(y, event.targetDateFormatted, '已经 $y 周年');
  }

  if (event.repeatCycle == RepeatCycle.weekly && event.weekDays.isNotEmpty) {
    final wkToday = now.weekday == 7 ? 6 : now.weekday - 1;
    for (int offset = 0; offset < 7; offset++) {
      final day = (wkToday + offset) % 7;
      if (event.weekDays.contains(day)) {
        final nextDate = now.add(Duration(days: offset));
        final ds = '${nextDate.year}-${(nextDate.month).toString().padLeft(2,"0")}-${(nextDate.day).toString().padLeft(2,"0")}';
        if (offset == 0) return CountdownStatus(0, ds, '就是今天！');
        return CountdownStatus(offset, ds, '还有 $offset 天');
      }
    }
  }

  if (event.repeatCycle == RepeatCycle.monthly && event.monthDays.isNotEmpty) {
    final todayDay = now.day;
    final sorted = List.of(event.monthDays)..sort();
    for (final d in sorted) {
      if (d > todayDay) {
        final nextDate = DateTime(now.year, now.month, d);
        final ds = '${nextDate.year}-${(nextDate.month).toString().padLeft(2,"0")}-${(nextDate.day).toString().padLeft(2,"0")}';
        return CountdownStatus(d - todayDay, ds, '还有 ${d - todayDay} 天');
      }
      if (d == todayDay) {
        final ds = '${now.year}-${(now.month).toString().padLeft(2,"0")}-${(now.day).toString().padLeft(2,"0")}';
        return CountdownStatus(0, ds, '就是今天！');
      }
    }
    final firstNext = sorted.first;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final clamped = firstNext > daysInMonth ? daysInMonth : firstNext;
    final total = daysInMonth - todayDay + clamped;
    final nextDate = DateTime(now.year, now.month + 1, clamped);
    final ds = '${nextDate.year}-${(nextDate.month).toString().padLeft(2,"0")}-${(nextDate.day).toString().padLeft(2,"0")}';
    return CountdownStatus(total, ds, '还有 $total 天');
  }

  if (event.isLunar && event.repeatCycle == RepeatCycle.yearly) {
    final lunar = solarToLunar(event.targetDate.year, event.targetDate.month, event.targetDate.day);
    if (lunar != null) {
      final label = '农历 ${lunar.monthName}月${lunar.dayName}';
      final thisSolar = lunarToSolar(now.year, lunar.month, lunar.day);
      if (thisSolar != null && !thisSolar.isBefore(today)) {
        final diff = thisSolar.difference(today).inDays;
        final ds = '${thisSolar.year}-${(thisSolar.month).toString().padLeft(2,"0")}-${(thisSolar.day).toString().padLeft(2,"0")}';
        if (diff == 0) return CountdownStatus(0, '$label · 今天', '就是今天！');
        return CountdownStatus(diff, '$label · $ds', '还有 $diff 天');
      }
      final nextSolar = lunarToSolar(now.year + 1, lunar.month, lunar.day);
      if (nextSolar != null) {
        final diff = nextSolar.difference(today).inDays;
        final ds = '${nextSolar.year}-${(nextSolar.month).toString().padLeft(2,"0")}-${(nextSolar.day).toString().padLeft(2,"0")}';
        return CountdownStatus(diff, '$label · $ds', '还有 $diff 天');
      }
    }
  }

  final raw = targetDay.difference(today).inDays;
  if (raw > 0) return CountdownStatus(raw, event.targetDateFormatted, '还有 $raw 天');
  if (raw == 0) return CountdownStatus(0, event.targetDateFormatted, '就是今天！');
  return CountdownStatus(raw, event.targetDateFormatted, '已经 ${-raw} 天');
}

class CountdownEvent {
  final String id;
  final String emoji;
  final String emojiName;
  final String title;
  final CountdownType type;
  final RepeatCycle repeatCycle;
  final DateTime targetDate;
  final String notes;
  final List<int> weekDays;
  final List<int> monthDays;
  final bool isLunar;
  final bool isPinned;

  CountdownEvent({required this.id, this.emoji = '📅', this.emojiName = '日历', required this.title, this.type = CountdownType.days, this.repeatCycle = RepeatCycle.none, required this.targetDate, this.notes = '', this.weekDays = const [], this.monthDays = const [], this.isLunar = false, this.isPinned = false});

  String get targetDateFormatted {
    if (isLunar) {
      final lunar = solarToLunar(targetDate.year, targetDate.month, targetDate.day);
      if (lunar != null) return '农历 ${lunar.year}年${lunar.monthName}月${lunar.dayName}';
    }
    return '${targetDate.year}-${targetDate.month.toString().padLeft(2,'0')}-${targetDate.day.toString().padLeft(2,'0')}';
  }

  String get typeLabel => switch (type) { CountdownType.days => '倒/正数日', CountdownType.anniversary => '纪念日' };
  String get repeatLabel => switch (repeatCycle) { RepeatCycle.none => '不重复', RepeatCycle.weekly => '每周', RepeatCycle.monthly => '每月', RepeatCycle.yearly => '每年' };

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

  Map<String, dynamic> toJson() => {'id': id, 'emoji': emoji, 'emojiName': emojiName, 'title': title, 'type': type.name, 'repeatCycle': repeatCycle.name, 'targetDate': targetDate.toIso8601String(), 'notes': notes, 'weekDays': weekDays, 'monthDays': monthDays, 'isLunar': isLunar, 'isPinned': isPinned};

  factory CountdownEvent.fromJson(Map<String, dynamic> json) => CountdownEvent(
    id: json['id'] as String,
    emoji: json['emoji'] as String? ?? '📅',
    emojiName: json['emojiName'] as String? ?? '日历',
    title: json['title'] as String,
    type: CountdownType.values.firstWhere((e) => e.name == json['type'], orElse: () => CountdownType.days),
    repeatCycle: RepeatCycle.values.firstWhere((e) => e.name == (json['repeatCycle'] ?? 'none'), orElse: () => RepeatCycle.none),
    targetDate: DateTime.parse(json['targetDate'] as String),
    notes: json['notes'] as String? ?? '',
    weekDays: json['weekDays'] != null ? (json['weekDays'] as List).map((e) => e as int).toList() : const [],
    monthDays: json['monthDays'] != null ? (json['monthDays'] as List).map((e) => e as int).toList() : const [],
    isLunar: json['isLunar'] as bool? ?? false,
    isPinned: json['isPinned'] as bool? ?? false,
  );
}
