import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import '../backend/live_backend.dart';

class SubscribersDirectoryView extends StatefulWidget {
  final String selectedDateRange;
  final String filterMode; // 'all', 'active', 'deactivated', 'vip'
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const SubscribersDirectoryView({
    super.key,
    required this.selectedDateRange,
    this.filterMode = 'all',
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<SubscribersDirectoryView> createState() => _SubscribersDirectoryViewState();
}

class _SubscribersDirectoryViewState extends State<SubscribersDirectoryView> {
  String _searchQuery = '';

  final AdminList _src = AdminList.of('/admin/subscriptions');

  static Map<String, dynamic> _row(Map<String, dynamic> x) {
    final months = (x['months'] as num? ?? 1).toInt();
    final active = x['active'] == true;
    final expired = !active && x['status'] == 'active';
    final status = active ? 'Active' : (expired ? 'Expired' : 'Deactivated');
    final color = active ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final amount = x['amount'] as num? ?? 0;
    final pay = '${x['paymentStatus'] ?? 'pending'}';
    final id = '${x['id']}';
    return {
      ...x,
      'subId': id,
      'id': id.length > 8 ? 'SUB-${id.substring(id.length - 6).toUpperCase()}' : id,
      'name': '${x['userName']}',
      'email': '${x['email']}',
      'phone': '${x['phone']}'.isEmpty ? 'No phone' : '${x['phone']}',
      'plan': '${x['planName'] ?? 'Coaching'} with ${x['trainerName'] ?? 'coach'}',
      'planTier': months >= 12 ? '👑 VIP ANNUAL' : (months >= 3 ? '⭐ QUARTERLY' : 'MONTHLY'),
      'planColor': months >= 12 ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
      'billingAmount': '${fmtInr(amount)} / ${months >= 12 ? 'yr' : (months == 1 ? 'mo' : '$months mo')}',
      'status': status,
      'statusColor': color,
      'statusBg': color.withOpacity(0.1),
      'startDate': shortDate(x['since']?.toString()),
      'nextRenewal': shortDate(x['until']?.toString()),
      'paymentMethod': pay == 'paid' ? 'Paid online${x['paymentId'] != null ? ' (${x['paymentId']})' : ''}' : (pay == 'complimentary' ? 'Complimentary (added by admin)' : 'Payment pending'),
      'avatar': '${x['photo'] ?? ''}',
      'transactions': [
        {'id': id.length > 8 ? 'TXN-${id.substring(id.length - 6).toUpperCase()}' : id, 'date': shortDate(x['since']?.toString()), 'amount': fmtInr(amount), 'method': pay == 'complimentary' ? 'Admin grant' : 'Online', 'status': pay == 'paid' ? 'Success (Paid)' : (pay == 'complimentary' ? 'Complimentary' : 'Pending')},
        for (final g in (x['grants'] as List? ?? const []))
          if (g is Map) {'id': 'GRANT', 'date': shortDate(g['at']?.toString()), 'amount': '₹0', 'method': '+${g['days']} days free', 'status': 'Granted by admin'},
      ],
    };
  }

  List<Map<String, dynamic>> get _subscribersList => [for (final x in _src.items) _row(x)];

  void _changed() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    _src.addListener(_changed);
    _src.load();
  }

  @override
  void dispose() {
    _src.removeListener(_changed);
    super.dispose();
  }

  Future<void> _patch(Map<String, dynamic> s, Map<String, dynamic> body, String ok) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Api.send('PATCH', '/admin/subscriptions/${s['subId']}', body);
      await _src.load();
      messenger.showSnackBar(SnackBar(content: Text(ok), behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFF10B981)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFFEF4444)));
    }
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

  void _showSubscriberDetailModal(Map<String, dynamic> s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _SubscriberDetailBottomSheet(
        subscriber: s,
        onStatusToggle: () => _patch(s, {'status': s['status'] == 'Active' ? 'cancelled' : 'active'}, s['status'] == 'Active' ? 'Subscription deactivated' : 'Subscription activated'),
        onGrant: () => _patch(s, {'extendDays': 30}, '1 free month added for ${s['name']}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _subscribersList.where((s) {
      if (widget.filterMode == 'active' && s['status'] != 'Active') return false;
      if (widget.filterMode == 'deactivated' && !s['status'].toString().contains('Deactivated')) return false;
      if (widget.filterMode == 'vip' && !s['planTier'].toString().contains('VIP')) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (s['name'] as String).toLowerCase().contains(q) ||
          (s['plan'] as String).toLowerCase().contains(q) ||
          (s['email'] as String).toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedSection(0, _buildKpiCarousel()),
        const SizedBox(height: 16),
        _buildAnimatedSection(1, _buildSearchBar()),
        const SizedBox(height: 16),
        _buildAnimatedSection(2, _buildSubscribersList(filtered)),
      ],
    );
  }

  Widget _buildKpiCarousel() {
    final all = _subscribersList;
    final active = all.where((x) => x['status'] == 'Active').toList();
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    final newMo = all.where((x) => DateTime.tryParse('${x['since'] ?? ''}')?.isAfter(monthAgo) ?? false).length;
    final annual = active.where((x) => (x['months'] as num? ?? 1) >= 12).length;
    final paid = all.where((x) => x['paymentStatus'] == 'paid').length;
    final lapsed = all.where((x) => x['status'] != 'Active').length;
    final kpis = [
      {'title': 'Total Subscribers', 'val': '${fmtInt(active.length)} Active', 'growth': '+$newMo this mo', 'icon': Icons.people_alt_rounded, 'color': const Color(0xFF6366F1), 'bg': const Color(0xFFEEF2FF)},
      {'title': 'Annual Members', 'val': '${fmtInt(annual)} VIPs', 'growth': '${fmtPct(all.isEmpty ? 0 : active.length / all.length * 100)} retention', 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Paid Online', 'val': fmtPct(all.isEmpty ? 0 : paid / all.length * 100), 'growth': '$paid of ${all.length} plans', 'icon': Icons.autorenew_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Expired / Failed', 'val': '${fmtInt(lapsed)} Users', 'growth': 'Payment recovery', 'icon': Icons.cancel_rounded, 'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEF2F2)},
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
              decoration: const InputDecoration(hintText: 'Search subscriber by name, email, plan...', border: InputBorder.none, isDense: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribersList(List<Map<String, dynamic>> list) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final s = list[i];
        final isActive = s['status'] == 'Active';

        return GestureDetector(
          onTap: () => _showSubscriberDetailModal(s),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? Colors.grey.shade200 : Colors.red.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 22, backgroundColor: const Color(0xFFE2E8F0), backgroundImage: '${s['avatar']}'.startsWith('http') ? NetworkImage('${s['avatar']}') : null, child: '${s['avatar']}'.startsWith('http') ? null : Icon(Icons.person, size: 22, color: const Color(0xFF64748B))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    s['name'] as String,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (isActive) const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(s['plan'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: s['statusBg'] as Color, borderRadius: BorderRadius.circular(8)),
                        child: Text(s['status'] as String, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: s['statusColor'] as Color)),
                      ),
                    ],
                  ),
                ),

                // Metrics Row (Billing & Renewal)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      children: [
                        Expanded(child: _buildMetricItem('Rate', s['billingAmount'] as String, const Color(0xFF10B981))),
                        Container(width: 1, height: 20, color: Colors.grey.shade300),
                        Expanded(child: _buildMetricItem('Renewal Date', s['nextRenewal'] as String, const Color(0xFF3B82F6))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Payment: ${s['paymentMethod']}',
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Details →',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
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

  Widget _buildMetricItem(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color))),
        Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// Subscriber Details Bottom Sheet (with Transaction Slider)
