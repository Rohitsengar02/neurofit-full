import 'package:flutter/material.dart';

class NotificationsCenterSheet extends StatefulWidget {
  const NotificationsCenterSheet({super.key});

  @override
  State<NotificationsCenterSheet> createState() => _NotificationsCenterSheetState();
}

class _NotificationsCenterSheetState extends State<NotificationsCenterSheet> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'NOTIF-1',
      'type': 'Trainer Application',
      'title': 'New Trainer Application: Coach Ryan Cooper',
      'subtitle': 'Applied for Senior Strength & Conditioning Specialist • ACE-CPT & CSCS certified (6 yrs exp)',
      'time': '10 mins ago',
      'category': 'Applications',
      'color': const Color(0xFFF59E0B),
      'icon': Icons.sports_gymnastics_rounded,
      'avatar': 'assets/images/trainers_hero_banner.jpg',
      'status': 'Pending', // 'Pending', 'Approved', 'Rejected'
      'meta': 'Applicant ID: #TR-8821 • Certifications Verified',
    },
    {
      'id': 'NOTIF-2',
      'type': 'Store Order',
      'title': 'High Volume Order: ₹12,450 Placed',
      'subtitle': 'Order #ORD-9942 by Priya Sharma • 4x NutriFit Hydro Whey & Creatine Monohydrate',
      'time': '25 mins ago',
      'category': 'Orders',
      'color': const Color(0xFF3B82F6),
      'icon': Icons.shopping_bag_rounded,
      'avatar': 'assets/images/nutrifit_whey_protein.jpg',
      'status': 'Pending', // 'Pending', 'Dispatched'
      'meta': 'Vendor: MuscleTech Direct • Express Courier',
    },
    {
      'id': 'NOTIF-3',
      'type': 'ID Verification',
      'title': 'User Verification Request: Dr. Vikram Seth',
      'subtitle': 'National Government Passport & Medical Fitness License uploaded for verification',
      'time': '1 hour ago',
      'category': 'Verifications',
      'color': const Color(0xFF10B981),
      'icon': Icons.verified_user_rounded,
      'avatar': 'assets/images/athlete_transform.jpg',
      'status': 'Pending', // 'Pending', 'Verified', 'Rescan Requested'
      'meta': 'User ID: #ATH-1092 • VIP Platinum Member',
    },
    {
      'id': 'NOTIF-4',
      'type': 'Content Moderation',
      'title': 'Reported Comment in Community Forum',
      'subtitle': 'Flagged by 3 athletes for promotional spam in "Strength & Hypertrophy" discussion thread',
      'time': '3 hours ago',
      'category': 'Reports',
      'color': const Color(0xFFEF4444),
      'icon': Icons.report_problem_rounded,
      'avatar': 'assets/images/hero_banner_2.png',
      'status': 'Pending', // 'Pending', 'Resolved', 'Dismissed'
      'meta': 'Report Ticket: #TKT-4412 • Auto-Hidden',
    },
    {
      'id': 'NOTIF-5',
      'type': 'Subscription Alert',
      'title': 'Annual Pass Renewal: Rhea Singhania',
      'subtitle': 'NeuroFit Elite Annual Pass successfully auto-debited for ₹7,999 / year',
      'time': '5 hours ago',
      'category': 'Billing',
      'color': const Color(0xFF8B5CF6),
      'icon': Icons.card_membership_rounded,
      'avatar': 'assets/images/category_yoga_model.png',
      'status': 'Completed',
      'meta': 'Auto-Pay HDFC • Invoice #INV-2025-884',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _notifications.where((n) {
      if (_selectedFilter == 'All') return true;
      return n['category'] == _selectedFilter;
    }).toList();

    final int pendingCount = _notifications.where((n) => n['status'] == 'Pending').length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),

          // Sheet Header (Guaranteed Zero Overflow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF6366F1),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Command Notifications',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$pendingCount Actionable',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Live system alerts requiring administrative approval',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    setState(() {
                      for (var n in _notifications) {
                        if (n['status'] == 'Pending') n['status'] = 'Dismissed';
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All pending notifications marked as handled.'),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                'All',
                'Applications',
                'Orders',
                'Verifications',
                'Reports',
                'Billing',
              ].map((f) {
                final isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Notifications List with Distinct Cards
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications found in this category.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return _buildNotificationCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final type = item['type'] as String;
    final color = item['color'] as Color;
    final status = item['status'] as String;
    final isPending = status == 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending ? color.withOpacity(0.3) : const Color(0xFFE2E8F0),
          width: isPending ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isPending ? 0.06 : 0.01),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Type, Time, Status Pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                item['time'] as String,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isPending ? const Color(0xFFD97706) : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Subtitle with Avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    item['avatar'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Icon(item['icon'] as IconData, color: color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF475569),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['meta'] as String,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action Buttons if Pending
          if (isPending) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            _buildActionButtonsForType(item),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtonsForType(Map<String, dynamic> item) {
    final type = item['type'] as String;

    if (type == 'Trainer Application') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () {
                setState(() => item['status'] = 'Approved ✓');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item['title']} approved successfully!'), backgroundColor: const Color(0xFF10B981)),
                );
              },
              icon: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              label: const Text('Approve Coach', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() => item['status'] = 'Rejected ✕');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Application rejected.'), backgroundColor: const Color(0xFFEF4444)),
                );
              },
              icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
              label: const Text('Decline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
            ),
          ),
        ],
      );
    }

    if (type == 'Store Order') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () {
                setState(() => item['status'] = 'Dispatched 🚚');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order marked as packed & dispatched!'), backgroundColor: Color(0xFF3B82F6)),
                );
              },
              icon: const Icon(Icons.local_shipping_rounded, size: 14, color: Colors.white),
              label: const Text('Mark Dispatched', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      );
    }

    if (type == 'ID Verification') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () {
                setState(() => item['status'] = 'Verified ✓');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User identity verified and verified badge granted!'), backgroundColor: Color(0xFF10B981)),
                );
              },
              icon: const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
              label: const Text('Verify & Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() => item['status'] = 'Rescan Requested');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Requested rescan from athlete.'), backgroundColor: Color(0xFFF59E0B)),
                );
              },
              child: const Text('Request Rescan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              setState(() => item['status'] = 'Resolved ✓');
            },
            child: const Text('Resolve Ticket', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
