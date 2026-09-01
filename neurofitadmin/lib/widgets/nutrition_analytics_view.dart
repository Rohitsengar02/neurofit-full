import 'package:flutter/material.dart';

class NutritionAnalyticsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const NutritionAnalyticsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<NutritionAnalyticsView> createState() => _NutritionAnalyticsViewState();
}

class _NutritionAnalyticsViewState extends State<NutritionAnalyticsView> {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedSection(0, _buildKpiCarousel()),
        const SizedBox(height: 16),
        _buildAnimatedSection(1, _buildMacroDistributionCard()),
        const SizedBox(height: 16),
        _buildAnimatedSection(2, _buildMealTimingAndLoggingCard()),
        const SizedBox(height: 16),
        _buildAnimatedSection(3, _buildTopLoggedItemsCard()),
      ],
    );
  }

  Widget _buildKpiCarousel() {
    final kpis = [
      {'title': 'Total Meals Logged', 'val': '1.42M', 'growth': '+18.6% this month', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Avg Calorie Intake', 'val': '2,180 kcal', 'growth': 'Target: 2,200 kcal', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEF2F2)},
      {'title': 'Protein Adherence', 'val': '86.4%', 'growth': '+4.2% macro compliance', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Water Logs', 'val': '2.8L / Day', 'growth': 'Hydration goal met', 'icon': Icons.water_drop_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
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

  Widget _buildMacroDistributionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Macro Distribution Breakdown', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(6)),
                child: const Text('Last 7 Days', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildMacroBar('Protein', '145g / 35%', const Color(0xFF3B82F6), 0.35)),
              const SizedBox(width: 10),
              Expanded(child: _buildMacroBar('Carbohydrates', '220g / 45%', const Color(0xFF10B981), 0.45)),
              const SizedBox(width: 10),
              Expanded(child: _buildMacroBar('Healthy Fats', '52g / 20%', const Color(0xFFF59E0B), 0.20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar(String label, String val, Color color, double ratio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: ratio, backgroundColor: color.withOpacity(0.12), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6),
        ),
      ],
    );
  }

  Widget _buildMealTimingAndLoggingCard() {
    final mealSlots = [
      {'slot': 'Breakfast', 'logs': '482K Logs', 'avgKcal': '520 kcal', 'pct': '32%', 'color': const Color(0xFFF59E0B)},
      {'slot': 'Lunch', 'logs': '540K Logs', 'avgKcal': '680 kcal', 'pct': '38%', 'color': const Color(0xFF10B981)},
      {'slot': 'Snacks', 'logs': '210K Logs', 'avgKcal': '240 kcal', 'pct': '14%', 'color': const Color(0xFF8B5CF6)},
      {'slot': 'Dinner', 'logs': '410K Logs', 'avgKcal': '620 kcal', 'pct': '28%', 'color': const Color(0xFF3B82F6)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Meal Time Logging Distribution', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          ...mealSlots.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: m['color'] as Color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(m['slot'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                  ],
                ),
                Text('${m['logs']} • ${m['avgKcal']}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTopLoggedItemsCard() {
    final items = [
      {'name': 'Grilled Chicken Breast (200g)', 'cat': 'Poultry', 'count': '94.2K times', 'kcal': '330 kcal', 'p': '62g Protein'},
      {'name': 'Rolled Oats with Whey (1 Bowl)', 'cat': 'Grains', 'count': '88.5K times', 'kcal': '420 kcal', 'p': '34g Protein'},
      {'name': 'Medium Red Apple (150g)', 'cat': 'Fruits', 'count': '76.1K times', 'kcal': '78 kcal', 'p': '0.5g Protein'},
      {'name': 'Greek Yogurt 0% Fat (200g)', 'cat': 'Dairy', 'count': '64.8K times', 'kcal': '130 kcal', 'p': '22g Protein'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Logged Food Items', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          ...items.map((it) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it['name'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      Text('${it['cat']} • ${it['count']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(it['kcal'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
                    Text(it['p'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
