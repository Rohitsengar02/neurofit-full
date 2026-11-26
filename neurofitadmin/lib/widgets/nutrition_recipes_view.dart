import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import '../backend/live_backend.dart';
import 'net_or_asset_image.dart';

class NutritionRecipesView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const NutritionRecipesView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<NutritionRecipesView> createState() => _NutritionRecipesViewState();
}

class _NutritionRecipesViewState extends State<NutritionRecipesView> {
  int _selectedCatIndex = 0;
  String _searchQuery = '';

  List<String> get _recipeCategories => ['All Recipes', ...{..._defaultCats, for (final r in _src.items) '${r['category'] ?? 'Other'}'}];
  static const _defaultCats = ['Breakfast', 'High Protein', 'Keto', 'Vegan', 'Pre-Workout'];

  final AdminList _src = AdminList.of('/recipes?limit=2000');

  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  static String _n(dynamic v) { final d = _d(v); return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1); }

  static Map<String, dynamic> _row(Map<String, dynamic> r) {
    final prep = r['prepTime'] ?? r['prepTimeMinutes'] ?? r['readyInMinutes'];
    return {
      ...r,
      'id': r['id'],
      'title': '${r['title'] ?? r['name'] ?? 'Recipe'}',
      'category': '${r['category'] ?? 'Other'}',
      'prepTime': prep == null ? '-' : (prep is num ? '$prep mins' : '$prep'),
      'calories': '${_n(r['calories'])} kcal',
      'protein': '${_n(r['protein'])}g P',
      'carbs': '${_n(r['carbs'])}g C',
      'fats': '${_n(r['fat'] ?? r['fats'])}g F',
      'difficulty': '${r['difficulty'] ?? 'Easy'}',
      'rating': r['rating'] == null ? 'New' : '${r['rating']} ★',
      'tag': r['isFeatured'] == true ? '🔥 Featured' : '${r['category'] ?? ''}',
      'img': '${r['imageUrl'] ?? r['image'] ?? ''}',
      'ingredients': [for (final x in (r['ingredients'] as List? ?? const [])) x is Map ? '${x['amount'] ?? ''} ${x['name'] ?? ''}'.trim() : '$x'],
      'steps': [for (final x in (r['steps'] as List? ?? r['instructions'] as List? ?? const [])) '$x'],
    };
  }

  List<Map<String, dynamic>> get _recipesList => [for (final r in _src.items) _row(r)];

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
        await Api.send('POST', '/recipes', {...body, 'isActive': true, 'status': 'Active', 'ingredients': [], 'steps': []});
      } else {
        await Api.send('PUT', '/recipes/${existing['id']}', body);
      }
      await _src.load();
      _showSnackbar(existing == null ? 'Recipe "${body['title']}" published!' : 'Recipe "${body['title']}" updated.', const Color(0xFF10B981));
    } catch (e) {
      _showSnackbar('Could not save: $e', const Color(0xFFEF4444));
    }
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    try {
      await Api.send('DELETE', '/recipes/${r['id']}');
      await _src.load();
      _showSnackbar('Recipe deleted.', const Color(0xFFEF4444));
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

  void _showAddRecipeDialog([Map<String, dynamic>? existing]) {
    final e = existing ?? const <String, dynamic>{};
    final titleController = TextEditingController(text: '${e['title'] ?? e['name'] ?? ''}');
    final kcalController = TextEditingController(text: existing == null ? '' : _n(e['calories']));
    final pController = TextEditingController(text: existing == null ? '' : _n(e['protein']));
    String selectedCat = existing == null ? 'High Protein' : '${e['category'] ?? 'High Protein'}';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: const [
              Icon(Icons.menu_book_rounded, color: Color(0xFF10B981), size: 22),
              SizedBox(width: 8),
              Text('Create New Recipe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recipe Title', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                TextField(
                  controller: titleController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'e.g. Crispy Air-Fryer Salmon Bowl',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCat,
                      items: _recipeCategories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) => setDlgState(() => selectedCat = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Calories (kcal)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: kcalController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Protein (g)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: pController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  Navigator.pop(ctx);
                  _save(existing, {'title': title, 'name': title, 'category': selectedCat, 'calories': _d(kcalController.text).round(), 'protein': _d(pController.text)});
                }
              },
              child: const Text('Publish Recipe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetailModal(Map<String, dynamic> r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _buildRecipeDetailBottomSheet(r),
    );
  }

  Widget _buildRecipeDetailBottomSheet(Map<String, dynamic> r) {
    final ingredients = (r['ingredients'] as List<dynamic>?) ?? [];
    final steps = (r['steps'] as List<dynamic>?) ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
                ClipRRect(borderRadius: BorderRadius.circular(14), child: NetOrAssetImage(r['img'] as String, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.soup_kitchen, size: 36))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                        child: Text(r['category'] as String, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                      ),
                      const SizedBox(height: 4),
                      Text(r['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text('Prep Time: ${r['prepTime']} • ${r['difficulty']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18)),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 0.8, color: Color(0xFFF1F5F9)),

          // 4 Macro Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMacroBox('Calories', r['calories'] as String, const Color(0xFFF59E0B)),
                _buildMacroBox('Protein', r['protein'] as String, const Color(0xFF3B82F6)),
                _buildMacroBox('Carbs', r['carbs'] as String, const Color(0xFF10B981)),
                _buildMacroBox('Fats', r['fats'] as String, const Color(0xFFEF4444)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const Text('Ingredients Checklist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                ...ingredients.map((ing) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(ing as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                const Text('Preparation Instructions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                ...List.generate(steps.length, (i) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                      Expanded(child: Text(steps[i] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.3))),
                    ],
                  ),
                )),
              ],
            ),
          ),

          // Bottom Edit/Delete Actions
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
                      _showAddRecipeDialog(r);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                    label: const Text('Edit Recipe', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      Navigator.pop(context);
                      _delete(r);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white),
                    label: const Text('Delete Recipe', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBox(String label, String val, Color color) {
    return Container(
      width: 74,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
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
        _buildAnimatedSection(3, _buildRecipesGrid()),
      ],
    );
  }

  Widget _buildKpiCarousel() {
    final items = _src.items;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final added = items.where((r) => DateTime.tryParse('${r['createdAt'] ?? ''}')?.isAfter(weekAgo) ?? false).length;
    final hp = items.where((r) => _d(r['protein']) >= 25).length;
    final keto = items.where((r) => _d(r['carbs']) <= 20 || '${r['category']}'.toLowerCase().contains('keto')).length;
    final preps = [for (final r in items) if (r['prepTime'] is num) (r['prepTime'] as num).toDouble()];
    final kpis = [
      {'title': 'Total Recipes', 'val': fmtInt(items.length), 'growth': '+$added New recipes', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'High-Protein', 'val': fmtInt(hp), 'growth': '${fmtPct(items.isEmpty ? 0 : hp / items.length * 100)} of database', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'title': 'Keto & Low Carb', 'val': fmtInt(keto), 'growth': '20g carbs or less', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Avg Prep Time', 'val': preps.isEmpty ? '-' : '${(preps.reduce((a, b) => a + b) / preps.length).round()} mins', 'growth': 'Across all recipes', 'icon': Icons.timer_outlined, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
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
                    decoration: const InputDecoration(hintText: 'Search recipes (e.g. Oatmeal, Chicken)...', border: InputBorder.none, isDense: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showAddRecipeDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(
              children: const [
                Icon(Icons.add_rounded, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text('Add Recipe', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
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
        children: List.generate(_recipeCategories.length, (i) {
          final isSelected = _selectedCatIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCatIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade200),
                ),
                child: Text(
                  _recipeCategories[i],
                  style: TextStyle(fontSize: 10.5, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRecipesGrid() {
    final filtered = _recipesList.where((r) {
      if (_selectedCatIndex > 0 && _selectedCatIndex < _recipeCategories.length) {
        final cat = _recipeCategories[_selectedCatIndex];
        if (r['category'] != cat) return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (r['title'] as String).toLowerCase().contains(q) ||
          (r['category'] as String).toLowerCase().contains(q);
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
        final r = filtered[i];
        return GestureDetector(
          onTap: () => _showRecipeDetailModal(r),
          child: _buildRecipeCard(r),
        );
      },
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> r) {
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
                  r['img'] as String,
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
                  child: Text(r['category'] as String, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['title'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(r['calories'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
                    const SizedBox(width: 6),
                    Text(r['protein'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 11, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Expanded(child: Text(r['prepTime'] as String, style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
