import 'package:flutter/material.dart';
import '../models/countdown_event.dart';
import 'edit_countdown_event_page.dart';

/// 倒数日详情页 — 返回 CountdownEvent(编辑) 或 true(删除) 或 null(无变化)
class CountdownDetailPage extends StatefulWidget {
  final CountdownEvent event;
  const CountdownDetailPage({super.key, required this.event});

  @override
  State<CountdownDetailPage> createState() => _CountdownDetailPageState();
}

class _CountdownDetailPageState extends State<CountdownDetailPage> {
  late CountdownEvent _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) {
        final dcs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: Theme.of(ctx).dialogTheme.backgroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 40, color: dcs.error),
              const SizedBox(height: 16),
              const Text('确认删除', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                '确定要删除「${_event.title}」吗？',
                style: TextStyle(fontSize: 14, color: dcs.onSurfaceVariant),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dcs.surfaceContainerHighest,
                      foregroundColor: dcs.onSurfaceVariant,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('取消', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dcs.error,
                      foregroundColor: dcs.onError,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('删除', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _edit() async {
    final updated = await pushEditCountdownPage(context, _event);
    if (updated != null && mounted) {
      setState(() => _event = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('编辑成功', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black.withValues(alpha: 0.75),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _event);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '日子详情',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 20, color: cs.onSurface),
            onPressed: () => Navigator.pop(context, _event),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant, size: 22),
              onPressed: _edit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error, size: 22),
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(_event.emoji, style: const TextStyle(fontSize: 38)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_event.isPinned) ...[
                      Icon(Icons.push_pin, size: 20, color: cs.primary),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _event.title,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  computeCountdownStatus(_event).statusText,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.primary),
                ),
                const SizedBox(height: 24),
                _InfoRow(icon: Icons.calendar_today, label: '日期', value: _event.targetDateFormatted),
                const SizedBox(height: 14),
                Divider(height: 1),
                const SizedBox(height: 14),
                _InfoRow(icon: Icons.category_outlined, label: '类型', value: _event.typeLabel),
                if (_event.repeatCycle != RepeatCycle.none) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1),
                  const SizedBox(height: 14),
                  _InfoRow(icon: Icons.repeat, label: '重复', value: _event.repeatLabel),
                ],
                if (_event.repeatCycle == RepeatCycle.weekly && _event.weekDays.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1),
                  const SizedBox(height: 14),
                  _InfoRow(icon: Icons.event_available, label: '每周', value: _event.weekDaysLabel),
                ],
                if (_event.repeatCycle == RepeatCycle.monthly && _event.monthDays.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1),
                  const SizedBox(height: 14),
                  _InfoRow(icon: Icons.event_available, label: '每月', value: _event.monthDaysLabel),
                ],
                if (_event.isLunar) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1),
                  const SizedBox(height: 14),
                  _InfoRow(icon: Icons.nights_stay_outlined, label: '历法', value: '农历'),
                ],
                if (_event.notes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1),
                  const SizedBox(height: 14),
                  _InfoRow(icon: Icons.article_outlined, label: '备注', value: _event.notes, multiline: true),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _InfoRow({required this.icon, required this.label, required this.value, this.multiline = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 15, color: cs.onSurface),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
