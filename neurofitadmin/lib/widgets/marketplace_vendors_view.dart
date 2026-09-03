import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:neurofitadmin/constants/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/category_backend_service.dart';
import 'skeleton_loader.dart';

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
        {
          'name': '100% Whey Protein Isolate (2kg)',
          'sales': '1.8K Sold',
          'price': '₹4,499',
          'stock': '142 in stock',
          'img': 'assets/images/workout_banner_1.png',
        },
        {
          'name': 'Micronized Creatine Monohydrate (300g)',
          'sales': '3.1K Sold',
          'price': '₹999',
          'stock': '85 in stock',
          'img': 'assets/images/hero_banner_4.png',
        },
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
        {
          'name': 'Hexagon Rubber Dumbbells (15kg)',
          'sales': '640 Sold',
          'price': '₹3,299',
          'stock': '48 in stock',
          'img': 'assets/images/athlete_transform_1787825621309.jpg',
        },
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
        {
          'name': 'Seamless Dry-Fit Gym T-Shirt',
          'sales': '2.4K Sold',
          'price': '₹1,299',
          'stock': '210 in stock',
          'img': 'assets/images/hero_banner_1.png',
        },
      ],
    },
  ];

  Widget _buildAnimatedSection(int index, Widget child) {
    final int safeIndex = index < widget.fadeAnimations.length
        ? index
        : widget.fadeAnimations.length - 1;
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
      {
        'title': 'Active Vendors',
        'val': '14 Stores',
        'growth': '+2 Onboarded',
        'icon': Icons.store_mall_directory_rounded,
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFECFDF5),
      },
      {
        'title': 'Total Vendor GMV',
        'val': '₹29.5 Lakhs',
        'growth': '+21.4% growth',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'title': 'Platform Fees',
        'val': '₹3.67 Lakhs',
        'growth': '12.4% avg cut',
        'icon': Icons.monetization_on_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
      },
      {
        'title': 'Vendor Rating',
        'val': '4.91 ★',
        'growth': '99.2% SLA met',
        'icon': Icons.star_rounded,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
      },
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
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: k['bg'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        k['icon'] as IconData,
                        color: color,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        k['title'] as String,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  k['val'] as String,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  k['growth'] as String,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Search vendors, brands, categories...',
                border: InputBorder.none,
                isDense: true,
              ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
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
                          errorBuilder: (c, e, s) => Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFFECFDF5),
                            child: const Icon(
                              Icons.store,
                              color: Color(0xFF16A34A),
                            ),
                          ),
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
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: Color(0xFF10B981),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              v['category'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: v['tierBg'] as Color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          v['tier'] as String,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: v['tierColor'] as Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3-Metric Performance Bar (Clean & No Overflow)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInlineMetric(
                            'Catalog SKUs',
                            '${v['skusCount']} Items',
                            const Color(0xFF3B82F6),
                          ),
                        ),
                        _buildInlineDivider(),
                        Expanded(
                          child: _buildInlineMetric(
                            'Gross Sales',
                            v['grossSales'] as String,
                            const Color(0xFF10B981),
                          ),
                        ),
                        _buildInlineDivider(),
                        Expanded(
                          child: _buildInlineMetric(
                            'Platform Fee',
                            v['commission'] as String,
                            const Color(0xFFF59E0B),
                          ),
                        ),
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
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rating: ${v['rating']} (${v['reviews']})',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      const Text(
                        'View Store Profile →',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16A34A),
                        ),
                      ),
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            val,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 7.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
  State<_VendorDetailBottomSheet> createState() =>
      _VendorDetailBottomSheetState();
}

