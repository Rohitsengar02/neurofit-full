import 'package:flutter/material.dart';

class MarketplaceOrdersView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const MarketplaceOrdersView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<MarketplaceOrdersView> createState() => _MarketplaceOrdersViewState();
}

class _MarketplaceOrdersViewState extends State<MarketplaceOrdersView> {
  final List<Map<String, dynamic>> _ordersList = [
    {
      'id': 'ORD-98421',
      'customer': 'Rahul Verma',
      'phone': '+91 98765 43210',
      'address': 'Flat 204, Green Heights, Andheri West, Mumbai',
      'itemsSummary': '100% Whey Protein Isolate (2kg)',
      'total': '₹4,499',
      'date': 'Today, 2:15 PM',
      'status': 'Processing',
      'statusColor': const Color(0xFFF59E0B),
      'statusBg': const Color(0xFFFFFBEB),
      'carrier': 'BlueDart Express (#BD-982149)',
      'items': [
        {'name': '100% Whey Protein Isolate (2kg)', 'qty': '1x', 'price': '₹4,499', 'sku': 'NUTRI-WHEY-01', 'img': 'assets/images/workout_banner_1.png'},
      ],
    },
    {
      'id': 'ORD-98420',
      'customer': 'Priya Patel',
      'phone': '+91 91234 56789',
      'address': 'Villa 12, Palm Meadows, Whitefield, Bangalore',
      'itemsSummary': 'Hexagon Rubber Dumbbells Pair (15kg)',
      'total': '₹3,299',
      'date': 'Today, 10:45 AM',
      'status': 'Shipped',
      'statusColor': const Color(0xFF3B82F6),
      'statusBg': const Color(0xFFEFF6FF),
      'carrier': 'DTDC Cargo (#DT-894210)',
      'items': [
        {'name': 'Hexagon Rubber Dumbbells (15kg)', 'qty': '1x Pair', 'price': '₹3,299', 'sku': 'GEAR-DB-15KG', 'img': 'assets/images/athlete_transform_1787825621309.jpg'},
      ],
    },
    {
      'id': 'ORD-98419',
      'customer': 'Dr. Vikram Seth',
      'phone': '+91 99112 23344',
      'address': 'Plot 45, Bandra West, Mumbai',
      'itemsSummary': 'Creatine Monohydrate 300g + Gym T-Shirt',
      'total': '₹2,298',
      'date': 'Yesterday, 6:30 PM',
      'status': 'Delivered',
      'statusColor': const Color(0xFF10B981),
      'statusBg': const Color(0xFFECFDF5),
      'carrier': 'Delhivery (#DL-782190)',
      'items': [
        {'name': 'Creatine Monohydrate (300g)', 'qty': '1x', 'price': '₹999', 'sku': 'NUTRI-CREATINE-02', 'img': 'assets/images/hero_banner_4.png'},
        {'name': 'Seamless Dry-Fit Gym T-Shirt', 'qty': '1x', 'price': '₹1,299', 'sku': 'APP-TEE-DRY', 'img': 'assets/images/hero_banner_1.png'},
      ],
    },
  ];

  void _showOrderDetailModal(Map<String, dynamic> o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _OrderDetailBottomSheet(order: o),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Marketplace Orders Feed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            Text('Export CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
          ],
        ),
        const SizedBox(height: 12),
        ..._ordersList.map((o) {
          final items = (o['items'] as List<dynamic>?) ?? [];
          final firstItem = items.isNotEmpty ? items[0] : null;

          return GestureDetector(
            onTap: () => _showOrderDetailModal(o),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(o['id'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: o['statusBg'] as Color, borderRadius: BorderRadius.circular(6)),
                        child: Text(o['status'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: o['statusColor'] as Color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (firstItem != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(firstItem['img'] as String, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag)),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o['itemsSummary'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('👤 Customer: ${o['customer']} • ${o['date']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16, thickness: 0.7, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Total: ${o['total']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                      const Text('View Tracking & Items →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6))),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// Order Detail Bottom Sheet
class _OrderDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderDetailBottomSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final o = order;
    final items = (o['items'] as List<dynamic>?) ?? [];

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ID: ${o['id']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('Placed on ${o['date']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18)),
              ],
            ),
          ),
          const Divider(height: 18, thickness: 0.8, color: Color(0xFFF1F5F9)),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const Text('Purchased Items & Thumbnails', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                ...items.map((it) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(it['img'] as String, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it['name'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            Text('SKU: ${it['sku']} • Qty: ${it['qty']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Text(it['price'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                    ],
                  ),
                )),
                const SizedBox(height: 12),

                const Text('Delivery & Shipping Details', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    children: [
                      _buildDetailRow('Customer Name', o['customer'] as String),
                      _buildDetailRow('Contact Phone', o['phone'] as String),
                      _buildDetailRow('Shipping Address', o['address'] as String),
                      _buildDetailRow('Shipping Carrier', o['carrier'] as String),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Update Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Print Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          Expanded(child: Text(val, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)))),
        ],
      ),
    );
  }
}
