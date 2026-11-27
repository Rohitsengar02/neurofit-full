import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsOverviewView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const ReportsOverviewView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<ReportsOverviewView> createState() => _ReportsOverviewViewState();
}

class _ReportsOverviewViewState extends State<ReportsOverviewView> with LiveStats {
  String get selectedDateRange => widget.selectedDateRange;
  List<Animation<double>> get fadeAnimations => widget.fadeAnimations;
  List<Animation<Offset>> get slideAnimations => widget.slideAnimations;

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
        // 1. HERO BANNER: "Reports That Drive Smarter Decisions"
        _buildAnimatedSection(0, _buildReportsHeroBanner()),
        const SizedBox(height: 20),

        // 2. QUICK ACCESS CAROUSEL
        _buildAnimatedSection(1, _buildQuickAccessReportsSection()),
        const SizedBox(height: 20),

        // 3. REPORTS CATEGORIES (8 Cards)
        _buildAnimatedSection(2, _buildReportsCategoriesSection()),
        const SizedBox(height: 20),

        // 4. POPULAR REPORTS WITH LIVE SPARKLINE WAVES
        _buildAnimatedSection(3, _buildPopularReportsSection()),
        const SizedBox(height: 20),

        // 5. RECENT REPORT DOWNLOADS & SCHEDULED REPORTS
        _buildAnimatedSection(4, _buildRecentAndScheduledReportsSection()),
        const SizedBox(height: 20),

