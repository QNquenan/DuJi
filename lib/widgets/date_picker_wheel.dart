import 'package:flutter/material.dart';

/// 三列滚轮日期选择器弹窗（年 / 月 / 日）
Future<DateTime?> showDatePickerWheel(BuildContext context, {DateTime? initialDate}) {
  final now = DateTime.now();
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _DatePickerDialog(initialDate: initialDate ?? now),
  );
}

class _DatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const _DatePickerDialog({required this.initialDate});

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  static const _minYear = 2000;
  late final int _maxYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;

    _yearCtrl = FixedExtentScrollController(initialItem: _selectedYear - _minYear);
    _monthCtrl = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _selectedDay - 1);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择日期', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            // 三列滚轮
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 选中遮罩
                  IgnorePointer(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.symmetric(
                          horizontal: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // 年
                      Expanded(flex: 2, child: _buildWheel(_yearCtrl, _maxYear - _minYear + 1, (i) => '${_minYear + i}', (i) => setState(() => _selectedYear = _minYear + i))),
                      const Padding(padding: EdgeInsets.only(bottom: 2), child: Text('年', style: TextStyle(fontSize: 15, color: Colors.black87))),
                      // 月
                      Expanded(flex: 1, child: _buildWheel(_monthCtrl, 12, (i) => '${i + 1}', (i) => setState(() => _selectedMonth = i + 1))),
                      const Padding(padding: EdgeInsets.only(bottom: 2), child: Text('月', style: TextStyle(fontSize: 15, color: Colors.black87))),
                      // 日
                      Expanded(flex: 1, child: _buildWheel(_dayCtrl, _daysInMonth(_selectedYear, _selectedMonth), (i) => '${i + 1}', (i) => setState(() => _selectedDay = i + 1))),
                      const Padding(padding: EdgeInsets.only(bottom: 2), child: Text('日', style: TextStyle(fontSize: 15, color: Colors.black87))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
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
                onPressed: () => Navigator.pop(context, DateTime(_selectedYear, _selectedMonth, _selectedDay)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('确定', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWheel(
    FixedExtentScrollController controller,
    int itemCount,
    String Function(int) label,
    ValueChanged<int> onChanged,
  ) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 40,
      perspective: 0.002,
      diameterRatio: 1.6,
      squeeze: 1.15,
      overAndUnderCenterOpacity: 0.3,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (_, i) => Center(
          child: Text(
            label(i),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
