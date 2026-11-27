import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import 'net_or_asset_image.dart';
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

class _TrainersAnalyticsViewState extends State<TrainersAnalyticsView> with LiveStats {
  List<Map<String, dynamic>> get _status => ins.list('trainers', 'status');
  double _st(String l) => labelValue(_status, l);
  double get _all => _status.fold<double>(0, (a, r) => a + ((r['n'] as num?) ?? 0).toDouble());
  String _line(String l) => '${share(_st(l), _all)} (${fmtInt(_st(l))})';
  List<double> get _new7 => ins.series('trainers', 'growth', 7);
  List<double> get _total7 {
    final n = _new7;
    var run = _all;
    final out = List<double>.filled(n.length, 0);
    for (var i = n.length - 1; i >= 0; i--) { out[i] = run; run -= n[i]; }
    return out;
  }
  List<double> get _live7 => ins.series('trainers', 'liveDaily', 7);
  List<double> get _earn7 => ins.series('trainers', 'earningsDaily', 7);
  List<double> get _rating7 => ins.series('trainers', 'ratingDaily', 7);
  double get _approved => _st('approved') == 0 ? 1 : _st('approved');
  List<Map<String, dynamic>> get _payout => ins.list('trainers', 'payout');
  double get _payTotal => _payout.fold<double>(0, (a, r) => a + ((r['amount'] as num?) ?? 0).toDouble());
  double _pay(String l) => pick(_payout, l);
  double get _payOther => _payTotal - _pay('Paid') - _pay('Pending');
  List<FlSpot> _sp(List<double> v) => [for (var i = 0; i < v.length; i++) FlSpot(i.toDouble(), v[i])];

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
                          children: [
                            Text('Top Trainer • ${ins.list('trainers', 'top').isEmpty ? 'None yet' : ins.list('trainers', 'top').first['name']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            Text(ins.list('trainers', 'top').isEmpty ? 'No sessions yet' : '${fmtInt((ins.list('trainers', 'top').first['clients'] as num?) ?? 0)} Clients • ${(((ins.list('trainers', 'top').first['rating'] as num?) ?? 0)).toStringAsFixed(1)}★ Rating', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
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
      {'title': 'Total Trainers', 'val': fmtInt(_all), 'growth': '+${fmtInt(_new7.fold<double>(0, (a, b) => a + b))} this week', 'icon': Icons.groups_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Active Trainers', 'val': fmtInt(_st('approved')), 'growth': '${fmtInt(st.n('trainers', 'live_now'))} live now', 'icon': Icons.how_to_reg_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'New Trainers', 'val': fmtInt(ins.series('trainers', 'growth').fold<double>(0, (a, b) => a + b)), 'growth': 'last 30 days', 'icon': Icons.person_add_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'Total Sessions', 'val': fmtInt(st.n('trainers', 'sessions')), 'growth': 'live classes', 'icon': Icons.event_available_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'title': 'Total Earnings', 'val': fmtInr(st.n('trainers', 'sub_revenue')), 'growth': '${fmtInt(st.n('trainers', 'active_subs'))} active clients', 'icon': Icons.monetization_on_rounded, 'color': const Color(0xFF14B8A6), 'bg': const Color(0xFFE6FAF8)},
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
              _buildLegendDot(const Color(0xFF3B82F6), 'Total Trainers'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: top(_total7, 4) / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: top(_total7, 4) / 4, getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)))),
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
                maxY: top(_total7, 4),
                lineBarsData: [
                  LineChartBarData(
                    spots: _sp(_new7),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: _sp(_total7),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: _st('approved') + (_all == 0 ? 1 : 0), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: _st('pending'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: _st('rejected'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF97316), value: _st('suspended'), radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInt(_all), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const Text('Trainers', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Active', _line('approved')),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Pending', _line('pending')),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Rejected', _line('rejected')),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFFF97316), 'Suspended', _line('suspended')),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: _st('approved') + (_all == 0 ? 1 : 0), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: _st('pending'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF97316), value: _st('rejected'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: _st('suspended'), radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInt(_all), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const Text('Applications', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Verified', _line('approved')),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Pending', _line('pending')),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFFF97316), 'Rejected', _line('rejected')),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Suspended', _line('suspended')),
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
    const specColors = [Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFF97316), Color(0xFF64748B)];
    final cats = ins.list('trainers', 'categories');
    final catTotal = cats.fold<num>(0, (a, c) => a + ((c['n'] as num?) ?? 0));
    final specs = [
      for (var i = 0; i < cats.length; i++)
        {'name': '${cats[i]['label']}', 'pct': catTotal == 0 ? 0.0 : ((cats[i]['n'] as num) / catTotal).toDouble(), 'val': '${cats[i]['n']} (${share(cats[i]['n'] as num, catTotal)})', 'color': specColors[i % specColors.length]},
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
    const rColors = {'4.5 - 5.0': Color(0xFF10B981), '4.0 - 4.5': Color(0xFF3B82F6), '3.0 - 4.0': Color(0xFFF59E0B), 'Below 3.0': Color(0xFFEF4444), 'No reviews': Color(0xFF94A3B8)};
    final rr = ins.list('trainers', 'ratings');
    final rTotal = rr.fold<num>(0, (a, c) => a + ((c['n'] as num?) ?? 0));
    final ratings = [
      for (final r in rr)
        {'star': '${r['label']}${r['label'] == 'No reviews' ? '' : '★'}', 'pct': rTotal == 0 ? 0.0 : ((r['n'] as num) / rTotal).toDouble(), 'val': '${r['n']} (${share(r['n'] as num, rTotal)})', 'color': rColors['${r['label']}'] ?? const Color(0xFF64748B)},
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
      for (final t in ins.list('trainers', 'top'))
        {'name': '${t['name'] ?? 'Coach'}', 'desc': '${t['clients']} clients • ${t['rating'] == null || t['rating'] == 0 ? 'New' : '${t['rating']}★'}', 'earnings': fmtInr(t['earnings'] as num? ?? 0), 'img': '${t['photo'] ?? ''}'},
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
                  child: NetOrAssetImage(t['img'] as String, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person)),
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
    final days = [for (final d in dayLabels(7)) d.split(' ').last];
    final sessions = _live7;

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
          Text(fmtInt(st.n('trainers', 'sessions')), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('${fmtInt(_live7.fold<double>(0, (a, b) => a + b))} in the last 7 days', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: top(_live7, 4) / 4, getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))))),
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
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: top(_live7, 4) / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                maxY: top(_live7, 4),
                barGroups: List.generate(days.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: sessions[i], color: i == 6 ? const Color(0xFF65D300) : const Color(0xFF86EFAC), width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))])),
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
          Text('${ins.sub('trainers', 'rating')['avg'] ?? 0} ★', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('${ins.sub('trainers', 'rating')['n'] ?? 0} reviews in total', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
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
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: _sp(_rating7),
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
          Text(fmtInr(st.n('trainers', 'sub_revenue')), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('${fmtInr(_earn7.fold<double>(0, (a, b) => a + b))} in the last 7 days', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: top(_earn7, 1000) / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: top(_earn7, 1000),
                lineBarsData: [
                  LineChartBarData(
                    spots: _sp(_earn7),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: _pay('Paid') + (_payTotal == 0 ? 1 : 0), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: _pay('Pending'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF97316), value: _payOther, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInrShort(_payTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const Text('Total Payout', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Paid', '${fmtInrShort(_pay('Paid'))} (${share(_pay('Paid'), _payTotal)})'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Pending', '${fmtInrShort(_pay('Pending'))} (${share(_pay('Pending'), _payTotal)})'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFF97316), 'Other', '${fmtInrShort(_payOther)} (${share(_payOther, _payTotal)})'),
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
          Text(fmtInr(st.n('trainers', 'sub_revenue') / _approved), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('${fmtInr(_earn7.fold<double>(0, (a, b) => a + b) / _approved)} per coach this week', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: top([for (final e in _earn7) e / _approved], 100) / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: top([for (final e in _earn7) e / _approved], 100),
                lineBarsData: [
                  LineChartBarData(
                    spots: _sp([for (final e in _earn7) e / _approved]),
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
    const regColor = {'approved': Color(0xFF10B981), 'pending': Color(0xFFF97316), 'rejected': Color(0xFFEF4444), 'suspended': Color(0xFF64748B)};
    final regs = [
      for (final r in ins.list('trainers', 'recent'))
        {'name': '${r['name'] ?? 'Coach'}', 'spec': '${r['cat']}', 'date': shortDate(r['at']?.toString()), 'status': r['status'] == 'approved' ? 'Verified' : '${r['status']}'[0].toUpperCase() + '${r['status']}'.substring(1), 'color': regColor['${r['status']}'] ?? const Color(0xFFF97316), 'img': '${r['photo'] ?? ''}'},
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
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: NetOrAssetImage(r['img'] as String, width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.person))),
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
    const tag = {'live': ['Live Session', Color(0xFF3B82F6)], 'payment': ['Payment', Color(0xFF8B5CF6)], 'review': ['Review', Color(0xFF10B981)], 'update': ['Update', Color(0xFFF97316)]};
    final acts = [
      for (final a in ins.list('trainers', 'activity'))
        {'user': '${a['who']}', 'act': '${a['what']} · ${timeAgo(a['at']?.toString())}', 'tag': (tag['${a['kind']}'] ?? tag['update']!)[0], 'color': (tag['${a['kind']}'] ?? tag['update']!)[1], 'img': '${a['photo'] ?? ''}'},
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
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: NetOrAssetImage(a['img'] as String, width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.person))),
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
