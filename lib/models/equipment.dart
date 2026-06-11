/// 装备数据模型
class Equipment {
  final String id;
  final String title;
  final double price;
  final DateTime purchaseDate;
  final String notes;

  Equipment({
    required this.id,
    required this.title,
    required this.price,
    required this.purchaseDate,
    this.notes = '',
  });

  String get priceFormatted {
    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  String get purchaseDateFormatted {
    return '${purchaseDate.year}-${_pad(purchaseDate.month)}-${_pad(purchaseDate.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  /// 均摊每天价格 = price / 已购买天数 (至少1天)
  double dailyAverage() {
    final days = DateTime.now().difference(purchaseDate).inDays;
    final effectiveDays = days < 1 ? 1 : days;
    return price / effectiveDays;
  }
}
