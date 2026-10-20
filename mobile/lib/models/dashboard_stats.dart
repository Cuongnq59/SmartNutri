import 'meal.dart';

class DashboardStats {
  final String userName;
  final String goalType;
  final double todayCaloriesConsumed;
  final double todayCaloriesTarget;
  final double todayProteinConsumed;
  final double todayProteinTarget;
  final double todayCarbsConsumed;
  final double todayCarbsTarget;
  final double todayFatConsumed;
  final double todayFatTarget;

  final double weeklyBudget;
  final double weeklySpent;
  final double weeklyRemaining;
  final double dailyRemainingBudget;
  final String burnRateStatus;
  final String burnRateMessage;

  final double cpgpIndexVnd;
  final String cpgpEvaluation;

  final int activePantryCount;
  final int expiringPantryCount;
  final List<Meal> recentMeals;

  DashboardStats({
    required this.userName,
    required this.goalType,
    required this.todayCaloriesConsumed,
    required this.todayCaloriesTarget,
    required this.todayProteinConsumed,
    required this.todayProteinTarget,
    required this.todayCarbsConsumed,
    required this.todayCarbsTarget,
    required this.todayFatConsumed,
    required this.todayFatTarget,
    required this.weeklyBudget,
    required this.weeklySpent,
    required this.weeklyRemaining,
    required this.dailyRemainingBudget,
    required this.burnRateStatus,
    required this.burnRateMessage,
    required this.cpgpIndexVnd,
    required this.cpgpEvaluation,
    required this.activePantryCount,
    required this.expiringPantryCount,
    required this.recentMeals,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    List<Meal> meals = [];
    if (json['recentMeals'] != null && json['recentMeals'] is List) {
      meals = (json['recentMeals'] as List).map((m) => Meal.fromJson(m)).toList();
    }

    return DashboardStats(
      userName: json['userName'] ?? 'Sinh viên SmartNutri',
      goalType: json['goalType'] ?? 'BULK',
      todayCaloriesConsumed: (json['todayCaloriesConsumed'] ?? 0.0).toDouble(),
      todayCaloriesTarget: (json['todayCaloriesTarget'] ?? 2200.0).toDouble(),
      todayProteinConsumed: (json['todayProteinConsumed'] ?? 0.0).toDouble(),
      todayProteinTarget: (json['todayProteinTarget'] ?? 120.0).toDouble(),
      todayCarbsConsumed: (json['todayCarbsConsumed'] ?? 0.0).toDouble(),
      todayCarbsTarget: (json['todayCarbsTarget'] ?? 280.0).toDouble(),
      todayFatConsumed: (json['todayFatConsumed'] ?? 0.0).toDouble(),
      todayFatTarget: (json['todayFatTarget'] ?? 65.0).toDouble(),
      weeklyBudget: (json['weeklyBudget'] ?? 450000.0).toDouble(),
      weeklySpent: (json['weeklySpent'] ?? 0.0).toDouble(),
      weeklyRemaining: (json['weeklyRemaining'] ?? 450000.0).toDouble(),
      dailyRemainingBudget: (json['dailyRemainingBudget'] ?? 65000.0).toDouble(),
      burnRateStatus: json['burnRateStatus'] ?? 'NORMAL',
      burnRateMessage: json['burnRateMessage'] ?? 'Tiến độ chi tiêu ổn định.',
      cpgpIndexVnd: (json['cpgpIndexVnd'] ?? 0.0).toDouble(),
      cpgpEvaluation: json['cpgpEvaluation'] ?? 'Hợp lý',
      activePantryCount: json['activePantryCount'] ?? 0,
      expiringPantryCount: json['expiringPantryCount'] ?? 0,
      recentMeals: meals,
    );
  }
}
