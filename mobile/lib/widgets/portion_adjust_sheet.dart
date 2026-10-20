import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../theme/app_theme.dart';

class PortionAdjustSheet extends StatefulWidget {
  final MealAnalysisResult analysisResult;
  final Function(Meal meal, bool deductPantry) onSaveMeal;

  const PortionAdjustSheet({
    super.key,
    required this.analysisResult,
    required this.onSaveMeal,
  });

  @override
  State<PortionAdjustSheet> createState() => _PortionAdjustSheetState();
}

class _PortionAdjustSheetState extends State<PortionAdjustSheet> {
  late List<MealComponent> _components;
  late double _totalCalories;
  late double _totalProtein;
  late double _totalCarbs;
  late double _totalFat;
  String _mealType = 'LUNCH';
  bool _deductFromPantry = true;
  double _cost = 35000.0;

  @override
  void initState() {
    super.initState();
    _components = List.from(widget.analysisResult.components);
    _recalculateTotals();
  }

  void _recalculateTotals() {
    double cal = 0, pro = 0, carb = 0, fat = 0;
    for (var c in _components) {
      cal += c.calories;
      pro += c.proteinG;
      carb += c.carbsG;
      fat += c.fatG;
    }
    setState(() {
      _totalCalories = cal;
      _totalProtein = pro;
      _totalCarbs = carb;
      _totalFat = fat;
    });
  }

  void _adjustComponent(int index, double factorDelta) {
    setState(() {
      final comp = _components[index];
      double currentWeight = comp.weightG;
      double newWeight = (currentWeight + factorDelta).clamp(0.0, 1000.0);
      if (currentWeight > 0) {
        double ratio = newWeight / currentWeight;
        comp.calories = (comp.calories * ratio).roundToDouble();
        comp.proteinG = (comp.proteinG * ratio * 10).round() / 10.0;
        comp.carbsG = (comp.carbsG * ratio * 10).round() / 10.0;
        comp.fatG = (comp.fatG * ratio * 10).round() / 10.0;
      }
      comp.weightG = newWeight;
      _recalculateTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.analysisResult.dishName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Độ tin cậy: ${(widget.analysisResult.confidenceScore * 100).toInt()}% • AI Vision Engine',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Real-time macro summary bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalMacroCol('Calo', '${_totalCalories.toInt()} kcal', AppTheme.calorieOrange),
                _buildTotalMacroCol('Protein', '${_totalProtein.toInt()}g', AppTheme.proteinBlue),
                _buildTotalMacroCol('Carbs', '${_totalCarbs.toInt()}g', AppTheme.carbAmber),
                _buildTotalMacroCol('Fat', '${_totalFat.toInt()}g', AppTheme.fatPurple),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Chạm để tinh chỉnh khẩu phần từng thành phần:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _components.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final comp = _components[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comp.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${comp.calories.toInt()} kcal • ${comp.proteinG}g Pro • ${comp.carbsG}g Carbs',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                            onPressed: () => _adjustComponent(index, -25.0),
                            color: Colors.redAccent,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${comp.weightG.toInt()}g',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                            onPressed: () => _adjustComponent(index, 25.0),
                            color: AppTheme.primaryGreen,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Meal type selector & Pantry deduction checkbox
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _mealType,
                  decoration: InputDecoration(
                    labelText: 'Bữa ăn',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'BREAKFAST', child: Text('Bữa Sáng')),
                    DropdownMenuItem(value: 'LUNCH', child: Text('Bữa Trưa')),
                    DropdownMenuItem(value: 'DINNER', child: Text('Bữa Tối')),
                    DropdownMenuItem(value: 'SNACK', child: Text('Bữa Phụ')),
                  ],
                  onChanged: (val) => setState(() => _mealType = val ?? 'LUNCH'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: '35000',
                  decoration: InputDecoration(
                    labelText: 'Giá tiền (VNĐ)',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _cost = double.tryParse(val) ?? 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _deductFromPantry,
            activeColor: AppTheme.primaryGreen,
            title: const Text(
              'Tự động trừ nguyên liệu tương ứng trong Tủ lạnh ảo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            onChanged: (val) => setState(() => _deductFromPantry = val ?? true),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.bookmark_added_rounded),
              label: const Text('Lưu vào Nhật ký Bữa ăn', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () {
                final meal = Meal(
                  dishName: widget.analysisResult.dishName,
                  mealType: _mealType,
                  calories: _totalCalories,
                  protein: _totalProtein,
                  carbs: _totalCarbs,
                  fat: _totalFat,
                  cost: _cost,
                  healthNote: widget.analysisResult.healthNote,
                  createdAt: DateTime.now(),
                  items: _components,
                );
                widget.onSaveMeal(meal, _deductFromPantry);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalMacroCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
