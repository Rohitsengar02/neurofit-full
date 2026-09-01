import 'package:flutter/material.dart';

class GenericCategoryView extends StatelessWidget {
  final String categoryName;
  final String subActionTitle;
  final Color categoryColor;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const GenericCategoryView({
    super.key,
    required this.categoryName,
    required this.subActionTitle,
    required this.categoryColor,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  Widget _buildAnimatedSection(int index, Widget child) {
    final int safeIndex = index < fadeAnimations.length ? index : fadeAnimations.length - 1;
    return FadeTransition(
      opacity: fadeAnimations[safeIndex],
      child: SlideTransition(
        position: slideAnimations[safeIndex],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header Card
        _buildAnimatedSection(
          0,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: categoryColor.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.dashboard_customize_rounded, color: categoryColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            categoryName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Live Hub',
                              style: TextStyle(color: categoryColor, fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Viewing: $subActionTitle module',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Quick Stats Metric Row
        _buildAnimatedSection(
          1,
          Row(
            children: [
              Expanded(child: _buildMetricMiniCard('Total Records', '1,420', '+12.4%', categoryColor)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricMiniCard('Active Status', '98.6%', 'Online', const Color(0xFF10B981))),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Content Placeholder Panel
        _buildAnimatedSection(
          2,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$categoryName • $subActionTitle', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('Manage', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: categoryColor)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFF65D300), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Real-time $subActionTitle Feed', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            Text('All data streams and filters are operational.', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricMiniCard(String label, String val, String tag, Color color) {
    return Container(
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
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(6)),
                child: Text(tag, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
