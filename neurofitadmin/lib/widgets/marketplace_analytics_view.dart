import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/category_backend_service.dart';
import '../backend/admin_data.dart';
import 'skeleton_loader.dart';

class MarketplaceAnalyticsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const MarketplaceAnalyticsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<MarketplaceAnalyticsView> createState() => _MarketplaceAnalyticsViewState();
}

class _MarketplaceAnalyticsViewState extends State<MarketplaceAnalyticsView> with LiveStats {
  int _selectedFilterIndex = 2; // 0=Today, 1=Yesterday, 2=This Week, 3=Last Week, 4=This Month, 5=This Year, 6=Custom

  // Everything below comes from /admin/stats and /admin/insights (cached on the server,
  // refreshed by socket events), so this screen never downloads every order or user.
  Map<String, dynamic> get _m => ins.sec('marketplace');
  num _mn(String k) => (_m[k] as num?) ?? 0;
  List<Map<String, dynamic>> _ml(String k) => [for (final x in (_m[k] as List? ?? const [])) if (x is Map) Map<String, dynamic>.from(x)];
  List<double> _mSeries(String k, [int days = 7]) {
    final v = [for (final p in _ml(k)) ((p['value'] as num?) ?? 0).toDouble()];
    return v.length > days ? v.sublist(v.length - days) : v;
  }

  Future<void> _fetchRealAnalyticsData() async {
    await Future.wait([AdminStats.I.load(force: true), AdminInsights.I.load(force: true)]);
  }

  double get _totalSalesRevenue => st.n('orders', 'revenue').toDouble();

  int get _totalOrdersCount => st.n('orders', 'total').toInt();

  double get _averageOrderValue => st.n('orders', 'avg_order_value').toDouble();

  int get _totalProductsCount => st.n('catalog', 'products').toInt();

  int get _totalProductsSold => ins.list('orders', 'categories').fold<int>(0, (a, c) => a + ((c['qty'] as num?) ?? 0).toInt());

  Map<String, int> get _orderStatusCounts {
    final Map<String, int> map = {'Placed': 0, 'Processing': 0, 'Shipped': 0, 'Delivered': 0, 'Cancelled': 0};
    for (final r in st.rows('ordersByStatus')) {
      final s = (r['status'] ?? '').toString().toLowerCase();
      final n = ((r['n'] as num?) ?? 0).toInt();
      if (s == 'processing' || s == 'confirmed' || s == 'packed') map['Processing'] = map['Processing']! + n;
      else if (s == 'shipped' || s == 'out for delivery') map['Shipped'] = map['Shipped']! + n;
      else if (s == 'delivered') map['Delivered'] = map['Delivered']! + n;
      else if (s == 'cancelled' || s == 'returned') map['Cancelled'] = map['Cancelled']! + n;
      else map['Placed'] = map['Placed']! + n;
    }
    return map;
  }

  /// Payment split of marketplace orders, largest first.
  List<Map<String, dynamic>> get _payRows {
    final rows = ins.list('revenue', 'paymentMethods')..sort((a, b) => ((b['amount'] as num?) ?? 0).compareTo((a['amount'] as num?) ?? 0));
    return rows;
  }

  String _orderStatusLabel(String s) {
    final l = s.toLowerCase();
    if (l.contains('deliver')) return 'Delivered';
    if (l.contains('ship') || l.contains('out for')) return 'Shipped';
    if (l.contains('cancel') || l.contains('return')) return 'Cancelled';
    if (l.contains('process') || l.contains('confirm') || l.contains('pack')) return 'Processing';
    return 'Pending';
  }

  Color _orderStatusColor(String s) {
    switch (_orderStatusLabel(s)) {
      case 'Delivered': return const Color(0xFF10B981);
      case 'Shipped': return const Color(0xFF3B82F6);
      case 'Processing': return const Color(0xFF8B5CF6);
      case 'Cancelled': return const Color(0xFFEF4444);
      default: return const Color(0xFFF97316);
    }
  }

