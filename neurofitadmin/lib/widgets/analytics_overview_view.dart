import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../backend/admin_data.dart';

class AnalyticsOverviewView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const AnalyticsOverviewView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<AnalyticsOverviewView> createState() => _AnalyticsOverviewViewState();
}

class _AnalyticsOverviewViewState extends State<AnalyticsOverviewView> {
  bool _showPromoBanner = true;
  AdminStats get st => AdminStats.I;

  @override
  void initState() {
    super.initState();
    AdminStats.I.addListener(_onStats);
    AdminStats.I.load();
  }

  @override
  void dispose() {
    AdminStats.I.removeListener(_onStats);
    super.dispose();
  }

  void _onStats() {
    if (mounted) setState(() {});
  }

  static const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  List<String> _lastDays(int n, {bool withMonth = true}) => List.generate(n, (i) {
        final d = DateTime.now().subtract(Duration(days: n - 1 - i));
        return withMonth ? '${_mon[d.month - 1]} ${d.day}' : '${d.day}';
      });

  double _niceMax(Iterable<double> v, [double min = 5]) {
    final m = v.fold<double>(0, (a, b) => b > a ? b : a);
    final t = m < min ? min : m * 1.25;
    final step = t <= 10 ? 2.0 : t <= 50 ? 10.0 : t <= 200 ? 50.0 : t <= 1000 ? 100.0 : (t / 5).roundToDouble();
    return (t / step).ceil() * step;
  }

  String _pctOf(num part, num whole) => whole <= 0 ? '0%' : '${(part / whole * 100).toStringAsFixed(1)}%';

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
        // A. Hero Banner: "Grow Stronger Every Day"
        if (_showPromoBanner) ...[
          _buildAnimatedSection(0, _buildGrowStrongerHeroBannerClean()),
          const SizedBox(height: 20),
        ],

        // B. 1. KPI Overview (4 Top Cards + Date Picker)
        _buildAnimatedSection(1, _buildKpiOverviewSection()),
        const SizedBox(height: 20),

        // C. 2. User Growth Spline Chart
        _buildAnimatedSection(2, _buildUserGrowthSection()),
        const SizedBox(height: 20),

        // D. 3. Revenue Overview Bar Chart
        _buildAnimatedSection(3, _buildRevenueOverviewSection()),
        const SizedBox(height: 20),

