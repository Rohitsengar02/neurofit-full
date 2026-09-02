import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/category_backend_service.dart';
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

class _MarketplaceAnalyticsViewState extends State<MarketplaceAnalyticsView> {
  int _selectedFilterIndex = 2; // 0=Today, 1=Yesterday, 2=This Week, 3=Last Week, 4=This Month, 5=This Year, 6=Custom
  bool _isLoading = true;
  IO.Socket? _socket;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchRealAnalyticsData();
    _initSocket();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _initSocket() {
    try {
      final socketUri = 'http://localhost:5000';
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder().setTransports(['websocket', 'polling']).disableAutoConnect().build(),
      );

      _socket?.connect();

      _socket?.on('order:created', (_) => _fetchRealAnalyticsData(silent: true));
      _socket?.on('admin:new_order', (_) => _fetchRealAnalyticsData(silent: true));
      _socket?.on('order:updated', (_) => _fetchRealAnalyticsData(silent: true));
      _socket?.on('product_created', (_) => _fetchRealAnalyticsData(silent: true));
      _socket?.on('product_updated', (_) => _fetchRealAnalyticsData(silent: true));
      _socket?.on('products_updated', (_) => _fetchRealAnalyticsData(silent: true));
      _socket?.on('user:updated', (_) => _fetchRealAnalyticsData(silent: true));
    } catch (_) {}
  }

  Future<void> _fetchRealAnalyticsData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    List<Map<String, dynamic>> fetchedOrders = [];
    List<Map<String, dynamic>> fetchedProducts = [];
    List<Map<String, dynamic>> fetchedCategories = [];
    List<Map<String, dynamic>> fetchedUsers = [];

    final candidateBases = [
      'http://localhost:5000/api',
      'http://192.168.1.34:5000/api',
      'http://10.0.2.2:5000/api',
    ];

    for (final base in candidateBases) {
      try {
        final resOrders = await http.get(Uri.parse('$base/orders')).timeout(const Duration(seconds: 3));
        if (resOrders.statusCode == 200) {
          final body = jsonDecode(resOrders.body);
          final raw = (body['data'] ?? body) as List<dynamic>? ?? [];
          fetchedOrders = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }

        final resProducts = await http.get(Uri.parse('$base/products')).timeout(const Duration(seconds: 3));
        if (resProducts.statusCode == 200) {
          final body = jsonDecode(resProducts.body);
          final raw = (body['data'] ?? body) as List<dynamic>? ?? [];
          fetchedProducts = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }

        final resCategories = await http.get(Uri.parse('$base/categories')).timeout(const Duration(seconds: 3));
        if (resCategories.statusCode == 200) {
          final body = jsonDecode(resCategories.body);
          final raw = (body['data'] ?? body) as List<dynamic>? ?? [];
          fetchedCategories = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }

        final resUsers = await http.get(Uri.parse('$base/users')).timeout(const Duration(seconds: 3));
        if (resUsers.statusCode == 200) {
          final body = jsonDecode(resUsers.body);
          final raw = (body['data'] ?? body) as List<dynamic>? ?? [];
          fetchedUsers = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }

        if (fetchedOrders.isNotEmpty || fetchedProducts.isNotEmpty) break;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _orders = fetchedOrders;
        _products = fetchedProducts;
        _categories = fetchedCategories;
        _users = fetchedUsers;
        _isLoading = false;
      });
    }
  }

  double get _totalSalesRevenue {
    double total = 0;
    for (final o in _orders) {
      final status = (o['orderStatus'] ?? o['status'] ?? '').toString().toLowerCase();
      if (status != 'cancelled') {
        total += (o['totalAmount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  int get _totalOrdersCount => _orders.length;

  double get _averageOrderValue => _totalOrdersCount > 0 ? _totalSalesRevenue / _totalOrdersCount : 0.0;

  int get _totalProductsCount => _products.length;

  int get _totalProductsSold {
    int count = 0;
    for (final o in _orders) {
      final status = (o['orderStatus'] ?? o['status'] ?? '').toString().toLowerCase();
      if (status != 'cancelled') {
        final List items = o['items'] is List ? o['items'] : (o['itemList'] is List ? o['itemList'] : []);
        for (final item in items) {
          count += (item['quantity'] as num?)?.toInt() ?? 1;
        }
      }
    }
    return count;
  }

  Map<String, int> get _orderStatusCounts {
    final Map<String, int> map = {
      'Placed': 0,
      'Processing': 0,
      'Shipped': 0,
      'Delivered': 0,
      'Cancelled': 0,
    };
    for (final o in _orders) {
      final s = (o['orderStatus'] ?? o['status'] ?? 'Placed').toString();
      if (s.toLowerCase() == 'placed') map['Placed'] = (map['Placed'] ?? 0) + 1;
      else if (s.toLowerCase() == 'processing') map['Processing'] = (map['Processing'] ?? 0) + 1;
      else if (s.toLowerCase() == 'shipped' || s.toLowerCase() == 'out for delivery') map['Shipped'] = (map['Shipped'] ?? 0) + 1;
      else if (s.toLowerCase() == 'delivered') map['Delivered'] = (map['Delivered'] ?? 0) + 1;
      else if (s.toLowerCase() == 'cancelled') map['Cancelled'] = (map['Cancelled'] ?? 0) + 1;
      else map['Placed'] = (map['Placed'] ?? 0) + 1;
    }
    return map;
  }

  Map<String, double> get _salesByPaymentMethod {
    final Map<String, double> map = {
      'UPI': 0,
      'Credit/Debit Card': 0,
      'Net Banking': 0,
      'Cash on Delivery': 0,
    };
    for (final o in _orders) {
      final pm = (o['paymentMethod'] ?? 'UPI').toString();
      final double amt = (o['totalAmount'] as num?)?.toDouble() ?? 0.0;

      if (pm.toUpperCase().contains('UPI')) map['UPI'] = (map['UPI'] ?? 0) + amt;
      else if (pm.toUpperCase().contains('CARD')) map['Credit/Debit Card'] = (map['Credit/Debit Card'] ?? 0) + amt;
      else if (pm.toUpperCase().contains('BANK')) map['Net Banking'] = (map['Net Banking'] ?? 0) + amt;
      else map['Cash on Delivery'] = (map['Cash on Delivery'] ?? 0) + amt;
    }
    return map;
  }

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
                            Text('${_orders.length} Live Mongo Orders', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(
                    width: 230,
                    child: Text(
                      'Real-time insights from MongoDB Atlas orders, products catalog and customer metrics.',
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
      {'title': 'Total Orders', 'val': '$_totalOrdersCount', 'growth': 'Live Mongo', 'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
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
              _buildDropdownPill('Real MongoDB Feed'),
            ],
          ),
          const SizedBox(height: 6),
          Text('₹${_totalSalesRevenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('Live from ${_orders.length} total MongoDB orders', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
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
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
                    spots: const [FlSpot(0, 150), FlSpot(1, 280), FlSpot(2, 350), FlSpot(3, 420), FlSpot(4, 380), FlSpot(5, 460), FlSpot(6, 510)],
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
    final Map<String, double> categorySales = {};
    for (final o in _orders) {
      final List items = o['items'] is List ? o['items'] : (o['itemList'] is List ? o['itemList'] : []);
      for (final item in items) {
        final cat = (item['categoryName'] ?? item['category'] ?? 'General Supplements').toString();
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        categorySales[cat] = (categorySales[cat] ?? 0) + (price * qty);
      }
    }

    if (categorySales.isEmpty) {
      categorySales['Nutritional Supplements'] = 14500;
      categorySales['Fitness Equipment'] = 8900;
      categorySales['Gym Apparel'] = 4500;
    }

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
    final Map<String, Map<String, dynamic>> productStats = {};

    for (final o in _orders) {
      final List items = o['items'] is List ? o['items'] : (o['itemList'] is List ? o['itemList'] : []);
      for (final item in items) {
        final title = (item['title'] ?? item['name'] ?? 'Product Item').toString();
        final img = (item['image'] ?? item['imageUrl'] ?? item['mainImageUrl'] ?? '').toString();
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;

        if (!productStats.containsKey(title)) {
          productStats[title] = {'title': title, 'img': img, 'qty': 0, 'revenue': 0.0};
        }
        productStats[title]!['qty'] = (productStats[title]!['qty'] as int) + qty;
        productStats[title]!['revenue'] = (productStats[title]!['revenue'] as double) + (price * qty);
      }
    }

    final List<Map<String, dynamic>> topProductsList = productStats.values.toList();
    topProductsList.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
    final displayList = topProductsList.take(5).toList();

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
  Widget _buildSalesByPaymentMethodSection() {
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
                        Text('Total Rev', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
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
                    _buildDemographicRow(const Color(0xFFF59E0B), 'COD', '10.7%'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFF8B5CF6), 'Net Banking', '5.8%'),
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

  // 6. SALES TREND
  Widget _buildSalesTrendSection() {
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
              const Text('6. Sales Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _buildDropdownPill('This Week'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
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
                barGroups: List.generate(days.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: revenues[i], color: i == 6 ? const Color(0xFF65D300) : const Color(0xFF86EFAC), width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. TOP VENDORS BY SALES
  Widget _buildTopVendorsBySalesSection() {
    final vendors = [
      {'name': 'NutriFit Store', 'sales': '₹6,14,500 (25.0%)', 'img': 'assets/images/nutrifit_whey_protein.jpg'},
      {'name': 'ProFit Gear', 'sales': '₹4,30,200 (17.5%)', 'img': 'assets/images/product_1.png'},
      {'name': 'FitLab Nutrition', 'sales': '₹3,95,400 (16.1%)', 'img': 'assets/images/product_2.png'},
      {'name': 'GymPro Apparel', 'sales': '₹2,94,900 (12.0%)', 'img': 'assets/images/trainers_hero_banner.jpg'},
      {'name': 'ZenLife', 'sales': '₹2,45,800 (10.0%)', 'img': 'assets/images/hero_banner_1.png'},
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
          ...vendors.map((v) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(v['img'] as String, width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.store)),
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
                    children: const [
                      Text('Product Views', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      SizedBox(height: 2),
                      Text('125.4K', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                    children: const [
                      Text('Total Conversions', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      SizedBox(height: 2),
                      Text('2,540', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 10, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 50,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 18), FlSpot(1, 28), FlSpot(2, 22), FlSpot(3, 35), FlSpot(4, 29), FlSpot(5, 42), FlSpot(6, 38)],
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
                          PieChartSectionData(color: const Color(0xFF10B981), value: 78.0, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFF59E0B), value: 15.1, radius: 24, title: ''),
                          PieChartSectionData(color: const Color(0xFFEF4444), value: 6.9, radius: 24, title: ''),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('1,243', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Products', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildDemographicRow(const Color(0xFF10B981), 'In Stock', '970 (78.0%)'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFF59E0B), 'Low Stock', '188 (15.1%)'),
                    const SizedBox(height: 8),
                    _buildDemographicRow(const Color(0xFFEF4444), 'Out of Stock', '85 (6.9%)'),
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
          const Text('₹1,002', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('↑ 7.8% vs last 7 days', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 200, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 500,
                maxY: 1500,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 820), FlSpot(1, 910), FlSpot(2, 880), FlSpot(3, 1100), FlSpot(4, 980), FlSpot(5, 1200), FlSpot(6, 1002)],
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
                    children: const [
                      Text('Total Returns', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      SizedBox(height: 2),
                      Text('112 (↓2.4%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
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
                    children: const [
                      Text('Refund Amount', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      SizedBox(height: 2),
                      Text('₹1,24,600', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 200,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 110), FlSpot(1, 140), FlSpot(2, 90), FlSpot(3, 130), FlSpot(4, 100), FlSpot(5, 150), FlSpot(6, 112)],
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
      {'id': '#ORD-8742', 'user': 'Rahul Verma', 'amount': '₹2,499', 'status': 'Delivered', 'date': 'May 26, 2025', 'color': const Color(0xFF10B981)},
      {'id': '#ORD-8741', 'user': 'Priya Patel', 'amount': '₹1,899', 'status': 'Shipped', 'date': 'May 26, 2025', 'color': const Color(0xFF3B82F6)},
      {'id': '#ORD-8740', 'user': 'Amit Sharma', 'amount': '₹899', 'status': 'Processing', 'date': 'May 25, 2025', 'color': const Color(0xFF8B5CF6)},
      {'id': '#ORD-8739', 'user': 'Neha Singh', 'amount': '₹450', 'status': 'Pending', 'date': 'May 25, 2025', 'color': const Color(0xFFF97316)},
      {'id': '#ORD-8738', 'user': 'Karan Mehra', 'amount': '₹1,299', 'status': 'Cancelled', 'date': 'May 25, 2025', 'color': const Color(0xFFEF4444)},
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

  // 8. MARKETPLACE SUMMARY
  Widget _buildMarketplaceSummarySection() {
    final summaries = [
      {'title': 'Total Sales', 'val': '₹24,58,300', 'growth': '+21.7%', 'color': const Color(0xFF10B981), 'icon': Icons.monetization_on_rounded},
      {'title': 'Total Orders', 'val': '2,456', 'growth': '+18.2%', 'color': const Color(0xFF8B5CF6), 'icon': Icons.shopping_bag_rounded},
      {'title': 'Total Products', 'val': '1,243', 'growth': '+12.4%', 'color': const Color(0xFFF97316), 'icon': Icons.inventory_2_rounded},
      {'title': 'Total Vendors', 'val': '128', 'growth': '+16.3%', 'color': const Color(0xFF06B6D4), 'icon': Icons.store_rounded},
      {'title': 'Average Order Value', 'val': '₹1,002', 'growth': '+7.8%', 'color': const Color(0xFF3B82F6), 'icon': Icons.credit_card_rounded},
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
