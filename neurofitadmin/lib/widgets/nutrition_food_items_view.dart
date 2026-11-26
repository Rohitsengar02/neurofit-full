import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import '../backend/live_backend.dart';
import 'net_or_asset_image.dart';

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


  final AdminList _src = AdminList.of('/foods?limit=2000');

  static String _num(dynamic v) {
    final d = v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
  }

  static Map<String, dynamic> _row(Map<String, dynamic> f) => {
        ...f,
        'id': f['id'],
        'name': '${f['name'] ?? f['title'] ?? 'Food'}',
        'category': '${f['category'] ?? 'Other'}',
        'serving': '${f['servingSize'] ?? f['serving'] ?? '100 g'}',
        'calories': '${_num(f['calories'])} kcal',
        'protein': '${_num(f['protein'])}g',
        'carbs': '${_num(f['carbs'])}g',
        'fiber': '${_num(f['fiber'])}g',
        'fats': '${_num(f['fat'] ?? f['fats'])}g',
        'sugar': '${_num(f['sugar'])}g',
        'vitamins': '${f['vitamins'] ?? ''}'.isEmpty ? 'Not added yet' : '${f['vitamins']}',
        'img': '${f['imageUrl'] ?? f['image'] ?? ''}',
      };

  List<Map<String, dynamic>> get _foodItemsList => [for (final f in _src.items) _row(f)];

  List<String> get _foodCategories => ['All Foods', ...{..._defaultCats, for (final f in _src.items) '${f['category'] ?? 'Other'}'}];
  static const _defaultCats = ['Fruits', 'Vegetables', 'Poultry & Meat', 'Grains & Oats', 'Dairy & Eggs', 'Nuts & Seeds', 'Seafood'];

  void _changed() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    _src.addListener(_changed);
    _src.load();
  }

  @override
  void dispose() {
    _src.removeListener(_changed);
    super.dispose();
  }

  Future<void> _save(Map<String, dynamic>? existing, Map<String, dynamic> body) async {
    try {
      if (existing == null) {
        await Api.send('POST', '/foods', {...body, 'isActive': true, 'status': 'Active', 'source': 'NeuroFit'});
      } else {
        await Api.send('PUT', '/foods/${existing['id']}', body);
      }
      await _src.load();
      _showSnackbar(existing == null ? 'Food item "${body['name']}" added with full nutrition facts!' : 'Food item "${body['name']}" updated.', const Color(0xFF3B82F6));
    } catch (e) {
      _showSnackbar('Could not save: $e', const Color(0xFFEF4444));
    }
  }

  Future<void> _delete(Map<String, dynamic> f) async {
    try {
      await Api.send('DELETE', '/foods/${f['id']}');
      await _src.load();
      _showSnackbar('Food item deleted.', const Color(0xFFEF4444));
    } catch (e) {
      _showSnackbar('Could not delete: $e', const Color(0xFFEF4444));
    }
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

  void _showAddFoodItemDialog([Map<String, dynamic>? existing]) {
    final e = existing ?? const <String, dynamic>{};
    final nameController = TextEditingController(text: '${e['name'] ?? ''}');
    final servingController = TextEditingController(text: '${e['servingSize'] ?? '100 g'}');
    final kcalController = TextEditingController(text: existing == null ? '' : _num(e['calories']));
    final pController = TextEditingController(text: existing == null ? '' : _num(e['protein']));
    final cController = TextEditingController(text: existing == null ? '' : _num(e['carbs']));
    final fController = TextEditingController(text: existing == null ? '' : _num(e['fat'] ?? e['fats']));
    final fiberController = TextEditingController(text: existing == null ? '' : _num(e['fiber']));
    String selectedCat = existing == null ? 'Fruits' : '${e['category'] ?? 'Fruits'}';

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
                double n(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
                if (name.isNotEmpty) {
                  Navigator.pop(ctx);
                  _save(existing, {
                    'name': name,
                    'title': name,
                    'category': selectedCat,
                    'servingSize': servingController.text.trim(),
                    'calories': n(kcalController).round(),
                    'protein': n(pController),
                    'carbs': n(cController),
                    'fat': n(fController),
                    'fiber': n(fiberController),
                  });
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
                ClipRRect(borderRadius: BorderRadius.circular(14), child: NetOrAssetImage(f['img'] as String, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.restaurant, size: 36))),
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
                      _showAddFoodItemDialog(f);
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
                      _delete(f);
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
    final items = _src.items;
    final cats = {for (final f in items) '${f['category'] ?? 'Other'}'};
    final complete = items.where((f) => (f['calories'] ?? 0) != 0 && f['protein'] != null && f['carbs'] != null).length;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final added = items.where((f) => DateTime.tryParse('${f['createdAt'] ?? ''}')?.isAfter(weekAgo) ?? false).length;
    final top = [...items]..sort((a, b) => ((b['protein'] as num? ?? 0)).compareTo(a['protein'] as num? ?? 0));
    final kpis = [
      {'title': 'Food Items', 'val': fmtInt(items.length), 'growth': '+$added added this week', 'icon': Icons.kitchen_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'title': 'Full Macros', 'val': fmtPct(items.isEmpty ? 0 : complete / items.length * 100), 'growth': 'Calories, protein & carbs set', 'icon': Icons.verified_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Food Categories', 'val': '${cats.length} Groups', 'growth': 'Plus live search in the app', 'icon': Icons.category_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Top Protein', 'val': top.isEmpty ? '-' : '${top.first['name']}', 'growth': top.isEmpty ? 'Add foods to see' : '${_num(top.first['protein'])}g protein', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
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
      if (_selectedCatIndex > 0 && _selectedCatIndex < _foodCategories.length) {
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
                child: NetOrAssetImage(
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