        // 6. NEED A CUSTOM REPORT? BOTTOM CTA BANNER
        _buildAnimatedSection(5, _buildNeedCustomReportBanner()),
      ],
    );
  }

  // 1. REPORTS HERO BANNER
  Widget _buildReportsHeroBanner() {
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
                'assets/images/hero_banner_1.png',
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
                        TextSpan(text: 'Reports That Drive\n'),
                        TextSpan(text: 'Smarter ', style: TextStyle(color: Color(0xFF10B981))),
                        TextSpan(text: 'Decisions'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(
                    width: 200,
                    child: Text(
                      'Explore detailed reports and export data in multiple formats.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildHeroReportStat(Icons.description_outlined, '58', 'Reports', const Color(0xFF10B981)),
                      const SizedBox(width: 14),
                      _buildHeroReportStat(Icons.grid_view_rounded, '12', 'Categories', const Color(0xFF3B82F6)),
                      const SizedBox(width: 14),
                      _buildHeroReportStat(Icons.download_rounded, '8.4K', 'Downloads', const Color(0xFF8B5CF6)),
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
                          'Create Custom Report',
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

  Widget _buildHeroReportStat(IconData icon, String val, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }

  // 2. QUICK ACCESS REPORTS
  Widget _buildQuickAccessReportsSection() {
    final quickItems = [
      {'title': 'Daily Report', 'desc': 'Yesterday Overview', 'icon': Icons.today_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Weekly Report', 'desc': 'Last 7 Days', 'icon': Icons.date_range_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'Monthly Report', 'desc': 'Last 30 Days', 'icon': Icons.calendar_month_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Quarterly Report', 'desc': 'Quarter Overview', 'icon': Icons.folder_shared_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Yearly Report', 'desc': 'Year Overview', 'icon': Icons.event_note_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'title': 'Custom Report', 'desc': 'Select Date Range', 'icon': Icons.tune_rounded, 'color': const Color(0xFF06B6D4), 'bg': const Color(0xFFECFEFF)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Quick Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(selectedDateRange, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: quickItems.length,
            itemBuilder: (ctx, i) {
              final item = quickItems[i];
              final Color color = item['color'] as Color;

              return Container(
                width: 125,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: item['bg'] as Color, borderRadius: BorderRadius.circular(10)),
                      child: Icon(item['icon'] as IconData, color: color, size: 18),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        const SizedBox(height: 1),
                        Text(item['desc'] as String, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 3. REPORTS CATEGORIES
  Widget _buildReportsCategoriesSection() {
    final categories = [
      {'title': 'User Reports', 'desc': 'User growth, activity, retention, demographics and more', 'count': '7 Reports', 'icon': Icons.people_outline_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Fitness Reports', 'desc': 'Workout performance, completion rates, logs and analytics', 'count': '8 Reports', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Nutrition Reports', 'desc': 'Meal logs, nutrition analytics, goals and insights', 'count': '6 Reports', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Trainer Reports', 'desc': 'Trainer performance, earnings, sessions and reviews', 'count': '8 Reports', 'icon': Icons.sports_gymnastics_rounded, 'color': const Color(0xFF06B6D4), 'bg': const Color(0xFFECFEFF)},
      {'title': 'Marketplace Reports', 'desc': 'Products, orders, vendors, inventory and sales', 'count': '7 Reports', 'icon': Icons.storefront_rounded, 'color': const Color(0xFFEC4899), 'bg': const Color(0xFFFDF2F8)},
      {'title': 'Finance Reports', 'desc': 'Revenue, payments, refunds, payouts and transactions', 'count': '8 Reports', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFF0FDF4)},
      {'title': 'Engagement Reports', 'desc': 'Challenges, rewards, community, engagement and more', 'count': '9 Reports', 'icon': Icons.emoji_events_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'App Reports', 'desc': 'App usage, crashes, performance and system analytics', 'count': '7 Reports', 'icon': Icons.phone_android_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reports Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
          ),
          itemCount: categories.length,
          itemBuilder: (ctx, i) {
            final cat = categories[i];
            final Color color = cat['color'] as Color;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: cat['bg'] as Color, borderRadius: BorderRadius.circular(8)),
                    child: Icon(cat['icon'] as IconData, color: color, size: 16),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(cat['desc'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cat['count'] as String, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: color),
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

  // 4. POPULAR REPORTS
  String _g(String key) => '${st.growthUp(key) ? '+' : '-'}${st.growth(key).abs().toStringAsFixed(1)}%';

  Widget _buildPopularReportsSection() {
    final popular = [
      {'title': 'User Growth Report', 'desc': 'Detailed user growth and registration trends', 'metric': fmtInt(st.n('users', 'total')), 'label': 'Total Users', 'growth': _g('signups'), 'key': 'signups', 'color': const Color(0xFF10B981), 'icon': Icons.people_outline_rounded},
      {'title': 'Revenue Summary Report', 'desc': 'Revenue summary and financial insights', 'metric': fmtInr(ins.n('revenue', 'total') == 0 ? st.n('orders', 'revenue') : ins.n('revenue', 'total')), 'label': 'Total Revenue', 'growth': _g('revenue'), 'key': 'revenue', 'color': const Color(0xFF8B5CF6), 'icon': Icons.account_balance_wallet_rounded},
      {'title': 'Workout Performance Report', 'desc': 'Workout completions, types and performance', 'metric': fmtInt(st.n('fitness', 'completed')), 'label': 'Completed Workouts', 'growth': _g('workoutsDone'), 'key': 'workoutsDone', 'color': const Color(0xFF3B82F6), 'icon': Icons.fitness_center_rounded},
      {'title': 'Order & Sales Report', 'desc': 'Orders, sales overview and product insights', 'metric': fmtInt(st.n('orders', 'total')), 'label': 'Total Orders', 'growth': _g('orders'), 'key': 'orders', 'color': const Color(0xFFF97316), 'icon': Icons.shopping_bag_rounded},
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
              Text('Popular Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...popular.map((p) {
            final Color color = p['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(p['icon'] as IconData, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(p['desc'] as String, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(p['metric'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            const SizedBox(width: 4),
                            Text('(${p['growth']})', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    height: 26,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: top(st.series(p['key'] as String, 7), 1),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [for (final e in st.series(p['key'] as String, 7).asMap().entries) FlSpot(e.key.toDouble(), e.value)],
                            isCurved: true,
                            color: color,
                            barWidth: 2.0,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                    child: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 5. RECENT & SCHEDULED REPORTS
  Widget _buildRecentAndScheduledReportsSection() {
    final downloads = [
      {'title': 'User Growth Report', 'time': 'May 26, 2025 • PDF', 'icon': Icons.picture_as_pdf_rounded, 'color': const Color(0xFF10B981)},
      {'title': 'Revenue Summary Report', 'time': 'May 26, 2025 • Excel', 'icon': Icons.table_chart_rounded, 'color': const Color(0xFF8B5CF6)},
      {'title': 'Workout Performance Report', 'time': 'May 25, 2025 • PDF', 'icon': Icons.picture_as_pdf_rounded, 'color': const Color(0xFF3B82F6)},
      {'title': 'Marketplace Sales Report', 'time': 'May 25, 2025 • Excel', 'icon': Icons.table_chart_rounded, 'color': const Color(0xFFF97316)},
    ];

    final scheduled = [
      {'title': 'Daily Overview Report', 'time': 'Every day at 09:00 AM', 'status': 'Active'},
      {'title': 'Weekly Performance Report', 'time': 'Every Monday at 08:00 AM', 'status': 'Active'},
      {'title': 'Monthly Executive Report', 'time': '1st of Every Month at 09:00 AM', 'status': 'Active'},
      {'title': 'Quarterly Financial Report', 'time': '1st of Every Quarter at 10:00 AM', 'status': 'Active'},
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Recent Report Downloads', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  Text('View All', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
                ],
              ),
              const SizedBox(height: 12),
              ...downloads.map((d) {
                final Color color = d['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(d['icon'] as IconData, color: color, size: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['title'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            Text(d['time'] as String, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const Icon(Icons.download_rounded, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Scheduled Reports', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  Text('View All', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
                ],
              ),
              const SizedBox(height: 12),
              ...scheduled.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.schedule_rounded, color: Color(0xFF0F172A), size: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['title'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            Text(s['time'] as String, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Active', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // 6. NEED A CUSTOM REPORT?
  Widget _buildNeedCustomReportBanner() {
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
          const Text('Need a Custom Report?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text(
            'Create custom reports with specific filters and metrics that matter most to your business.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
            decoration: BoxDecoration(
              color: const Color(0xFF65D300),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF65D300).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Create Custom Report', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF0F172A)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
