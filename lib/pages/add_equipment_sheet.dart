import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/equipment.dart';
import '../widgets/date_picker_wheel.dart';

/// 添加装备页（全屏页面）
Future<Equipment?> pushAddEquipmentPage(BuildContext context) {
  return Navigator.push<Equipment>(
    context,
    MaterialPageRoute(builder: (_) => const _AddEquipmentPage()),
  );
}

class _AddEquipmentPage extends StatefulWidget {
  const _AddEquipmentPage();

  @override
  State<_AddEquipmentPage> createState() => _AddEquipmentPageState();
}

class _AddEquipmentPageState extends State<_AddEquipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePickerWheel(context, initialDate: _purchaseDate);
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final equipment = Equipment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      purchaseDate: _purchaseDate,
      notes: _notesCtrl.text.trim(),
    );
    Navigator.pop(context, equipment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('添加装备',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ── 名称 ──
            _label('名称'),
            const SizedBox(height: 8),
            _buildField(
              controller: _titleCtrl,
              hint: '请输入装备名称',
              validator: (v) => v == null || v.trim().isEmpty ? '请输入名称' : null,
            ),
            const SizedBox(height: 20),

            // ── 价格 ──
            _label('价格'),
            const SizedBox(height: 8),
            _buildField(
              controller: _priceCtrl,
              hint: '¥ 请输入价格',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入价格';
                if (double.tryParse(v.trim()) == null) return '请输入有效价格';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── 购买日期 ──
            _label('购买日期'),
            const SizedBox(height: 8),
            _buildDateField(),
            const SizedBox(height: 20),

            // ── 备注 ──
            _label('备注'),
            const SizedBox(height: 8),
            _buildField(
              controller: _notesCtrl,
              hint: '选填，装备备注信息',
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // ── 添加按钮 ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('添加', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87));
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 10),
            Text(
              '${_purchaseDate.year}-${_purchaseDate.month.toString().padLeft(2, '0')}-${_purchaseDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
