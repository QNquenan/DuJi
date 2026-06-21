import 'package:flutter/services.dart';

/// 价格输入格式化器 — 兼容中文输入法
/// 标准 [FilteringTextInputFormatter.digitsOnly] 会在 IME 组合输入时拒绝字符，
/// 导致某些输入法崩溃。此实现允许组合范围（composing range）通过。
/// 允许数字和一个小数点。
class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // 如果 IME 正在组合输入中，让所有字符通过
    if (newValue.composing.isValid) return newValue;

    // 只保留数字和一个小数点
    final filtered = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    // 确保最多一个小数点
    final parts = filtered.split('.');
    final result = parts.length > 2
        ? '${parts.first}.${parts.sublist(1).join()}'
        : filtered;

    // 不允许以小数点开头
    if (result == '.') return const TextEditingValue(text: '');

    if (result == newValue.text) return newValue;

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
