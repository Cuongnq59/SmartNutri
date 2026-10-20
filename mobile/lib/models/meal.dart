class MealComponent {
  String name;
  double weightG;
  double calories;
  double proteinG;
  double carbsG;
  double fatG;

  MealComponent({
    required this.name,
    required this.weightG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory MealComponent.fromJson(Map<String, dynamic> json) {
    return MealComponent(
      name: json['name'] ?? 'Thành phần',
      weightG: (json['estimated_weight_g'] ?? json['weightG'] ?? 100.0).toDouble(),
      calories: (json['calories'] ?? 150.0).toDouble(),
      proteinG: (json['protein_g'] ?? json['protein'] ?? 10.0).toDouble(),
      carbsG: (json['carbs_g'] ?? json['carbs'] ?? 15.0).toDouble(),
      fatG: (json['fat_g'] ?? json['fat'] ?? 5.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'itemName': name,
      'weightG': weightG,
      'estimated_weight_g': weightG,
      'calories': calories,
      'protein': proteinG,
      'protein_g': proteinG,
      'carbs': carbsG,
      'carbs_g': carbsG,
      'fat': fatG,
      'fat_g': fatG,
    };
  }
}

class Meal {
  final int? id;
  final String dishName;
  final String mealType;
  final String? imageUrl;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double cost;
  final String? healthNote;
  final DateTime createdAt;
  final List<MealComponent> items;

  Meal({
    this.id,
    required this.dishName,
    required this.mealType,
    this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.cost,
    this.healthNote,
    required this.createdAt,
    this.items = const [],
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    List<MealComponent> compList = [];
    if (json['items'] != null && json['items'] is List) {
      compList = (json['items'] as List)
          .map((i) => MealComponent.fromJson(i))
          .toList();
    }

    return Meal(
      id: json['id'],
      dishName: json['dishName'] ?? 'Bữa ăn',
      mealType: json['mealType'] ?? 'LUNCH',
      imageUrl: json['imageUrl'],
      calories: (json['totalCalories'] ?? 0.0).toDouble(),
      protein: (json['totalProtein'] ?? 0.0).toDouble(),
      carbs: (json['totalCarbs'] ?? 0.0).toDouble(),
      fat: (json['totalFat'] ?? 0.0).toDouble(),
      cost: (json['cost'] ?? 0.0).toDouble(),
      healthNote: json['healthNote'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      items: compList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'dishName': dishName,
      'mealType': mealType,
      'imageUrl': imageUrl,
      'totalCalories': calories,
      'totalProtein': protein,
      'totalCarbs': carbs,
      'totalFat': fat,
      'cost': cost,
      'healthNote': healthNote,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class MealAnalysisResult {
  final String dishName;
  final double confidenceScore;
  final double estimatedWeightG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<MealComponent> components;
  final String healthNote;

  MealAnalysisResult({
    required this.dishName,
    required this.confidenceScore,
    required this.estimatedWeightG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.components,
    required this.healthNote,
  });

  factory MealAnalysisResult.fromJson(Map<String, dynamic> json) {
    final summary = json['nutritionSummary'] ?? json['nutrition_summary'] ?? {};
    final compJson = json['components'] as List? ?? [];
    final comps = compJson.map((c) => MealComponent.fromJson(c)).toList();

    return MealAnalysisResult(
      dishName: json['dish_name'] ?? json['dishName'] ?? 'Đĩa cơm Việt',
      confidenceScore: (json['confidence_score'] ?? json['confidence'] ?? 0.95).toDouble(),
      estimatedWeightG: (json['estimated_weight_g'] ?? json['estimatedWeightG'] ?? 450.0).toDouble(),
      calories: (summary['calories'] ?? 600.0).toDouble(),
      proteinG: (summary['protein_g'] ?? summary['proteinG'] ?? 30.0).toDouble(),
      carbsG: (summary['carbs_g'] ?? summary['carbsG'] ?? 70.0).toDouble(),
      fatG: (summary['fat_g'] ?? summary['fatG'] ?? 20.0).toDouble(),
      components: comps,
      healthNote: json['health_note'] ?? json['healthNote'] ?? '',
    );
  }
}
