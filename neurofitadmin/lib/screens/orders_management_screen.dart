import 'package:flutter/material.dart';

class OrdersManagementScreen extends StatelessWidget {
  const OrdersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {'id': '#ORD-12543', 'user': 'Rohit Verma', 'amount': '₹2,499', 'item': 'Hydro Pure Whey Isolate 2kg', 'status': 'Processing', 'color': Colors.purple},
      {'id': '#ORD-12542', 'user': 'Sneha Kapoor', 'amount': '₹1,899', 'item': '2x Creatine Monohydrate 250g', 'status': 'Shipped', 'color': Colors.blue},
      {'id': '#ORD-12541', 'user': 'Arjun Singh', 'amount': '₹3,398', 'item': 'Pre Workout Igniter Extreme', 'status': 'Confirmed', 'color': Colors.amber},
      {'id': '#ORD-12540', 'user': 'Ananya Desai', 'amount': '₹899', 'item': 'Shaker Bottle + Omega 3', 'status': 'Pending', 'color': Colors.orange},
      {'id': '#ORD-12539', 'user': 'Karan Mehta', 'amount': '₹2,199', 'item': 'Yoga Mat Elite Pro', 'status': 'Delivered', 'color': Colors.green},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text('Orders & Fulfillment', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order summary bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Orders', '1,243'),
                Container(width: 1, height: 32, color: Colors.white24),
                _buildStatItem('Dispatched', '1,066'),
                Container(width: 1, height: 32, color: Colors.white24),
                _buildStatItem('Pending', '177'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...orders.map((ord) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ord['id'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (ord['color'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ord['status'] as String,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ord['color'] as Color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(ord['item'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Customer: ${ord['user']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    Text(ord['amount'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF10B981))),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}
