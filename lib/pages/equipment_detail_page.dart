import 'package:flutter/material.dart';
import '../models/equipment.dart';

/// 装备详情页
class EquipmentDetailPage extends StatelessWidget {
  final Equipment equipment;

  const EquipmentDetailPage({super.key, required this.equipment});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, size: 40, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text('确认删除', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('确定要删除「${equipment.title}」吗？',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
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
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey.shade700,
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
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('装备详情',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            onPressed: () => _confirmDelete(context),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  // ── 图标 ──
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.backpack_outlined, size: 36, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Text(equipment.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('¥${equipment.priceFormatted}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.black)),
                  const SizedBox(height: 24),
                  _InfoRow(icon: Icons.calendar_today, label: '购买日期', value: equipment.purchaseDateFormatted),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 14),
                  _InfoRow(icon: Icons.person_outline, label: '所属', value: '我的装备'),
                  if (equipment.notes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 14),
                    _InfoRow(icon: Icons.article_outlined, label: '备注', value: equipment.notes, multiline: true),
                  ],
                ],
              ),
            ),
          ],
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
    return Row(
      crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
