/// 装备数据模型
class Equipment {
  final String id;
  final String title;
  final double price;
  final DateTime purchaseDate;
  final String notes;
  final String emoji;
  final String emojiName;

  Equipment({
    required this.id,
    required this.title,
    required this.price,
    required this.purchaseDate,
    this.notes = '',
    this.emoji = '📦',
    this.emojiName = '箱子',
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

  /// 已使用天数
  int get usageDays {
    final days = DateTime.now().difference(purchaseDate).inDays;
    return days < 0 ? 0 : days;
  }

  /// 使用时间描述
  String get usageTime {
    final d = usageDays;
    if (d == 0) return '今天刚买';
    if (d < 30) return '$d天';
    if (d < 365) {
      final m = d ~/ 30;
      final remaining = d % 30;
      return remaining > 0 ? '$m个月$remaining天' : '$m个月';
    }
    final y = d ~/ 365;
    final remaining = d % 365;
    final m = remaining ~/ 30;
    if (m > 0) return '$y年$m个月';
    return '$y年';
  }

  /// 日均价格式化
  String get dailyAverageFormatted {
    return '¥${dailyAverage().toStringAsFixed(1)}/天';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'purchaseDate': purchaseDate.toIso8601String(),
    'notes': notes,
    'emoji': emoji,
    'emojiName': emojiName,
  };

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
    id: json['id'] as String,
    title: json['title'] as String,
    price: (json['price'] as num).toDouble(),
    purchaseDate: DateTime.parse(json['purchaseDate'] as String),
    notes: json['notes'] as String? ?? '',
    emoji: json['emoji'] as String? ?? '📦',
    emojiName: json['emojiName'] as String? ?? '箱子',
  );
}
