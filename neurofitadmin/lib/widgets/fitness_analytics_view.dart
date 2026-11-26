import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import 'net_or_asset_image.dart';
import 'package:fl_chart/fl_chart.dart';

class FitnessAnalyticsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const FitnessAnalyticsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<FitnessAnalyticsView> createState() => _FitnessAnalyticsViewState();
}

class _FitnessAnalyticsViewState extends State<FitnessAnalyticsView> with LiveStats {
  num _f(String k) => ins.n('fitness', k);
  List<double> get _done7 => st.series('workoutsDone', 7);
  List<double> get _users7 => ins.series('fitness', 'usersDaily', 7);
  List<double> get _dur7 => ins.series('fitness', 'durationDaily', 7);
  List<double> get _cal7 => ins.series('fitness', 'caloriesDaily', 7);
  List<Map<String, dynamic>> get _types => ins.list('fitness', 'types');
  double get _typesTotal => _types.fold<double>(0, (a, r) => a + ((r['n'] as num?) ?? 0).toDouble());
  double _type(int i) => i < _types.length ? ((_types[i]['n'] as num?) ?? 0).toDouble() : 0;
  String _typeName(int i) => i < _types.length ? '${_types[i]['label']}' : '-';
  String _typeLine(int i) => '${share(_type(i), _typesTotal)} (${fmtInt(_type(i))})';
  Map<String, dynamic> get _comp => ins.sub('fitness', 'completion');
  double _c(String k) => ((_comp[k] as num?) ?? 0).toDouble();
  double get _cTotal => _c('completed') + _c('incomplete') + _c('abandoned');
  List<FlSpot> _sp(List<double> v) => [for (var i = 0; i < v.length; i++) FlSpot(i.toDouble(), v[i])];

  int _selectedFilterIndex = 2; // 0=Today, 1=Yesterday, 2=This Week, 3=Last Week, 4=This Month, 5=This Year, 6=Custom

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
        // 1. HERO BANNER: "Fitness Analytics"
        _buildAnimatedSection(0, _buildFitnessHeroBanner()),
        const SizedBox(height: 20),

        // 2. QUICK TIME FILTER BAR & EXPORT
        _buildAnimatedSection(1, _buildTimeFilterBar()),
        const SizedBox(height: 16),

