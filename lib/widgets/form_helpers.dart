import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 统一浮动提示
void showStyledSnackBar(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black.withValues(alpha: 0.75),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// 通用底部抽屉选择器
Future<T?> showPickerSheet<T>(
  BuildContext context, {
  required List<(T, String)> items,
  required T currentValue,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      final dcs = Theme.of(ctx).colorScheme;
      return Container(
        decoration: BoxDecoration(
          color: dcs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: dcs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: items.map((item) {
                  final selected = item.$1 == currentValue;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, item.$1),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? dcs.primary.withValues(alpha: 0.12)
                              : dcs.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: selected
                              ? Border.all(color: dcs.primary.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? dcs.primary : dcs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

/// 表单标签
Widget buildLabel(BuildContext context, String text) {
  final cs = Theme.of(context).colorScheme;
  return Text(
    text,
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
  );
}

/// 表单输入框
Widget buildFormField({
  required BuildContext context,
  required TextEditingController controller,
  required String hint,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
  int maxLines = 1,
}) {
  final cs = Theme.of(context).colorScheme;
  final cardColor = Theme.of(context).cardColor;
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    maxLines: maxLines,
    style: TextStyle(color: cs.onSurface, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    ),
    validator: validator,
  );
}

/// 日期显示字段
Widget buildDateField(BuildContext context, String label, VoidCallback onTap) {
  final cs = Theme.of(context).colorScheme;
  final cardColor = Theme.of(context).cardColor;
  return InkWell(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
            ),
          ),
        ],
      ),
    ),
  );
}
