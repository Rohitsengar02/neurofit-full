import 'package:flutter/material.dart';

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

  final List<String> _dietCategories = ['All Diet Plans', 'High Protein Shred', 'Keto Protocol', 'Plant-Based Fuel', 'Lean Bulk'];

  final List<String> _availableRecipes = [
    'High-Protein Blueberry Whey Oatmeal',
    'Lemon Herb Grilled Chicken with Quinoa',
    'Avocado & Egg Salad with Sourdough',
    'Tofu & Edamame Teriyaki Power Bowl',
    'Crispy Air-Fryer Salmon Bowl',
    'Greek Yogurt & Mixed Almonds Snack',
  ];

  late List<Map<String, dynamic>> _dietPlansList;

  @override
  void initState() {
    super.initState();

    _dietPlansList = [
      {
        'id': 'DIET-301',
        'title': '21-Day High-Protein Lean Shred Diet',
        'category': 'High Protein Shred',
        'tag': '🔥 Most Popular',
        'calories': '2,100 kcal / Day',
        'macros': 'P: 180g (35%) • C: 200g (40%) • F: 55g (25%)',
        'duration': '21 Days',
        'enrolled': '14,200 Athletes',
        'rating': '4.9 ★',
        'goal': 'Rapid Fat Loss with Muscle Retention',
        'img': 'assets/images/workout_banner_1.png',
        'meals': [
          {'slot': 'Breakfast', 'recipe': 'High-Protein Blueberry Whey Oatmeal', 'kcal': '420 kcal'},
          {'slot': 'Lunch', 'recipe': 'Lemon Herb Grilled Chicken with Quinoa', 'kcal': '540 kcal'},
          {'slot': 'Snack', 'recipe': 'Greek Yogurt & Mixed Almonds Snack', 'kcal': '280 kcal'},
          {'slot': 'Dinner', 'recipe': 'Crispy Air-Fryer Salmon Bowl', 'kcal': '580 kcal'},
        ],
      },
      {
        'id': 'DIET-302',
        'title': 'Ketogenic Metabolic Fat Burn Protocol',
        'category': 'Keto Protocol',
        'tag': 'Low Carb',
        'calories': '1,950 kcal / Day',
        'macros': 'P: 140g (30%) • C: 25g (5%) • F: 145g (65%)',
        'duration': '4 Weeks',
        'enrolled': '8,650 Athletes',
        'rating': '4.8 ★',
        'goal': 'Ketosis & Accelerated Lipolysis',
        'img': 'assets/images/athlete_transform_1787825621309.jpg',
        'meals': [
          {'slot': 'Breakfast', 'recipe': 'Avocado & Egg Salad with Sourdough', 'kcal': '460 kcal'},
          {'slot': 'Lunch', 'recipe': 'Grilled Chicken with Garlic Butter Asparagus', 'kcal': '520 kcal'},
          {'slot': 'Dinner', 'recipe': 'Wild Salmon Fillet with Olive Oil Salad', 'kcal': '620 kcal'},
        ],
      },
      {
        'id': 'DIET-303',
        'title': 'Plant-Based Athlete Muscle Fuel',
        'category': 'Plant-Based Fuel',
        'tag': '100% Vegan',
        'calories': '2,400 kcal / Day',
        'macros': 'P: 150g (25%) • C: 320g (55%) • F: 50g (20%)',
        'duration': '8 Weeks',
        'enrolled': '6,410 Athletes',
        'rating': '4.9 ★',
        'goal': 'Endurance, Recovery & Clean Bulking',
        'img': 'assets/images/hero_banner_1.png',
        'meals': [
          {'slot': 'Breakfast', 'recipe': 'Chia Seed & Soy Milk Protein Oatmeal', 'kcal': '480 kcal'},
          {'slot': 'Lunch', 'recipe': 'Tofu & Edamame Teriyaki Power Bowl', 'kcal': '580 kcal'},
          {'slot': 'Dinner', 'recipe': 'Lentil & Sweet Potato Protein Curry', 'kcal': '640 kcal'},
        ],
      },
      {
        'id': 'DIET-304',
        'title': 'Clean Hypertrophy 3000 kcal Bulk Diet',
        'category': 'Lean Bulk',
        'tag': 'Mass Gainer',
        'calories': '3,050 kcal / Day',
        'macros': 'P: 210g (30%) • C: 380g (50%) • F: 75g (20%)',
        'duration': '12 Weeks',
        'enrolled': '9,120 Athletes',
        'rating': '5.0 ★',
        'goal': 'Lean Muscle Hypertrophy without Fat Gain',
        'img': 'assets/images/hero_banner_4.png',
        'meals': [
          {'slot': 'Breakfast', 'recipe': 'Double Scoop Whey Oatmeal with Peanut Butter', 'kcal': '680 kcal'},
          {'slot': 'Lunch', 'recipe': 'Extra Large Chicken & Brown Rice Bowl', 'kcal': '780 kcal'},
          {'slot': 'Snack', 'recipe': 'Mass Protein Shake with Banana & Honey', 'kcal': '520 kcal'},
          {'slot': 'Dinner', 'recipe': 'Salmon Fillet with Sweet Potato Mash', 'kcal': '750 kcal'},
        ],
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

  void _showAddDietPlanDialog() {
    final titleController = TextEditingController();
    final kcalController = TextEditingController(text: '2,200 kcal/Day');
    String selectedCat = 'High Protein Shred';
    String selectedBreakfast = _availableRecipes[0];
    String selectedLunch = _availableRecipes[1];
    String selectedDinner = _availableRecipes[4];

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
                  setState(() {
                    _dietPlansList.insert(0, {
                      'id': 'DIET-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                      'title': title,
                      'category': selectedCat,
                      'tag': 'New Diet',
                      'calories': kcalController.text.trim(),
                      'macros': 'P: 160g • C: 190g • F: 50g',
                      'duration': '21 Days',
                      'enrolled': '0 Athletes',
                      'rating': '5.0 ★',
                      'goal': 'Custom Macro Adherence',
                      'img': 'assets/images/workout_banner_1.png',
                      'meals': [
                        {'slot': 'Breakfast', 'recipe': selectedBreakfast, 'kcal': '420 kcal'},
                        {'slot': 'Lunch', 'recipe': selectedLunch, 'kcal': '540 kcal'},
                        {'slot': 'Dinner', 'recipe': selectedDinner, 'kcal': '580 kcal'},
                      ],
                    });
                  });
                  Navigator.pop(ctx);
                  _showSnackbar('Diet Plan "$title" published!', const Color(0xFF8B5CF6));
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
                ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(d['img'] as String, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.restaurant_menu, size: 36))),
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
                      _showSnackbar('Edit diet plan opened.', const Color(0xFF3B82F6));
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
                      setState(() => _dietPlansList.removeWhere((item) => item['id'] == d['id']));
                      _showSnackbar('Diet plan deleted.', const Color(0xFFEF4444));
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
    final kpis = [
      {'title': 'Diet Plans', 'val': '32 Plans', 'growth': '+6 New protocols', 'icon': Icons.restaurant_menu_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Athletes Enrolled', 'val': '38.4K', 'growth': '+21.4% adherence', 'icon': Icons.groups_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'High-Protein Shred', 'val': '14.2K Users', 'growth': 'Top selected', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'Avg Duration', 'val': '28 Days', 'growth': '4-Week cycle', 'icon': Icons.date_range_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
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
      if (_selectedFilterIndex > 0) {
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
                child: Image.asset(
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
