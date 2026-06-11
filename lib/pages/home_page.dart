import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/equipment_tile.dart';
import 'add_equipment_sheet.dart';
import 'equipment_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Equipment> _equipmentList = [];

  double get _totalValue => _equipmentList.fold(0, (s, e) => s + e.price);

  /// 均摊价格 = 所有装备的单日均价之和 / 装备数量
  double get _averagePrice {
    if (_equipmentList.isEmpty) return 0;
    final totalDaily = _equipmentList.fold<double>(0, (s, e) => s + e.dailyAverage());
    return totalDaily / _equipmentList.length;
  }

  Future<void> _addEquipment() async {
    final equipment = await pushAddEquipmentPage(context);
    if (equipment != null) {
      setState(() => _equipmentList.add(equipment));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('添加成功', style: TextStyle(color: Colors.black87)),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openDetail(int index) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EquipmentDetailPage(equipment: _equipmentList[index])),
    );
    if (deleted == true) {
      setState(() => _equipmentList.removeAt(index));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('删除成功', style: TextStyle(color: Colors.black87)),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('嘟迹', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black54, size: 24), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings, color: Colors.black54, size: 24), onPressed: () {}),
        ],
      ),
      body: RepaintBoundary(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatsCardWidget(
                equipmentCount: _equipmentList.length,
                totalValue: _totalValue,
                averagePrice: _averagePrice,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('装备列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 12),
              if (_equipmentList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('还没有装备，点击右下角 + 添加',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _equipmentList.length,
                  itemBuilder: (context, index) => EquipmentTile(
                    equipment: _equipmentList[index],
                    onTap: () => _openDetail(index),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEquipment,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
