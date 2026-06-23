import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption { system, light, dark }

enum DisplayMode { list, grid }

enum SortMode { created, purchaseDate }

enum CountdownSortMode { created, eventDate }

class AppSettings {
  final ThemeOption theme;
  final DisplayMode displayMode;
  final SortMode sortMode;
  final CountdownSortMode countdownSortMode;
  final bool countdownIncludeStartDay;
  final bool sortAscending;

  const AppSettings({
    this.theme = ThemeOption.light,
    this.displayMode = DisplayMode.list,
    this.sortMode = SortMode.created,
    this.countdownSortMode = CountdownSortMode.created,
    this.countdownIncludeStartDay = false,
    this.sortAscending = false,
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
    CountdownSortMode? countdownSortMode,
    bool? countdownIncludeStartDay,
    bool? sortAscending,
  }) =>
      AppSettings(
        theme: theme ?? this.theme,
        displayMode: displayMode ?? this.displayMode,
        sortMode: sortMode ?? this.sortMode,
        countdownSortMode: countdownSortMode ?? this.countdownSortMode,
        countdownIncludeStartDay: countdownIncludeStartDay ?? this.countdownIncludeStartDay,
        sortAscending: sortAscending ?? this.sortAscending,
      );

  Map<String, dynamic> toJson() => {
    'theme': theme.name,
    'displayMode': displayMode.name,
    'sortMode': sortMode.name,
    'countdownSortMode': countdownSortMode.name,
    'countdownIncludeStartDay': countdownIncludeStartDay,
    'sortAscending': sortAscending,
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
    countdownSortMode: CountdownSortMode.values.firstWhere(
      (e) => e.name == json['countdownSortMode'],
      orElse: () => CountdownSortMode.created,
    ),
    countdownIncludeStartDay: json['countdownIncludeStartDay'] as bool? ?? false,
    sortAscending: json['sortAscending'] as bool? ?? false,
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
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          value = AppSettings.fromJson(decoded);
        }
      } catch (_) {}
    }
  }

  Future<void> update(AppSettings newValue) async {
    value = newValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(newValue.toJson()));
  }
}

/// 全局应用设置单例
final appSettings = AppSettingsNotifier();
