import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption { system, light, dark }

enum DisplayMode { list, grid }

enum SortMode { created, purchaseDate }

class AppSettings {
  final ThemeOption theme;
  final DisplayMode displayMode;
  final SortMode sortMode;

  const AppSettings({
    this.theme = ThemeOption.light,
    this.displayMode = DisplayMode.list,
    this.sortMode = SortMode.created,
  });

  ThemeMode get themeMode {
    switch (theme) {
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
      case ThemeOption.system:
        return ThemeMode.system;
    }
  }

  AppSettings copyWith({
    ThemeOption? theme,
    DisplayMode? displayMode,
    SortMode? sortMode,
  }) =>
      AppSettings(
        theme: theme ?? this.theme,
        displayMode: displayMode ?? this.displayMode,
        sortMode: sortMode ?? this.sortMode,
      );

  Map<String, dynamic> toJson() => {
    'theme': theme.name,
    'displayMode': displayMode.name,
    'sortMode': sortMode.name,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    theme: ThemeOption.values.firstWhere(
      (e) => e.name == json['theme'],
      orElse: () => ThemeOption.system,
    ),
    displayMode: DisplayMode.values.firstWhere(
      (e) => e.name == json['displayMode'],
      orElse: () => DisplayMode.list,
    ),
    sortMode: SortMode.values.firstWhere(
      (e) => e.name == json['sortMode'],
      orElse: () => SortMode.created,
    ),
  );
}

/// 全局应用设置，修改后自动通知监听者
class AppSettingsNotifier extends ValueNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings());

  static const _key = 'app_settings';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final map = _parseJson(raw);
        if (map != null) value = AppSettings.fromJson(map);
      } catch (_) {}
    }
  }

  Future<void> update(AppSettings newValue) async {
    value = newValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _toJsonString(newValue));
  }

  static Map<String, dynamic>? _parseJson(String raw) {
    // 简单解析：{"theme":"system","displayMode":"list","sortMode":"created"}
    final map = <String, dynamic>{};
    for (final part in raw.replaceAll(RegExp(r'[{}" ]'), '').split(',')) {
      final kv = part.split(':');
      if (kv.length == 2) map[kv[0]] = kv[1];
    }
    return map;
  }

  static String _toJsonString(AppSettings s) {
    return '{"theme":"${s.theme.name}","displayMode":"${s.displayMode.name}","sortMode":"${s.sortMode.name}"}';
  }
}

/// 全局应用设置单例
final appSettings = AppSettingsNotifier();
