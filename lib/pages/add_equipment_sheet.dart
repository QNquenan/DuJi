import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../utils/input_formatters.dart' show PriceInputFormatter;
import '../widgets/date_picker_lunar.dart';
import '../widgets/emoji_picker_sheet.dart';
import '../widgets/form_helpers.dart';

/// 添加物品页（全屏页面）
Future<Equipment?> pushAddEquipmentPage(BuildContext context) {
  return Navigator.push<Equipment>(
    context,
    MaterialPageRoute(builder: (_) => const _EquipmentFormPage()),
  );
}

/// 编辑物品页（全屏页面）
Future<Equipment?> pushEditEquipmentPage(BuildContext context, Equipment equipment) {
  return Navigator.push<Equipment>(
    context,
    MaterialPageRoute(builder: (_) => _EquipmentFormPage(existing: equipment)),
  );
}

class _EquipmentFormPage extends StatefulWidget {
  final Equipment? existing;
  const _EquipmentFormPage({this.existing});

  @override
  State<_EquipmentFormPage> createState() => _EquipmentFormPageState();
}

class _EquipmentFormPageState extends State<_EquipmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late DateTime _purchaseDate;
  late String _emoji;
  late String _emojiName;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _priceCtrl.text = e.price.toStringAsFixed(2);
      _notesCtrl.text = e.notes;
      _purchaseDate = e.purchaseDate;
      _emoji = e.emoji;
      _emojiName = e.emojiName;
    } else {
      _purchaseDate = DateTime.now();
      _emoji = '📦';
      _emojiName = '箱子';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showLunarDatePicker(context, initialDate: _purchaseDate);
    if (result != null && mounted) setState(() => _purchaseDate = result.solarDate);
  }

  Future<void> _pickEmoji() async {
    final option = await showEmojiPicker(context);
    if (option != null && mounted) {
      setState(() {
        _emoji = option.emoji;
        _emojiName = option.name;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final equipment = Equipment(
      id: _isEditing ? widget.existing!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      purchaseDate: _purchaseDate,
      notes: _notesCtrl.text.trim(),
      emoji: _emoji,
      emojiName: _emojiName,
    );
    Navigator.pop(context, equipment);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? '编辑物品' : '添加物品',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // ── 表情封面 ──
            Center(
              child: GestureDetector(
                onTap: _pickEmoji,
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      alignment: Alignment.center,
                      child: Text(_emoji, style: const TextStyle(fontSize: 38)),
                    ),
                    const SizedBox(height: 6),
                    Text(_emojiName, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── 名称 ──
            buildLabel(context, '名称'),
            const SizedBox(height: 8),
            buildFormField(
              context: context,
              controller: _titleCtrl,
              hint: '请输入物品名称',
              validator: (v) => v == null || v.trim().isEmpty ? '请输入名称' : null,
            ),
            const SizedBox(height: 20),

            // ── 价格 ──
            buildLabel(context, '价格'),
            const SizedBox(height: 8),
            buildFormField(
              context: context,
              controller: _priceCtrl,
              hint: '¥ 请输入价格',
              keyboardType: TextInputType.number,
              inputFormatters: [PriceInputFormatter()],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入价格';
                if (double.tryParse(v.trim()) == null) return '请输入有效价格';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── 购买日期 ──
            buildLabel(context, '购买日期'),
            const SizedBox(height: 8),
            buildDateField(
              context,
              '${_purchaseDate.year}-${_purchaseDate.month.toString().padLeft(2, '0')}-${_purchaseDate.day.toString().padLeft(2, '0')}',
              _pickDate,
            ),
            const SizedBox(height: 20),

            // ── 备注 ──
            buildLabel(context, '备注'),
            const SizedBox(height: 8),
            buildFormField(context: context, controller: _notesCtrl, hint: '选填，物品备注信息', maxLines: 3),
            const SizedBox(height: 32),

            // ── 按钮 ──
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
                child: Text(
                  _isEditing ? '保存修改' : '添加',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
