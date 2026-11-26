import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import 'package:fl_chart/fl_chart.dart';

class UserAnalyticsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const UserAnalyticsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<UserAnalyticsView> createState() => _UserAnalyticsViewState();
}

class _UserAnalyticsViewState extends State<UserAnalyticsView> with LiveStats {
  String get selectedDateRange => widget.selectedDateRange;
  List<Animation<double>> get fadeAnimations => widget.fadeAnimations;
  List<Animation<Offset>> get slideAnimations => widget.slideAnimations;

  List<FlSpot> _spots(List<double> v) => [for (var i = 0; i < v.length; i++) FlSpot(i.toDouble(), v[i])];
  double get _growthMax => top([...st.series('signups', 7), ...st.series('active', 7)]);
  double _ret(String k) => ((ins.sub('users', 'retention')[k] as num?) ?? 0).toDouble();
  List<Map<String, dynamic>> get _gender => [for (final x in (st.sec('demographics')['gender'] as List? ?? const [])) Map<String, dynamic>.from(x as Map)];
  List<Map<String, dynamic>> get _platforms => ins.list('users', 'platforms');
  Map<String, dynamic> get _sess => ins.sub('users', 'sessions');
  double _pct(List<Map<String, dynamic>> rows, List<String> labels) {
    final total = rows.fold<num>(0, (a, r) => a + ((r['n'] as num?) ?? 0));
    final part = labels.fold<double>(0, (a, l) => a + labelValue(rows, l));
    return total == 0 ? 0 : part / total * 100;
  }
  double get _otherGenderPct => _pct(_gender, ['Other', 'Not set']);
  double get _platformOtherPct => _pct(_platforms, ['Web', 'Unknown']);
  String _topOf(dynamic rows, String suffix) {
    final l = [for (final x in (rows as List? ?? const [])) Map<String, dynamic>.from(x as Map)];
    if (l.isEmpty) return 'Not enough data';
    final total = l.fold<num>(0, (a, r) => a + ((r['n'] as num?) ?? 0));
    return '${l.first['label']}$suffix (${share(l.first['n'] as num? ?? 0, total)})';
  }

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
        // 1. HERO BANNER: "User Analytics"
        _buildAnimatedSection(0, _buildUserAnalyticsHeroBanner()),
        const SizedBox(height: 20),

        // 2. TOP 4 KPI METRIC CARDS
        _buildAnimatedSection(1, _buildTopKpisSection()),
        const SizedBox(height: 20),