        // E. 4. User Demographics & 5. Top Performing Workouts
        _buildAnimatedSection(4, _buildUserDemographicsSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(5, _buildTopPerformingWorkoutsSection()),
        const SizedBox(height: 20),

        // F. 6. Orders Status & 7. App Engagement
        _buildAnimatedSection(6, _buildOrdersStatusSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(7, _buildAppEngagementSection()),
        const SizedBox(height: 20),

        // G. 8. Recent Activity Table
        _buildAnimatedSection(8, _buildRecentActivityTableSection()),
      ],
    );
  }

  // CLEAN BANNER
  Widget _buildGrowStrongerHeroBannerClean() {
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
                'assets/images/hero_banner_4.png',
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
                      Colors.white.withOpacity(0.97),
                      Colors.white.withOpacity(0.88),
                      Colors.white.withOpacity(0.2),
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
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: 'Grow '),
                        TextSpan(text: 'Stronger ', style: TextStyle(color: Color(0xFF10B981))),
                        TextSpan(text: 'Every Day'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track everything, improve everything.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildHeroStat(fmtShort(st.n('users', 'mau')), 'Active Users'),
                      const SizedBox(width: 14),
                      _buildHeroStat(fmtShort(st.n('fitness', 'completed')), 'Workouts Done'),
                      const SizedBox(width: 14),
                      _buildHeroStat('${st.growth('signups').toStringAsFixed(1)}%', 'Growth'),
                    ],
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
                          'View Full Report',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF0F172A)),
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

  Widget _buildHeroStat(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      ],
    );
  }

  // 1. KPI OVERVIEW
  Widget _buildKpiOverviewSection() {
    final kpis = [
      {'title': 'Total Users', 'value': fmtInt(st.n('users', 'total')), 'growth': st.growthLabel('signups'), 'icon': Icons.groups_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Active Users', 'value': fmtInt(st.n('users', 'wau')), 'growth': st.growthLabel('active'), 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Orders', 'value': fmtInt(st.n('orders', 'total')), 'growth': st.growthLabel('orders'), 'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'Revenue', 'value': fmtInr(st.n('orders', 'revenue')), 'growth': st.growthLabel('revenue'), 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('1. KPI Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(widget.selectedDateRange, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemCount: kpis.length,
          itemBuilder: (ctx, i) {
            final k = kpis[i];
            final Color color = k['color'] as Color;

            return Container(
              padding: const EdgeInsets.all(12),
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
                      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: k['bg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(k['icon'] as IconData, color: color, size: 16)),
                      const SizedBox(width: 8),
                      Text(k['title'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    ],
                  ),
                  Text(k['value'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                  Row(
                    children: [
                      const Icon(Icons.north_east_rounded, size: 11, color: Color(0xFF10B981)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(k['growth'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 2. USER GROWTH
  Widget _buildUserGrowthSection() {
    final newU = st.series('signups', 7);
    final actU = st.series('active', 7);
    final maxY = _niceMax([...newU, ...actU]);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. User Growth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendDot(const Color(0xFF10B981), 'New Users'),
              const SizedBox(width: 14),
              _buildLegendDot(const Color(0xFF3B82F6), 'Active Users'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxY / 4,
                      getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final days = _lastDays(7);
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
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (var i = 0; i < newU.length; i++) FlSpot(i.toDouble(), newU[i])],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: [for (var i = 0; i < actU.length; i++) FlSpot(i.toDouble(), actU[i])],
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

  // 3. REVENUE OVERVIEW
  Widget _buildRevenueOverviewSection() {
    final days = _lastDays(7, withMonth: false);
    final revenues = [for (final v in st.series('revenue', 7)) v / 1000];
    final revMax = _niceMax(revenues, 1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('3. Revenue Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 8),
          Text(fmtInr(st.sum('revenue', 7)), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.north_east_rounded, size: 11, color: Color(0xFF10B981)),
              const SizedBox(width: 3),
              Text(st.growthLabel('revenue'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: revMax / 4, getTitlesWidget: (v, meta) => Text('${v.toStringAsFixed(v < 10 ? 1 : 0)}K', style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))))),
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
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: revMax / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                maxY: revMax,
                barGroups: List.generate(days.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: revenues[i], color: i == 6 ? const Color(0xFF65D300) : const Color(0xFF86EFAC), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. USER DEMOGRAPHICS
  Widget _buildUserDemographicsSection() {
    final g = st.sec('demographics')['gender'] as List? ?? const [];
    num gv(String l) => (g.firstWhere((x) => x['label'] == l, orElse: () => {'n': 0})['n'] as num);
    final male = gv('Male'), female = gv('Female'), other = gv('Other') + gv('Not set');
    final totalG = male + female + other;
    final ages = st.sec('demographics')['ages'] as List? ?? const [];
    final ageTotal = ages.fold<num>(0, (a, x) => a + (x['n'] as num));
    final topAge = ages.isEmpty ? 'Not enough data' : '${ages.first['label']} Years (${_pctOf(ages.first['n'] as num, ageTotal)})';
    final cities = st.sec('demographics')['cities'] as List? ?? const [];
    final cityTotal = cities.fold<num>(0, (a, x) => a + (x['n'] as num));
    final topCity = cities.isEmpty ? 'Not enough data' : '${cities.first['label']} (${_pctOf(cities.first['n'] as num, cityTotal)})';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('4. User Demographics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          PieChartSectionData(color: const Color(0xFF65D300), value: totalG == 0 ? 1 : male.toDouble(), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: female.toDouble(), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: other.toDouble(), radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInt(st.n('users', 'total')), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const Text('Total Users', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF65D300), 'Male', _pctOf(male, totalG)),
                    const SizedBox(height: 10),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Female', _pctOf(female, totalG)),
                    const SizedBox(height: 10),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Other', _pctOf(other, totalG)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDemographicFooterCard(Icons.person_pin_circle_outlined, 'Top Age Group', topAge)),
              const SizedBox(width: 10),
              Expanded(child: _buildDemographicFooterCard(Icons.public_rounded, 'Top Location', topCity)),
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
        Text(pct, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildDemographicFooterCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF65D300)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. TOP PERFORMING WORKOUTS
  Widget _buildTopPerformingWorkoutsSection() {
    const imgs = ['assets/images/workout_exercise_cutout_1787895967050.jpg', 'assets/images/workout_banner_1.png', 'assets/images/workout_banner_2.png', 'assets/images/workout_banner_3.png', 'assets/images/workout_banner_4.png'];
    final top = st.rows('topWorkouts');
    final workouts = [
      for (var i = 0; i < top.length && i < 5; i++)
        {'title': (top[i]['title'] ?? 'Workout').toString(), 'users': 'Started by ${fmtInt(top[i]['athletes'] as num? ?? 0)} users', 'growth': '${fmtInt(top[i]['completed'] as num? ?? 0)} done', 'img': imgs[i]},
      if (top.isEmpty) {'title': 'No workouts tracked yet', 'users': 'Appears when users start workouts', 'growth': '', 'img': imgs[0]},
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
              Text('5. Top Performing Workouts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...workouts.map((w) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(w['img'] as String, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.fitness_center)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w['title'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(w['users'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Text(w['growth'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // 6. ORDERS STATUS
  Widget _buildOrdersStatusSection() {
    const stageColors = [Color(0xFFF59E0B), Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFF10B981), Color(0xFF06B6D4), Color(0xFFEF4444), Color(0xFF64748B)];
    final byStatus = st.rows('ordersByStatus');
    final totalOrders = byStatus.fold<num>(0, (a, r) => a + (r['n'] as num));
    final stages = [
      for (var i = 0; i < byStatus.length && i < 7; i++)
        {'name': byStatus[i]['status'].toString(), 'n': byStatus[i]['n'] as num, 'val': '${fmtInt(byStatus[i]['n'] as num)} (${_pctOf(byStatus[i]['n'] as num, totalOrders)})', 'color': stageColors[i]},
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
              const Text('6. Orders Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                        sections: stages.isEmpty
                            ? [PieChartSectionData(color: const Color(0xFFE2E8F0), value: 1, radius: 24, title: '')]
                            : [for (final x in stages) PieChartSectionData(color: x['color'] as Color, value: (x['n'] as num).toDouble(), radius: 24, title: '')],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInt(totalOrders), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const Text('Total Orders', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: stages.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: s['color'] as Color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(s['name'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                          ],
                        ),
                        Text(s['val'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. APP ENGAGEMENT
  Widget _buildAppEngagementSection() {
    final engagements = [
      {'title': 'Workouts Completed', 'val': fmtShort(st.n('fitness', 'completed')), 'growth': '${st.growthUp('workoutsDone') ? '+' : '-'}${st.growth('workoutsDone').abs().toStringAsFixed(1)}%', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Calories Burned', 'val': fmtShort(st.n('activity', 'caloriesBurned')), 'growth': '', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'Steps Tracked', 'val': fmtShort(st.n('activity', 'steps')), 'growth': '', 'icon': Icons.directions_walk_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'title': 'Active Minutes', 'val': fmtShort(st.n('fitness', 'minutes')), 'growth': '', 'icon': Icons.timer_outlined, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
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
              const Text('7. App Engagement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
            ),
            itemCount: engagements.length,
            itemBuilder: (ctx, i) {
              final e = engagements[i];
              final Color color = e['color'] as Color;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: e['bg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(e['icon'] as IconData, color: color, size: 14)),
                        Text(e['growth'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['val'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text(e['title'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 8. RECENT ACTIVITY
  Widget _buildRecentActivityTableSection() {
    const kinds = {
      'user': ['New user registered', 'New', Color(0xFF10B981), Icons.person_add_rounded],
      'order': ['New order placed', 'Order', Color(0xFF3B82F6), Icons.shopping_cart_rounded],
      'trainer': ['Trainer application', 'Coach', Color(0xFFF97316), Icons.assignment_ind_rounded],
      'subscription': ['Coach subscription', 'Paid', Color(0xFF8B5CF6), Icons.check_circle_rounded],
    };
    final activities = [
      for (final r in st.rows('recentActivity').take(6))
        {
          'title': kinds[r['kind']]![0],
          'detail': r['kind'] == 'user' ? '${r['title']} (${r['detail'] ?? ''})' : r['kind'] == 'trainer' ? '${r['title']} · ${r['detail']}' : '${r['title']} · ${r['detail']}',
          'time': timeAgo(r['at']?.toString()),
          'status': kinds[r['kind']]![1],
          'color': kinds[r['kind']]![2],
          'icon': kinds[r['kind']]![3],
        },
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
              Text('8. Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...activities.map((a) {
            final Color color = a['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(a['icon'] as IconData, color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text(a['detail'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text(a['status'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
                      ),
                      const SizedBox(height: 3),
                      Text(a['time'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
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
