class OptimizedItem {
  final String name;
  final double portion;
  final String unit;
  final double cost;
  final double protein;
  final double calories;
  final bool fromPantry;

  OptimizedItem({
    required this.name,
    required this.portion,
    required this.unit,
    required this.cost,
    required this.protein,
    required this.calories,
    required this.fromPantry,
  });

  factory OptimizedItem.fromJson(Map<String, dynamic> json) {
    return OptimizedItem(
      name: json['name'] ?? '',
      portion: (json['portion'] ?? 1.0).toDouble(),
      unit: json['unit'] ?? '',
      cost: (json['cost'] ?? 0.0).toDouble(),
      protein: (json['protein'] ?? 0.0).toDouble(),
      calories: (json['calories'] ?? 0.0).toDouble(),
      fromPantry: json['fromPantry'] ?? false,
    );
  }
}

class OptimizerResult {
  final bool isFeasible;
  final double totalCost;
  final double totalProtein;
  final double totalCalories;
  final List<OptimizedItem> items;
  final String shoppingAdvice;
  final String statusMessage;
  final double shortfallProtein;
  final double neededExtraBudget;

  OptimizerResult({
    required this.isFeasible,
    required this.totalCost,
    required this.totalProtein,
    required this.totalCalories,
    required this.items,
    required this.shoppingAdvice,
    required this.statusMessage,
    required this.shortfallProtein,
    required this.neededExtraBudget,
  });

  factory OptimizerResult.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return OptimizerResult(
      isFeasible: json['isFeasible'] ?? true,
      totalCost: (json['totalCost'] ?? 0.0).toDouble(),
      totalProtein: (json['totalProtein'] ?? 0.0).toDouble(),
      totalCalories: (json['totalCalories'] ?? 0.0).toDouble(),
      items: list.map((i) => OptimizedItem.fromJson(i)).toList(),
      shoppingAdvice: json['shoppingAdvice'] ?? '',
      statusMessage: json['statusMessage'] ?? '',
      shortfallProtein: (json['shortfallProtein'] ?? 0.0).toDouble(),
      neededExtraBudget: (json['neededExtraBudget'] ?? 0.0).toDouble(),
    );
  }
}
