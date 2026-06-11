import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/equipment.dart';

class StorageService {
  static const _key = 'equipment_list';

  static Future<List<Equipment>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Equipment.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> save(List<Equipment> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
