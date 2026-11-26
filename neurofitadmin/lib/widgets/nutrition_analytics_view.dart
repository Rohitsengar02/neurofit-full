import 'package:flutter/material.dart';
import '../backend/admin_data.dart';

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

class _NutritionAnalyticsViewState extends State<NutritionAnalyticsView> with LiveStats {
  num _nu(String k) => ins.n('nutrition', k);
  double get _macroKcal => _nu('protein') * 4.0 + _nu('carbs') * 4.0 + _nu('fat') * 9.0;
  double _macroShare(String k, int perG) => _macroKcal == 0 ? 0 : _nu(k) * perG / _macroKcal;
  String _avgG(String k) => '${(_nu('days_logged') == 0 ? 0 : _nu(k) / st.n('nutrition', 'days_logged')).round()}g';

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
      {'title': 'Total Meals Logged', 'val': fmtShort(_nu('meals')), 'growth': '${fmtInt(st.n('nutrition', 'users'))} people logging', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Avg Calorie Intake', 'val': '${fmtInt(_nu('avg_kcal'))} kcal', 'growth': 'Target: ${fmtInt(_nu('target_kcal'))} kcal', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEF2F2)},
      {'title': 'Protein Adherence', 'val': fmtPct(_nu('protein_adherence')), 'growth': 'days within 90% of target', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Water Logs', 'val': '${(st.n('nutrition', 'avg_water') * 0.25).toStringAsFixed(1)}L / Day', 'growth': '${fmtInt(_nu('water_logs'))} days logged', 'icon': Icons.water_drop_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
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
                child: const Text('All time', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildMacroBar('Protein', '${_avgG('protein')} / ${(_macroShare('protein', 4) * 100).round()}%', const Color(0xFF3B82F6), _macroShare('protein', 4))),
              const SizedBox(width: 10),
              Expanded(child: _buildMacroBar('Carbohydrates', '${_avgG('carbs')} / ${(_macroShare('carbs', 4) * 100).round()}%', const Color(0xFF10B981), _macroShare('carbs', 4))),
              const SizedBox(width: 10),
              Expanded(child: _buildMacroBar('Healthy Fats', '${_avgG('fat')} / ${(_macroShare('fat', 9) * 100).round()}%', const Color(0xFFF59E0B), _macroShare('fat', 9))),
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
    const slotColor = {'breakfast': Color(0xFFF59E0B), 'lunch': Color(0xFF10B981), 'snack': Color(0xFF8B5CF6), 'snacks': Color(0xFF8B5CF6), 'dinner': Color(0xFF3B82F6)};
    final slots = ins.list('nutrition', 'slots');
    final slotTotal = slots.fold<num>(0, (a, r) => a + ((r['n'] as num?) ?? 0));
    final mealSlots = [
      for (final m in slots)
        {
          'slot': '${m['slot']}'.isEmpty ? 'Other' : '${m['slot']}'[0].toUpperCase() + '${m['slot']}'.substring(1),
          'logs': '${fmtShort(m['n'] as num? ?? 0)} Logs',
          'avgKcal': '${fmtInt(m['avg_kcal'] as num? ?? 0)} kcal',
          'pct': share(m['n'] as num? ?? 0, slotTotal),
          'color': slotColor['${m['slot']}'] ?? const Color(0xFF64748B),
        },
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
      for (final f in ins.list('nutrition', 'topFoods'))
        {'name': '${f['name']}', 'cat': '${f['cat']}'.isEmpty ? 'Food' : '${f['cat']}', 'count': '${fmtShort(f['n'] as num? ?? 0)} times', 'kcal': '${fmtInt(f['kcal'] as num? ?? 0)} kcal', 'p': '${f['protein'] ?? 0}g Protein'},
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
