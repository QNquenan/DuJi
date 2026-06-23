import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_settings.dart';
import 'about_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    appSettings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  Future<void> _update(AppSettings Function(AppSettings) cb) async {
    await appSettings.update(cb(appSettings.value));
  }

  /// 弹出底部抽屉选择器
  Future<T?> _showPickerSheet<T>({
    required List<(T, String)> items,
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
                    final selected = item.$1 == currentValue;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, item.$1),
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
                            item.$2,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = appSettings.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '设置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── 外观 ──
          _sectionHeader('外观', cs),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: [
              _SettingTile(
                icon: Icons.brightness_6_outlined,
                label: '主题',
                value: _themeLabel(s.theme),
                onTap: () async {
                  final result = await _showPickerSheet<ThemeOption>(
                    currentValue: s.theme,
                    items: const [
                      (ThemeOption.system, '跟随系统'),
                      (ThemeOption.light, '浅色'),
                      (ThemeOption.dark, '深色'),
                    ],
                  );
                  if (result != null) _update((s) => s.copyWith(theme: result));
                },
              ),
              _divider(),
              _SettingTile(
                icon: Icons.view_module_outlined,
                label: '显示模式',
                value: s.displayMode == DisplayMode.list ? '列表' : '块状',
                onTap: () async {
                  final result = await _showPickerSheet(
                    currentValue: s.displayMode,
                    items: const [
                      (DisplayMode.list, '列表'),
                      (DisplayMode.grid, '块状'),
                    ],
                  );
                  if (result != null) _update((s) => s.copyWith(displayMode: result));
                },
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── 我的物品 ──
          _sectionHeader('我的物品', cs),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: [
              _SettingTile(
                icon: Icons.sort_outlined,
                label: '排序方式',
                value: s.sortMode == SortMode.created ? '创建时间' : '购买日期',
                onTap: () async {
                  final result = await _showPickerSheet(
                    currentValue: s.sortMode,
                    items: const [
                      (SortMode.created, '创建时间'),
                      (SortMode.purchaseDate, '购买日期'),
                    ],
                  );
                  if (result != null) _update((s) => s.copyWith(sortMode: result));
                },
              ),
              _divider(),
              _SettingTile(
                icon: Icons.swap_vert_outlined,
                label: '排序方向',
                value: s.sortAscending ? '升序' : '倒序',
                onTap: () async {
                  final result = await _showPickerSheet<bool>(
                    currentValue: s.sortAscending,
                    items: const [
                      (false, '倒序'),
                      (true, '升序'),
                    ],
                  );
                  if (result != null) _update((s) => s.copyWith(sortAscending: result));
                },
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── 倒数日 ──
          _sectionHeader('倒数日', cs),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: [
              _SettingTile(
                icon: Icons.sort_outlined,
                label: '排序方式',
                value: s.countdownSortMode == CountdownSortMode.created ? '创建日期' : '事件时间',
                onTap: () async {
                  final result = await _showPickerSheet(
                    currentValue: s.countdownSortMode,
                    items: const [
                      (CountdownSortMode.created, '创建日期'),
                      (CountdownSortMode.eventDate, '事件时间'),
                    ],
                  );
                  if (result != null) _update((s) => s.copyWith(countdownSortMode: result));
                },
              ),
              _divider(),
              _SettingTile(
                icon: Icons.swap_vert_outlined,
                label: '排序方向',
                value: s.sortAscending ? '升序' : '倒序',
                onTap: () async {
                  final result = await _showPickerSheet<bool>(
                    currentValue: s.sortAscending,
                    items: const [
                      (false, '倒序'),
                      (true, '升序'),
                    ],
                  );
                  if (result != null) _update((s) => s.copyWith(sortAscending: result));
                },
              ),
              _divider(),
              _SwitchTile(
                icon: Icons.calendar_today,
                label: '正数包含起始日',
                subtitle: '开启后正数天数 +1',
                value: s.countdownIncludeStartDay,
                onChanged: (v) => _update((s) => s.copyWith(countdownIncludeStartDay: v)),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── 关于 ──
          _sectionHeader('关于', cs),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: [
              _LinkTile(
                icon: Icons.mail_outline,
                label: '联系我',
                trailing: Text(
                  'quenan.cn',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                ),
                onTap: () => _launchUrl('https://quenan.cn'),
              ),
              _divider(),
              _buildAboutTile(context, cs),
            ],
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeOption t) => switch (t) {
    ThemeOption.system => '跟随系统',
    ThemeOption.light => '浅色',
    ThemeOption.dark => '深色',
  };

  Widget _sectionHeader(String text, ColorScheme cs) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: cs.onSurfaceVariant,
      ),
    ),
  );

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    final cardColor = Theme.of(context).cardColor;
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: children),
      );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _buildAboutTile(BuildContext context, ColorScheme cs) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutPage()),
    ),
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 22, color: cs.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Text('关于APP', style: TextStyle(fontSize: 16, color: cs.onSurface)),
          ),
          Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
        ],
      ),
    ),
  );

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(16),
        bottom: Radius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: cs.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 15, color: cs.onSurface)),
            ),
            Text(value, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: cs.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 15, color: cs.onSurface)),
            ),
            trailing,
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: cs.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 15, color: cs.onSurface)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
