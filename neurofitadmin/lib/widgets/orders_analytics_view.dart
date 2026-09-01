import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OrdersAnalyticsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const OrdersAnalyticsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<OrdersAnalyticsView> createState() => _OrdersAnalyticsViewState();
}

class _OrdersAnalyticsViewState extends State<OrdersAnalyticsView> {
  int _selectedFilterIndex = 2; // 0=Today, 1=Yesterday, 2=This Week, 3=Last Week, 4=This Month, 5=Custom

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
        // 1. HERO BANNER: "Orders Analytics"
        _buildAnimatedSection(0, _buildOrdersHeroBanner()),
        const SizedBox(height: 20),

        // 2. QUICK TIME FILTER BAR & EXPORT
        _buildAnimatedSection(1, _buildTimeFilterBar()),
        const SizedBox(height: 16),

        // 3. 6 ORDER STATUS CARDS
        _buildAnimatedSection(2, _buildOrderStageCards()),
        const SizedBox(height: 20),

        // 4. ORDERS OVERVIEW & ORDERS BY STATUS
        _buildAnimatedSection(3, _buildOrdersOverviewSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(4, _buildOrdersByStatusSection()),
        const SizedBox(height: 20),

        // 5. ORDERS BY CATEGORY & ORDERS BY PAYMENT METHOD
        _buildAnimatedSection(5, _buildOrdersByCategorySection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(6, _buildOrdersByPaymentMethodSection()),
        const SizedBox(height: 20),

        // 6. TOP SELLING PRODUCTS
        _buildAnimatedSection(7, _buildTopSellingProductsSection()),
        const SizedBox(height: 20),

        // 7. ORDERS BY LOCATION, DAILY ORDER TREND & AVERAGE ORDER VALUE
        _buildAnimatedSection(8, _buildOrdersByLocationSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(9, _buildDailyOrderTrendSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(10, _buildAverageOrderValueSection()),
        const SizedBox(height: 20),

        // 8. RECENT ORDERS & ORDERS SUMMARY
        _buildAnimatedSection(11, _buildRecentOrdersSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(12, _buildOrdersSummarySection()),
        const SizedBox(height: 20),

        // 9. BOTTOM DARK CTA BANNER
        _buildAnimatedSection(13, _buildBottomDeliveryBanner()),
      ],
    );
  }

  // 1. HERO BANNER
  Widget _buildOrdersHeroBanner() {
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
                            TextSpan(text: 'Orders '),
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
                      'Comprehensive insights into orders, sales performance and delivery metrics.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildHeroStat('1,243', 'Total Orders (↑14.3%)', const Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        _buildHeroStat('1,018', 'Delivered (↑12.7%)', const Color(0xFF3B82F6)),
                        const SizedBox(width: 12),
                        _buildHeroStat('₹10,12,500', 'Order Value (↑21.7%)', const Color(0xFFF97316)),
                        const SizedBox(width: 12),
                        _buildHeroStat('₹815', 'Avg Order Value (↑6.4%)', const Color(0xFF8B5CF6)),
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
    final filters = ['Today', 'Yesterday', 'This Week', 'Last Week', 'This Month', 'Custom 📅'];

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

  // 3. 6 ORDER STAGE CARDS
  Widget _buildOrderStageCards() {
    final stages = [
      {'title': 'Total Orders', 'val': '1,243', 'growth': '+14.3%', 'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Pending Orders', 'val': '156', 'growth': '-2.4%', 'icon': Icons.schedule_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'Processing Orders', 'val': '312', 'growth': '+8.7%', 'icon': Icons.inventory_2_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Shipped Orders', 'val': '256', 'growth': '+11.2%', 'icon': Icons.local_shipping_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'title': 'Delivered Orders', 'val': '1,018', 'growth': '+16.5%', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF14B8A6), 'bg': const Color(0xFFE6FAF8)},
      {'title': 'Cancelled Orders', 'val': '145', 'growth': '-3.1%', 'icon': Icons.cancel_rounded, 'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEE2E2)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: stages.map((s) {
          final Color color = s['color'] as Color;
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
                    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: s['bg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(s['icon'] as IconData, color: color, size: 14)),
                    Text(s['growth'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(s['val'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                Text(s['title'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 4. ORDERS OVERVIEW
  Widget _buildOrdersOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1. Orders Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendDot(const Color(0xFF10B981), 'Orders'),
              const SizedBox(width: 14),
              _buildLegendDot(const Color(0xFF3B82F6), 'Order Value'),
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

  // 4. ORDERS BY STATUS
  Widget _buildOrdersByStatusSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('2. Orders by Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          PieChartSectionData(color: const Color(0xFFF97316), value: 12.5, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: 25.1, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: 20.6, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF10B981), value: 30.7, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFEF4444), value: 11.1, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('1,243', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Total Orders', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFFF97316), 'Pending', '12.5% (156)'),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Processing', '25.1% (312)'),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Shipped', '20.6% (256)'),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFF10B981), 'Delivered', '30.7% (382)'),
                    const SizedBox(height: 6),
                    _buildDemographicRow(const Color(0xFFEF4444), 'Cancelled', '11.1% (138)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. ORDERS BY CATEGORY
  Widget _buildOrdersByCategorySection() {
    final categories = [
      {'name': 'Supplements', 'pct': 0.425, 'val': '42.5% • 528', 'color': const Color(0xFF10B981)},
      {'name': 'Nutrition', 'pct': 0.378, 'val': '37.8% • 470', 'color': const Color(0xFF3B82F6)},
      {'name': 'Accessories', 'pct': 0.156, 'val': '15.6% • 194', 'color': const Color(0xFF8B5CF6)},
      {'name': 'Workout Gear', 'pct': 0.118, 'val': '11.8% • 146', 'color': const Color(0xFFF97316)},
      {'name': 'Others', 'pct': 0.089, 'val': '8.9% • 111', 'color': const Color(0xFF14B8A6)},
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
              const Text('3. Orders by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.map((c) {
            final Color color = c['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(c['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                      Text(c['val'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c['pct'] as double,
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

  // 5. ORDERS BY PAYMENT METHOD
  Widget _buildOrdersByPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('4. Orders by Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: 54.1, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: 26.7, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF59E0B), value: 11.2, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF8B5CF6), value: 5.6, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF06B6D4), value: 2.4, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('1,243', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Orders', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'UPI', '54.1%'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF3B82F6), 'Card', '26.7%'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFF59E0B), 'COD', '11.2%'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Net Banking', '5.6%'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF06B6D4), 'Wallet', '2.4%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. TOP SELLING PRODUCTS
  Widget _buildTopSellingProductsSection() {
    final products = [
      {'title': 'Whey Protein', 'desc': '380 Orders', 'growth': '+18.4%', 'img': 'assets/images/nutrifit_whey_protein.jpg'},
      {'title': 'Creatine Monohydrate', 'desc': '295 Orders', 'growth': '+14.2%', 'img': 'assets/images/product_1.png'},
      {'title': 'Peanut Butter', 'desc': '241 Orders', 'growth': '+10.1%', 'img': 'assets/images/product_2.png'},
      {'title': 'Pre-Workout', 'desc': '201 Orders', 'growth': '+12.6%', 'img': 'assets/images/nutrifit_whey_protein.jpg'},
      {'title': 'Gym Bag', 'desc': '162 Orders', 'growth': '+7.4%', 'img': 'assets/images/product_1.png'},
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
              Text('5. Top Selling Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...products.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(p['img'] as String, width: 38, height: 38, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.inventory_2)),
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

  // 7. ORDERS BY LOCATION
  Widget _buildOrdersByLocationSection() {
    final locations = [
      {'name': 'Maharashtra', 'val': '34.2% (425)'},
      {'name': 'Karnataka', 'val': '24.1% (299)'},
      {'name': 'Uttar Pradesh', 'val': '18.5% (230)'},
      {'name': 'Tamil Nadu', 'val': '12.8% (159)'},
      {'name': 'Delhi', 'val': '9.4% (117)'},
      {'name': 'Others', 'val': '21.0% (261)'},
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
              const Text('6. Orders by Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 14),
          ...locations.map((loc) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(loc['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  ],
                ),
                Text(loc['val'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // 7. DAILY ORDER TREND
  Widget _buildDailyOrderTrendSection() {
    final days = ['May 20', 'May 21', 'May 22', 'May 23', 'May 24', 'May 25', 'May 26'];
    final orders = [120.0, 165.0, 140.0, 195.0, 235.0, 180.0, 208.0];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('7. Daily Order Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
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
                          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(days[i].substring(4), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: i == 4 ? const Color(0xFF10B981) : const Color(0xFF94A3B8))));
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
                barGroups: List.generate(days.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: orders[i], color: i == 4 ? const Color(0xFF65D300) : const Color(0xFF86EFAC), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. AVERAGE ORDER VALUE
  Widget _buildAverageOrderValueSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('8. Average Order Value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 6),
          const Text('₹815', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('↑ 6.4% vs last 7 days', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 200, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 1000,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 520), FlSpot(1, 680), FlSpot(2, 640), FlSpot(3, 820), FlSpot(4, 760), FlSpot(5, 890), FlSpot(6, 815)],
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

  // 8. RECENT ORDERS
  Widget _buildRecentOrdersSection() {
    final orders = [
      {'id': '#ORD-1243', 'user': 'Manoj Sharma', 'amount': '₹2,499', 'status': 'Delivered', 'date': 'May 26, 2025', 'color': const Color(0xFF10B981)},
      {'id': '#ORD-1242', 'user': 'Priya Patel', 'amount': '₹1,899', 'status': 'Shipped', 'date': 'May 26, 2025', 'color': const Color(0xFF3B82F6)},
      {'id': '#ORD-1241', 'user': 'Amit Verma', 'amount': '₹899', 'status': 'Processing', 'date': 'May 25, 2025', 'color': const Color(0xFF8B5CF6)},
      {'id': '#ORD-1240', 'user': 'Neha Singh', 'amount': '₹450', 'status': 'Pending', 'date': 'May 25, 2025', 'color': const Color(0xFFF97316)},
      {'id': '#ORD-1239', 'user': 'Suresh Raina', 'amount': '₹1,299', 'status': 'Cancelled', 'date': 'May 25, 2025', 'color': const Color(0xFFEF4444)},
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
              Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          ...orders.map((o) {
            final Color color = o['color'] as Color;
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
                        Text(o['id'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text('${o['user']} • ${o['date']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(o['amount'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(4)),
                        child: Text(o['status'] as String, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: color)),
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

  // 8. ORDERS SUMMARY
  Widget _buildOrdersSummarySection() {
    final summaries = [
      {'title': 'Total Orders', 'val': '1,243', 'growth': '+14.3%', 'color': const Color(0xFF10B981), 'icon': Icons.shopping_bag_rounded},
      {'title': 'Total Order Value', 'val': '₹10,12,500', 'growth': '+21.7%', 'color': const Color(0xFF8B5CF6), 'icon': Icons.account_balance_wallet_rounded},
      {'title': 'Average Order Value', 'val': '₹815', 'growth': '+6.4%', 'color': const Color(0xFFF97316), 'icon': Icons.show_chart_rounded},
      {'title': 'Refunded Amount', 'val': '₹52,000', 'growth': '-2.4%', 'color': const Color(0xFFEF4444), 'icon': Icons.replay_rounded},
      {'title': 'Return Requests', 'val': '16', 'growth': '+1.8%', 'color': const Color(0xFF3B82F6), 'icon': Icons.swap_horiz_rounded},
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
              const Text('Orders Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
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

  // 9. BOTTOM DELIVERY BANNER
  Widget _buildBottomDeliveryBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Optimize Orders, Improve Fulfillment', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          const Text(
            'Track performance, reduce delays, and increase customer satisfaction with real-time insights.',
            style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
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
