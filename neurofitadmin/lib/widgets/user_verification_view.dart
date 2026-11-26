import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import '../backend/live_backend.dart';
import 'net_or_asset_image.dart';

class UserVerificationView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const UserVerificationView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<UserVerificationView> createState() => _UserVerificationViewState();
}

class _UserVerificationViewState extends State<UserVerificationView> {
  int _selectedTab = 0; // 0=All, 1=Pending, 2=Approved, 3=Rejected
  String _searchQuery = '';

  AdminUsers get _src => AdminUsers.of('all');

  static Map<String, dynamic> _row(Map<String, dynamic> u) {
    final vs = '${u['verificationStatus'] ?? ''}';
    final status = u['isVerified'] == true ? 'Approved' : (vs == 'rejected' ? 'Rejected' : 'Pending Review');
    final checks = [
      '${u['name'] ?? ''}'.trim().isNotEmpty,
      '${u['email'] ?? ''}'.isNotEmpty,
      '${u['phone'] ?? ''}'.isNotEmpty && u['phone'] != 'No phone',
      '${u['photoUrl'] ?? ''}'.isNotEmpty,
      u['hasCompletedOnboarding'] == true,
    ];
    final score = checks.where((c) => c).length / checks.length * 100;
    final risk = score >= 80 ? 'Low Risk' : (score >= 50 ? 'Medium Risk' : 'High Risk');
    final riskColor = score >= 80 ? const Color(0xFF10B981) : (score >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    final phone = '${u['phone'] ?? ''}'.replaceAll(RegExp(r'[^0-9]'), '');
    final uid = '${u['uid'] ?? ''}';
    final google = u['authProvider'] == 'google';
    return {
      ...u,
      'id': '#${uid.length > 6 ? uid.substring(uid.length - 6).toUpperCase() : uid}',
      'name': u['name'],
      'role': u['role'] == 'trainer' ? 'Coach' : (u['isPremium'] == true ? 'Premium Member' : 'Member'),
      'email': u['email'],
      'submitted': '${timeAgo(u['createdAt']?.toString())} · ${shortDate(u['createdAt']?.toString())}',
      'docType': google ? 'Google account${phone.isNotEmpty ? ' + Phone' : ''}' : 'Email sign-up${phone.isNotEmpty ? ' + Phone' : ''}',
      'docIcon': google ? Icons.verified_user_rounded : Icons.badge_rounded,
      'aiScore': '${score.round()}% complete',
      'risk': risk,
      'riskColor': riskColor,
      'riskBg': riskColor.withOpacity(0.1),
      'status': status,
      'statusColor': status == 'Approved' ? const Color(0xFF10B981) : (status == 'Rejected' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
      'avatar': '${u['photoUrl'] ?? ''}',
      'avatarBg': const Color(0xFFEDE9FE),
      'idNumber': phone.length >= 4 ? 'XXXX-XXXX-${phone.substring(phone.length - 4)}' : 'No phone on file',
    };
  }

  List<Map<String, dynamic>> get _verificationList => [for (final u in _src.rows) _row(u)];

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

  Future<void> _decide(Map<String, dynamic> item, bool ok) async {
    try {
      await Api.send('PUT', '/users/${item['uid']}', ok
          ? {'isVerified': true, 'verificationStatus': 'approved', 'verifiedAt': DateTime.now().toUtc().toIso8601String()}
          : {'isVerified': false, 'verificationStatus': 'rejected', 'verifiedAt': DateTime.now().toUtc().toIso8601String()});
      await _src.load();
      AdminStats.I.load(force: true);
      _showSnackbar(ok ? '${item['name']} approved successfully!' : '${item['name']} marked as rejected / resubmit.', ok ? const Color(0xFF10B981) : const Color(0xFFEF4444));
    } catch (e) {
      _showSnackbar('Could not update: $e', const Color(0xFFEF4444));
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

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 12)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDocumentPreviewDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF06B6D4).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF06B6D4), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  Text(item['id'] as String, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.description_rounded, size: 54, color: Color(0xFF94A3B8)),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                      child: const Text('🔍 Click to Zoom', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Document: ${item['docType']}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            Text('Document ID: ${item['idNumber']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: item['riskBg'] as Color, borderRadius: BorderRadius.circular(6)),
                  child: Text('Profile: ${item['aiScore']}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: item['riskColor'] as Color)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: item['riskBg'] as Color, borderRadius: BorderRadius.circular(6)),
                  child: Text(item['risk'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: item['riskColor'] as Color)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              _decide(item, true);
            },
            child: const Text('Approve KYC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TOP KPI SUMMARY CARDS
        _buildAnimatedSection(0, _buildKpiCarousel()),
        const SizedBox(height: 16),

        // 2. SEARCH & FILTER TABS
        _buildAnimatedSection(1, _buildSearchAndFilterSection()),
        const SizedBox(height: 16),

        // 3. VERIFICATION QUEUE LIST
        _buildAnimatedSection(2, _buildVerificationList()),
      ],
    );
  }

  Widget _buildKpiCarousel() {
    final all = _verificationList;
    int c(String s) => all.where((x) => x['status'] == s).length;
    final today = DateTime.now();
    bool isToday(dynamic v) { final t = DateTime.tryParse('${v ?? ''}')?.toLocal(); return t != null && t.year == today.year && t.month == today.month && t.day == today.day; }
    final todayCount = all.where((x) => x['status'] == 'Approved' && isToday(x['verifiedAt'])).length;
    final waits = [
      for (final x in all)
        if (x['verifiedAt'] != null && x['createdAt'] != null)
          DateTime.parse('${x['verifiedAt']}').difference(DateTime.parse('${x['createdAt']}')).inMinutes / 60
    ];
    final kpis = [
      {'title': 'Pending KYC', 'val': fmtInt(c('Pending Review')), 'growth': 'Requires review', 'icon': Icons.pending_actions_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Verified Today', 'val': fmtInt(todayCount), 'growth': '${fmtInt(c('Approved'))} verified in total', 'icon': Icons.verified_user_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Rejected / Resubmit', 'val': fmtInt(c('Rejected')), 'growth': 'Asked to resubmit', 'icon': Icons.gpp_bad_rounded, 'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEF2F2)},
      {'title': 'Avg Turnaround', 'val': waits.isEmpty ? '-' : '${(waits.reduce((a, b) => a + b) / waits.length).toStringAsFixed(1)} hrs', 'growth': 'Sign-up to decision', 'icon': Icons.speed_rounded, 'color': const Color(0xFF06B6D4), 'bg': const Color(0xFFECFEFF)},
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

  Widget _buildSearchAndFilterSection() {
    final all = _verificationList;
    int c(String s) => all.where((x) => x['status'] == s).length;
    final tabs = ['All (${all.length})', 'Pending (${c('Pending Review')})', 'Approved (${c('Approved')})', 'Rejected (${c('Rejected')})'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'Search KYC by applicant name, ID or email',
                    hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isSelected = _selectedTab == i;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF06B6D4) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.grey.shade200),
                    ),
                    child: Text(
                      tabs[i],
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
      ],
    );
  }

  Widget _buildVerificationList() {
    final filtered = _verificationList.where((it) {
      if (_selectedTab == 1 && !it['status'].toString().contains('Pending')) return false;
      if (_selectedTab == 2 && !it['status'].toString().contains('Approved')) return false;
      if (_selectedTab == 3 && !it['status'].toString().contains('Rejected')) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (it['name'] as String).toLowerCase().contains(q) ||
          (it['id'] as String).toLowerCase().contains(q) ||
          (it['email'] as String).toLowerCase().contains(q);
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final item = filtered[i];
        final isPending = item['status'] == 'Pending Review';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Profile row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: item['avatarBg'] as Color, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: NetOrAssetImage(item['avatar'] as String, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(item['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            const SizedBox(width: 4),
                            Text(item['id'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                          ],
                        ),
                        Text(item['role'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF06B6D4))),
                        Text(item['email'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (item['statusColor'] as Color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['status'] as String,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: item['statusColor'] as Color),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16, thickness: 0.7, color: Color(0xFFF1F5F9)),

              // Document & AI Score Info
              Row(
                children: [
                  Icon(item['docIcon'] as IconData, size: 14, color: const Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item['docType'] as String,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: item['riskBg'] as Color, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      'AI: ${item['aiScore']} • ${item['risk']}',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: item['riskColor'] as Color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showDocumentPreviewDialog(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF475569)),
                            SizedBox(width: 4),
                            Text('View Documents', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isPending) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _decide(item, true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Approve', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        _decide(item, false);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                        child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
