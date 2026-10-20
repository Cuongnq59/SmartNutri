import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_service.dart';
import '../models/meal.dart';
import '../theme/app_theme.dart';
import '../widgets/portion_adjust_sheet.dart';

class SnapAndLogScreen extends StatefulWidget {
  final Function(int targetTab)? onNavigateTab;

  const SnapAndLogScreen({super.key, this.onNavigateTab});

  @override
  State<SnapAndLogScreen> createState() => _SnapAndLogScreenState();
}

class _SnapAndLogScreenState extends State<SnapAndLogScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  String? _statusText;

  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (file == null) return;

      setState(() {
        _isAnalyzing = true;
        _statusText = 'AI Vision Engine đang phân tích đĩa thức ăn...';
      });

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await ApiService.analyzeMeal(base64Image, 'image/jpeg');

      setState(() {
        _isAnalyzing = false;
      });

      if (!mounted) return;
      _showPortionSheet(result);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chụp ảnh: $e')),
      );
    }
  }

  void _analyzeSampleMeal(String mealName) async {
    setState(() {
      _isAnalyzing = true;
      _statusText = 'Đang phân tích mẫu món: $mealName...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    final result = await ApiService.analyzeMeal('', 'image/jpeg');

    setState(() {
      _isAnalyzing = false;
    });

    if (!mounted) return;
    _showPortionSheet(result);
  }

  void _showPortionSheet(MealAnalysisResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PortionAdjustSheet(
        analysisResult: result,
        onSaveMeal: (meal, deductPantry) async {
          await ApiService.logMeal(meal, deductFromPantry: deductPantry);
          if (mounted) {
            final pantryMsg = deductPantry ? ' (Đã trừ nguyên liệu trong Tủ lạnh)' : '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.primaryGreen,
                content: Text(
                  'Đã lưu "${meal.dishName}" vào nhật ký!$pantryMsg',
                ),
              ),
            );
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(0); // return to dashboard
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap & Log (AI Vision)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Camera Guide Frame Viewport
            Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Frame boundary corners
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.primaryGreen, width: 3),
                          left: BorderSide(color: AppTheme.primaryGreen, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.primaryGreen, width: 3),
                          right: BorderSide(color: AppTheme.primaryGreen, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.primaryGreen, width: 3),
                          left: BorderSide(color: AppTheme.primaryGreen, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.primaryGreen, width: 3),
                          right: BorderSide(color: AppTheme.primaryGreen, width: 3),
                        ),
                      ),
                    ),
                  ),

                  // Center Prompt / Scanning state
                  Center(
                    child: _isAnalyzing
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: AppTheme.primaryGreen),
                              const SizedBox(height: 16),
                              Text(
                                _statusText ?? 'AI đang bóc tách thành phần đĩa ăn...',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Cơm sườn • Phở bò • Bún chả • Bánh mì',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 48,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Căn chỉnh đĩa thức ăn vào khung hình',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'AI nhận diện chính xác món Việt và định lượng Calo/Macros',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Shutter buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.camera_rounded),
                    label: const Text('Chụp ảnh ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isAnalyzing ? null : () => _pickAndAnalyze(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryGreen),
                    label: const Text('Thư viện', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    onPressed: _isAnalyzing ? null : () => _pickAndAnalyze(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Fast Demo Buttons (Perfect for emulator or immediate demo)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Món ăn mẫu thử nghiệm nhanh (Demo):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.restaurant_rounded, size: 16, color: AppTheme.calorieOrange),
                  label: const Text('Cơm tấm sườn bì chả'),
                  onPressed: () => _analyzeSampleMeal('Cơm tấm sườn bì chả'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.soup_kitchen_rounded, size: 16, color: AppTheme.proteinBlue),
                  label: const Text('Phở bò tái gầu'),
                  onPressed: () => _analyzeSampleMeal('Phở bò tái gầu'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.fitness_center_rounded, size: 16, color: AppTheme.primaryGreen),
                  label: const Text('Cơm ức gà xào sả ớt'),
                  onPressed: () => _analyzeSampleMeal('Cơm ức gà xào sả ớt'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Feature Highlights Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.tune_rounded, color: AppTheme.primaryGreen, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Tính năng Human-in-the-Loop:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sau khi AI nhận diện món, bạn có thể chạm để tăng/giảm định lượng (+1 bát cơm, +1 trứng, bỏ mỡ hành) và ứng dụng sẽ tự động tính toán lại Calo & Macros theo thời gian thực.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
