import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenueAnalyticsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const RevenueAnalyticsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<RevenueAnalyticsView> createState() => _RevenueAnalyticsViewState();
}

class _RevenueAnalyticsViewState extends State<RevenueAnalyticsView> with LiveStats {
  String get selectedDateRange => widget.selectedDateRange;
  List<Animation<double>> get fadeAnimations => widget.fadeAnimations;
  List<Animation<Offset>> get slideAnimations => widget.slideAnimations;

  double _r(String k) => ins.n('revenue', k).toDouble();
  double get _week => _r('week');
  double get _wkGrowth => _r('prev_week') == 0 ? (_week > 0 ? 100 : 0) : (_week - _r('prev_week')) / _r('prev_week') * 100;
  List<double> get _daily7 => ins.series('revenue', 'daily', 7);
  double get _dayMax => top(_daily7, 1000);
  List<Map<String, dynamic>> get _pm => ins.list('revenue', 'paymentMethods');
  double get _pmTotal => _pm.fold<double>(0, (a, r) => a + ((r['amount'] as num?) ?? 0).toDouble());
  double get _pmOther => _pmTotal - ['UPI', 'Card', 'Cash on Delivery', 'Wallet'].fold<double>(0, (a, l) => a + pick(_pm, l));
  double _ut(String label) => pick(ins.list('revenue', 'byUserType'), label);

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
                        _buildHeroStat(fmtInr(_week), 'Revenue this week (${_wkGrowth >= 0 ? '↑' : '↓'}${_wkGrowth.abs().toStringAsFixed(1)}%)', const Color(0xFF10B981)),
                        const SizedBox(width: 14),
                        _buildHeroStat(fmtInr(_week / 7), 'Avg. Daily Revenue', const Color(0xFF3B82F6)),
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
      {'title': 'Total Revenue', 'val': fmtInr(_r('total')), 'growth': fmtPct(_wkGrowth), 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Subscription', 'val': fmtInr(_r('subs')), 'growth': share(_r('subs'), _r('total')), 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Market Revenue', 'val': fmtInr(_r('market')), 'growth': share(_r('market'), _r('total')), 'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'This Month', 'val': fmtInr(_r('month')), 'growth': 'since the 1st', 'icon': Icons.credit_card_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
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
          Text(fmtInr(_week), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(_wkGrowth >= 0 ? Icons.north_east_rounded : Icons.south_east_rounded, size: 11, color: const Color(0xFF10B981)),
              const SizedBox(width: 3),
              Text('${fmtPct(_wkGrowth.abs())} vs last 7 days', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _dayMax / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: _dayMax / 4, getTitlesWidget: (v, meta) => Text(fmtInrShort(v).replaceAll('₹', ''), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final days = dayLabels(7);
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
                maxY: _dayMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (var i = 0; i < _daily7.length; i++) FlSpot(i.toDouble(), _daily7[i])],
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: _r('subs') + (_r('total') == 0 ? 1 : 0), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: _r('market'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: 0, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInrShort(_r('total')), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const Text('Total Rev', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Subscriptions', '${share(_r('subs'), _r('total'))} (${fmtInrShort(_r('subs'))})'),
                    const SizedBox(height: 10),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Orders', '${share(_r('market'), _r('total'))} (${fmtInrShort(_r('market'))})'),
                    const SizedBox(height: 10),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Other', '0.0% (₹0)'),
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
    const planColors = [Color(0xFFF59E0B), Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFF06B6D4), Color(0xFF8B5CF6), Color(0xFFEC4899)];
    final planRows = ins.list('revenue', 'plans');
    final plans = [
      for (var i = 0; i < planRows.length; i++)
        {'title': '${planRows[i]['label']} coaching', 'rev': fmtInr(planRows[i]['amount'] as num? ?? 0), 'growth': '${planRows[i]['n']} sold', 'color': planColors[i % planColors.length]},
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
    final days = [for (final d in dayLabels(7)) d.split(' ').last];
    final revenues = _daily7;

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
          Text(fmtInr(_week), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: _dayMax / 4, getTitlesWidget: (v, meta) => Text(fmtInrShort(v).replaceAll('₹', ''), style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))))),
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
                maxY: _dayMax,
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: pick(_pm, 'UPI') + (_pmTotal == 0 ? 1 : 0), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: pick(_pm, 'Card'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF59E0B), value: pick(_pm, 'Cash on Delivery'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: pick(_pm, 'Wallet'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF06B6D4), value: _pmOther, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInrShort(_r('total')), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const Text('Total Rev', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'UPI', share(pick(_pm, 'UPI'), _pmTotal)),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Card', share(pick(_pm, 'Card'), _pmTotal)),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFF59E0B), 'Cash on Delivery', share(pick(_pm, 'Cash on Delivery'), _pmTotal)),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Wallet', share(pick(_pm, 'Wallet'), _pmTotal)),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF06B6D4), 'Other', share(_pmOther, _pmTotal)),
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
    const mn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthly = ins.list('revenue', 'monthly');
    final last6 = monthly.length > 6 ? monthly.sublist(monthly.length - 6) : monthly;
    final months = [for (final m in last6) mn[int.parse('${m['month']}'.split('-')[1]) - 1]];
    // grey bar = marketplace, green bar = total (marketplace + coaching), in lakhs
    final lastYear = [for (final m in last6) ((m['market'] as num? ?? 0) / 1e5).toDouble()];
    final thisYear = [for (final m in last6) ((m['value'] as num? ?? 0) / 1e5).toDouble()];
    final mMax = top([...thisYear, ...lastYear], 0.1);

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
          Text(fmtInr(_r('year')), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('${fmtInr(_r('month'))} this month', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: mMax / 4, getTitlesWidget: (v, meta) => Text('${v.toStringAsFixed(mMax < 4 ? 1 : 0)}L', style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))))),
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
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: mMax / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                maxY: mMax,
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: _ut('Premium') + (_r('total') == 0 ? 1 : 0), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: _ut('Free users'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF59E0B), value: _ut('Coaches'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: _r('subs'), radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInrShort(_r('total')), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const Text('Total Rev', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Premium Users', '${share(_ut('Premium'), _r('total'))} (${fmtInrShort(_ut('Premium'))})'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Free Users', '${share(_ut('Free users'), _r('total'))} (${fmtInrShort(_ut('Free users'))})'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFF59E0B), 'Trainers', '${share(_ut('Coaches'), _r('total'))} (${fmtInrShort(_ut('Coaches'))})'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Coaching plans', '${share(_r('subs'), _r('total'))} (${fmtInrShort(_r('subs'))})'),
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
    const pColors = [Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFF06B6D4)];
    final merged = [
      for (final p in st.rows('topProducts')) {'title': '${p['name'] ?? 'Product'}', 'amount': (p['revenue'] as num? ?? 0), 'growth': '${p['qty'] ?? 0} sold'},
      for (final p in ins.list('revenue', 'plans')) {'title': '${p['label']} coaching', 'amount': (p['amount'] as num? ?? 0), 'growth': '${p['n'] ?? 0} sold'},
    ]..sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));
    final products = [
      for (var i = 0; i < merged.length && i < 5; i++)
        {'title': merged[i]['title'], 'rev': fmtInr(merged[i]['amount'] as num), 'growth': merged[i]['growth'], 'color': pColors[i]},
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
      for (final t in ins.list('revenue', 'transactions'))
        () {
          final bad = t['status'] == 'Cancelled' || t['status'] == 'Returned' || t['status'] == 'cancelled';
          final id = '${t['id']}';
          return {
            'id': '#${id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id}',
            'desc': '${t['title']}',
            'amount': '${bad ? '-' : ''}${fmtInr(t['amount'] as num? ?? 0)}',
            'status': bad ? (t['status'] == 'Returned' ? 'Refunded' : 'Cancelled') : ('${t['payment']}'.toLowerCase() == 'paid' ? 'Success' : 'Pending'),
            'date': shortDate(t['at']?.toString()),
            'color': bad ? const Color(0xFFF97316) : const Color(0xFF10B981),
          };
        }(),
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
      {'title': 'Today\'s Revenue', 'val': fmtInr(_r('today')), 'growth': 'since midnight', 'color': const Color(0xFFF59E0B), 'icon': Icons.today_rounded},
      {'title': 'This Week\'s Revenue', 'val': fmtInr(_week), 'growth': '${_wkGrowth >= 0 ? '+' : ''}${_wkGrowth.toStringAsFixed(1)}%', 'color': const Color(0xFF8B5CF6), 'icon': Icons.date_range_rounded},
      {'title': 'This Month\'s Revenue', 'val': fmtInr(_r('month')), 'growth': 'month to date', 'color': const Color(0xFF3B82F6), 'icon': Icons.calendar_month_rounded},
      {'title': 'This Year\'s Revenue', 'val': fmtInr(_r('year')), 'growth': 'year to date', 'color': const Color(0xFF10B981), 'icon': Icons.event_note_rounded},
      {'title': 'All-Time Revenue', 'val': fmtInr(_r('total')), 'growth': 'Lifetime', 'color': const Color(0xFFEC4899), 'icon': Icons.all_inclusive_rounded},
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
