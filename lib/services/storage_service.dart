import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/equipment.dart';
import '../models/countdown_event.dart';

class StorageService {
  static const _equipmentKey = 'equipment_list';
  static const _countdownKey = 'countdown_list';

  // ── 物品 ──

  static Future<List<Equipment>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_equipmentKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Equipment.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> save(List<Equipment> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_equipmentKey, raw);
  }

  // ── 倒数日 ──

  static Future<List<CountdownEvent>> loadCountdowns() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_countdownKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => CountdownEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveCountdowns(List<CountdownEvent> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_countdownKey, raw);
  }
}
