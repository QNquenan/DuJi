import 'package:flutter/material.dart';

/// 统计卡片组件 —— 深色背景、三列数据
class StatsCardWidget extends StatelessWidget {
  final int equipmentCount;
  final double totalValue;
  final double averagePrice;

  const StatsCardWidget({
    super.key,
    required this.equipmentCount,
    required this.totalValue,
    required this.averagePrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我的物品',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: '物品价值',
                  value: equipmentCount > 0 ? '¥${totalValue.round()}' : '¥0',
                ),
              ),
              Expanded(
                child: _StatColumn(label: '物品数量', value: '$equipmentCount'),
              ),
              Expanded(
                child: _StatColumn(
                  label: '总日均价格',
                  value: equipmentCount > 0 ? '¥${averagePrice.round()}' : '¥0',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
