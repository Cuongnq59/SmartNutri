import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/pantry_item.dart';
import '../theme/app_theme.dart';
import '../widgets/receipt_review_sheet.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<PantryItem>> _pantryFuture;
  late Future<List<SmartRecipe>> _recipesFuture;
  final ImagePicker _picker = ImagePicker();
  final NumberFormat _currencyFmt = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _pantryFuture = ApiService.getPantryItems();
      _recipesFuture = ApiService.getSmartLeftovers();
    });
  }

  Future<void> _scanReceipt(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );

      if (file == null) return;

      _showLoadingDialog('Đang quét hóa đơn qua OCR & Gemini AI...');
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await ApiService.scanReceipt(base64Image, 'image/jpeg');
      if (!mounted) return;
      Navigator.pop(context); // close loading

      _showReceiptReviewSheet(result);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _demoReceiptScan();
    }
  }

  void _demoReceiptScan() async {
    _showLoadingDialog('Đang giải mã bill WinMart+ qua Gemini Vision...');
    await Future.delayed(const Duration(milliseconds: 1400));
    final result = await ApiService.scanReceipt('', 'image/jpeg');
    if (!mounted) return;
    Navigator.pop(context);
    _showReceiptReviewSheet(result);
  }

  void _showLoadingDialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryGreen),
            const SizedBox(width: 16),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  void _showReceiptReviewSheet(ReceiptScanResult scanResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReceiptReviewSheet(
        scanResult: scanResult,
        onConfirm: (approvedItems) async {
          await ApiService.confirmReceipt(
            merchantName: scanResult.merchantName,
            purchaseDate: scanResult.purchaseDate,
            totalAmount: scanResult.totalAmount,
            items: approvedItems,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppTheme.primaryGreen,
                content: Text('Đã cập nhật thực phẩm vào Tủ lạnh và trừ ngân sách tuần!'),
              ),
            );
            _loadData();
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
        title: const Text('Tủ Lạnh Ảo & Hóa Đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Quét Bill Demo',
            onPressed: _demoReceiptScan,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          indicatorColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(icon: Icon(Icons.kitchen_rounded), text: 'Kho Tủ Lạnh'),
            Tab(icon: Icon(Icons.restaurant_menu_rounded), text: 'Smart Leftovers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Virtual Pantry Items
          _buildPantryTab(isDark),

          // Tab 2: Smart Leftovers Recipes
          _buildLeftoversTab(isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Quét Hóa Đơn', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryGreen),
                    title: const Text('Chụp ảnh hóa đơn siêu thị / chợ'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _scanReceipt(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_rounded, color: AppTheme.proteinBlue),
                    title: const Text('Chọn ảnh từ thư viện'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _scanReceipt(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.flash_on_rounded, color: AppTheme.calorieOrange),
                    title: const Text('Quét mẫu hóa đơn WinMart+ (Demo)'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _demoReceiptScan();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPantryTab(bool isDark) {
    return FutureBuilder<List<PantryItem>>(
      future: _pantryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }

        final items = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppTheme.primaryGreen,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Pantry Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF1E3A8A)]
                        : [const Color(0xFFECFDF5), const Color(0xFFEFF6FF)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryGreen, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tủ lạnh hiện có ${items.length} nguyên liệu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Tự động đồng bộ từ hóa đơn siêu thị & trừ kho khi nấu ăn.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.kitchen_rounded, size: 50, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'Tủ lạnh đang trống!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Chụp hóa đơn mua sắm để nạp thực phẩm tự động.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...items.map((item) => _buildPantryItemCard(context, item, isDark)),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPantryItemCard(BuildContext context, PantryItem item, bool isDark) {
    Color badgeColor;
    String badgeText;
    final days = item.daysUntilExpiry;

    if (days <= 1) {
      badgeColor = AppTheme.dangerRed;
      badgeText = 'Hết hạn hôm nay!';
    } else if (days <= 3) {
      badgeColor = AppTheme.warningAmber;
      badgeText = 'Còn $days ngày';
    } else {
      badgeColor = AppTheme.successGreen;
      badgeText = 'Còn $days ngày';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: days <= 1 ? AppTheme.dangerRed.withOpacity(0.5) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fastfood_rounded, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.customName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Số lượng: ${item.quantity} ${item.unit} • Mua: ${_currencyFmt.format(item.costPaid)} đ',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                tooltip: 'Đã dùng',
                onPressed: () async {
                  if (item.id != null) {
                    await ApiService.consumePantryItem(item.id!);
                    _loadData();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftoversTab(bool isDark) {
    return FutureBuilder<List<SmartRecipe>>(
      future: _recipesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }

        final recipes = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.soup_kitchen_rounded, color: AppTheme.carbAmber, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Công thức nấu nhanh cho Sinh viên',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tận dụng nguyên liệu sẵn có trong tủ lạnh bằng chảo chống dính hoặc nồi cơm điện.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            ...recipes.map((recipe) => _buildRecipeCard(context, recipe, isDark)),

            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildRecipeCard(BuildContext context, SmartRecipe recipe, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              Expanded(
                child: Text(
                  recipe.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 12, color: AppTheme.primaryDark),
                    const SizedBox(width: 4),
                    Text(
                      recipe.cookingTime,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.proteinBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${recipe.proteinG.toInt()}g Protein',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.proteinBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.calorieOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${recipe.calories.toInt()} kcal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.calorieOrange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Dụng cụ: ${recipe.equipment}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          const Text(
            'Cách làm nhanh:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ...recipe.instructions.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                step,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
