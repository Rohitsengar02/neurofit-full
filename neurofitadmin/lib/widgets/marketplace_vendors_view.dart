import 'package:flutter/material.dart';

// =============================================================
// 1. MARKETPLACE VENDORS VIEW WITH BEAUTIFUL CARDS & 4-TAB SLIDER
// =============================================================
class MarketplaceVendorsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const MarketplaceVendorsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<MarketplaceVendorsView> createState() => _MarketplaceVendorsViewState();
}

class _MarketplaceVendorsViewState extends State<MarketplaceVendorsView> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _vendorsList = [
    {
      'id': 'VEN-101',
      'name': 'NutriFit Official Partner',
      'category': 'Supplements & Nutrition',
      'tier': '⭐ Top Brand',
      'tierColor': const Color(0xFF10B981),
      'tierBg': const Color(0xFFECFDF5),
      'rating': '4.95 ★',
      'reviews': '1.4K reviews',
      'skusCount': 184,
      'grossSales': '₹14.20L',
      'commission': '12% Fee',
      'commissionEarned': '₹1,70,400',
      'ordersFulfilled': '3,840 Orders',
      'refundRate': '0.6%',
      'avgFulfillmentTime': '1.2 Days',
      'contactPerson': 'Sunil Mehta (Head)',
      'email': 'sunil.mehta@nutrifit.com',
      'phone': '+91 98234 56789',
      'status': 'Verified',
      'statusColor': const Color(0xFF10B981),
      'img': 'assets/images/workout_banner_1.png',
      'topProducts': [
        {'name': '100% Whey Protein Isolate (2kg)', 'sales': '1.8K Sold', 'price': '₹4,499', 'stock': '142 in stock', 'img': 'assets/images/workout_banner_1.png'},
        {'name': 'Micronized Creatine Monohydrate (300g)', 'sales': '3.1K Sold', 'price': '₹999', 'stock': '85 in stock', 'img': 'assets/images/hero_banner_4.png'},
      ],
    },
    {
      'id': 'VEN-102',
      'name': 'IronGrip Equipment Hub',
      'category': 'Weights & Benches',
      'tier': '👑 VIP Supplier',
      'tierColor': const Color(0xFFF59E0B),
      'tierBg': const Color(0xFFFFFBEB),
      'rating': '4.88 ★',
      'reviews': '890 reviews',
      'skusCount': 96,
      'grossSales': '₹8.90L',
      'commission': '15% Fee',
      'commissionEarned': '₹1,33,500',
      'ordersFulfilled': '1,120 Orders',
      'refundRate': '0.9%',
      'avgFulfillmentTime': '2.1 Days',
      'contactPerson': 'Rajesh Singhania',
      'email': 'support@irongrip.in',
      'phone': '+91 91234 78901',
      'status': 'Verified',
      'statusColor': const Color(0xFF10B981),
      'img': 'assets/images/athlete_transform_1787825621309.jpg',
      'topProducts': [
        {'name': 'Hexagon Rubber Dumbbells (15kg)', 'sales': '640 Sold', 'price': '₹3,299', 'stock': '48 in stock', 'img': 'assets/images/athlete_transform_1787825621309.jpg'},
      ],
    },
    {
      'id': 'VEN-103',
      'name': 'NeuroFit Apparel Store',
      'category': 'Activewear & Gear',
      'tier': '⚡ Official Store',
      'tierColor': const Color(0xFF8B5CF6),
      'tierBg': const Color(0xFFF5F3FF),
      'rating': '4.92 ★',
      'reviews': '1.1K reviews',
      'skusCount': 142,
      'grossSales': '₹6.40L',
      'commission': '10% Fee',
      'commissionEarned': '₹64,000',
      'ordersFulfilled': '2,490 Orders',
      'refundRate': '1.1%',
      'avgFulfillmentTime': '1.0 Days',
      'contactPerson': 'Ananya Roy',
      'email': 'merch@neurofit.app',
      'phone': '+91 87654 32109',
      'status': 'Verified',
      'statusColor': const Color(0xFF10B981),
      'img': 'assets/images/hero_banner_1.png',
      'topProducts': [
        {'name': 'Seamless Dry-Fit Gym T-Shirt', 'sales': '2.4K Sold', 'price': '₹1,299', 'stock': '210 in stock', 'img': 'assets/images/hero_banner_1.png'},
      ],
    },
  ];

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

  void _showVendorDetailModal(Map<String, dynamic> v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _VendorDetailBottomSheet(vendor: v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _vendorsList.where((v) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (v['name'] as String).toLowerCase().contains(q) ||
          (v['category'] as String).toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedSection(0, _buildKpiCarousel()),
        const SizedBox(height: 16),
        _buildAnimatedSection(1, _buildSearchBar()),
        const SizedBox(height: 16),
        _buildAnimatedSection(2, _buildVendorsList(filtered)),
      ],
    );
  }

  Widget _buildKpiCarousel() {
    final kpis = [
      {'title': 'Active Vendors', 'val': '14 Stores', 'growth': '+2 Onboarded', 'icon': Icons.store_mall_directory_rounded, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Total Vendor GMV', 'val': '₹29.5 Lakhs', 'growth': '+21.4% growth', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'title': 'Platform Fees', 'val': '₹3.67 Lakhs', 'growth': '12.4% avg cut', 'icon': Icons.monetization_on_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Vendor Rating', 'val': '4.91 ★', 'growth': '99.2% SLA met', 'icon': Icons.star_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: kpis.map((k) {
          final Color color = k['color'] as Color;
          return Container(
            width: 140,
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
                  children: [
                    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: k['bg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(k['icon'] as IconData, color: color, size: 14)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(k['title'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(k['val'] as String, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(k['growth'] as String, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
              decoration: const InputDecoration(hintText: 'Search vendors, brands, categories...', border: InputBorder.none, isDense: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorsList(List<Map<String, dynamic>> list) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final v = list[i];
        return GestureDetector(
          onTap: () => _showVendorDetailModal(v),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with Brand Image
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          v['img'] as String,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(width: 48, height: 48, color: const Color(0xFFECFDF5), child: const Icon(Icons.store, color: Color(0xFF16A34A))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    v['name'] as String,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(v['category'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: v['tierBg'] as Color, borderRadius: BorderRadius.circular(8)),
                        child: Text(v['tier'] as String, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: v['tierColor'] as Color)),
                      ),
                    ],
                  ),
                ),

                // 3-Metric Performance Bar (Clean & No Overflow)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      children: [
                        Expanded(child: _buildInlineMetric('Catalog SKUs', '${v['skusCount']} Items', const Color(0xFF3B82F6))),
                        _buildInlineDivider(),
                        Expanded(child: _buildInlineMetric('Gross Sales', v['grossSales'] as String, const Color(0xFF10B981))),
                        _buildInlineDivider(),
                        Expanded(child: _buildInlineMetric('Platform Fee', v['commission'] as String, const Color(0xFFF59E0B))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Bottom Action Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rating: ${v['rating']} (${v['reviews']})', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
                      const Text('View Store Profile →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInlineMetric(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color))),
        Text(label, style: const TextStyle(fontSize: 7.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildInlineDivider() {
    return Container(width: 1, height: 22, color: Colors.grey.shade300);
  }
}

// 4-Tab Vendor Detail Sheet
class _VendorDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> vendor;
  const _VendorDetailBottomSheet({required this.vendor});

  @override
  State<_VendorDetailBottomSheet> createState() => _VendorDetailBottomSheetState();
}

class _VendorDetailBottomSheetState extends State<_VendorDetailBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final topProducts = (v['topProducts'] as List<dynamic>?) ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(v['img'] as String, width: 52, height: 52, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.store, size: 30)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v['name'] as String, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Text(v['category'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      Text('Contact: ${v['contactPerson']}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TabBar(
            controller: _tabCtrl,
            labelColor: const Color(0xFF0F172A),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF16A34A),
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            tabs: const [
              Tab(text: 'Financials & GMV'),
              Tab(text: 'Catalog SKUs'),
              Tab(text: 'Fulfillment & SLA'),
            ],
          ),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatBox('Gross GMV', v['grossSales'] as String, const Color(0xFF10B981)),
                        _buildStatBox('Platform Cut', v['commissionEarned'] as String, const Color(0xFFF59E0B)),
                        _buildStatBox('Orders', v['ordersFulfilled'] as String, const Color(0xFF8B5CF6)),
                        _buildStatBox('Refund Rate', v['refundRate'] as String, const Color(0xFF3B82F6)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          _buildDetailRow('Settlement Cycle', 'Weekly Direct Bank Wire'),
                          _buildDetailRow('Platform Commission', v['commission'] as String),
                          _buildDetailRow('GSTIN Tax ID', '27AABCN8921M1Z4'),
                        ],
                      ),
                    ),
                  ],
                ),

                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: topProducts.length,
                  itemBuilder: (ctx, i) {
                    final p = topProducts[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(p['img'] as String, width: 42, height: 42, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                Text('${p['sales']} • ${p['stock']}', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Text(p['price'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                        ],
                      ),
                    );
                  },
                ),

                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          _buildDetailRow('Avg Fulfillment Time', v['avgFulfillmentTime'] as String),
                          _buildDetailRow('Customer Refund Rate', v['refundRate'] as String),
                          _buildDetailRow('On-Time Delivery SLA', '99.4% SLA Score'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String val, Color color) {
    return Container(
      width: 74,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

// =============================================================
// 2. MARKETPLACE CUSTOMERS VIEW WITH BEAUTIFUL CARDS & 4-TAB SLIDER
// =============================================================
class MarketplaceCustomersView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const MarketplaceCustomersView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<MarketplaceCustomersView> createState() => _MarketplaceCustomersViewState();
}

class _MarketplaceCustomersViewState extends State<MarketplaceCustomersView> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _customersList = [
    {
      'id': 'CUST-801',
      'name': 'Dr. Vikram Seth',
      'tier': '👑 VIP Platinum',
      'tierColor': const Color(0xFFF59E0B),
      'tierBg': const Color(0xFFFFFBEB),
      'email': 'vikram.seth@gmail.com',
      'phone': '+91 99112 23344',
      'city': 'Mumbai, MH',
      'totalSpend': '₹38,400',
      'ordersCount': 18,
      'rewardPoints': '2,450 Pts',
      'coach': 'Coach Amit Sharma',
      'diet': '21-Day High-Protein Shred',
      'latestOrder': 'Whey Protein Isolate (2kg)',
      'avatar': 'assets/images/trainers_hero_banner.jpg',
      'recentOrders': [
        {'id': 'ORD-98421', 'item': 'Whey Protein Isolate (2kg)', 'total': '₹4,499', 'status': 'Delivered', 'img': 'assets/images/workout_banner_1.png'},
        {'id': 'ORD-98112', 'item': 'Creatine Monohydrate 300g', 'total': '₹999', 'status': 'Delivered', 'img': 'assets/images/hero_banner_4.png'},
      ],
    },
    {
      'id': 'CUST-802',
      'name': 'Rhea Singhania',
      'tier': '⭐ Gold Member',
      'tierColor': const Color(0xFF8B5CF6),
      'tierBg': const Color(0xFFF5F3FF),
      'email': 'rhea.s@gmail.com',
      'phone': '+91 98223 34455',
      'city': 'Bangalore, KA',
      'totalSpend': '₹29,800',
      'ordersCount': 14,
      'rewardPoints': '1,890 Pts',
      'coach': 'Coach Priya Patel',
      'diet': 'Keto Fat Burn Protocol',
      'latestOrder': 'Seamless Gym Top & Bands',
      'avatar': 'assets/images/athlete_transform_1787825621309.jpg',
      'recentOrders': [
        {'id': 'ORD-98210', 'item': 'Seamless Gym Top', 'total': '₹1,299', 'status': 'Delivered', 'img': 'assets/images/hero_banner_1.png'},
      ],
    },
    {
      'id': 'CUST-803',
      'name': 'Rahul Verma',
      'tier': '🥈 Silver Member',
      'tierColor': const Color(0xFF3B82F6),
      'tierBg': const Color(0xFFEFF6FF),
      'email': 'rahul.v@gmail.com',
      'phone': '+91 99887 76655',
      'city': 'Delhi NCR',
      'totalSpend': '₹14,200',
      'ordersCount': 9,
      'rewardPoints': '940 Pts',
      'coach': 'Coach Rahul Verma',
      'diet': 'Clean Hypertrophy 3000 kcal',
      'latestOrder': 'Pre-Workout & Shaker',
      'avatar': 'assets/images/hero_banner_4.png',
      'recentOrders': [
        {'id': 'ORD-98012', 'item': 'Pre-Workout Energy', 'total': '₹1,899', 'status': 'Delivered', 'img': 'assets/images/workout_banner_1.png'},
      ],
    },
  ];

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

  void _showCustomerDetailModal(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _CustomerDetailBottomSheet(customer: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _customersList.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (c['name'] as String).toLowerCase().contains(q) ||
          (c['city'] as String).toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedSection(0, _buildKpiCarousel()),
        const SizedBox(height: 16),
        _buildAnimatedSection(1, _buildCustomersList(filtered)),
      ],
    );
  }

  Widget _buildKpiCarousel() {
    final kpis = [
      {'title': 'Total Shoppers', 'val': '8,420 Users', 'growth': '+18.4% active', 'icon': Icons.people_alt_rounded, 'color': const Color(0xFF6366F1), 'bg': const Color(0xFFEEF2FF)},
      {'title': 'VIP Shoppers', 'val': '1,240 VIPs', 'growth': 'Top 15% spenders', 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Avg Spend / User', 'val': '₹4,850', 'growth': '+12.8% LTV', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Repeat Rate', 'val': '64.2%', 'growth': 'High retention', 'icon': Icons.repeat_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: kpis.map((k) {
          final Color color = k['color'] as Color;
          return Container(
            width: 140,
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
                  children: [
                    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: k['bg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(k['icon'] as IconData, color: color, size: 14)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(k['title'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(k['val'] as String, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(k['growth'] as String, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomersList(List<Map<String, dynamic>> list) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final c = list[i];
        return GestureDetector(
          onTap: () => _showCustomerDetailModal(c),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 22, backgroundImage: AssetImage(c['avatar'] as String)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name'] as String, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(c['city'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: c['tierBg'] as Color, borderRadius: BorderRadius.circular(8)),
                        child: Text(c['tier'] as String, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: c['tierColor'] as Color)),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      children: [
                        Expanded(child: _buildInlineMetric('Orders', '${c['ordersCount']}', const Color(0xFF3B82F6))),
                        _buildInlineDivider(),
                        Expanded(child: _buildInlineMetric('Spend', c['totalSpend'] as String, const Color(0xFF10B981))),
                        _buildInlineDivider(),
                        Expanded(child: _buildInlineMetric('Rewards', c['rewardPoints'] as String, const Color(0xFFF59E0B))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Latest: ${c['latestOrder']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      const Text('View Profile →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInlineMetric(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color))),
        Text(label, style: const TextStyle(fontSize: 7.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildInlineDivider() {
    return Container(width: 1, height: 22, color: Colors.grey.shade300);
  }
}

// Customer Detail Sheet
class _CustomerDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> customer;
  const _CustomerDetailBottomSheet({required this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final recentOrders = (c['recentOrders'] as List<dynamic>?) ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(radius: 26, backgroundImage: AssetImage(c['avatar'] as String)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Text('${c['email']} • ${c['phone']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      Text(c['tier'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18)),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 0.8, color: Color(0xFFF1F5F9)),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBox('Total Spent', c['totalSpend'] as String, const Color(0xFF10B981)),
                    _buildStatBox('Orders', '${c['ordersCount']}', const Color(0xFF3B82F6)),
                    _buildStatBox('Rewards', c['rewardPoints'] as String, const Color(0xFF6366F1)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Recent Orders Timeline', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                ...recentOrders.map((o) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(o['img'] as String, width: 38, height: 38, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o['item'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            Text('Order ID: ${o['id']}', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Text(o['total'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String val, Color color) {
    return Container(
      width: 95,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color))),
        ],
      ),
    );
  }
}
