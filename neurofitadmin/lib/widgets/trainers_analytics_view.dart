import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrainersAnalyticsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const TrainersAnalyticsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<TrainersAnalyticsView> createState() => _TrainersAnalyticsViewState();
}

class _TrainersAnalyticsViewState extends State<TrainersAnalyticsView> {
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
        // 1. HERO BANNER: "Trainers Analytics" + Top Trainer badge
        _buildAnimatedSection(0, _buildTrainersHeroBanner()),
        const SizedBox(height: 20),

        // 2. 5 TOP KPI METRICS CARDS (HORIZONTAL CAROUSEL)
        _buildAnimatedSection(1, _buildTop5KpisSection()),
        const SizedBox(height: 20),

        // 3. TRAINER GROWTH & TRAINER STATUS
        _buildAnimatedSection(2, _buildTrainerGrowthSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(3, _buildTrainerStatusSection()),
        const SizedBox(height: 20),

        // 4. TRAINER VERIFICATION, SPECIALIZATION & RATING
        _buildAnimatedSection(4, _buildTrainerVerificationSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(5, _buildTrainersBySpecializationSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(6, _buildTrainersByRatingSection()),
        const SizedBox(height: 20),

        // 5. TOP PERFORMING TRAINERS, SESSIONS CONDUCTED & AVERAGE RATING
        _buildAnimatedSection(7, _buildTopPerformingTrainersSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(8, _buildSessionsConductedSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(9, _buildAverageSessionRatingSection()),
        const SizedBox(height: 20),

        // 6. TRAINER EARNINGS, PAYOUT STATUS & AVERAGE EARNINGS PER TRAINER
        _buildAnimatedSection(10, _buildTrainerEarningsSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(11, _buildEarningsByPayoutStatusSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(12, _buildAverageEarningsPerTrainerSection()),
        const SizedBox(height: 20),

        // 7. RECENT TRAINER REGISTRATIONS & RECENT TRAINER ACTIVITY
        _buildAnimatedSection(13, _buildRecentTrainerRegistrationsSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(13, _buildRecentTrainerActivitySection()),
        const SizedBox(height: 20),

        // 8. BOTTOM CTA BANNER
        _buildAnimatedSection(14, _buildBottomEmpowerTrainersBanner()),
      ],
    );
  }

  // 1. HERO BANNER
  Widget _buildTrainersHeroBanner() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/trainers_hero_banner.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (ctx, err, st) => Image.asset(
                  'assets/images/workout_banner_1.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.98),
                      Colors.white.withOpacity(0.94),
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.52, 0.82, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          children: [
                            TextSpan(text: 'Trainers '),
                            TextSpan(text: 'Analytics', style: TextStyle(color: Color(0xFF10B981))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 10, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(widget.selectedDateRange, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(
                    width: 210,
                    child: Text(
                      'Track trainer performance, engagement, earnings and growth metrics in real-time.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF8B5CF6), size: 16),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Top Trainer • Amit Sharma', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            Text('152 Sessions • 4.9★ Rating', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
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

  // 2. TOP 5 KPI CARDS
  Widget _buildTop5KpisSection() {
    final kpis = [
      {'title': 'Total Trainers', 'val': '1,243', 'growth': '+15.8%', 'icon': Icons.groups_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Active Trainers', 'val': '986', 'growth': '+18.5%', 'icon': Icons.how_to_reg_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'New Trainers', 'val': '135', 'growth': '+9.7%', 'icon': Icons.person_add_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'Total Sessions', 'val': '12,458', 'growth': '+14.8%', 'icon': Icons.event_available_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'title': 'Total Earnings', 'val': '₹24,58,300', 'growth': '+21.7%', 'icon': Icons.monetization_on_rounded, 'color': const Color(0xFF14B8A6), 'bg': const Color(0xFFE6FAF8)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: kpis.map((k) {
          final Color color = k['color'] as Color;
          return Container(
            width: 130,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: k['bg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(k['icon'] as IconData, color: color, size: 14)),
                    Text(k['growth'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(k['val'] as String, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ),
                Text(k['title'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 3. TRAINER GROWTH
  Widget _buildTrainerGrowthSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1. Trainer Growth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendDot(const Color(0xFF10B981), 'New Trainers'),
              const SizedBox(width: 14),
              _buildLegendDot(const Color(0xFF3B82F6), 'Active Trainers'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 50, getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final days = ['May 20', 'May 21', 'May 22', 'May 23', 'May 24', 'May 25', 'May 26'];
                        final i = v.toInt();
                        if (i >= 0 && i < days.length) {
                          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(days[i], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5, fontWeight: FontWeight.w600)));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 250,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 90), FlSpot(1, 140), FlSpot(2, 110), FlSpot(3, 160), FlSpot(4, 130), FlSpot(5, 180), FlSpot(6, 210)],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: const [FlSpot(0, 40), FlSpot(1, 80), FlSpot(2, 60), FlSpot(3, 100), FlSpot(4, 90), FlSpot(5, 120), FlSpot(6, 150)],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF3B82F6),
                    barWidth: 2.0,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. TRAINER STATUS
  Widget _buildTrainerStatusSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('2. Trainer Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 36,
                        sections: [
                          PieChartSectionData(color: const Color(0xFF10B981), value: 79.3, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: 10.8, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: 6.2, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF97316), value: 3.5, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('1,243', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Trainers', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Active', '79.3% (986)'),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Pending', '10.8% (135)'),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Inactive', '6.2% (78)'),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFFF97316), 'Suspended', '3.5% (44)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. TRAINER VERIFICATION
  Widget _buildTrainerVerificationSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('3. Trainer Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 36,
                        sections: [
                          PieChartSectionData(color: const Color(0xFF10B981), value: 64.2, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: 18.9, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF97316), value: 11.1, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: 5.8, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('1,243', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Applications', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Verified', '64.2% (798)'),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Pending', '18.9% (235)'),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFFF97316), 'Rejected', '11.1% (138)'),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Not Applied', '5.8% (72)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. TRAINERS BY SPECIALIZATION
  Widget _buildTrainersBySpecializationSection() {
    final specs = [
      {'name': 'Strength Training', 'pct': 0.31, 'val': '385 (31.0%)', 'color': const Color(0xFF10B981)},
      {'name': 'Yoga', 'pct': 0.221, 'val': '275 (22.1%)', 'color': const Color(0xFF3B82F6)},
      {'name': 'Weight Loss', 'pct': 0.200, 'val': '248 (20.0%)', 'color': const Color(0xFF8B5CF6)},
      {'name': 'HIIT', 'pct': 0.146, 'val': '182 (14.6%)', 'color': const Color(0xFF06B6D4)},
      {'name': 'Rehabilitation', 'pct': 0.095, 'val': '118 (9.5%)', 'color': const Color(0xFFF97316)},
      {'name': 'Others', 'pct': 0.028, 'val': '35 (2.8%)', 'color': const Color(0xFF64748B)},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('4. Trainers by Specialization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 16),
          ...specs.map((s) {
            final Color color = s['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                      Text(s['val'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: s['pct'] as double,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 4. TRAINERS BY RATING
  Widget _buildTrainersByRatingSection() {
    final ratings = [
      {'star': '5★', 'pct': 0.299, 'val': '372 (29.9%)', 'color': const Color(0xFF10B981)},
      {'star': '4★', 'pct': 0.386, 'val': '480 (38.6%)', 'color': const Color(0xFF3B82F6)},
      {'star': '3★', 'pct': 0.135, 'val': '168 (13.5%)', 'color': const Color(0xFFF59E0B)},
      {'star': '2★', 'pct': 0.036, 'val': '45 (3.6%)', 'color': const Color(0xFFF97316)},
      {'star': '1★', 'pct': 0.018, 'val': '23 (1.8%)', 'color': const Color(0xFFEF4444)},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('5. Trainers by Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 16),
          ...ratings.map((r) {
            final Color color = r['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 26, child: Text(r['star'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: r['pct'] as double,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(r['val'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 5. TOP PERFORMING TRAINERS
  Widget _buildTopPerformingTrainersSection() {
    final trainers = [
      {'name': 'Amit Sharma', 'desc': '152 Sessions • 4.9★', 'earnings': '₹4,75,500', 'img': 'assets/images/trainers_hero_banner.jpg'},
      {'name': 'Priya Patel', 'desc': '140 Sessions • 4.8★', 'earnings': '₹3,94,800', 'img': 'assets/images/athlete_transform_1787825621309.jpg'},
      {'name': 'Rahul Verma', 'desc': '118 Sessions • 4.9★', 'earnings': '₹2,25,000', 'img': 'assets/images/hero_banner_4.png'},
      {'name': 'Neha Singh', 'desc': '98 Sessions • 4.7★', 'earnings': '₹1,72,500', 'img': 'assets/images/hero_banner_1.png'},
      {'name': 'Karan Mehra', 'desc': '84 Sessions • 4.8★', 'earnings': '₹1,20,500', 'img': 'assets/images/workout_banner_1.png'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('6. Top Performing Trainers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...trainers.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(t['img'] as String, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      Text(t['desc'] as String, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(t['earnings'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const Text('Earnings', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // 5. SESSIONS CONDUCTED
  Widget _buildSessionsConductedSection() {
    final days = ['20', '21', '22', '23', '24', '25', '26'];
    final sessions = [140.0, 190.0, 165.0, 210.0, 250.0, 195.0, 220.0];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('7. Sessions Conducted', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 6),
          const Text('12,458', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('↑ 14.8% vs last 7 days', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 50, getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i >= 0 && i < days.length) {
                          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(days[i], style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: i == 4 ? const Color(0xFF10B981) : const Color(0xFF94A3B8))));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(days.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: sessions[i], color: i == 4 ? const Color(0xFF65D300) : const Color(0xFF86EFAC), width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. AVERAGE SESSION RATING
  Widget _buildAverageSessionRatingSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('8. Average Session Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 6),
          const Text('4.7 ★', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('↑ 0.2% vs last 7 days', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 3,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 4.4), FlSpot(1, 4.6), FlSpot(2, 4.5), FlSpot(3, 4.8), FlSpot(4, 4.7), FlSpot(5, 4.9), FlSpot(6, 4.7)],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF8B5CF6),
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFF8B5CF6).withOpacity(0.2), const Color(0xFF8B5CF6).withOpacity(0.0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. TRAINER EARNINGS OVERVIEW
  Widget _buildTrainerEarningsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('9. Trainer Earnings Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 6),
          const Text('₹24,58,300', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('↑ 21.7% vs last 7 days', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 100, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 550,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 210), FlSpot(1, 310), FlSpot(2, 380), FlSpot(3, 490), FlSpot(4, 320), FlSpot(5, 420), FlSpot(6, 520)],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFF10B981).withOpacity(0.2), const Color(0xFF10B981).withOpacity(0.0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. EARNINGS BY PAYOUT STATUS
  Widget _buildEarningsByPayoutStatusSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('10. Earnings by Payout Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 36,
                        sections: [
                          PieChartSectionData(color: const Color(0xFF10B981), value: 76.2, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: 17.3, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF97316), value: 6.5, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('₹24.58L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Total Payout', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Paid', '₹18.72L (76.2%)'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Pending', '₹4.24L (17.3%)'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFF97316), 'Hold', '₹1.62L (6.5%)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. AVERAGE EARNINGS PER TRAINER
  Widget _buildAverageEarningsPerTrainerSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('11. Average Earnings Per Trainer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 6),
          const Text('₹19,782', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('↑ 18.7% vs last 7 days', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5000, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 10000,
                maxY: 25000,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 14000), FlSpot(1, 16500), FlSpot(2, 15500), FlSpot(3, 18500), FlSpot(4, 17000), FlSpot(5, 21000), FlSpot(6, 19782)],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF3B82F6),
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFF3B82F6).withOpacity(0.2), const Color(0xFF3B82F6).withOpacity(0.0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. RECENT TRAINER REGISTRATIONS
  Widget _buildRecentTrainerRegistrationsSection() {
    final regs = [
      {'name': 'Devraj Joshi', 'spec': 'Strength Training', 'date': 'May 26, 2025', 'status': 'Pending', 'color': const Color(0xFFF97316), 'img': 'assets/images/trainers_hero_banner.jpg'},
      {'name': 'Aniket Rajput', 'spec': 'Yoga', 'date': 'May 26, 2025', 'status': 'Pending', 'color': const Color(0xFFF97316), 'img': 'assets/images/hero_banner_4.png'},
      {'name': 'Rishi Raina', 'spec': 'Weight Loss', 'date': 'May 25, 2025', 'status': 'Verified', 'color': const Color(0xFF10B981), 'img': 'assets/images/hero_banner_1.png'},
      {'name': 'Pooja Mishra', 'spec': 'HIIT', 'date': 'May 25, 2025', 'status': 'Verified', 'color': const Color(0xFF10B981), 'img': 'assets/images/athlete_transform_1787825621309.jpg'},
      {'name': 'Jatin Verma', 'spec': 'Rehabilitation', 'date': 'May 25, 2025', 'status': 'Verified', 'color': const Color(0xFF10B981), 'img': 'assets/images/workout_banner_1.png'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Recent Trainer Registrations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...regs.map((r) {
            final Color color = r['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(r['img'] as String, width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.person))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text('${r['spec']} • ${r['date']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(r['status'] as String, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 7. RECENT TRAINER ACTIVITY
  Widget _buildRecentTrainerActivitySection() {
    final acts = [
      {'user': 'Amit Sharma', 'act': 'completed session: Strength Training (1h 30m)', 'tag': 'Session Completed', 'color': const Color(0xFF10B981), 'img': 'assets/images/trainers_hero_banner.jpg'},
      {'user': 'Priya Patel', 'act': 'scheduled a live class: Yoga (10 to 11 AM)', 'tag': 'Live Session', 'color': const Color(0xFF3B82F6), 'img': 'assets/images/athlete_transform_1787825621309.jpg'},
      {'user': 'Rahul Verma', 'act': 'received ₹8,500: Payout of Session #TXN-8742', 'tag': 'Payment', 'color': const Color(0xFF8B5CF6), 'img': 'assets/images/hero_banner_4.png'},
      {'user': 'Neha Singh', 'act': 'created a new program: HIIT Weight Loss', 'tag': 'New Program', 'color': const Color(0xFF06B6D4), 'img': 'assets/images/hero_banner_1.png'},
      {'user': 'Karan Mehra', 'act': 'updated profile info: Added certificate in nutrition', 'tag': 'Update', 'color': const Color(0xFFF97316), 'img': 'assets/images/workout_banner_1.png'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Recent Trainer Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...acts.map((a) {
            final Color color = a['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(a['img'] as String, width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.person))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['user'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text(a['act'] as String, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(a['tag'] as String, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: color)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 8. BOTTOM CTA BANNER
  Widget _buildBottomEmpowerTrainersBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Empower Your Trainers, Elevate Results.', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          const Text(
            'Support and track trainers to boost engagement and grow your platform with actionable insights.',
            style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF65D300),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF65D300).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: const [
                    Text('Create Custom Report', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF0F172A)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                child: const Text('📑 Saved Reports', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicRow(Color color, String label, String pct) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          ],
        ),
        Text(pct, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildDropdownPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      ],
    );
  }
}