class _SubscriberDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> subscriber;
  final VoidCallback onStatusToggle;
  final VoidCallback onGrant;

  const _SubscriberDetailBottomSheet({required this.subscriber, required this.onStatusToggle, required this.onGrant});

  @override
  State<_SubscriberDetailBottomSheet> createState() => _SubscriberDetailBottomSheetState();
}

class _SubscriberDetailBottomSheetState extends State<_SubscriberDetailBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subscriber;
    final txns = (s['transactions'] as List<dynamic>?) ?? [];
    final isActive = s['status'] == 'Active';

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
                CircleAvatar(radius: 26, backgroundColor: const Color(0xFFE2E8F0), backgroundImage: '${s['avatar']}'.startsWith('http') ? NetworkImage('${s['avatar']}') : null, child: '${s['avatar']}'.startsWith('http') ? null : Icon(Icons.person, size: 26, color: const Color(0xFF64748B))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Text('${s['email']} • ${s['phone']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      Text('Plan: ${s['plan']}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          TabBar(
            controller: _tabCtrl,
            labelColor: const Color(0xFF0F172A),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF8B5CF6),
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            tabs: const [
              Tab(text: 'Transactions & Invoices'),
              Tab(text: 'Plan Details & Mandate'),
            ],
          ),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Tab 1: Transactions
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: txns.length,
                  itemBuilder: (ctx, i) {
                    final t = txns[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t['id'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                Text('${t['date']} • ${t['method']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                                Text(t['status'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                              ],
                            ),
                          ),
                          Text(t['amount'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                        ],
                      ),
                    );
                  },
                ),

                // Tab 2: Plan Details
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          _buildDetailRow('Current Status', s['status'] as String),
                          _buildDetailRow('Start Date', s['startDate'] as String),
                          _buildDetailRow('Next Billing Renewal', s['nextRenewal'] as String),
                          _buildDetailRow('Recurring Amount', s['billingAmount'] as String),
                          _buildDetailRow('Payment Mandate', s['paymentMethod'] as String),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      widget.onStatusToggle();
                      Navigator.pop(context);
                    },
                    icon: Icon(isActive ? Icons.block_flipped : Icons.check_circle_rounded, size: 14, color: Colors.white),
                    label: Text(isActive ? 'Deactivate Subscription' : 'Activate Subscription', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      widget.onGrant();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.card_giftcard_rounded, size: 14, color: Colors.white),
                    label: const Text('Grant +1 Month Free', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
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
