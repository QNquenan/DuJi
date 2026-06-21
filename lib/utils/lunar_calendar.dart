// 农历工具：公历 ↔ 农历 转换
// 基于开源 lunar 包 (https://pub.dev/packages/lunar)

import 'package:lunar/lunar.dart';

/// 农历日期
class LunarDate {
  final int year;   // 农历年
  final int month;  // 农历月 (1-12, 闰月为负数，如闰三月为 -3)
  final int day;    // 农历日 (1-29/30)

  const LunarDate(this.year, this.month, this.day);

  bool get isLeapMonth => month < 0;
  int get absoluteMonth => month.abs();

  /// 月名称（如 "正月"、"五月"、"闰六月"）
  String get monthName {
    final lunar = Lunar.fromYmd(year, month, 1);
    return lunar.getMonthInChinese();
  }

  String get dayName {
    if (day == 10) return '初十';
    if (day == 20) return '二十';
    if (day == 30) return '三十';
    final tens = day ~/ 10;
    final ones = day % 10;
    const cn = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
    if (tens == 0) return '初${cn[ones]}';
    if (tens == 1) return '十${cn[ones]}';
    if (tens == 2) return '廿${cn[ones]}';
    return '';
  }

  String get formatted => '$monthName$dayName';
}

/// 农历年是否有闰月
int leapMonth(int year) {
  final ly = LunarYear.fromYear(year);
  return ly.getLeapMonth();
}

/// 农历月天数
int lunarMonthDayCount(int year, int month) {
  final m = LunarMonth.fromYm(year, month);
  return m?.getDayCount() ?? 0;
}

/// 农历 → 公历
DateTime? lunarToSolar(int year, int month, int day) {
  try {
    final lunar = Lunar.fromYmd(year, month, day);
    final solar = lunar.getSolar();
    return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
  } catch (_) {
    return null;
  }
}

/// 公历 → 农历
LunarDate? solarToLunar(int year, int month, int day) {
  try {
    final lunar = Lunar.fromDate(DateTime(year, month, day));
    return LunarDate(lunar.getYear(), lunar.getMonth(), lunar.getDay());
  } catch (_) {
    return null;
  }
}

/// 获取农历月名称列表（含闰月标签）
List<(int month, String label)> lunarMonthList(int year) {
  final ly = LunarYear.fromYear(year);
  final months = ly.getMonths();
  final list = <(int, String)>[];
  for (final m in months) {
    if (m.getYear() == year) {
      final month = m.getMonth(); // 闰月为负数
      final lunar = Lunar.fromYmd(year, month, 1);
      // lunar 包的 getMonthInChinese() 返回 "正"、"五"、"闰六" 等（不含"月"）
      final label = '${lunar.getMonthInChinese()}月';
      list.add((month, label));
    }
  }
  return list;
}
