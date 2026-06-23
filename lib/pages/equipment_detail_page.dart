import 'package:flutter/material.dart';
import '../models/equipment.dart';
import 'add_equipment_sheet.dart';

/// 物品详情页 — 返回 true(删除) 或 Equipment(编辑) 或 null(无变化)
class EquipmentDetailPage extends StatefulWidget {
  final Equipment equipment;
  const EquipmentDetailPage({super.key, required this.equipment});

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  late Equipment _equipment;

  @override
  void initState() {
    super.initState();
    _equipment = widget.equipment;
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final dcs = theme.colorScheme;
        return AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 40, color: dcs.error),
              const SizedBox(height: 16),
              const Text(
                '确认删除',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '确定要删除「${_equipment.title}」吗？',
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '删除',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
    final updated = await pushEditEquipmentPage(context, _equipment);
    if (updated != null && mounted) {
      setState(() => _equipment = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('编辑成功', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black.withValues(alpha: 0.75),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _equipment);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '物品详情',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 20, color: cs.onSurface),
            onPressed: () => Navigator.pop(context, _equipment),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: cs.onSurfaceVariant,
                size: 22,
              ),
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
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // ── 表情封面（不显示名称）──
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _equipment.emoji,
                        style: const TextStyle(fontSize: 38),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _equipment.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '¥${_equipment.priceFormatted}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: '购买日期',
                      value: _equipment.purchaseDateFormatted,
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      label: '使用时间',
                      value: _equipment.usageTime,
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.trending_down,
                      label: '日均价格',
                      value: _equipment.dailyAverageFormatted,
                    ),
                    if (_equipment.notes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Divider(height: 1),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.article_outlined,
                        label: '备注',
                        value: _equipment.notes,
                        multiline: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
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

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: multiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
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
