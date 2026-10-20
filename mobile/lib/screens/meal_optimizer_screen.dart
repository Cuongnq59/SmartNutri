import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/optimizer_result.dart';
import '../theme/app_theme.dart';

class MealOptimizerScreen extends StatefulWidget {
  const MealOptimizerScreen({super.key});

  @override
  State<MealOptimizerScreen> createState() => _MealOptimizerScreenState();
}

class _MealOptimizerScreenState extends State<MealOptimizerScreen> {
  double _targetProtein = 50.0;
  double _maxBudget = 35000.0;
  double _minCalories = 500.0;
  double _maxCalories = 850.0;
  bool _usePantry = true;

  bool _isOptimizing = false;
  OptimizerResult? _result;
  final NumberFormat _currencyFmt = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _runOptimizer();
  }

  void _runOptimizer() async {
    setState(() {
      _isOptimizing = true;
    });

    final res = await ApiService.optimizeMeal(
      targetProtein: _targetProtein,
      minCalories: _minCalories,
      maxCalories: _maxCalories,
      maxBudget: _maxBudget,
      usePantry: _usePantry,
    );

    setState(() {
      _isOptimizing = false;
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bữa Ăn Tiết Kiệm (MILP)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Nguyên lý MILP',
            onPressed: () => _showMathExplanation(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Core Pitch Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF14532D)]
                      : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFA7F3D0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: AppTheme.primaryDark, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Thuật toán Quy hoạch Nguyên hỗn hợp (MILP)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Giải bài toán: "Tôi còn X VNĐ hôm nay và cần nạp Y g protein. Tôi nên mua gì?"',
                          style: TextStyle(fontSize: 12, color: AppTheme.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Controls Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target Protein Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.fitness_center_rounded, size: 18, color: AppTheme.proteinBlue),
                          SizedBox(width: 6),
                          Text('Mục tiêu Protein cần nạp:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Text(
                        '${_targetProtein.toInt()} g',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.proteinBlue),
                      ),
                    ],
                  ),
                  Slider(
                    value: _targetProtein,
                    min: 20.0,
                    max: 100.0,
                    divisions: 16,
                    activeColor: AppTheme.proteinBlue,
                    onChanged: (val) => setState(() => _targetProtein = val),
                  ),
                  const SizedBox(height: 8),

                  // Max Budget Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.payments_outlined, size: 18, color: AppTheme.primaryGreen),
                          SizedBox(width: 6),
                          Text('Ngân sách tối đa cho bữa ăn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Text(
                        '${_currencyFmt.format(_maxBudget)} đ',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxBudget,
                    min: 15000.0,
                    max: 100000.0,
                    divisions: 17,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) => setState(() => _maxBudget = val),
                  ),
                  const SizedBox(height: 8),

                  // Calorie Range info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.local_fire_department_rounded, size: 18, color: AppTheme.calorieOrange),
                          SizedBox(width: 6),
                          Text('Khoảng Calo an toàn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Text(
                        '${_minCalories.toInt()} - ${_maxCalories.toInt()} kcal',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.calorieOrange),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(_minCalories, _maxCalories),
                    min: 300.0,
                    max: 1200.0,
                    divisions: 18,
                    activeColor: AppTheme.calorieOrange,
                    onChanged: (vals) {
                      setState(() {
                        _minCalories = vals.start;
                        _maxCalories = vals.end;
                      });
                    },
                  ),

                  // Toggle Pantry
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primaryGreen,
                    title: const Text(
                      'Ưu tiên tận dụng thực phẩm trong tủ lạnh (Tính phí 0 VNĐ)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    value: _usePantry,
                    onChanged: (val) => setState(() => _usePantry = val),
                  ),
                  const SizedBox(height: 10),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isOptimizing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _isOptimizing ? 'Đang chạy thuật toán MILP...' : 'Tìm Thực Đơn Tiết Kiệm Tối Ưu',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: _isOptimizing ? null : _runOptimizer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Optimization Output Section
            if (_result != null) ...[
              if (!_result!.isFeasible)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dangerRed.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Ngân sách hiện tại chưa đủ!',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _result!.shoppingAdvice,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      if (_result!.neededExtraBudget > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Gợi ý: Tăng ngân sách thêm ít nhất ${_currencyFmt.format(_result!.neededExtraBudget)} VNĐ để đạt đủ ${_targetProtein.toInt()}g protein.',
                            style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else ...[
                // Optimization Success Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.verified_rounded, color: AppTheme.primaryGreen, size: 20),
                              SizedBox(width: 6),
                              Text('Thực Đơn Tối Ưu Đã Chọn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Chi phí: ${_currencyFmt.format(_result!.totalCost)} đ',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatBadge(
                            'Protein',
                            '${_result!.totalProtein.toInt()}g',
                            AppTheme.proteinBlue,
                          ),
                          const SizedBox(width: 10),
                          _buildStatBadge(
                            'Năng lượng',
                            '${_result!.totalCalories.toInt()} kcal',
                            AppTheme.calorieOrange,
                          ),
                          const SizedBox(width: 10),
                          _buildStatBadge(
                            'Tiết kiệm',
                            '${_currencyFmt.format(_maxBudget - _result!.totalCost)} đ',
                            AppTheme.primaryGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      const Text('Danh sách mua sắm cụ thể:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),

                      ..._result!.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  item.fromPantry ? Icons.kitchen_rounded : Icons.shopping_basket_rounded,
                                  size: 16,
                                  color: item.fromPantry ? AppTheme.primaryGreen : AppTheme.proteinBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item.portion} ${item.unit} ${item.name}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  '${item.protein.toInt()}g Pro',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.proteinBlue, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.fromPantry ? '0 đ' : '${_currencyFmt.format(item.cost)} đ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: item.fromPantry ? AppTheme.primaryGreen : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )),

                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _result!.shoppingAdvice,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _showMathExplanation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mô hình Toán học MILP'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Biến thể Bài toán Dinh dưỡng Stigler (The Stigler Diet Problem):\n\n'
                '• Hàm mục tiêu: min ∑ c_i * x_i\n'
                '• Ràng buộc Đạm: ∑ p_i * x_i ≥ P_min\n'
                '• Ràng buộc Calo: K_min ≤ ∑ k_i * x_i ≤ K_max\n'
                '• Ràng buộc Ngân sách: ∑ c_i * x_i ≤ B_max\n'
                '• Ràng buộc Khẩu phần: 0 ≤ x_i ≤ u_i\n'
                '• Ràng buộc Đa dạng: Mỗi món không chiếm quá 60% đạm\n'
                '• Tủ lạnh ảo: Các món sẵn có được gán c_i = 0 VNĐ để giảm tối đa chi phí mua sắm!',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
        ],
      ),
    );
  }
}
