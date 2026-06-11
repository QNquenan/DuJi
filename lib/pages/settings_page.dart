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
    appSettings.addListener(_onChanged);
  }

  @override
  void dispose() {
    appSettings.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _update(AppSettings Function(AppSettings) cb) async {
    await appSettings.update(cb(appSettings.value));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = appSettings.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _sectionHeader('外观', cs),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: [
              _DropdownTile(
                icon: Icons.brightness_6_outlined,
                label: '主题',
                value: s.theme,
                items: const [
                  DropdownMenuItem(
                    value: ThemeOption.system,
                    child: Text('跟随系统'),
                  ),
                  DropdownMenuItem(value: ThemeOption.light, child: Text('浅色')),
                  DropdownMenuItem(value: ThemeOption.dark, child: Text('深色')),
                ],
                onChanged: (v) => _update((s) => s.copyWith(theme: v)),
              ),
              _divider(),
              _DropdownTile(
                icon: Icons.view_module_outlined,
                label: '显示模式',
                value: s.displayMode,
                items: const [
                  DropdownMenuItem(value: DisplayMode.list, child: Text('列表')),
                  DropdownMenuItem(value: DisplayMode.grid, child: Text('块状')),
                ],
                onChanged: (v) => _update((s) => s.copyWith(displayMode: v)),
              ),
              _divider(),
              _DropdownTile(
                icon: Icons.sort_outlined,
                label: '排序方式',
                value: s.sortMode,
                items: const [
                  DropdownMenuItem(
                    value: SortMode.created,
                    child: Text('创建时间'),
                  ),
                  DropdownMenuItem(
                    value: SortMode.purchaseDate,
                    child: Text('购买日期'),
                  ),
                ],
                onChanged: (v) => _update((s) => s.copyWith(sortMode: v)),
              ),
            ],
          ),
          const SizedBox(height: 28),
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

  Widget _buildCard(BuildContext context, {required List<Widget> children}) =>
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: children),
      );

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
            child: Text(
              '关于APP',
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
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

class _DropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
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
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
            ),
          ),
          SizedBox(
            height: 36,
            child: DropdownButtonHideUnderline(
              child: Theme(
                data: Theme.of(context).copyWith(
                  menuTheme: MenuThemeData(
                    style: MenuStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                child: DropdownButton<T>(
                  value: value,
                  isDense: true,
                  alignment: AlignmentDirectional.centerEnd,
                  style: TextStyle(fontSize: 14, color: cs.onSurface),
                  items: items.map((item) {
                    return DropdownMenuItem<T>(
                      value: item.value,
                      child: Center(child: item.child),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
              ),
            ),
          ),
        ],
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
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: cs.onSurface),
              ),
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
