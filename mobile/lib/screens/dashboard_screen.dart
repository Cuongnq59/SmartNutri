import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/dashboard_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/macro_ring_card.dart';
import '../widgets/budget_watchdog_card.dart';
import '../widgets/cpgp_card.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int targetTab) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
    ApiService.refreshDashboardNotifier.addListener(_loadStats);
  }

  @override
  void dispose() {
    ApiService.refreshDashboardNotifier.removeListener(_loadStats);
    super.dispose();
  }

  void _loadStats() {
    if (mounted) {
      setState(() {
        _statsFuture = ApiService.getDashboardStats();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 4),
                Text(
                  'SmartNutri',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            Text(
              'Trợ lý Dinh Dưỡng & Ngân Sách Sinh Viên',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Hồ sơ',
            onPressed: () => widget.onNavigateTab(4),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<DashboardStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }

          final stats = snapshot.data ?? ApiService.mockDashboardStats();

          return RefreshIndicator(
            onRefresh: () async => _loadStats(),
            color: AppTheme.primaryGreen,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Quick greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Xin chào, ${stats.userName} 👋',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Lộ trình: ${stats.goalType}',
                        style: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. Macro Ring Card
                MacroRingCard(
                  calories: stats.todayCaloriesConsumed,
                  targetCalories: stats.todayCaloriesTarget,
                  protein: stats.todayProteinConsumed,
                  targetProtein: stats.todayProteinTarget,
                  carbs: stats.todayCarbsConsumed,
                  targetCarbs: stats.todayCarbsTarget,
                  fat: stats.todayFatConsumed,
                  targetFat: stats.todayFatTarget,
                ),
                const SizedBox(height: 14),

                // Quick Action Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildActionBtn(
                        context,
                        title: 'Snap & Log',
                        subtitle: 'Chụp ảnh đĩa ăn',
                        icon: Icons.camera_alt_rounded,
                        color: AppTheme.calorieOrange,
                        onTap: () => widget.onNavigateTab(1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionBtn(
                        context,
                        title: 'Quét Hóa Đơn',
                        subtitle: 'Nạp vào Tủ lạnh',
                        icon: Icons.document_scanner_rounded,
                        color: AppTheme.primaryGreen,
                        onTap: () => widget.onNavigateTab(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionBtn(
                        context,
                        title: 'Gợi Ý Bữa Ăn',
                        subtitle: 'MILP Tiết kiệm',
                        icon: Icons.auto_awesome_rounded,
                        color: AppTheme.proteinBlue,
                        onTap: () => widget.onNavigateTab(3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2. Budget Watchdog Card
                BudgetWatchdogCard(
                  weeklyBudget: stats.weeklyBudget,
                  weeklySpent: stats.weeklySpent,
                  weeklyRemaining: stats.weeklyRemaining,
                  dailyRemaining: stats.dailyRemainingBudget,
                  burnRateStatus: stats.burnRateStatus,
                  burnRateMessage: stats.burnRateMessage,
                ),
                const SizedBox(height: 14),

                // 3. CPGP Metric Card
                CpgpCard(
                  cpgpIndex: stats.cpgpIndexVnd,
                  evaluation: stats.cpgpEvaluation,
                ),
                const SizedBox(height: 16),

                // 4. Recent Meals Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bữa ăn gần đây',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () => widget.onNavigateTab(1),
                      child: const Text('Thêm bữa mới', style: TextStyle(color: AppTheme.primaryGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (stats.recentMeals.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.restaurant_rounded, size: 40, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          const Text('Chưa có bữa ăn nào được ghi lại hôm nay'),
                        ],
                      ),
                    ),
                  )
                else
                  ...stats.recentMeals.map((meal) => _buildMealItemCard(context, meal)),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItemCard(BuildContext context, meal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat('#,###', 'vi_VN');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.calorieOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lunch_dining_rounded, color: AppTheme.calorieOrange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.dishName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${meal.calories.toInt()} kcal • ${meal.protein.toInt()}g Protein • ${currencyFmt.format(meal.cost)} đ',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              meal.mealType,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
