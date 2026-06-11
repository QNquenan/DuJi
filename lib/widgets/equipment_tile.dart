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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              // ── 图标 ──
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.backpack_outlined, color: Colors.black87, size: 22),
              ),
              const SizedBox(width: 14),
              // ── 信息 ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(equipment.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(equipment.purchaseDateFormatted,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
              // ── 价格 ──
              Text('¥${equipment.priceFormatted}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
