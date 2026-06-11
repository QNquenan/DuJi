import 'package:flutter/material.dart';
import '../models/equipment.dart';

/// 装备列表项组件
class EquipmentTile extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const EquipmentTile({
    super.key,
    required this.equipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              // ── 表情图标 ──
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(equipment.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              // ── 信息 ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(equipment.title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(equipment.purchaseDateFormatted,
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              // ── 价格 + 日均 ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('¥${equipment.priceFormatted}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(equipment.dailyAverageFormatted,
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
