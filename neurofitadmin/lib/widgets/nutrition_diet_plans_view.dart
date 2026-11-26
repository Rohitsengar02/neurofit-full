import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import '../backend/live_backend.dart';
import 'net_or_asset_image.dart';

class NutritionDietPlansView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const NutritionDietPlansView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<NutritionDietPlansView> createState() => _NutritionDietPlansViewState();
}

class _NutritionDietPlansViewState extends State<NutritionDietPlansView> {
  int _selectedFilterIndex = 0;
  String _searchQuery = '';

  List<String> get _dietCategories => ['All Diet Plans', ...{..._defaultCats, for (final d in _src.items) '${d['category'] ?? 'Other'}'}];
  static const _defaultCats = ['High Protein Shred', 'Keto Protocol', 'Plant-Based Fuel', 'Lean Bulk'];

  final AdminList _src = AdminList.of('/diet-plans?limit=1000');
  final AdminList _recipes = AdminList.of('/recipes?limit=2000');

  List<String> get _availableRecipes {
    final r = [for (final x in _recipes.items) '${x['title'] ?? x['name'] ?? ''}'].where((t) => t.isNotEmpty).toSet().toList();
    return r.isEmpty ? ['Add recipes first'] : r;
  }

  Map<String, dynamic>? _recipe(String title) {
    for (final x in _recipes.items) {
      if ('${x['title'] ?? x['name']}' == title) return x;
    }
    return null;
  }

  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  static Map<String, dynamic> _row(Map<String, dynamic> d) {
    final days = (d['durationDays'] as num?)?.toInt();
    final enrolled = (d['enrolledCount'] as num? ?? 0).toInt();
    return {
      ...d,
      'id': d['id'],
      'title': '${d['title'] ?? d['name'] ?? 'Diet plan'}',
      'category': '${d['category'] ?? 'Other'}',
      'tag': d['isFeatured'] == true ? '🔥 Featured' : '${d['tag'] ?? d['category'] ?? ''}',
      'calories': '${fmtInt(_d(d['calories'] ?? d['targetCalories']))} kcal / Day',
      'macros': 'P: ${_d(d['protein']).round()}g • C: ${_d(d['carbs']).round()}g • F: ${_d(d['fat']).round()}g',
      'duration': days == null ? '${d['duration'] ?? '-'}' : '$days Days',
      'enrolled': '${fmtInt(enrolled)} Athletes',
      'rating': d['rating'] == null ? 'New' : '${d['rating']} ★',
      'goal': '${d['goal'] ?? d['description'] ?? ''}',
      'img': '${d['imageUrl'] ?? d['image'] ?? ''}',
      'meals': [
        for (final m in (d['meals'] as List? ?? const []))
          if (m is Map) {'slot': '${m['slot'] ?? ''}', 'recipe': '${m['recipe'] ?? m['title'] ?? ''}', 'kcal': '${_d(m['calories'] ?? m['kcal']).round()} kcal'},
      ],
    };
  }

  List<Map<String, dynamic>> get _dietPlansList => [for (final d in _src.items) _row(d)];

