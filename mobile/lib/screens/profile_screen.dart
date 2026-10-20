import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _height = 172.0;
  double _weight = 64.0;
  double _targetWeight = 68.0;
  String _goalType = 'BULK'; // BULK, CUT, MAINTAIN
  String _activityLevel = 'MODERATE';
  double _weeklyBudget = 450000.0;
  final NumberFormat _currencyFmt = NumberFormat('#,###', 'vi_VN');

  // Mifflin-St Jeor formula
  double get _rmr {
    return 10 * _weight + 6.25 * _height - 5 * 21 + 5;
  }

  double get _tdee {
    double factor = 1.375;
    if (_activityLevel == 'SEDENTARY') factor = 1.2;
    if (_activityLevel == 'LIGHT') factor = 1.375;
    if (_activityLevel == 'MODERATE') factor = 1.55;
    if (_activityLevel == 'VERY_ACTIVE') factor = 1.725;
    return _rmr * factor;
  }

  double get _targetCalories {
    switch (_goalType) {
      case 'BULK':
        return _tdee + 350;
      case 'CUT':
        return (_tdee - 450).clamp(1400.0, 3500.0);
      default:
        return _tdee;
    }
  }

  double get _targetProtein {
    switch (_goalType) {
      case 'BULK':
        return _weight * 2.0;
      case 'CUT':
        return _weight * 2.2;
      default:
        return _weight * 1.6;
    }
  }

  double get _targetFat {
    return (_targetCalories * 0.25) / 9.0;
  }

  double get _targetCarbs {
    return (_targetCalories - (_targetProtein * 4 + _targetFat * 9)) / 4.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentUser = AuthService.instance.currentUser;
    final displayName = (currentUser?.displayName.isNotEmpty == true)
        ? currentUser!.displayName
        : 'Nguyễn Văn An';
    final email = currentUser?.email ?? 'sinhvien@smartnutri.vn';
    final authBadge = (currentUser != null && !currentUser.uid.startsWith('demo'))
        ? 'Firebase UID: ${currentUser.uid.substring(0, currentUser.uid.length > 8 ? 8 : currentUser.uid.length)}...'
        : 'Tài khoản Demo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Thể Trạng & Mục Tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: _showLogoutConfirmDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryLight,
                    child: const Icon(Icons.person_rounded, size: 36, color: AppTheme.primaryDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$email • $authBadge',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Body Metrics Card
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
                  const Text('Chỉ số nhân trắc học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile('Chiều cao', '${_height.toInt()} cm', Icons.height_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile('Cân nặng', '${_weight.toInt()} kg', Icons.monitor_weight_outlined),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile('Mục tiêu', '${_targetWeight.toInt()} kg', Icons.flag_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Sliders
                  _buildSlider('Chiều cao (cm)', _height, 140, 200, (v) => setState(() => _height = v)),
                  _buildSlider('Cân nặng hiện tại (kg)', _weight, 40, 120, (v) => setState(() => _weight = v)),
                  _buildSlider('Cân nặng mục tiêu (kg)', _targetWeight, 40, 120, (v) => setState(() => _targetWeight = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Goal Roadmap Card
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
                  const Text('Lộ trình thể trạng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGoalOption(
                          'Tăng Cân Nạc',
                          'Lean Bulk',
                          'BULK',
                          Icons.trending_up_rounded,
                          AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildGoalOption(
                          'Giảm Mỡ',
                          'Cut',
                          'CUT',
                          Icons.trending_down_rounded,
                          AppTheme.calorieOrange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildGoalOption(
                          'Duy Trì',
                          'Maintain',
                          'MAINTAIN',
                          Icons.balance_rounded,
                          AppTheme.proteinBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Mức độ vận động:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _activityLevel,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'SEDENTARY', child: Text('Ít vận động (Học tập, ngồi nhiều)')),
                      DropdownMenuItem(value: 'LIGHT', child: Text('Vận động nhẹ (Tập 1-3 buổi/tuần)')),
                      DropdownMenuItem(value: 'MODERATE', child: Text('Vận động vừa (Tập 3-5 buổi/tuần)')),
                      DropdownMenuItem(value: 'VERY_ACTIVE', child: Text('Vận động nhiều (Tập 6-7 buổi/tuần)')),
                    ],
                    onChanged: (v) => setState(() => _activityLevel = v ?? 'MODERATE'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Computed Targets Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF172554)]
                      : [const Color(0xFFF8FAFC), const Color(0xFFEFF6FF)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mục tiêu mỗi ngày (Tự động tính)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.proteinBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TDEE: ${_tdee.toInt()} kcal',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.proteinBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroBadge('Calo', '${_targetCalories.toInt()} kcal', AppTheme.calorieOrange),
                      _buildMacroBadge('Protein', '${_targetProtein.toInt()} g', AppTheme.proteinBlue),
                      _buildMacroBadge('Carbs', '${_targetCarbs.toInt()} g', AppTheme.carbAmber),
                      _buildMacroBadge('Fat', '${_targetFat.toInt()} g', AppTheme.fatPurple),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Budget Setting Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.savings_rounded, color: AppTheme.primaryGreen, size: 20),
                          SizedBox(width: 8),
                          Text('Ngân sách ăn uống tuần:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Text(
                        '${_currencyFmt.format(_weeklyBudget)} đ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                  Slider(
                    value: _weeklyBudget,
                    min: 200000.0,
                    max: 1200000.0,
                    divisions: 20,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (v) => setState(() => _weeklyBudget = v),
                  ),
                  Text(
                    'Tương đương khoảng ${_currencyFmt.format((_weeklyBudget / 7).round())} đ / ngày cho tiền ăn sinh viên.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Lưu Thay Đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppTheme.primaryGreen,
                      content: Text('Đã cập nhật mục tiêu thể trạng và ngân sách!'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Đăng Xuất Tài Khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: _showLogoutConfirmDialog,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Đăng Xuất'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi SmartNutri không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.instance.signOut();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Slider(
          value: val,
          min: min,
          max: max,
          activeColor: AppTheme.primaryGreen,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildGoalOption(String title, String subtitle, String key, IconData icon, Color color) {
    final isSelected = _goalType == key;

    return InkWell(
      onTap: () => setState(() => _goalType = key),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : null,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
