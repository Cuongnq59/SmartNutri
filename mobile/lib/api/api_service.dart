import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import '../models/pantry_item.dart';
import '../models/dashboard_stats.dart';
import '../models/optimizer_result.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, localhost for Web and desktop
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    return 'http://10.0.2.2:8080/api';
  }

  static const Duration timeoutDuration = Duration(seconds: 5);

  // 1. Dashboard Stats
  static Future<DashboardStats> getDashboardStats([int userId = 1]) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/dashboard/stats?userId=$userId'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return DashboardStats.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      debugPrint('API Error getDashboardStats: $e. Using local fallback.');
    }
    return mockDashboardStats();
  }

  // 2. Vision AI - Analyze Meal
  static Future<MealAnalysisResult> analyzeMeal(String base64Image, [String mimeType = 'image/jpeg']) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vision/analyze-meal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'base64Image': base64Image,
          'mimeType': mimeType,
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return MealAnalysisResult.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      debugPrint('API Error analyzeMeal: $e. Using local mock dish.');
    }
    return _mockMealAnalysis();
  }

  // 3. Quick Adjust Macros
  static Future<MealAnalysisResult> quickAdjust(List<MealComponent> components) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vision/quick-adjust'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'components': components.map((c) => c.toJson()).toList(),
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return MealAnalysisResult.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      debugPrint('API Error quickAdjust: $e');
    }

    // Local calculation
    double cal = 0, pro = 0, carb = 0, fat = 0, weight = 0;
    for (var c in components) {
      cal += c.calories;
      pro += c.proteinG;
      carb += c.carbsG;
      fat += c.fatG;
      weight += c.weightG;
    }
    return MealAnalysisResult(
      dishName: 'Món ăn đã điều chỉnh',
      confidenceScore: 1.0,
      estimatedWeightG: weight,
      calories: cal,
      proteinG: pro,
      carbsG: carb,
      fatG: fat,
      components: components,
      healthNote: pro >= 30 ? 'Lượng đạm rất dồi dào, phù hợp mục tiêu thể trạng!' : 'Khẩu phần vừa phải, hãy ăn thêm rau xanh.',
    );
  }

  static final ValueNotifier<int> refreshDashboardNotifier = ValueNotifier<int>(0);
  static final List<Meal> _localLoggedMeals = [];

  // 4. Log Meal
  static Future<bool> logMeal(Meal meal, {bool deductFromPantry = false, int userId = 1}) async {
    _localLoggedMeals.insert(0, meal);
    refreshDashboardNotifier.value++;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meals?userId=$userId&deductFromPantry=$deductFromPantry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(meal.toJson()),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        refreshDashboardNotifier.value++;
        return true;
      }
    } catch (e) {
      debugPrint('API Error logMeal: $e');
    }
    return true; // Treat as saved locally
  }

  // 5. Scan Receipt OCR
  static Future<ReceiptScanResult> scanReceipt(String base64Image, [String mimeType = 'image/jpeg']) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/receipts/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'base64Image': base64Image,
          'mimeType': mimeType,
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return ReceiptScanResult.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      debugPrint('API Error scanReceipt: $e');
    }
    return _mockReceiptScanResult();
  }

  // 6. Confirm Receipt
  static Future<bool> confirmReceipt({
    required String merchantName,
    required String purchaseDate,
    required double totalAmount,
    required List<ReceiptItem> items,
    int userId = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/receipts/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'merchantName': merchantName,
          'purchaseDate': purchaseDate,
          'totalAmount': totalAmount,
          'items': items.map((i) => i.toJson()).toList(),
        }),
      ).timeout(timeoutDuration);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API Error confirmReceipt: $e');
      return true;
    }
  }

  // 7. Virtual Pantry
  static Future<List<PantryItem>> getPantryItems([int userId = 1]) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/pantry?userId=$userId'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        return list.map((i) => PantryItem.fromJson(i)).toList();
      }
    } catch (e) {
      debugPrint('API Error getPantryItems: $e');
    }
    return _mockPantryItems();
  }

  static Future<bool> consumePantryItem(int id, [double? quantity]) async {
    try {
      final uri = quantity != null
          ? Uri.parse('$baseUrl/pantry/consume/$id?quantity=$quantity')
          : Uri.parse('$baseUrl/pantry/consume/$id');
      final res = await http.post(uri).timeout(timeoutDuration);
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 8. Smart Leftovers
  static Future<List<SmartRecipe>> getSmartLeftovers([int userId = 1]) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/pantry/smart-leftovers?userId=$userId'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        return list.map((r) => SmartRecipe.fromJson(r)).toList();
      }
    } catch (e) {
      debugPrint('API Error getSmartLeftovers: $e');
    }
    return _mockSmartRecipes();
  }

  // 9. Target Budget Meal Optimizer (MILP)
  static Future<OptimizerResult> optimizeMeal({
    required double targetProtein,
    required double minCalories,
    required double maxCalories,
    required double maxBudget,
    bool usePantry = true,
    int userId = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/optimizer/target-meal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'targetProtein': targetProtein,
          'minCalories': minCalories,
          'maxCalories': maxCalories,
          'maxBudget': maxBudget,
          'usePantryItems': usePantry,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return OptimizerResult.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      debugPrint('API Error optimizeMeal: $e');
    }

    return _mockOptimizerResult(targetProtein, maxBudget, usePantry);
  }

  // Fallback Mock Generators
  static DashboardStats mockDashboardStats() {
    final sampleMeals = [
      Meal(
        id: 1,
        dishName: 'Cơm tấm sườn bì chả trứng',
        mealType: 'LUNCH',
        calories: 745.0,
        protein: 42.5,
        carbs: 82.0,
        fat: 26.0,
        cost: 45000.0,
        healthNote: 'Bữa trưa giàu đạm và năng lượng phục vụ tập luyện.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        items: [
          MealComponent(name: 'Cơm tấm', weightG: 200, calories: 260, proteinG: 5.0, carbsG: 58, fatG: 0.6),
          MealComponent(name: 'Sườn nướng', weightG: 120, calories: 290, proteinG: 25.0, carbsG: 4, fatG: 19.0),
          MealComponent(name: 'Chả trứng hấp', weightG: 60, calories: 110, proteinG: 7.5, carbsG: 2, fatG: 8.0),
        ],
      ),
      Meal(
        id: 2,
        dishName: 'Bánh mì pate trứng ốp la',
        mealType: 'BREAKFAST',
        calories: 520.0,
        protein: 24.5,
        carbs: 58.0,
        fat: 19.0,
        cost: 25000.0,
        healthNote: 'Bữa sáng nhanh, nạp đạm tốt.',
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      ),
    ];

    double extraCal = 0, extraPro = 0, extraCarb = 0, extraFat = 0, extraCost = 0;
    for (var m in _localLoggedMeals) {
      extraCal += m.calories;
      extraPro += m.protein;
      extraCarb += m.carbs;
      extraFat += m.fat;
      extraCost += m.cost;
    }

    final combinedRecent = [..._localLoggedMeals, ...sampleMeals];

    return DashboardStats(
      userName: 'Nguyễn Văn An',
      goalType: 'BULK',
      todayCaloriesConsumed: 1650.0 + extraCal,
      todayCaloriesTarget: 2200.0,
      todayProteinConsumed: 88.0 + extraPro,
      todayProteinTarget: 120.0,
      todayCarbsConsumed: 195.0 + extraCarb,
      todayCarbsTarget: 280.0,
      todayFatConsumed: 48.0 + extraFat,
      todayFatTarget: 65.0,
      weeklyBudget: 450000.0,
      weeklySpent: 165000.0 + extraCost,
      weeklyRemaining: (285000.0 - extraCost).clamp(0.0, 450000.0),
      dailyRemainingBudget: 57000.0,
      burnRateStatus: 'NORMAL',
      burnRateMessage: 'Tiến độ chi tiêu ổn định.',
      cpgpIndexVnd: 460.0,
      cpgpEvaluation: 'Mức độ hợp lý (460đ/g đạm)',
      activePantryCount: 3,
      expiringPantryCount: 1,
      recentMeals: combinedRecent,
    );
  }

  static MealAnalysisResult _mockMealAnalysis() {
    return MealAnalysisResult(
      dishName: 'Cơm tấm sườn bì chả trứng',
      confidenceScore: 0.96,
      estimatedWeightG: 480.0,
      calories: 745.0,
      proteinG: 42.5,
      carbsG: 82.0,
      fatG: 26.0,
      components: [
        MealComponent(name: 'Cơm tấm chín', weightG: 200, calories: 260, proteinG: 5.0, carbsG: 58, fatG: 0.6),
        MealComponent(name: 'Sườn heo nướng', weightG: 120, calories: 290, proteinG: 25.0, carbsG: 4, fatG: 19.0),
        MealComponent(name: 'Chả trứng hấp', weightG: 60, calories: 110, proteinG: 7.5, carbsG: 2, fatG: 8.0),
        MealComponent(name: 'Bì lợn trộn thính', weightG: 30, calories: 55, proteinG: 4.0, carbsG: 3, fatG: 2.5),
        MealComponent(name: 'Dưa leo & cà chua', weightG: 70, calories: 30, proteinG: 1.0, carbsG: 15, fatG: 0.2),
      ],
      healthNote: 'Bữa ăn giàu đạm. Khuyên dùng thêm một chén canh chua để cân bằng vi chất.',
    );
  }

  static ReceiptScanResult _mockReceiptScanResult() {
    final now = DateTime.now();
    return ReceiptScanResult(
      merchantName: 'WinMart+ Thăng Long',
      purchaseDate: now.toString().split(' ')[0],
      totalAmount: 99000.0,
      foodAmount: 84000.0,
      items: [
        ReceiptItem(rawName: 'UC GA PHI LE CP 500G', cleanName: 'Ức gà phi lê', category: 'FOOD', quantity: 500, unit: 'g', totalPrice: 38000, expiryDate: now.add(const Duration(days: 3)).toString().split(' ')[0], selected: true),
        ReceiptItem(rawName: 'TRUNG GA CP HOP 10Q', cleanName: 'Trứng gà công nghiệp', category: 'FOOD', quantity: 10, unit: 'piece', totalPrice: 28000, expiryDate: now.add(const Duration(days: 21)).toString().split(' ')[0], selected: true),
        ReceiptItem(rawName: 'DAU PHU MO 2 BIA', cleanName: 'Đậu phụ Mơ', category: 'FOOD', quantity: 2, unit: 'piece', totalPrice: 8000, expiryDate: now.add(const Duration(days: 3)).toString().split(' ')[0], selected: true),
        ReceiptItem(rawName: 'RAU MUONG LANG 500G', cleanName: 'Rau muống', category: 'FOOD', quantity: 500, unit: 'g', totalPrice: 10000, expiryDate: now.add(const Duration(days: 4)).toString().split(' ')[0], selected: true),
        ReceiptItem(rawName: 'KHAN GIAY PULPY 3 LOP', cleanName: 'Khăn giấy Pulpy', category: 'NON_FOOD', quantity: 1, unit: 'pack', totalPrice: 15000, expiryDate: now.add(const Duration(days: 365)).toString().split(' ')[0], selected: false),
      ],
    );
  }

  static List<PantryItem> _mockPantryItems() {
    final now = DateTime.now();
    return [
      PantryItem(
        id: 1,
        customName: 'Ức gà phi lê CP',
        rawName: 'UC GA PHI LE',
        quantity: 250.0,
        unit: 'g',
        costPaid: 19000.0,
        purchaseDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 2)), // Sắp hết hạn!
      ),
      PantryItem(
        id: 2,
        customName: 'Trứng gà Ba Huân',
        rawName: 'TRUNG GA CP',
        quantity: 4.0,
        unit: 'quả',
        costPaid: 11200.0,
        purchaseDate: now.subtract(const Duration(days: 2)),
        expiryDate: now.add(const Duration(days: 19)),
      ),
      PantryItem(
        id: 3,
        customName: 'Đậu phụ Mơ',
        rawName: 'DAU PHU MO',
        quantity: 2.0,
        unit: 'bìa',
        costPaid: 8000.0,
        purchaseDate: now,
        expiryDate: now.add(const Duration(days: 3)),
      ),
    ];
  }

  static List<SmartRecipe> _mockSmartRecipes() {
    return [
      SmartRecipe(
        title: 'Đậu phụ sốt trứng cà chua (Chảo chống dính)',
        cookingTime: '12 phút',
        equipment: 'Chảo chống dính',
        ingredientsUsed: ['Đậu phụ Mơ', 'Trứng gà', 'Cà chua'],
        proteinG: 26.5,
        calories: 340.0,
        instructions: [
          '1. Cắt đậu thành miếng vuông vừa ăn, áp chảo 4 phút cho vàng đều.',
          '2. Đập 2 quả trứng gà vào bát, khuấy đều với chút nước mắm và tiêu.',
          '3. Đổ trứng vào chảo đậu, đậy vung nhỏ lửa 3 phút cho trứng chín xốp.',
          '4. Rắc hành lá, ăn nóng kèm cơm.',
        ],
      ),
      SmartRecipe(
        title: 'Ức gà áp chảo tiêu chanh nhanh gọn',
        cookingTime: '15 phút',
        equipment: 'Chảo chống dính',
        ingredientsUsed: ['Ức gà phi lê', 'Tiêu', 'Chanh'],
        proteinG: 38.0,
        calories: 220.0,
        instructions: [
          '1. Thái ức gà thành lát mỏng vừa, khứa nhẹ để thấm vị.',
          '2. Ướp nhanh với chút nước mắm, tiêu đen, tỏi băm trong 5 phút.',
          '3. Quét lớp dầu mỏng lên chảo, áp chảo mỗi mặt 4-5 phút cho vàng óng.',
          '4. Vắt chút chanh lên bề mặt trước khi thưởng thức.',
        ],
      ),
    ];
  }

  static OptimizerResult _mockOptimizerResult(double targetProtein, double maxBudget, bool usePantry) {
    if (maxBudget < 20000 && targetProtein > 40) {
      return OptimizerResult(
        isFeasible: false,
        totalCost: 27000.0,
        totalProtein: 48.0,
        totalCalories: 620.0,
        items: [],
        shoppingAdvice: 'Ngân sách ${maxBudget.toInt()}đ chưa đủ để nạp ${targetProtein.toInt()}g protein. Cần thêm tối thiểu ${(27000 - maxBudget).toInt()} VNĐ.',
        statusMessage: 'Ngân sách chưa đủ.',
        shortfallProtein: 0.0,
        neededExtraBudget: (27000 - maxBudget),
      );
    }

    return OptimizerResult(
      isFeasible: true,
      totalCost: 27000.0,
      totalProtein: 68.0,
      totalCalories: 645.0,
      items: [
        OptimizedItem(name: 'Ức gà phi lê', portion: 2.0, unit: 'lạng (100g)', cost: 13000.0, protein: 46.0, calories: 250.0, fromPantry: false),
        OptimizedItem(name: 'Đậu phụ Mơ', portion: 2.0, unit: 'bìa', cost: 8000.0, protein: 16.0, calories: 180.0, fromPantry: false),
        OptimizedItem(name: 'Trứng gà', portion: 2.0, unit: 'quả', cost: 6000.0, protein: 13.0, calories: 144.0, fromPantry: false),
      ],
      shoppingAdvice: 'Gợi ý mua sắm: Mua 2 lạng ức gà (13k) + 2 bìa đậu (8k) + 2 quả trứng (6k) = 27k VNĐ ➔ Cung cấp 68g protein & 645 kcal.',
      statusMessage: 'Đã tìm thấy thực đơn tối ưu chi phí thành công!',
      shortfallProtein: 0.0,
      neededExtraBudget: 0.0,
    );
  }

  // 8. Auth - Sync Firebase User to Backend
  static Future<Map<String, dynamic>?> syncFirebaseUser({
    required String firebaseUid,
    required String email,
    String? fullName,
    String? photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebaseUid': firebaseUid,
          'email': email,
          'fullName': fullName ?? '',
          'photoUrl': photoUrl ?? '',
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error syncFirebaseUser: $e');
    }
    return null;
  }
}

