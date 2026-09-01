import 'package:flutter/material.dart';

class NutritionFoodItemsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const NutritionFoodItemsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<NutritionFoodItemsView> createState() => _NutritionFoodItemsViewState();
}

class _NutritionFoodItemsViewState extends State<NutritionFoodItemsView> {
  int _selectedCatIndex = 0;
  String _searchQuery = '';

  final List<String> _foodCategories = ['All Foods', 'Fruits', 'Poultry & Meat', 'Grains & Oats', 'Dairy & Eggs', 'Nuts & Seeds', 'Seafood'];

  late List<Map<String, dynamic>> _foodItemsList;

  @override
  void initState() {
    super.initState();

    _foodItemsList = [
      {
        'id': 'FOOD-101',
        'name': 'Fresh Red Apple',
        'category': 'Fruits',
        'serving': '1 Medium (182g)',
        'calories': '95 kcal',
        'protein': '0.5g',
        'carbs': '25g',
        'fiber': '4.4g',
        'fats': '0.3g',
        'sugar': '19g',
        'vitamins': 'Vitamin C (14%), Potassium (6%), Antioxidants',
        'img': 'assets/images/hero_banner_1.png',
      },
      {
        'id': 'FOOD-102',
        'name': 'Raw Boneless Chicken Breast',
        'category': 'Poultry & Meat',
        'serving': '100g raw',
        'calories': '165 kcal',
        'protein': '31.0g',
        'carbs': '0.0g',
        'fiber': '0.0g',
        'fats': '3.6g',
        'sugar': '0g',
        'vitamins': 'Niacin (B3 74%), Vitamin B6 (30%), Phosphorus',
        'img': 'assets/images/athlete_transform_1787825621309.jpg',
      },
      {
        'id': 'FOOD-103',
        'name': 'Whole Rolled Oats',
        'category': 'Grains & Oats',
        'serving': '100g dry',
        'calories': '389 kcal',
        'protein': '16.9g',
        'carbs': '66.3g',
        'fiber': '10.6g',
        'fats': '6.9g',
        'sugar': '0g',
        'vitamins': 'Beta-Glucan Fiber, Magnesium (44%), Iron (26%)',
        'img': 'assets/images/workout_banner_1.png',
      },
      {
        'id': 'FOOD-104',
        'name': 'Greek Yogurt 0% Fat',
        'category': 'Dairy & Eggs',
        'serving': '100g',
        'calories': '59 kcal',
        'protein': '10.0g',
        'carbs': '3.6g',
        'fiber': '0.0g',
        'fats': '0.4g',
        'sugar': '3.2g',
        'vitamins': 'Calcium (11%), Probiotics, Vitamin B12',
        'img': 'assets/images/trainers_hero_banner.jpg',
      },
      {
        'id': 'FOOD-105',
        'name': 'Fresh Hass Avocado',
        'category': 'Fruits',
        'serving': '100g (1/2 Avocado)',
        'calories': '160 kcal',
        'protein': '2.0g',
        'carbs': '8.5g',
        'fiber': '6.7g',
        'fats': '14.7g',
        'sugar': '0.7g',
        'vitamins': 'Monounsaturated Oleic Acid, Potassium (14%), Vitamin E',
        'img': 'assets/images/hero_banner_4.png',
      },
      {
        'id': 'FOOD-106',
        'name': 'Wild Atlantic Salmon Fillet',
        'category': 'Seafood',
        'serving': '100g raw',
        'calories': '208 kcal',
        'protein': '20.4g',
        'carbs': '0.0g',
        'fiber': '0.0g',
        'fats': '13.4g',
        'sugar': '0g',
        'vitamins': 'Omega-3 EPA/DHA (2.2g), Vitamin D (100%), Selenium',
        'img': 'assets/images/workout_banner_1.png',
      },
    ];
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    final int safeIndex = index < widget.fadeAnimations.length ? index : widget.fadeAnimations.length - 1;
    return FadeTransition(
      opacity: widget.fadeAnimations[safeIndex],
      child: SlideTransition(
        position: widget.slideAnimations[safeIndex],
        child: child,
      ),
    );
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 12)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddFoodItemDialog() {
    final nameController = TextEditingController();
    final servingController = TextEditingController(text: '100g');
    final kcalController = TextEditingController(text: '120');
    final pController = TextEditingController(text: '5');
    final cController = TextEditingController(text: '20');
    final fController = TextEditingController(text: '2');
    final fiberController = TextEditingController(text: '3');
    String selectedCat = 'Fruits';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: const [
              Icon(Icons.restaurant_rounded, color: Color(0xFF3B82F6), size: 22),
              SizedBox(width: 8),
              Text('Add Food & Nutrition Facts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Food Item Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                TextField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'e.g. Green Apple, Almond Butter',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedCat,
                                items: _foodCategories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 11)))).toList(),
                                onChanged: (val) => setDlgState(() => selectedCat = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Serving Size', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: servingController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Nutrition Facts (Per Serving)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildMiniInput('Calories (kcal)', kcalController)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildMiniInput('Protein (g)', pController)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildMiniInput('Carbs (g)', cController)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildMiniInput('Fats (g)', fController)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildMiniInput('Fiber (g)', fiberController)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _foodItemsList.insert(0, {
                      'id': 'FOOD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                      'name': name,
                      'category': selectedCat,
                      'serving': servingController.text.trim(),
                      'calories': '${kcalController.text.trim()} kcal',
                      'protein': '${pController.text.trim()}g',
                      'carbs': '${cController.text.trim()}g',
                      'fiber': '${fiberController.text.trim()}g',
                      'fats': '${fController.text.trim()}g',
                      'sugar': '2g',
                      'vitamins': 'Vitamins & Minerals profile verified',
                      'img': 'assets/images/workout_banner_1.png',
                    });
                  });
                  Navigator.pop(ctx);
                  _showSnackbar('Food item "$name" added with full nutrition facts!', const Color(0xFF3B82F6));
                }
              },
              child: const Text('Save Food Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInput(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
        ),
      ],
    );
  }

  void _showFoodDetailModal(Map<String, dynamic> f) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _buildFoodDetailBottomSheet(f),
    );
  }

  Widget _buildFoodDetailBottomSheet(Map<String, dynamic> f) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(f['img'] as String, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.restaurant, size: 36))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                        child: Text(f['category'] as String, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6))),
                      ),
                      const SizedBox(height: 4),
                      Text(f['name'] as String, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Text('Serving: ${f['serving']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18)),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 0.8, color: Color(0xFFF1F5F9)),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Nutrition Facts Label Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black, width: 1.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nutrition Facts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5)),
                      Text('Serving Size: ${f['serving']}', style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w600)),
                      const Divider(thickness: 4, color: Colors.black, height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Calories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black)),
                          Text(f['calories'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                        ],
                      ),
                      const Divider(thickness: 2, color: Colors.black, height: 12),
                      _buildNutriFactRow('Total Protein', f['protein'] as String, isBold: true),
                      _buildNutriFactRow('Total Carbohydrates', f['carbs'] as String, isBold: true),
                      _buildNutriFactRow('   Dietary Fiber', f['fiber'] as String),
                      _buildNutriFactRow('   Total Sugars', f['sugar'] as String),
                      _buildNutriFactRow('Total Fat', f['fats'] as String, isBold: true),
                      const Divider(thickness: 2, color: Colors.black, height: 12),
                      const Text('Vitamins & Minerals:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black)),
                      const SizedBox(height: 2),
                      Text(f['vitamins'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      Navigator.pop(context);
                      _showSnackbar('Edit food item opened.', const Color(0xFF3B82F6));
                    },
                    icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                    label: const Text('Edit Food', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _foodItemsList.removeWhere((item) => item['id'] == f['id']));
                      _showSnackbar('Food item deleted.', const Color(0xFFEF4444));
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white),
                    label: const Text('Delete Food', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutriFactRow(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.w900 : FontWeight.w500, color: Colors.black87)),
          Text(val, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: Colors.black)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedSection(0, _buildKpiCarousel()),
        const SizedBox(height: 16),
        _buildAnimatedSection(1, _buildSearchAndActionBar()),
        const SizedBox(height: 12),
        _buildAnimatedSection(2, _buildCategoryChips()),
        const SizedBox(height: 16),
        _buildAnimatedSection(3, _buildFoodItemsGrid()),
      ],
    );
  }

  Widget _buildKpiCarousel() {
    final kpis = [
      {'title': 'Food Items', 'val': '1,280', 'growth': '+42 Verified Foods', 'icon': Icons.kitchen_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'title': 'FDA Verified', 'val': '98.5%', 'growth': 'Macro database SLA', 'icon': Icons.verified_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Food Categories', 'val': '7 Groups', 'growth': 'Whole foods & snacks', 'icon': Icons.category_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Top Search', 'val': 'Red Apple', 'growth': '76.1K queries', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: kpis.map((k) {
          final Color color = k['color'] as Color;
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: k['bg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(k['icon'] as IconData, color: color, size: 14)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(k['title'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(k['val'] as String, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(k['growth'] as String, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndActionBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(hintText: 'Search foods (e.g. Apple, Chicken, Oats)...', border: InputBorder.none, isDense: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showAddFoodItemDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(
              children: const [
                Icon(Icons.add_rounded, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text('Add Food Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_foodCategories.length, (i) {
          final isSelected = _selectedCatIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCatIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade200),
                ),
                child: Text(
                  _foodCategories[i],
                  style: TextStyle(fontSize: 10.5, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFoodItemsGrid() {
    final filtered = _foodItemsList.where((f) {
      if (_selectedCatIndex > 0) {
        final cat = _foodCategories[_selectedCatIndex];
        if (f['category'] != cat) return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (f['name'] as String).toLowerCase().contains(q) ||
          (f['category'] as String).toLowerCase().contains(q);
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final f = filtered[i];
        return GestureDetector(
          onTap: () => _showFoodDetailModal(f),
          child: _buildFoodCard(f),
        );
      },
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> f) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.asset(
                  f['img'] as String,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(height: 90, color: const Color(0xFFF1F5F9)),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                  child: Text(f['category'] as String, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f['name'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(f['serving'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(f['calories'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
                    Text('P: ${f['protein']}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                    Text('C: ${f['carbs']}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
