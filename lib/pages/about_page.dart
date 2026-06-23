import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  bool _loaded = false;
  List<_ChangelogBlock>? _cachedBlocks;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    try {
      final text = await rootBundle.loadString('assets/changelog.md');
      if (mounted) {
        setState(() {
          _cachedBlocks = _parseChangelog(text);
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '关于APP',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // ── 头部信息 ──
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/icon/app_icon.png', width: 72, height: 72, cacheWidth: 72, cacheHeight: 72),
                ),
                const SizedBox(height: 16),
                Text('嘟迹', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 4),
                Text('v1.3.0', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // ── 更新日志 ──
          Text('更新日志', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 12),
          if (!_loaded)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else
            ..._cachedBlocks != null
                ? _buildChangelogSections(cs)
                : [Text('加载失败', style: TextStyle(color: cs.onSurfaceVariant))],
        ],
      ),
    );
  }

  List<Widget> _buildChangelogSections(ColorScheme cs) {
    final widgets = <Widget>[];
    for (final block in _cachedBlocks!) {
      switch (block) {
        case _VersionBlock(:final version, :final date):
          widgets.add(const SizedBox(height: 16));
          widgets.add(Text('$version — $date',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)));
          widgets.add(const SizedBox(height: 8));
        case _SectionBlock(:final title, :final dotColor, :final emoji):
          if (dotColor != null) {
            widgets.add(Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('$emoji$title',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
              ]),
            ));
          } else {
            widgets.add(Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text('$emoji$title',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            ));
          }
        case _ItemBlock(:final text):
          final parts = <TextSpan>[];
          final boldReg = RegExp(r'\*\*(.+?)\*\*');
          int last = 0;
          for (final m in boldReg.allMatches(text)) {
            if (m.start > last) parts.add(TextSpan(text: text.substring(last, m.start)));
            parts.add(TextSpan(text: m.group(1),
                style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)));
            last = m.end;
          }
          if (last < text.length) parts.add(TextSpan(text: text.substring(last)));
          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 12, top: 3, bottom: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('· ', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
              Expanded(child: RichText(text: TextSpan(
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.4),
                  children: parts))),
            ]),
          ));
      }
    }
    return widgets;
  }

  List<_ChangelogBlock> _parseChangelog(String raw) {
    final blocks = <_ChangelogBlock>[];
    for (final line in raw.split('\n')) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('# ')) continue;
      final vm = RegExp(r'^##\s+\[(.+?)\]\s*-\s*(.+)$').firstMatch(t);
      if (vm != null) { blocks.add(_VersionBlock(vm.group(1)!, vm.group(2)!)); continue; }
      final sm = RegExp(r'^###\s+(.+)$').firstMatch(t);
      if (sm != null) {
        final title = sm.group(1)!;
        String emoji;
        Color? dotColor;
        if (title.contains('新增')) { emoji = '✨ '; dotColor = const Color(0xFF34C759); }
        else if (title.contains('优化')) { emoji = '🎨 '; dotColor = const Color(0xFF007AFF); }
        else if (title.contains('Bug') || title.contains('修复')) { emoji = '🐛 '; dotColor = const Color(0xFFFF9500); }
        else if (title.contains('重构') || title.contains('代码')) { emoji = '🔧 '; dotColor = Colors.grey; }
        else { emoji = ''; dotColor = null; }
        blocks.add(_SectionBlock(title, dotColor, emoji)); continue;
      }
      final im = RegExp(r'^-\s+(.+)$').firstMatch(t);
      if (im != null) { blocks.add(_ItemBlock(im.group(1)!)); }
    }
    return blocks;
  }
}

sealed class _ChangelogBlock {}
class _VersionBlock extends _ChangelogBlock { final String version, date; _VersionBlock(this.version, this.date); }
class _SectionBlock extends _ChangelogBlock { final String title; final Color? dotColor; final String emoji; _SectionBlock(this.title, this.dotColor, this.emoji); }
class _ItemBlock extends _ChangelogBlock { final String text; _ItemBlock(this.text); }

