import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MacroRingCard extends StatelessWidget {
  final double calories;
  final double targetCalories;
  final double protein;
  final double targetProtein;
  final double carbs;
  final double targetCarbs;
  final double fat;
  final double targetFat;

  const MacroRingCard({
    super.key,
    required this.calories,
    required this.targetCalories,
    required this.protein,
    required this.targetProtein,
    required this.carbs,
    required this.targetCarbs,
    required this.fat,
    required this.targetFat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final calRatio = (calories / (targetCalories > 0 ? targetCalories : 2000)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dinh Dưỡng Hôm Nay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                  '${(calRatio * 100).toInt()}% Mục tiêu',
                  style: const TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Main calories banner
          Row(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: calRatio,
                      strokeWidth: 8,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.calorieOrange),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: AppTheme.calorieOrange,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${calories.toInt()}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        ' / ${targetCalories.toInt()} kcal',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    calories >= targetCalories
                        ? 'Đã đạt chỉ tiêu năng lượng hôm nay!'
                        : 'Còn thiếu ${(targetCalories - calories).toInt()} kcal cho ngày hôm nay',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),
          // 3 Macros row (Protein, Carbs, Fat)
          Row(
            children: [
              Expanded(
                child: _buildMacroItem(
                  context,
                  label: 'Protein',
                  consumed: protein,
                  target: targetProtein,
                  color: AppTheme.proteinBlue,
                  icon: Icons.fitness_center_rounded,
                  unit: 'g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroItem(
                  context,
                  label: 'Carbs',
                  consumed: carbs,
                  target: targetCarbs,
                  color: AppTheme.carbAmber,
                  icon: Icons.grain_rounded,
                  unit: 'g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroItem(
                  context,
                  label: 'Fat',
                  consumed: fat,
                  target: targetFat,
                  color: AppTheme.fatPurple,
                  icon: Icons.water_drop_rounded,
                  unit: 'g',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(
    BuildContext context, {
    required String label,
    required double consumed,
    required double target,
    required Color color,
    required IconData icon,
    required String unit,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = (consumed / (target > 0 ? target : 1.0)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${consumed.toInt()}/${target.toInt()}$unit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