        // 3. USER GROWTH & USER RETENTION
        _buildAnimatedSection(2, _buildUserGrowthSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(3, _buildUserRetentionSection()),
        const SizedBox(height: 20),

        // 4. USER DEMOGRAPHICS & USER ACTIVITY HEATMAP
        _buildAnimatedSection(4, _buildUserDemographicsSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(5, _buildUserActivityHeatmapSection()),
        const SizedBox(height: 20),

        // 5. USERS BY PLATFORM & USER ENGAGEMENT OVERVIEW
        _buildAnimatedSection(6, _buildUsersByPlatformSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(7, _buildUserEngagementOverviewSection()),
        const SizedBox(height: 20),

        // 6. TOP USER SEGMENTS & RECENT USER SIGNUPS
        _buildAnimatedSection(8, _buildTopUserSegmentsSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(9, _buildRecentUserSignupsSection()),
        const SizedBox(height: 20),

        // 7. BOTTOM CTA BANNER
        _buildAnimatedSection(10, _buildBottomUnderstandUsersBanner()),
      ],
    );
  }

  // 1. HERO BANNER
  Widget _buildUserAnalyticsHeroBanner() {
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
                'assets/images/hero_banner_2.png',
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
                            TextSpan(text: 'User '),
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
                      'Deep insights into your users\' behavior, growth, engagement and retention.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildHeroStat(fmtInt(st.n('users', 'new_30d')), 'New Users (${st.growthUp('signups') ? '↑' : '↓'}${st.growth('signups').abs().toStringAsFixed(1)}%)', const Color(0xFF10B981)),
                      const SizedBox(width: 14),
                      _buildHeroStat(fmtInt(st.n('users', 'mau')), 'Active Users', const Color(0xFF8B5CF6)),
                      const SizedBox(width: 14),
                      _buildHeroStat(fmtDuration(ins.sub('users', 'sessions')['avgSeconds'] as num? ?? 0), 'Avg. Session', const Color(0xFF3B82F6)),
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
                          'Export Report',
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
      {'title': 'Total Users', 'val': fmtInt(st.n('users', 'total')), 'growth': st.growthLabel('signups'), 'icon': Icons.groups_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Active Users', 'val': fmtInt(st.n('users', 'wau')), 'growth': st.growthLabel('active'), 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'New Users', 'val': fmtInt(st.n('users', 'new_7d')), 'growth': st.growthLabel('signups'), 'icon': Icons.person_add_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'Returning Users', 'val': fmtInt(ins.n('users', 'returning')), 'growth': 'active this week, joined earlier', 'icon': Icons.replay_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
    ];

    return GridView.builder(
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
              Text(k['val'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
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
    );
  }

  // 3. USER GROWTH
  Widget _buildUserGrowthSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1. User Growth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _growthMax / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: _growthMax / 4, getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)))),
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
                maxY: _growthMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots(st.series('signups', 7)),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: _spots(st.series('active', 7)),
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

  // 3. USER RETENTION
  Widget _buildUserRetentionSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. User Retention', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('Last 30 Days'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 25, getTitlesWidget: (v, meta) => Text('${v.toInt()}%', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final days = ['Day 1', 'Day 7', 'Day 14', 'Day 30'];
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
                maxX: 3,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: [FlSpot(0, _ret('d1')), FlSpot(1, _ret('d7')), FlSpot(2, _ret('d14')), FlSpot(3, _ret('d30'))],
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
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RetentionTag('Day 1', fmtPct(_ret('d1'))),
              _RetentionTag('Day 7', fmtPct(_ret('d7'))),
              _RetentionTag('Day 14', fmtPct(_ret('d14'))),
              _RetentionTag('Day 30', fmtPct(_ret('d30'))),
            ],
          ),
        ],
      ),
    );
  }

  // 4. USER DEMOGRAPHICS
  Widget _buildUserDemographicsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('3. User Demographics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          PieChartSectionData(color: const Color(0xFF65D300), value: labelValue(_gender, 'Male'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: labelValue(_gender, 'Female'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: labelValue(_gender, 'Other') + labelValue(_gender, 'Not set') + (_gender.isEmpty ? 1 : 0), radius: 24, title: ''),
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
                    _buildDemographicRow(const Color(0xFF65D300), 'Male', labelShare(_gender, 'Male')),
                    const SizedBox(height: 10),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Female', labelShare(_gender, 'Female')),
                    const SizedBox(height: 10),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Other / not set', fmtPct(_otherGenderPct)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDemographicFooterCard(Icons.person_pin_circle_outlined, 'Top Age Group', _topOf(st.sec('demographics')['ages'], ' Years'))),
              const SizedBox(width: 10),
              Expanded(child: _buildDemographicFooterCard(Icons.public_rounded, 'Top Location', _topOf(st.sec('demographics')['cities'], ''))),
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

  // 4. USER ACTIVITY HEATMAP
  Widget _buildUserActivityHeatmapSection() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final raw = [for (final row in (ins.sec('users')['heatmap'] as List? ?? const [])) [for (final v in (row as List)) (v as num).toDouble()]];
    final peak = raw.expand((r) => r).fold<double>(0, (a, b) => b > a ? b : a);
    final intensities = [
      for (var d = 0; d < 7; d++)
        [for (var h = 0; h < 7; h++) () {
          final v = d < raw.length && h < raw[d].length ? raw[d][h] : 0.0;
          return peak == 0 ? 1 : (1 + (v / peak * 4).round()).clamp(1, 5);
        }()]
    ];

    Color getHeatColor(int val) {
      switch (val) {
        case 5: return const Color(0xFF15803D);
        case 4: return const Color(0xFF22C55E);
        case 3: return const Color(0xFF86EFAC);
        case 2: return const Color(0xFFBBF7D0);
        default: return const Color(0xFFDCFCE7);
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('4. User Activity Heatmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('Last 30 Days'),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: List.generate(days.length, (d) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(width: 30, child: Text(days[d], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                    Expanded(
                      child: Row(
                        children: List.generate(7, (h) {
                          return Expanded(
                            child: Container(
                              height: 18,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: getHeatColor(intensities[d][h]),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SizedBox(width: 30),
              Text('12 AM', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))),
              Text('4 AM', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))),
              Text('8 AM', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))),
              Text('12 PM', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))),
              Text('4 PM', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))),
              Text('8 PM', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  // 5. USERS BY PLATFORM
  Widget _buildUsersByPlatformSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('5. Users by Platform', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: labelValue(_platforms, 'Android'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: labelValue(_platforms, 'iOS'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: labelValue(_platforms, 'Web') + labelValue(_platforms, 'Unknown') + (_platforms.isEmpty ? 1 : 0), radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInt(st.n('users', 'total')), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Total Users', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Android', labelShare(_platforms, 'Android')),
                    const SizedBox(height: 10),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'iOS', labelShare(_platforms, 'iOS')),
                    const SizedBox(height: 10),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Web / other', fmtPct(_platformOtherPct)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. USER ENGAGEMENT OVERVIEW
  Widget _buildUserEngagementOverviewSection() {
    final engagements = [
      {'title': 'Avg. Session Time', 'val': fmtDuration(_sess['avgSeconds'] as num? ?? 0), 'growth': '${fmtInt(_sess['total'] as num? ?? 0)} sessions', 'icon': Icons.timer_outlined, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Sessions per User', 'val': '${_sess['perUser'] ?? 0}', 'growth': '30 days', 'icon': Icons.touch_app_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Screens per Session', 'val': '${_sess['screensPerSession'] ?? 0}', 'growth': '30 days', 'icon': Icons.smartphone_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'title': 'Bounce Rate', 'val': fmtPct(_sess['bounceRate'] as num? ?? 0), 'growth': 'under 10 s', 'icon': Icons.exit_to_app_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
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
              const Text('6. User Engagement Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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

  // 7. TOP USER SEGMENTS
  Widget _buildTopUserSegmentsSection() {
    const icons = [Icons.monitor_weight_outlined, Icons.fitness_center_rounded, Icons.directions_run_rounded, Icons.self_improvement_rounded, Icons.emoji_events_rounded, Icons.flag_rounded];
    const colors = [Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFF65D300), Color(0xFF8B5CF6), Color(0xFFF97316), Color(0xFF06B6D4)];
    final goals = ins.list('users', 'goals');
    final totalUsers = st.n('users', 'total');
    final segments = [
      for (var i = 0; i < goals.length; i++)
        {
          'title': '${goals[i]['goal']}',
          'users': fmtInt(goals[i]['n'] as num? ?? 0),
          'pct': share(goals[i]['n'] as num? ?? 0, totalUsers),
          'trend': '+${goals[i]['new7'] ?? 0} this week',
          'icon': icons[i % icons.length],
          'color': colors[i % colors.length],
        },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7. Top User Segments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 14),
          ...segments.map((s) {
            final Color color = s['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(s['icon'] as IconData, color: color, size: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text('${s['users']} users (${s['pct']})', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Text(s['trend'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
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
            child: const Text('View All Segments', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  // 8. RECENT USER SIGNUPS
  Widget _buildRecentUserSignupsSection() {
    final signups = [
      for (final r in st.rows('recentActivity'))
        if (r['kind'] == 'user') {'name': '${r['title'] ?? 'User'}', 'email': '${r['detail'] ?? ''}', 'time': timeAgo(r['at']?.toString()), 'img': ''},
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
              Text('8. Recent User Signups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...signups.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(s['img'] as String, width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.person))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text(s['email'] as String, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(s['time'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      const Text('View', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
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

  // BOTTOM BANNER
  Widget _buildBottomUnderstandUsersBanner() {
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
          const Text('Understand your users better with advanced insights', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text(
            'Create custom reports with advanced filters and track user behavior scores.',
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

class _RetentionTag extends StatelessWidget {
  final String day;
  final String pct;
  const _RetentionTag(this.day, this.pct);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Text(day, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(pct, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
        ],
      ),
    );
  }
}