  void _changed() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    _src.addListener(_changed);
    _recipes.addListener(_changed);
    _src.load();
    _recipes.load();
  }

  @override
  void dispose() {
    _src.removeListener(_changed);
    _recipes.removeListener(_changed);
    super.dispose();
  }

  Future<void> _save(Map<String, dynamic>? existing, Map<String, dynamic> body) async {
    try {
      if (existing == null) {
        await Api.send('POST', '/diet-plans', {...body, 'isActive': true, 'status': 'Active', 'enrolledCount': 0});
      } else {
        await Api.send('PUT', '/diet-plans/${existing['id']}', body);
      }
      await _src.load();
      _showSnackbar(existing == null ? 'Diet Plan "${body['title']}" published!' : 'Diet Plan "${body['title']}" updated.', const Color(0xFF8B5CF6));
    } catch (e) {
      _showSnackbar('Could not save: $e', const Color(0xFFEF4444));
    }
  }

  Future<void> _delete(Map<String, dynamic> d) async {
    try {
      await Api.send('DELETE', '/diet-plans/${d['id']}');
      await _src.load();
      _showSnackbar('Diet plan deleted.', const Color(0xFFEF4444));
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

  void _showAddDietPlanDialog([Map<String, dynamic>? existing]) {
    final e = existing ?? const <String, dynamic>{};
    final opts = _availableRecipes;
    String pick(String slot, int i) {
      for (final m in (e['meals'] as List? ?? const [])) {
        if (m is Map && m['slot'] == slot && opts.contains('${m['recipe']}')) return '${m['recipe']}';
      }
      return opts[i < opts.length ? i : 0];
    }
    final titleController = TextEditingController(text: '${e['title'] ?? e['name'] ?? ''}');
    final kcalController = TextEditingController(text: existing == null ? '' : '${_d(e['calories']).round()}');
    String selectedCat = existing == null ? 'High Protein Shred' : '${e['category'] ?? 'High Protein Shred'}';
    String selectedBreakfast = pick('Breakfast', 0);
    String selectedLunch = pick('Lunch', 1);
    String selectedDinner = pick('Dinner', 2);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: const [
              Icon(Icons.restaurant_menu_rounded, color: Color(0xFF8B5CF6), size: 22),
              SizedBox(width: 8),
              Text('Create Diet Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Diet Plan Title', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                TextField(
                  controller: titleController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'e.g. 14-Day Rapid Shred Diet Protocol',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Diet Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCat,
                      items: _dietCategories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) => setDlgState(() => selectedCat = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Target Daily Calories', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                TextField(
                  controller: kcalController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
                const SizedBox(height: 12),
                const Text('Assign Recipes to Daily Schedule:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                _buildRecipeDropdown('Breakfast Recipe', selectedBreakfast, (val) => setDlgState(() => selectedBreakfast = val)),
                const SizedBox(height: 6),
                _buildRecipeDropdown('Lunch Recipe', selectedLunch, (val) => setDlgState(() => selectedLunch = val)),
                const SizedBox(height: 6),
                _buildRecipeDropdown('Dinner Recipe', selectedDinner, (val) => setDlgState(() => selectedDinner = val)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  Navigator.pop(ctx);
                  final meals = [
                    for (final m in [['Breakfast', selectedBreakfast], ['Lunch', selectedLunch], ['Dinner', selectedDinner]])
                      if (_recipe(m[1]) != null)
                        {'slot': m[0], 'recipe': m[1], 'recipeId': _recipe(m[1])!['id'], 'calories': _d(_recipe(m[1])!['calories']).round(),
                         'protein': _d(_recipe(m[1])!['protein']), 'carbs': _d(_recipe(m[1])!['carbs']), 'fat': _d(_recipe(m[1])!['fat'])},
                  ];
                  double sum(String k) => meals.fold<double>(0, (a, m) => a + _d(m[k]));
                  final kcal = _d(kcalController.text);
                  _save(existing, {
                    'title': title, 'name': title, 'category': selectedCat, 'meals': meals,
                    'calories': kcal > 0 ? kcal.round() : sum('calories').round(),
                    'protein': sum('protein').round(), 'carbs': sum('carbs').round(), 'fat': sum('fat').round(),
                    if (existing == null) 'durationDays': 21,
                  });
                }
              },
              child: const Text('Publish Diet Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeDropdown(String label, String currentVal, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentVal,
              items: _availableRecipes.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) => onChanged(val!),
            ),
          ),
        ),
      ],
    );
  }

  void _showDietDetailModal(Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _buildDietDetailBottomSheet(d),
    );
  }

  Widget _buildDietDetailBottomSheet(Map<String, dynamic> d) {
    final meals = (d['meals'] as List<dynamic>?) ?? [];

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
                ClipRRect(borderRadius: BorderRadius.circular(14), child: NetOrAssetImage(d['img'] as String, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.restaurant_menu, size: 36))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(6)),
                        child: Text(d['category'] as String, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF8B5CF6))),
                      ),
                      const SizedBox(height: 4),
                      Text(d['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text('Goal: ${d['goal']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18)),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 0.8, color: Color(0xFFF1F5F9)),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.pie_chart_rounded, size: 16, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(d['macros'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF334155)))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const Text('Daily Recipe & Meal Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                ...meals.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['slot'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF8B5CF6))),
                            const SizedBox(height: 2),
                            Text(m['recipe'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                      Text(m['kcal'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
                    ],
                  ),
                )),
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
                      _showAddDietPlanDialog(d);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                    label: const Text('Edit Diet Plan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      Navigator.pop(context);
                      _delete(d);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white),
                    label: const Text('Delete Diet Plan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
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
        _buildAnimatedSection(3, _buildDietPlansGrid()),
      ],
    );
  }

  Widget _buildKpiCarousel() {
    final items = _src.items;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final added = items.where((d) => DateTime.tryParse('${d['createdAt'] ?? ''}')?.isAfter(weekAgo) ?? false).length;
    final enrolled = items.fold<num>(0, (a, d) => a + (d['enrolledCount'] as num? ?? 0));
    final top = [...items]..sort((a, b) => (b['enrolledCount'] as num? ?? 0).compareTo(a['enrolledCount'] as num? ?? 0));
    final durs = [for (final d in items) if (d['durationDays'] is num) (d['durationDays'] as num).toDouble()];
    final kpis = [
      {'title': 'Diet Plans', 'val': '${items.length} Plans', 'growth': '+$added New protocols', 'icon': Icons.restaurant_menu_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Athletes Enrolled', 'val': fmtShort(enrolled), 'growth': 'Across all plans', 'icon': Icons.groups_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': top.isEmpty ? 'Top Plan' : '${top.first['title'] ?? top.first['name']}', 'val': top.isEmpty ? '-' : '${fmtShort(top.first['enrolledCount'] as num? ?? 0)} Users', 'growth': 'Top selected', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'Avg Duration', 'val': durs.isEmpty ? '-' : '${(durs.reduce((a, b) => a + b) / durs.length).round()} Days', 'growth': 'Average plan length', 'icon': Icons.date_range_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
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
                    decoration: const InputDecoration(hintText: 'Search diet plans (e.g. Keto, Shred, Bulk)...', border: InputBorder.none, isDense: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showAddDietPlanDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(
              children: const [
                Icon(Icons.add_rounded, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text('Create Diet Plan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
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
        children: List.generate(_dietCategories.length, (i) {
          final isSelected = _selectedFilterIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade200),
                ),
                child: Text(
                  _dietCategories[i],
                  style: TextStyle(fontSize: 10.5, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDietPlansGrid() {
    final filtered = _dietPlansList.where((d) {
      if (_selectedFilterIndex > 0 && _selectedFilterIndex < _dietCategories.length) {
        final cat = _dietCategories[_selectedFilterIndex];
        if (d['category'] != cat) return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (d['title'] as String).toLowerCase().contains(q) ||
          (d['category'] as String).toLowerCase().contains(q) ||
          (d['goal'] as String).toLowerCase().contains(q);
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
        final d = filtered[i];
        return GestureDetector(
          onTap: () => _showDietDetailModal(d),
          child: _buildDietCard(d),
        );
      },
    );
  }

  Widget _buildDietCard(Map<String, dynamic> d) {
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
                  d['img'] as String,
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
                  child: Text(d['tag'] as String, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['title'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(d['calories'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text(d['enrolled'] as String, style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(d['duration'] as String, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
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