  String _growth(num cur, num prev) {
    if (prev == 0) return cur > 0 ? '+100%' : '0%';
    final g = (cur - prev) / prev * 100;
    return '${g >= 0 ? '+' : ''}${g.toStringAsFixed(1)}%';
  }

  List<double> get _sales7K => [for (final v in st.series('revenue', 7)) v / 1000];
  double get _salesTop => top(_sales7K, 1);

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
        _buildAnimatedSection(0, _buildMarketplaceHeroBanner()),
        const SizedBox(height: 20),

        _buildAnimatedSection(1, _buildTop5KpisSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(2, _buildTimeFilterBar()),
        const SizedBox(height: 16),

        _buildAnimatedSection(3, _buildSalesOverviewSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(4, _buildOrderOverviewSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(5, _buildSalesByCategorySection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(6, _buildTopSellingProductsSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(7, _buildSalesByPaymentMethodSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(8, _buildSalesTrendSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(11, _buildInventoryStatusSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(12, _buildAverageOrderValueSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(14, _buildRecentOrdersSection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(14, _buildMarketplaceSummarySection()),
        const SizedBox(height: 20),

        _buildAnimatedSection(14, _buildBottomGrowMarketplaceBanner()),
      ],
    );
  }

  Widget _buildMarketplaceHeroBanner() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                'assets/images/hero_fitness_gear_1787825602174.jpg',
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
                      Colors.white.withValues(alpha: 0.98),
                      Colors.white.withValues(alpha: 0.94),
                      Colors.white.withValues(alpha: 0.28),
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
                            TextSpan(text: 'Marketplace '),
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
                            const Icon(Icons.sync_rounded, size: 10, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text('$_totalOrdersCount Live Orders', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(
                    width: 230,
                    child: Text(
                      'Insights from orders, the product catalog and customer metrics.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildHeroStat('₹${_totalSalesRevenue.toStringAsFixed(0)}', 'Total Live Revenue', const Color(0xFF10B981)),
                      const SizedBox(width: 14),
                      _buildHeroStat('$_totalOrdersCount', 'Total Orders', const Color(0xFF8B5CF6)),
                    ],
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

  Widget _buildTop5KpisSection() {
    final kpis = [
      {'title': 'Total Orders', 'val': '$_totalOrdersCount', 'growth': 'All time', 'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Total Sales', 'val': '₹${_totalSalesRevenue.toStringAsFixed(0)}', 'growth': 'Live Revenue', 'icon': Icons.monetization_on_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Catalog Products', 'val': '$_totalProductsCount', 'growth': 'Real Catalog', 'icon': Icons.inventory_2_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': 'Items Sold', 'val': '$_totalProductsSold', 'growth': 'Products Sold', 'icon': Icons.local_shipping_rounded, 'color': const Color(0xFF06B6D4), 'bg': const Color(0xFFECFEFF)},
      {'title': 'Avg Order Value', 'val': '₹${_averageOrderValue.toStringAsFixed(0)}', 'growth': 'AOV Metric', 'icon': Icons.credit_card_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
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
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: k['bg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(k['icon'] as IconData, color: color, size: 14)),
                    Text(k['growth'] as String, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: color)),
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
        GestureDetector(
          onTap: () => _fetchRealAnalyticsData(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF65D300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Text('Refresh Data', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                SizedBox(width: 4),
                Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF0F172A)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1. Sales Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('Live Feed'),
            ],
          ),
          const SizedBox(height: 6),
          Text('₹${_totalSalesRevenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('Live from $_totalOrdersCount orders', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _salesTop / 5, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: _salesTop / 5, getTitlesWidget: (v, meta) => Text(v >= 1 ? '${v.toStringAsFixed(v < 10 ? 1 : 0)}K' : '${(v * 1000).toInt()}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final days = weekdayLabels(7);
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
                maxY: _salesTop,
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (var i = 0; i < _sales7K.length; i++) FlSpot(i.toDouble(), _sales7K[i])],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFF10B981).withValues(alpha: 0.22), const Color(0xFF10B981).withValues(alpha: 0.0)],
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

  Widget _buildOrderOverviewSection() {
    final statusMap = _orderStatusCounts;
    final total = _totalOrdersCount > 0 ? _totalOrdersCount.toDouble() : 1.0;

    final placedPct = ((statusMap['Placed'] ?? 0) / total * 100).toStringAsFixed(1);
    final processingPct = ((statusMap['Processing'] ?? 0) / total * 100).toStringAsFixed(1);
    final shippedPct = ((statusMap['Shipped'] ?? 0) / total * 100).toStringAsFixed(1);
    final deliveredPct = ((statusMap['Delivered'] ?? 0) / total * 100).toStringAsFixed(1);
    final cancelledPct = ((statusMap['Cancelled'] ?? 0) / total * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('2. Order Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: (statusMap['Delivered'] ?? 0).toDouble() + 0.1, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF97316), value: (statusMap['Processing'] ?? 0).toDouble() + 0.1, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: (statusMap['Shipped'] ?? 0).toDouble() + 0.1, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFF4F46E5), value: (statusMap['Placed'] ?? 0).toDouble() + 0.1, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFEF4444), value: (statusMap['Cancelled'] ?? 0).toDouble() + 0.1, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_totalOrdersCount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const Text('Total Orders', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem('Delivered ($deliveredPct%)', '${statusMap['Delivered']}', const Color(0xFF10B981)),
                    _buildLegendItem('Shipped ($shippedPct%)', '${statusMap['Shipped']}', const Color(0xFF3B82F6)),
                    _buildLegendItem('Processing ($processingPct%)', '${statusMap['Processing']}', const Color(0xFFF97316)),
                    _buildLegendItem('Placed ($placedPct%)', '${statusMap['Placed']}', const Color(0xFF4F46E5)),
                    _buildLegendItem('Cancelled ($cancelledPct%)', '${statusMap['Cancelled']}', const Color(0xFFEF4444)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesByCategorySection() {
    final Map<String, double> categorySales = {
      for (final c in ins.list('orders', 'categories').take(5)) (c['label'] ?? 'Other').toString(): ((c['amount'] as num?) ?? 0).toDouble(),
    };

    final double totalCatRev = categorySales.values.fold(0, (sum, item) => sum + item);

    final colors = [const Color(0xFF10B981), const Color(0xFF3B82F6), const Color(0xFF8B5CF6), const Color(0xFFF97316), const Color(0xFF06B6D4)];
    int colorIdx = 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('3. Sales by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('Real Categories', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 16),
          if (categorySales.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('No category sales yet', style: TextStyle(color: Color(0xFF94A3B8)))),
            ),
          ...categorySales.entries.map((e) {
            final Color color = colors[colorIdx % colors.length];
            colorIdx++;
            final double pct = totalCatRev > 0 ? (e.value / totalCatRev).clamp(0.02, 1.0) : 0.2;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                      Text('₹${e.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
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

  // 5. TOP SELLING PRODUCTS
  Widget _buildTopSellingProductsSection() {
    final List<Map<String, dynamic>> displayList = [
      for (final p in st.rows('topProducts').take(5))
        {'title': (p['name'] ?? 'Product').toString(), 'img': (p['image'] ?? '').toString(), 'qty': ((p['qty'] as num?) ?? 0).toInt(), 'revenue': ((p['revenue'] as num?) ?? 0).toDouble()},
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
              Text('4. Top Selling Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('Live Sales', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 14),
          if (displayList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('No product sales recorded yet', style: TextStyle(color: Color(0xFF94A3B8)))),
            )
          else
            ...displayList.map((p) {
              final String title = p['title'];
              final String img = p['img'];
              final int qty = p['qty'];
              final double revenue = p['revenue'];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      clipBehavior: Clip.antiAlias,
                      child: img.isNotEmpty
                          ? Image.network(
                              CategoryBackendService.getDisplayableImageUrl(img),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_rounded, size: 20, color: Color(0xFF64748B)),
                            )
                          : const Icon(Icons.inventory_2_rounded, size: 20, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('$qty Units Sold', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Text('₹${revenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 5. SALES BY PAYMENT METHOD
  static const _payColors = [Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFF06B6D4)];

  Widget _buildSalesByPaymentMethodSection() {
    final pay = _payRows.take(5).toList();
    final num payTotal = pay.fold<num>(0, (a, r) => a + ((r['amount'] as num?) ?? 0));
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('5. Sales by Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          for (var i = 0; i < pay.length; i++)
                            PieChartSectionData(color: _payColors[i], value: ((pay[i]['amount'] as num?) ?? 0).toDouble() + (payTotal == 0 && i == 0 ? 1 : 0), radius: 24, title: ''),
                          if (pay.isEmpty) PieChartSectionData(color: const Color(0xFFE2E8F0), value: 1, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInrShort(payTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const Text('Total Rev', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < pay.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _buildDemographicRow(_payColors[i], (pay[i]['label'] ?? 'Other').toString(), share((pay[i]['amount'] as num?) ?? 0, payTotal)),
                    ],
                    if (pay.isEmpty) _buildDemographicRow(const Color(0xFFE2E8F0), 'No payments yet', '0%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. SALES TREND
  Widget _buildSalesTrendSection() {
    final days = [for (final l in dayLabels(7)) l.split(' ').last];
    final revenues = _sales7K;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('6. Sales Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: _salesTop,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: _salesTop / 5, getTitlesWidget: (v, meta) => Text(v >= 1 ? '${v.toStringAsFixed(v < 10 ? 1 : 0)}K' : '${(v * 1000).toInt()}', style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))))),
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
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _salesTop / 5, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(revenues.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: revenues[i], color: i == 6 ? const Color(0xFF65D300) : const Color(0xFF86EFAC), width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. TOP VENDORS BY SALES
  Widget _buildTopVendorsBySalesSection() {
    final vRows = _ml('vendors');
    final num vTotal = vRows.fold<num>(0, (a, r) => a + ((r['amount'] as num?) ?? 0));
    final vendors = [
      for (final v in vRows)
        {'name': (v['label'] ?? 'Store').toString(), 'sales': '${fmtInr((v['amount'] as num?) ?? 0)} (${share((v['amount'] as num?) ?? 0, vTotal)})', 'img': (v['image'] ?? '').toString()},
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
              Text('7. Top Vendors by Sales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          if (vendors.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('No vendor sales yet', style: TextStyle(color: Color(0xFF94A3B8)))),
            ),
          ...vendors.map((v) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (v['img'] as String).isEmpty
                      ? const SizedBox(width: 34, height: 34, child: Icon(Icons.store))
                      : Image.network(CategoryBackendService.getDisplayableImageUrl(v['img'] as String), width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.store)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(v['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ),
                Text(v['sales'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // 6. PRODUCT VIEWS & CONVERSIONS
  Widget _buildProductViewsAndConversionsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('8. Product Views & Conversions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product Views', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text(fmtShort(_mn('views7')), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Conversions', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text(fmtInt(_mn('orders_week')), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: top(_mSeries('viewsDaily'), 5) / 5, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: top(_mSeries('viewsDaily'), 5),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (final e in _mSeries('viewsDaily').asMap().entries) FlSpot(e.key.toDouble(), e.value)],
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

  // 7. INVENTORY STATUS
  Widget _buildInventoryStatusSection() {
    final inv = _m['inventory'] is Map ? Map<String, dynamic>.from(_m['inventory'] as Map) : const <String, dynamic>{};
    final num inStock = (inv['in_stock'] as num?) ?? 0, low = (inv['low'] as num?) ?? 0, out = (inv['out'] as num?) ?? 0;
    final num invTotal = inStock + low + out;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('9. Inventory Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: inStock.toDouble() + (invTotal == 0 ? 1 : 0), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF59E0B), value: low.toDouble(), radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFEF4444), value: out.toDouble(), radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtInt(invTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const Text('Products', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'In Stock', '${fmtInt(inStock)} (${share(inStock, invTotal)})'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFF59E0B), 'Low Stock', '${fmtInt(low)} (${share(low, invTotal)})'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFEF4444), 'Out of Stock', '${fmtInt(out)} (${share(out, invTotal)})'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. AVERAGE ORDER VALUE
  Widget _buildAverageOrderValueSection() {
    final aov7 = ins.series('orders', 'aovDaily', 7);
    final num aovNow = _mn('orders_week') == 0 ? 0 : _mn('week') / _mn('orders_week');
    final num aovPrev = _mn('orders_prev') == 0 ? 0 : _mn('prev_week') / _mn('orders_prev');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('10. Average Order Value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 6),
          Text(fmtInr(aovNow), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('${aovNow >= aovPrev ? '↑' : '↓'} ${_growth(aovNow, aovPrev).replaceAll('+', '').replaceAll('-', '')} vs last 7 days', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: aovNow >= aovPrev ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: top(aov7, 100) / 5, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: top(aov7, 100),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (final e in aov7.asMap().entries) FlSpot(e.key.toDouble(), e.value)],
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

  // 7. RETURNS & REFUNDS
  Widget _buildReturnsAndRefundsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('11. Returns & Refunds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Returns', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text('${fmtInt(ins.n('orders', 'returns'))} (${_mn('returns_week') <= _mn('returns_prev') ? '↓' : '↑'}${_growth(_mn('returns_week'), _mn('returns_prev')).replaceAll('+', '').replaceAll('-', '')})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Refund Amount', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text(fmtInr(ins.n('orders', 'refunded')), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: top(_mSeries('refundDaily'), 100) / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: top(_mSeries('refundDaily'), 100),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (final e in _mSeries('refundDaily').asMap().entries) FlSpot(e.key.toDouble(), e.value)],
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

  // 8. RECENT ORDERS
  Widget _buildRecentOrdersSection() {
    final orders = [
      for (final o in _ml('recent'))
        {
          'id': '#${o['id']}',
          'user': (o['name'] ?? 'Customer').toString(),
          'amount': fmtInr((o['amount'] as num?) ?? 0),
          'status': _orderStatusLabel((o['status'] ?? '').toString()),
          'date': shortDate(o['at']?.toString()),
          'color': _orderStatusColor((o['status'] ?? '').toString()),
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
              Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('No orders yet', style: TextStyle(color: Color(0xFF94A3B8)))),
            ),
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

  // 8. MARKETPLACE SUMMARY
  Widget _buildMarketplaceSummarySection() {
    final summaries = [
      {'title': 'Total Sales', 'val': fmtInr(_totalSalesRevenue), 'growth': _growth(_mn('week'), _mn('prev_week')), 'color': const Color(0xFF10B981), 'icon': Icons.monetization_on_rounded},
      {'title': 'Total Orders', 'val': fmtInt(_totalOrdersCount), 'growth': _growth(_mn('orders_week'), _mn('orders_prev')), 'color': const Color(0xFF8B5CF6), 'icon': Icons.shopping_bag_rounded},
      {'title': 'Total Products', 'val': fmtInt(_totalProductsCount), 'growth': '${fmtInt(st.n('catalog', 'low_stock'))} low', 'color': const Color(0xFFF97316), 'icon': Icons.inventory_2_rounded},
      {'title': 'Total Vendors', 'val': fmtInt(st.n('users', 'vendors')), 'growth': '${_ml('vendors').length} selling', 'color': const Color(0xFF06B6D4), 'icon': Icons.store_rounded},
      {'title': 'Average Order Value', 'val': fmtInr(_averageOrderValue), 'growth': _growth(_mn('orders_week') == 0 ? 0 : _mn('week') / _mn('orders_week'), _mn('orders_prev') == 0 ? 0 : _mn('prev_week') / _mn('orders_prev')), 'color': const Color(0xFF3B82F6), 'icon': Icons.credit_card_rounded},
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
              const Text('Marketplace Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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

  // 9. BOTTOM CTA BANNER
  Widget _buildBottomGrowMarketplaceBanner() {
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
          const Text('Grow Your Marketplace', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text(
            'Track performance, optimize inventory and boost sales across your fitness marketplace.',
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

  Widget _buildLegendItem(String title, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ],
          ),
          Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
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
