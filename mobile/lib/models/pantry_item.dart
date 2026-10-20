class PantryItem {
  final int? id;
  final String customName;
  final String? rawName;
  final double quantity;
  final String unit;
  final double costPaid;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final String status;

  PantryItem({
    this.id,
    required this.customName,
    this.rawName,
    required this.quantity,
    required this.unit,
    required this.costPaid,
    required this.purchaseDate,
    this.expiryDate,
    this.status = 'ACTIVE',
  });

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'],
      customName: json['customName'] ?? 'Nguyên liệu',
      rawName: json['rawName'],
      quantity: (json['quantity'] ?? 1.0).toDouble(),
      unit: json['unit'] ?? 'pack',
      costPaid: (json['costPaid'] ?? 0.0).toDouble(),
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.tryParse(json['purchaseDate']) ?? DateTime.now()
          : DateTime.now(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'])
          : null,
      status: json['status'] ?? 'ACTIVE',
    );
  }

  int get daysUntilExpiry {
    if (expiryDate == null) return 999;
    final now = DateTime.now();
    return expiryDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}

class ReceiptItem {
  final String rawName;
  final String cleanName;
  final String category;
  double quantity;
  final String unit;
  final double totalPrice;
  final int? matchedRefId;
  final String expiryDate;
  bool selected;

  ReceiptItem({
    required this.rawName,
    required this.cleanName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.totalPrice,
    this.matchedRefId,
    required this.expiryDate,
    this.selected = true,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      rawName: json['rawName'] ?? '',
      cleanName: json['cleanName'] ?? '',
      category: json['category'] ?? 'FOOD',
      quantity: (json['quantity'] ?? 1.0).toDouble(),
      unit: json['unit'] ?? 'pack',
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      matchedRefId: json['matchedRefId'],
      expiryDate: json['expiryDate'] ?? '',
      selected: json['selected'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rawName': rawName,
      'cleanName': cleanName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'totalPrice': totalPrice,
      'matchedRefId': matchedRefId,
      'expiryDate': expiryDate,
      'selected': selected,
    };
  }
}

class ReceiptScanResult {
  final String merchantName;
  final String purchaseDate;
  final double totalAmount;
  final double foodAmount;
  final List<ReceiptItem> items;

  ReceiptScanResult({
    required this.merchantName,
    required this.purchaseDate,
    required this.totalAmount,
    required this.foodAmount,
    required this.items,
  });

  factory ReceiptScanResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['items'] as List? ?? [];
    return ReceiptScanResult(
      merchantName: json['merchantName'] ?? 'WinMart+',
      purchaseDate: json['purchaseDate'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      foodAmount: (json['foodAmount'] ?? 0.0).toDouble(),
      items: rawList.map((i) => ReceiptItem.fromJson(i)).toList(),
    );
  }
}

class SmartRecipe {
  final String title;
  final String cookingTime;
  final String equipment;
  final List<String> ingredientsUsed;
  final double proteinG;
  final double calories;
  final List<String> instructions;

  SmartRecipe({
    required this.title,
    required this.cookingTime,
    required this.equipment,
    required this.ingredientsUsed,
    required this.proteinG,
    required this.calories,
    required this.instructions,
  });

  factory SmartRecipe.fromJson(Map<String, dynamic> json) {
    return SmartRecipe(
      title: json['title'] ?? 'Món ăn nhanh',
      cookingTime: json['cookingTime'] ?? '15 phút',
      equipment: json['equipment'] ?? 'Chảo chống dính',
      ingredientsUsed: List<String>.from(json['ingredientsUsed'] ?? []),
      proteinG: (json['proteinG'] ?? 20.0).toDouble(),
      calories: (json['calories'] ?? 300.0).toDouble(),
      instructions: List<String>.from(json['instructions'] ?? []),
    );
  }
}
