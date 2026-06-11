import 'package:flutter/services.dart';

/// 纯数字输入格式化器 — 兼容中文输入法
/// 标准 [FilteringTextInputFormatter.digitsOnly] 会在 IME 组合输入时拒绝字符，
/// 导致某些输入法崩溃。此实现允许组合范围（composing range）通过。
class DigitsOnlyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // 如果 IME 正在组合输入中，让所有字符通过
    if (newValue.composing.isValid) return newValue;

    // 只保留数字
    final filtered = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (filtered == newValue.text) return newValue;

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}