class _VendorDetailBottomSheetState extends State<_VendorDetailBottomSheet>
    with SingleTickerProviderStateMixin {
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    v['img'] as String,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.store, size: 30),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v['name'] as String,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        v['category'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Contact: ${v['contactPerson']}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
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
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
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
                        _buildStatBox(
                          'Gross GMV',
                          v['grossSales'] as String,
                          const Color(0xFF10B981),
                        ),
                        _buildStatBox(
                          'Platform Cut',
                          v['commissionEarned'] as String,
                          const Color(0xFFF59E0B),
                        ),
                        _buildStatBox(
                          'Orders',
                          v['ordersFulfilled'] as String,
                          const Color(0xFF8B5CF6),
                        ),
                        _buildStatBox(
                          'Refund Rate',
                          v['refundRate'] as String,
                          const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Settlement Cycle',
                            'Weekly Direct Bank Wire',
                          ),
                          _buildDetailRow(
                            'Platform Commission',
                            v['commission'] as String,
                          ),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              p['img'] as String,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.shopping_bag),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '${p['sales']} • ${p['stock']}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            p['price'] as String,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Avg Fulfillment Time',
                            v['avgFulfillmentTime'] as String,
                          ),
                          _buildDetailRow(
                            'Customer Refund Rate',
                            v['refundRate'] as String,
                          ),
                          _buildDetailRow(
                            'On-Time Delivery SLA',
                            '99.4% SLA Score',
                          ),
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            val,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// 2. MARKETPLACE CUSTOMERS VIEW (REAL MONGODB CUSTOMERS & ORDERS)
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
  State<MarketplaceCustomersView> createState() =>
      _MarketplaceCustomersViewState();
}

