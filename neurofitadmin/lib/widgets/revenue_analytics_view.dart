import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenueAnalyticsView extends StatelessWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const RevenueAnalyticsView({
    super.key,
    required this.selectedDateRange,
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
        // 1. HERO BANNER: "Revenue Insights"
        _buildAnimatedSection(0, _buildRevenueInsightsHeroBanner()),
        const SizedBox(height: 20),

        // 2. TOP 4 KPI CARDS
        _buildAnimatedSection(1, _buildTopKpisSection()),
        const SizedBox(height: 20),

        // 3. REVENUE OVERVIEW & REVENUE BY SOURCE
        _buildAnimatedSection(2, _buildRevenueOverviewSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(3, _buildRevenueBySourceSection()),
        const SizedBox(height: 20),

        // 4. REVENUE BY PLAN, DAILY REVENUE TREND, REVENUE BY PAYMENT METHOD
        _buildAnimatedSection(4, _buildRevenueByPlanSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(5, _buildDailyRevenueTrendSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(6, _buildRevenueByPaymentMethodSection()),
        const SizedBox(height: 20),

        // 5. MONTHLY REVENUE COMPARISON & REVENUE BY USER TYPE
        _buildAnimatedSection(7, _buildMonthlyRevenueComparisonSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(8, _buildRevenueByUserTypeSection()),
        const SizedBox(height: 20),

        // 6. TOP REVENUE PRODUCTS / SERVICES
        _buildAnimatedSection(9, _buildTopRevenueProductsSection()),
        const SizedBox(height: 20),

        // 7. RECENT TRANSACTIONS & REVENUE SUMMARY
        _buildAnimatedSection(10, _buildRecentTransactionsSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(11, _buildRevenueSummarySection()),
        const SizedBox(height: 20),

        // 8. BOTTOM CTA BANNER
        _buildAnimatedSection(12, _buildBottomDeeperRevenueBanner()),
      ],
    );
  }

  // 1. HERO BANNER
  Widget _buildRevenueInsightsHeroBanner() {
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
                'assets/images/hero_banner_3.png',
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
                      Colors.white.withOpacity(0.92),
                      Colors.white.withOpacity(0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.54, 0.84, 1.0],
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
                            TextSpan(text: 'Revenue '),
                            TextSpan(text: 'Insights', style: TextStyle(color: Color(0xFF10B981))),
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
                            Text(selectedDateRange, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
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
                      'Track your platform earnings and financial performance in real-time.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildHeroStat('₹24,58,300', 'Total Revenue (↑21.7%)', const Color(0xFF10B981)),
                        const SizedBox(width: 14),
                        _buildHeroStat('₹3,25,450', 'Avg. Daily Revenue', const Color(0xFF3B82F6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF65D300),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF65D300).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Download Financial Report',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF0F172A)),
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

  Widget _buildHeroStat(String val, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      ],
    );
  }

  // 2. TOP 4 KPI CARDS
  Widget _buildTopKpisSection() {
    final kpis = [
      {'title': 'Total Revenue', 'val': '₹24,58,300', 'growth': '21.7%', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Subscription', 'val': '₹12,45,800', 'growth': '18.6%', 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Market Revenue', 'val': '₹10,12,500', 'growth': '25.2%', 'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'Other Revenue', 'val': '₹2,00,000', 'growth': '12.8%', 'icon': Icons.credit_card_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.32,
      ),
      itemCount: kpis.length,
      itemBuilder: (ctx, i) {
        final k = kpis[i];
        final Color color = k['color'] as Color;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: k['bg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(k['icon'] as IconData, color: color, size: 15)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(k['title'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(k['val'] as String, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
              ),
              Row(
                children: [
                  const Icon(Icons.north_east_rounded, size: 10, color: Color(0xFF10B981)),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text('${k['growth']} vs last 7d', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF10B981)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. REVENUE OVERVIEW
  Widget _buildRevenueOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1. Revenue Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 6),
          const Text('₹24,58,300', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Row(
            children: const [
              Icon(Icons.north_east_rounded, size: 11, color: Color(0xFF10B981)),
              SizedBox(width: 3),
              Text('21.7% vs last 7 days', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 100, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 100, getTitlesWidget: (v, meta) => Text('${v.toInt()}K', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)))),
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
                        colors: [const Color(0xFF10B981).withOpacity(0.22), const Color(0xFF10B981).withOpacity(0.0)],
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

  // 3. REVENUE BY SOURCE
  Widget _buildRevenueBySourceSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. Revenue by Source', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: 50.7, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: 41.2, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: 8.1, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('₹24.58L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Total Rev', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Subscriptions', '50.7% (₹12.45L)'),
                    const SizedBox(height: 10),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Orders', '41.2% (₹10.12L)'),
                    const SizedBox(height: 10),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Other', '8.1% (₹2.00L)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. REVENUE BY PLAN
  Widget _buildRevenueByPlanSection() {
    final plans = [
      {'title': 'Premium Monthly', 'rev': '₹4,75,500', 'growth': '+18.4%', 'color': const Color(0xFFF59E0B)},
      {'title': 'Premium Quarterly', 'rev': '₹3,94,800', 'growth': '+14.7%', 'color': const Color(0xFF3B82F6)},
      {'title': 'Premium Yearly', 'rev': '₹2,25,000', 'growth': '+22.1%', 'color': const Color(0xFF10B981)},
      {'title': 'Trainer Pro Plan', 'rev': '₹1,20,500', 'growth': '+11.2%', 'color': const Color(0xFF06B6D4)},
      {'title': 'Other Plans', 'rev': '₹30,000', 'growth': '+8.3%', 'color': const Color(0xFF8B5CF6)},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('3. Revenue by Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 14),
          ...plans.map((p) {
            final Color color = p['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(p['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  ),
                  Text(p['rev'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(width: 8),
                  Text(p['growth'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('View All Plans', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  // 4. DAILY REVENUE TREND
  Widget _buildDailyRevenueTrendSection() {
    final days = ['20', '21', '22', '23', '24', '25', '26'];
    final revenues = [210.0, 310.0, 380.0, 490.0, 320.0, 420.0, 520.0];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('4. Daily Revenue Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 6),
          const Text('₹24,58,300', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 100, getTitlesWidget: (v, meta) => Text('${v.toInt()}K', style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i >= 0 && i < days.length) {
                          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(days[i], style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: i == 6 ? const Color(0xFF10B981) : const Color(0xFF94A3B8))));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 100, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(days.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: revenues[i], color: i == 6 ? const Color(0xFF65D300) : const Color(0xFF86EFAC), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. REVENUE BY PAYMENT METHOD
  Widget _buildRevenueByPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('5. Revenue by Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: 54.8, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: 26.7, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF59E0B), value: 10.7, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: 5.8, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF06B6D4), value: 2.0, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('₹24.58L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Total Rev', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'UPI', '54.8%'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Card', '26.7%'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFF59E0B), 'Net Banking', '10.7%'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Wallet', '5.8%'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF06B6D4), 'Other', '2.0%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. MONTHLY REVENUE COMPARISON
  Widget _buildMonthlyRevenueComparisonSection() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final thisYear = [18.0, 24.0, 29.0, 36.0, 42.0, 48.0];
    final lastYear = [12.0, 16.0, 21.0, 26.0, 31.0, 35.0];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('6. Monthly Revenue Comparison', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Year'),
            ],
          ),
          const SizedBox(height: 6),
          const Text('₹2,45,82,600', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('↑ 32.4% vs last year', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 10, getTitlesWidget: (v, meta) => Text('${v.toInt()}L', style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i >= 0 && i < months.length) {
                          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(months[i], style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 10, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(months.length, (i) => BarChartGroupData(x: i, barRods: [
                  BarChartRodData(toY: lastYear[i], color: const Color(0xFFE2E8F0), width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  BarChartRodData(toY: thisYear[i], color: const Color(0xFF65D300), width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                ])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. REVENUE BY USER TYPE
  Widget _buildRevenueByUserTypeSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7. Revenue by User Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: 52.8, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: 28.5, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF59E0B), value: 13.2, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: 5.5, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('₹24.58L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Total Rev', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Pro Users', '52.8% (₹12.98L)'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Premium Users', '28.5% (₹7.01L)'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFF59E0B), 'Trainers', '13.2% (₹3.25L)'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Others', '5.5% (₹1.35L)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. TOP REVENUE PRODUCTS / SERVICES
  Widget _buildTopRevenueProductsSection() {
    final products = [
      {'title': 'Premium Mentorship Plan', 'rev': '₹4,75,500', 'growth': '+18.4%', 'color': const Color(0xFF10B981)},
      {'title': 'Whey Protein Isolate 1kg', 'rev': '₹3,21,200', 'growth': '+22.6%', 'color': const Color(0xFF3B82F6)},
      {'title': 'Trainer Pro Plan', 'rev': '₹1,20,500', 'growth': '+11.2%', 'color': const Color(0xFFF59E0B)},
      {'title': 'Personal Training Session', 'rev': '₹75,000', 'growth': '+8.4%', 'color': const Color(0xFF8B5CF6)},
      {'title': 'Nutrition Plan', 'rev': '₹52,500', 'growth': '+6.8%', 'color': const Color(0xFF06B6D4)},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('8. Top Revenue Products / Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 14),
          ...products.map((p) {
            final Color color = p['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(p['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  ),
                  Text(p['rev'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(width: 8),
                  Text(p['growth'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('View All Products', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  // 7. RECENT TRANSACTIONS
  Widget _buildRecentTransactionsSection() {
    final txns = [
      {'id': '#TXN-8762', 'desc': 'Premium Monthly Plan', 'amount': '₹2,499', 'status': 'Success', 'date': 'May 26, 2025', 'color': const Color(0xFF10B981)},
      {'id': '#TXN-8761', 'desc': 'Whey Protein Isolate', 'amount': '₹2,499', 'status': 'Success', 'date': 'May 26, 2025', 'color': const Color(0xFF10B981)},
      {'id': '#TXN-8760', 'desc': 'Trainer Pro Plan', 'amount': '₹3,999', 'status': 'Success', 'date': 'May 25, 2025', 'color': const Color(0xFF10B981)},
      {'id': '#TXN-8759', 'desc': 'Refund: Order #ORD-8712', 'amount': '-₹1,200', 'status': 'Refunded', 'date': 'May 25, 2025', 'color': const Color(0xFFF97316)},
      {'id': '#TXN-8758', 'desc': 'Nutrition Plan', 'amount': '₹1,199', 'status': 'Success', 'date': 'May 25, 2025', 'color': const Color(0xFF10B981)},
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
              Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...txns.map((t) {
            final Color color = t['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['desc'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text('${t['id']} • ${t['date']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(t['amount'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(4)),
                        child: Text(t['status'] as String, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: color)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 7. REVENUE SUMMARY
  Widget _buildRevenueSummarySection() {
    final summaries = [
      {'title': 'Today\'s Revenue', 'val': '₹3,25,450', 'growth': '+18.4%', 'color': const Color(0xFFF59E0B), 'icon': Icons.today_rounded},
      {'title': 'This Week\'s Revenue', 'val': '₹24,58,300', 'growth': '+21.7%', 'color': const Color(0xFF8B5CF6), 'icon': Icons.date_range_rounded},
      {'title': 'This Month\'s Revenue', 'val': '₹1,05,72,500', 'growth': '+19.8%', 'color': const Color(0xFF3B82F6), 'icon': Icons.calendar_month_rounded},
      {'title': 'This Year\'s Revenue', 'val': '₹2,45,82,600', 'growth': '+32.4%', 'color': const Color(0xFF10B981), 'icon': Icons.event_note_rounded},
      {'title': 'All-Time Revenue', 'val': '₹10,50,00,000', 'growth': 'Lifetime', 'color': const Color(0xFFEC4899), 'icon': Icons.all_inclusive_rounded},
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
              Text('Revenue Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View Full Summary', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...summaries.map((s) {
            final Color color = s['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(s['icon'] as IconData, color: color, size: 16)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)))),
                  Text(s['val'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(width: 8),
                  Text(s['growth'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // BOTTOM BANNER
  Widget _buildBottomDeeperRevenueBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Want deeper revenue insights?', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text(
            'Create custom reports with advanced filters, compare data and export financial reports.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                child: const Text('📑 Saved Reports', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
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
}