        // 3. WORKOUT OVERVIEW & WORKOUTS BY TYPE
        _buildAnimatedSection(2, _buildWorkoutOverviewSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(3, _buildWorkoutsByTypeSection()),
        const SizedBox(height: 20),

        // 4. TOP PERFORMING MUSCLE GROUPS & WORKOUT COMPLETION RATE
        _buildAnimatedSection(4, _buildTopMuscleGroupsSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(5, _buildWorkoutCompletionRateSection()),
        const SizedBox(height: 20),

        // 5. AVERAGE WORKOUT DURATION & CALORIES BURNED
        _buildAnimatedSection(6, _buildAverageWorkoutDurationSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(7, _buildCaloriesBurnedSection()),
        const SizedBox(height: 20),

        // 6. POPULAR WORKOUT PROGRAMS
        _buildAnimatedSection(8, _buildPopularProgramsSection()),
        const SizedBox(height: 20),

        // 7. USER ENGAGEMENT IN FITNESS & RECENT ACTIVITY
        _buildAnimatedSection(9, _buildUserEngagementSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(10, _buildRecentFitnessActivitySection()),
        const SizedBox(height: 20),

        // 8. BOTTOM CTA BANNER
        _buildAnimatedSection(11, _buildBottomDriveResultsBanner()),
      ],
    );
  }

  // 1. HERO BANNER
  Widget _buildFitnessHeroBanner() {
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
                            TextSpan(text: 'Fitness '),
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
                      'Track workouts, programs and user performance to optimize fitness engagement.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildHeroStat(fmtInt(st.n('fitness', 'completed')), 'Workouts (${st.growthUp('workoutsDone') ? '↑' : '↓'}${st.growth('workoutsDone').abs().toStringAsFixed(1)}%)', const Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        _buildHeroStat(fmtInt(st.n('catalog', 'programs') + st.n('catalog', 'workouts')), 'Active Programs', const Color(0xFF8B5CF6)),
                        const SizedBox(width: 12),
                        _buildHeroStat(fmtShort(st.n('activity', 'caloriesBurned')), 'Calories burned', const Color(0xFFF97316)),
                        const SizedBox(width: 12),
                        _buildHeroStat(fmtDuration(_f('avg_seconds')), 'Avg Duration', const Color(0xFF3B82F6)),
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

  // 2. TIME FILTER BAR
  Widget _buildTimeFilterBar() {
    final filters = ['Today', 'Yesterday', 'This Week', 'Last Week', 'This Month', 'This Year', 'Custom 📅'];

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(filters.length, (i) {
                final isSelected = _selectedFilterIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilterIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF10B981) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade200),
                      ),
                      child: Text(
                        filters[i],
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF65D300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: const [
              Text('Export Report', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF0F172A)),
            ],
          ),
        ),
      ],
    );
  }

  // 3. WORKOUT OVERVIEW
  Widget _buildWorkoutOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Workout Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendDot(const Color(0xFF10B981), 'Workouts Completed'),
              const SizedBox(width: 14),
              _buildLegendDot(const Color(0xFF3B82F6), 'Users'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: top([..._done7, ..._users7], 4) / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: top([..._done7, ..._users7], 4) / 4, getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)))),
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
                maxY: top([..._done7, ..._users7], 4),
                lineBarsData: [
                  LineChartBarData(
                    spots: _sp(_done7),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: _sp(_users7),
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

  // 3. WORKOUTS BY TYPE
  Widget _buildWorkoutsByTypeSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Workouts by Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: _type(0) + (_typesTotal == 0 ? 1 : 0), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: _type(1), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: _type(2), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF97316), value: _type(3), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFEC4899), value: _type(4), radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInt(_typesTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Total Workouts', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), _typeName(0), _typeLine(0)),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF3B82F6), _typeName(1), _typeLine(1)),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF8B5CF6), _typeName(2), _typeLine(2)),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFFF97316), _typeName(3), _typeLine(3)),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFFEC4899), _typeName(4), _typeLine(4)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. TOP PERFORMING MUSCLE GROUPS
  Widget _buildTopMuscleGroupsSection() {
    const gColors = [Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFF97316)];
    final ms = ins.list('fitness', 'muscles');
    final mTotal = ms.fold<num>(0, (a, r) => a + ((r['n'] as num?) ?? 0));
    final groups = [
      for (var i = 0; i < ms.length; i++)
        {'name': '${ms[i]['label']}', 'pct': mTotal == 0 ? 0.0 : ((ms[i]['n'] as num) / mTotal).toDouble(), 'val': '${fmtInt(ms[i]['n'] as num)} • ${share(ms[i]['n'] as num, mTotal)}', 'color': gColors[i % gColors.length]},
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
              const Text('Top Performing Muscle Groups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 16),
          ...groups.map((g) {
            final Color color = g['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(g['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                      Text(g['val'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: g['pct'] as double,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('View All Muscle Groups', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  // 4. WORKOUT COMPLETION RATE
  Widget _buildWorkoutCompletionRateSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Workout Completion Rate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: _c('completed') + (_cTotal == 0 ? 1 : 0), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF59E0B), value: _c('incomplete'), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFEF4444), value: _c('abandoned'), radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(share(_c('completed'), _cTotal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Completion Rate', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'Completed', '${fmtInt(_c('completed'))} (${share(_c('completed'), _cTotal)})'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFF59E0B), 'Incomplete', '${fmtInt(_c('incomplete'))} (${share(_c('incomplete'), _cTotal)})'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFEF4444), 'Abandoned', '${fmtInt(_c('abandoned'))} (${share(_c('abandoned'), _cTotal)})'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. AVERAGE WORKOUT DURATION
  Widget _buildAverageWorkoutDurationSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Average Workout Duration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 6),
          Text(fmtDuration(_f('avg_seconds')), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('${(_dur7.isEmpty ? 0 : _dur7.last).toStringAsFixed(0)} min today', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: top(_dur7, 10) / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: top(_dur7, 10),
                lineBarsData: [
                  LineChartBarData(
                    spots: _sp(_dur7),
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

  // 5. CALORIES BURNED
  Widget _buildCaloriesBurnedSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Calories Burned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 6),
          Text(fmtShort(st.n('activity', 'caloriesBurned')), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('${fmtInt(_cal7.fold<double>(0, (a, b) => a + b))} kcal in the last 7 days', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: top(_cal7, 100) / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: top(_cal7, 100),
                lineBarsData: [
                  LineChartBarData(
                    spots: _sp(_cal7),
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

  // 6. POPULAR WORKOUT PROGRAMS
  Widget _buildPopularProgramsSection() {
    final programs = [
      for (final p in ins.list('fitness', 'programs'))
        {'title': '${p['title']}', 'desc': '${fmtInt(p['athletes'] as num? ?? 0)} Users', 'growth': '${fmtInt(p['completed'] as num? ?? 0)} done', 'img': ''},
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
              Text('Popular Workout Programs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...programs.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: NetOrAssetImage(p['img'] as String, width: 38, height: 38, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.fitness_center)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      Text(p['desc'] as String, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Text(p['growth'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // 7. USER ENGAGEMENT IN FITNESS
  Widget _buildUserEngagementSection() {
    final days = weekdayLabels(7);
    final heights = _users7;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Engagement in Fitness', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Active Users', fmtInt(_f('active')), '7 days'),
              _buildMiniMetric('New Users', fmtInt(_f('new')), '7 days'),
              _buildMiniMetric('Repeating Users', fmtInt(_f('repeating')), 'all time'),
              _buildMiniMetric('Inactive Users', fmtInt(_f('inactive')), '14+ days'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(days.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: heights[i], color: i == 6 ? const Color(0xFF65D300) : const Color(0xFF86EFAC), width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String val, String growth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        Text(growth, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
        Text(label, style: const TextStyle(fontSize: 7.5, color: Color(0xFF64748B))),
      ],
    );
  }

  // 7. RECENT FITNESS ACTIVITY
  Widget _buildRecentFitnessActivitySection() {
    final activities = [
      for (final a in ins.list('fitness', 'recent'))
        {'user': '${a['name'] ?? 'User'}', 'act': '${a['done'] == true ? 'completed' : 'started'} a workout: ${a['title']}', 'time': timeAgo(a['at']?.toString()), 'img': '${a['photo'] ?? ''}'},
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
              Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...activities.map((a) {
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
                  Text(a['time'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 8. BOTTOM CTA BANNER
  Widget _buildBottomDriveResultsBanner() {
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
          const Text('Drive More Results', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text(
            'Analyze performance, track workout trends and boost user fitness success.',
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