class _MarketplaceCustomersViewState extends State<MarketplaceCustomersView> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTierFilter = 'All';
  IO.Socket? _socket;

  final List<String> _tierFilters = [
    'All',
    'VIP Platinum 👑',
    'Gold Member ⭐',
    'Silver Member 🥈',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRealCustomers();
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
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .build(),
      );

      _socket?.connect();

      _socket?.on('user:updated', (_) => _fetchRealCustomers(silent: true));
      _socket?.on('order:created', (_) => _fetchRealCustomers(silent: true));
      _socket?.on('admin:new_order', (_) => _fetchRealCustomers(silent: true));
      _socket?.on('order:updated', (_) => _fetchRealCustomers(silent: true));
    } catch (_) {}
  }

  Future<void> _fetchRealCustomers({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    List<Map<String, dynamic>> fetchedUsers = [];
    List<Map<String, dynamic>> fetchedOrders = [];

    final candidateUsersUrls = ApiConstants.candidateBaseUrls
        .map((b) => '$b/api/users')
        .toList();
    final candidateOrdersUrls = ApiConstants.candidateBaseUrls
        .map((b) => '$b/api/orders')
        .toList();

    // 1. Fetch Users
    for (final url in candidateUsersUrls) {
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final raw = (body['data'] ?? body) as List<dynamic>? ?? [];
          fetchedUsers = raw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          break;
        }
      } catch (_) {}
    }

    // 2. Fetch Orders
    for (final url in candidateOrdersUrls) {
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final raw = (body['data'] ?? body) as List<dynamic>? ?? [];
          fetchedOrders = raw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          break;
        }
      } catch (_) {}
    }

    // 3. Map orders by User UID or Phone Number
    final Map<String, List<Map<String, dynamic>>> ordersByUid = {};
    for (final order in fetchedOrders) {
      final uid = (order['uid'] ?? order['userId'] ?? '').toString();
      final phone =
          (order['shippingAddress']?['phoneNumber'] ??
                  order['phoneNumber'] ??
                  '')
              .toString();

      final key = uid.isNotEmpty ? uid : phone;
      if (key.isNotEmpty) {
        ordersByUid.putIfAbsent(key, () => []).add(order);
      }
    }

    // 4. Merge Users and Orders into Customer Profiles
    final List<Map<String, dynamic>> customerProfiles = [];
    final Set<String> processedKeys = {};

    // Process registered users first
    for (final user in fetchedUsers) {
      final uid = (user['uid'] ?? user['_id'] ?? '').toString();
      final email = (user['email'] ?? '').toString();
      final phone = (user['phoneNumber'] ?? user['phone'] ?? '').toString();
      final name =
          (user['name'] ??
                  user['displayName'] ??
                  user['fullName'] ??
                  'Athlete Customer')
              .toString();
      final photoUrl =
          (user['photoUrl'] ?? user['avatar'] ?? user['profileImage'] ?? '')
              .toString();

      final userOrders =
          ordersByUid[uid] ??
          (phone.isNotEmpty ? (ordersByUid[phone] ?? []) : []);

      // Only show customers who bought products (ordersCount > 0)
      if (userOrders.isEmpty) continue;

      double totalSpend = 0.0;
      for (final o in userOrders) {
        totalSpend += (o['totalAmount'] as num?)?.toDouble() ?? 0.0;
      }

      String tier = 'New Athlete 🌱';
      Color tierColor = const Color(0xFF64748B);
      Color tierBg = const Color(0xFFF1F5F9);

      if (totalSpend >= 10000 || userOrders.length >= 5) {
        tier = '👑 VIP Platinum';
        tierColor = const Color(0xFFF59E0B);
        tierBg = const Color(0xFFFFFBEB);
      } else if (totalSpend >= 3000 || userOrders.length >= 2) {
        tier = '⭐ Gold Member';
        tierColor = const Color(0xFF8B5CF6);
        tierBg = const Color(0xFFF5F3FF);
      } else if (userOrders.isNotEmpty) {
        tier = '🥈 Silver Member';
        tierColor = const Color(0xFF3B82F6);
        tierBg = const Color(0xFFEFF6FF);
      }

      customerProfiles.add({
        'uid': uid,
        'name': name,
        'email': email.isNotEmpty ? email : 'No Email',
        'phone': phone.isNotEmpty ? phone : 'No Phone',
        'avatar': photoUrl,
        'city': (user['city'] ?? user['location'] ?? 'India').toString(),
        'ordersCount': userOrders.length,
        'totalSpend': totalSpend,
        'tier': tier,
        'tierColor': tierColor,
        'tierBg': tierBg,
        'orders': userOrders,
        'latestOrder': userOrders.isNotEmpty
            ? (userOrders.first['items'] is List &&
                      (userOrders.first['items'] as List).isNotEmpty
                  ? userOrders.first['items'][0]['title'] ??
                        'Order #${userOrders.first['orderId']}'
                  : 'Order #${userOrders.first['orderId']}')
            : 'No orders yet',
      });

      processedKeys.add(uid);
      if (phone.isNotEmpty) processedKeys.add(phone);
    }

    // Process guest buyers from orders
    ordersByUid.forEach((key, orders) {
      if (!processedKeys.contains(key)) {
        final firstOrder = orders.first;
        final addr = firstOrder['shippingAddress'] is Map
            ? firstOrder['shippingAddress']
            : {};
        final name =
            addr['fullName'] ??
            addr['name'] ??
            firstOrder['customerName'] ??
            'Shopper Guest';
        final phone =
            addr['phoneNumber'] ??
            addr['phone'] ??
            firstOrder['phoneNumber'] ??
            '';
        final email = addr['email'] ?? firstOrder['email'] ?? '';
        final city = addr['city'] ?? 'India';

        double totalSpend = 0.0;
        for (final o in orders) {
          totalSpend += (o['totalAmount'] as num?)?.toDouble() ?? 0.0;
        }

        customerProfiles.add({
          'uid': key,
          'name': name,
          'email': email.isNotEmpty ? email : 'Guest Order',
          'phone': phone.isNotEmpty ? phone : 'Guest Phone',
          'avatar': '',
          'city': city,
          'ordersCount': orders.length,
          'totalSpend': totalSpend,
          'tier': totalSpend > 5000 ? '⭐ Gold Member' : '🥈 Silver Member',
          'tierColor': totalSpend > 5000
              ? const Color(0xFF8B5CF6)
              : const Color(0xFF3B82F6),
          'tierBg': totalSpend > 5000
              ? const Color(0xFFF5F3FF)
              : const Color(0xFFEFF6FF),
          'orders': orders,
          'latestOrder': orders.isNotEmpty
              ? (orders.first['items'] is List &&
                        (orders.first['items'] as List).isNotEmpty
                    ? orders.first['items'][0]['title'] ??
                          'Order #${orders.first['orderId']}'
                    : 'Order #${orders.first['orderId']}')
              : 'No orders',
        });
      }
    });

    customerProfiles.sort(
      (a, b) =>
          (b['totalSpend'] as double).compareTo(a['totalSpend'] as double),
    );

    if (mounted) {
      setState(() {
        _customers = customerProfiles;
        _isLoading = false;
      });
    }
  }

  void _showCustomerDetailModal(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerDetailBottomSheet(customer: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _customers.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final email = (c['email'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString().toLowerCase();
      final city = (c['city'] ?? '').toString().toLowerCase();

      final matchesSearch =
          _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery.toLowerCase()) ||
          city.contains(_searchQuery.toLowerCase());

      final tier = (c['tier'] ?? '').toString();
      final matchesTier =
          _selectedTierFilter == 'All' ||
          tier.contains(
            _selectedTierFilter.replaceAll(RegExp(r'[^\w\s]'), '').trim(),
          );

      return matchesSearch && matchesTier;
    }).toList();

    int totalBuyers = _customers
        .where((c) => (c['ordersCount'] as int) > 0)
        .length;
    double totalRevenue = 0.0;
    for (final c in _customers) {
      totalRevenue += (c['totalSpend'] as double);
    }
    double avgSpend = _customers.isNotEmpty
        ? totalRevenue / _customers.length
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Search & Filter Bar
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people_alt_rounded,
                          color: Color(0xFF818CF8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Marketplace Customers Feed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_customers.length} Athletes • $totalBuyers Product Buyers',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => _fetchRealCustomers(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Input
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Search customer name, email, phone or city...',
                    hintStyle: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tier Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tierFilters.map((tf) {
                    final isSel = _selectedTierFilter == tf;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTierFilter = tf),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFF6366F1)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSel
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            tf,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: isSel ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // KPI Carousel
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildKpiCard(
                'Total Athletes',
                '${_customers.length}',
                'Registered users',
                Icons.people_alt_rounded,
                const Color(0xFF6366F1),
                const Color(0xFFEEF2FF),
              ),
              _buildKpiCard(
                'Product Buyers',
                '$totalBuyers',
                'Placed real orders',
                Icons.shopping_bag_rounded,
                const Color(0xFF10B981),
                const Color(0xFFDCFCE7),
              ),
              _buildKpiCard(
                'Total Revenue',
                '₹${totalRevenue.toStringAsFixed(0)}',
                'All time customer spend',
                Icons.account_balance_wallet_rounded,
                const Color(0xFFF59E0B),
                const Color(0xFFFFFBEB),
              ),
              _buildKpiCard(
                'Avg Customer Value',
                '₹${avgSpend.toStringAsFixed(0)}',
                'Per user spend',
                Icons.trending_up_rounded,
                const Color(0xFF0284C7),
                const Color(0xFFE0F2FE),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Customers List
        if (_isLoading && _customers.isEmpty)
          const SkeletonListView(count: 4)
        else if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.person_off_outlined,
                  size: 42,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(height: 10),
                Text(
                  'No Customers Found',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Registered users who purchase products will stream here in real-time.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = filtered[index];
              return _buildCustomerCard(c);
            },
          ),
      ],
    );
  }

  Widget _buildKpiCard(
    String title,
    String val,
    String sub,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> c) {
    final name = c['name'] as String;
    final email = c['email'] as String;
    final phone = c['phone'] as String;
    final city = c['city'] as String;
    final tier = c['tier'] as String;
    final tierColor = c['tierColor'] as Color;
    final tierBg = c['tierBg'] as Color;
    final ordersCount = c['ordersCount'] as int;
    final totalSpend = c['totalSpend'] as double;
    final latestOrder = c['latestOrder'] as String;
    final avatar = (c['avatar'] as String? ?? '');

    return GestureDetector(
      onTap: () => _showCustomerDetailModal(c),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: avatar.isNotEmpty
                        ? Image.network(
                            CategoryBackendService.getDisplayableImageUrl(
                              avatar,
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF64748B),
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: Color(0xFF64748B),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$email ${phone.isNotEmpty && phone != "No Phone" ? "• $phone" : ""} • $city',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tierBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tier,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: tierColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetric(
                        'Orders Placed',
                        '$ordersCount',
                        const Color(0xFF3B82F6),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      color: const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: _buildMetric(
                        'Total Spent',
                        '₹${totalSpend.toStringAsFixed(0)}',
                        const Color(0xFF10B981),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      color: const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: _buildMetric(
                        'Avg Order',
                        '₹${ordersCount > 0 ? (totalSpend / ordersCount).toStringAsFixed(0) : 0}',
                        const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Latest: $latestOrder',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Row(
                    children: [
                      Text(
                        'View Orders & Profile',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: Color(0xFF6366F1),
                      ),
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

  Widget _buildMetric(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Real Customer Detail Sheet Modal
class _CustomerDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> customer;
  const _CustomerDetailBottomSheet({required this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final String name = c['name'] ?? 'Athlete Customer';
    final String email = c['email'] ?? 'No Email';
    final String phone = c['phone'] ?? 'No Phone';
    final String uid = c['uid'] ?? 'NF-USER';
    final String tier = c['tier'] ?? 'Member';
    final Color tierColor = c['tierColor'] ?? const Color(0xFF6366F1);
    final Color tierBg = c['tierBg'] ?? const Color(0xFFEEF2FF);
    final double totalSpend = (c['totalSpend'] as num?)?.toDouble() ?? 0.0;
    final int ordersCount = (c['ordersCount'] as num?)?.toInt() ?? 0;
    final List orders = (c['orders'] is List ? c['orders'] : []);
    final String avatar = (c['avatar'] as String? ?? '');

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatar.isNotEmpty
                      ? Image.network(
                          CategoryBackendService.getDisplayableImageUrl(avatar),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: Color(0xFF64748B),
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 28,
                          color: Color(0xFF64748B),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '$email • $phone',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tierBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tier,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: tierColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Stat Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBox(
                        'Total Spend',
                        '₹${totalSpend.toStringAsFixed(0)}',
                        const Color(0xFF10B981),
                      ),
                      _buildStatBox(
                        'Orders Count',
                        '$ordersCount',
                        const Color(0xFF3B82F6),
                      ),
                      _buildStatBox(
                        'Avg Order Value',
                        '₹${ordersCount > 0 ? (totalSpend / ordersCount).toStringAsFixed(0) : 0}',
                        const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Customer Purchased Orders History Timeline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Purchased Orders History',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${orders.length} Orders',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (orders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'No orders placed yet by this athlete.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    )
                  else
                    ...orders.map((o) {
                      final orderMap = Map<String, dynamic>.from(o as Map);
                      final orderId =
                          orderMap['orderId'] ?? orderMap['id'] ?? 'NF-ORD';
                      final status =
                          orderMap['orderStatus'] ??
                          orderMap['status'] ??
                          'Placed';
                      final double amount =
                          (orderMap['totalAmount'] as num?)?.toDouble() ?? 0.0;

                      final List items = orderMap['items'] is List
                          ? orderMap['items']
                          : [];
                      final firstItem = items.isNotEmpty
                          ? Map<String, dynamic>.from(items.first as Map)
                          : null;
                      final String img = firstItem != null
                          ? (firstItem['image'] ?? firstItem['imageUrl'] ?? '')
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: img.isNotEmpty
                                  ? Image.network(
                                      CategoryBackendService.getDisplayableImageUrl(
                                        img,
                                      ),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.shopping_bag_rounded,
                                        size: 18,
                                        color: Color(0xFF64748B),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.shopping_bag_rounded,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order #$orderId',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '${items.length} Item(s) • Status: $status',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 20),

                  // Customer System Details
                  const Text(
                    'Customer Profile Info',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildRow('User UID', uid),
                        _buildRow('Primary Email', email),
                        _buildRow('Contact Phone', phone),
                        _buildRow('Location', c['city'] ?? 'India'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String val, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              val,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
