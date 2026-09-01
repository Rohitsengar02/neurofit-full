import 'package:flutter/material.dart';

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

  final List<Map<String, dynamic>> _verificationList = [
    {
      'id': '#KYC-9421',
      'name': 'Kavita Sharma',
      'role': 'Trainer Applicant (ACE Certified)',
      'email': 'kavita.sharma@gmail.com',
      'submitted': 'Today, 11:42 AM',
      'docType': 'National ID + ACE Certificate',
      'docIcon': Icons.badge_rounded,
      'aiScore': '98.4% Match',
      'risk': 'Low Risk',
      'riskColor': Color(0xFF10B981),
      'riskBg': Color(0xFFECFDF5),
      'status': 'Pending Review',
      'statusColor': Color(0xFFF59E0B),
      'avatar': 'assets/images/trainers_hero_banner.jpg',
      'avatarBg': Color(0xFFEDE9FE),
      'idNumber': 'XXXX-XXXX-8923',
    },
    {
      'name': 'Aman Singhania',
      'id': '#KYC-9420',
      'role': 'Premium VIP Member',
      'email': 'aman.s@gmail.com',
      'submitted': 'Today, 10:15 AM',
      'docType': 'Passport + Medical Fitness Clearance',
      'docIcon': Icons.medical_services_rounded,
      'aiScore': '99.1% Match',
      'risk': 'Low Risk',
      'riskColor': Color(0xFF10B981),
      'riskBg': Color(0xFFECFDF5),
      'status': 'Pending Review',
      'statusColor': Color(0xFFF59E0B),
      'avatar': 'assets/images/athlete_transform_1787825621309.jpg',
      'avatarBg': Color(0xFFDCFCE7),
      'idNumber': 'P-8927419',
    },
    {
      'name': 'Rajeshwari Iyer',
      'id': '#KYC-9419',
      'role': 'Yoga Instructor Partner',
      'email': 'rajeshwari.i@gmail.com',
      'submitted': 'Yesterday, 4:30 PM',
      'docType': 'Yoga Alliance 500h + Govt ID',
      'docIcon': Icons.spa_rounded,
      'aiScore': '96.8% Match',
      'risk': 'Low Risk',
      'riskColor': Color(0xFF10B981),
      'riskBg': Color(0xFFECFDF5),
      'status': 'Approved',
      'statusColor': Color(0xFF10B981),
      'avatar': 'assets/images/hero_banner_1.png',
      'avatarBg': Color(0xFFFEF3C7),
      'idNumber': 'YA-500-4821',
    },
    {
      'name': 'Mohit Deshpande',
      'id': '#KYC-9418',
      'role': 'Nutritionist Partner',
      'email': 'mohit.d@gmail.com',
      'submitted': 'May 25, 2025',
      'docType': 'Dietetics Degree + Address Proof',
      'docIcon': Icons.restaurant_rounded,
      'aiScore': '84.2% Match',
      'risk': 'Medium Risk',
      'riskColor': Color(0xFFF59E0B),
      'riskBg': Color(0xFFFFFBEB),
      'status': 'Approved',
      'statusColor': Color(0xFF10B981),
      'avatar': 'assets/images/hero_banner_4.png',
      'avatarBg': Color(0xFFDBEAFE),
      'idNumber': 'MCD-89214',
    },
    {
      'name': 'Tarun Malhotra',
      'id': '#KYC-9417',
      'role': 'Gym Partner & Trainer',
      'email': 'tarun.m@gmail.com',
      'submitted': 'May 24, 2025',
      'docType': 'Govt ID (Blurry copy)',
      'docIcon': Icons.warning_amber_rounded,
      'aiScore': '61.5% Match',
      'risk': 'High Risk',
      'riskColor': Color(0xFFEF4444),
      'riskBg': Color(0xFFFEF2F2),
      'status': 'Rejected',
      'statusColor': Color(0xFFEF4444),
      'avatar': 'assets/images/workout_banner_1.png',
      'avatarBg': Color(0xFFFFEDD5),
      'idNumber': 'UNREADABLE_DOC',
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
                  child: Text('AI Match: ${item['aiScore']}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: item['riskColor'] as Color)),
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
              setState(() => item['status'] = 'Approved');
              _showSnackbar('Verification for ${item['name']} approved!', const Color(0xFF10B981));
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
    final kpis = [
      {'title': 'Pending KYC', 'val': '42', 'growth': 'Requires review', 'icon': Icons.pending_actions_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Verified Today', 'val': '128', 'growth': '+18.4% processed', 'icon': Icons.verified_user_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Rejected / Resubmit', 'val': '9', 'growth': 'Doc blur / mismatch', 'icon': Icons.gpp_bad_rounded, 'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEF2F2)},
      {'title': 'Avg Turnaround', 'val': '4.2 hrs', 'growth': 'SLA compliance 99%', 'icon': Icons.speed_rounded, 'color': const Color(0xFF06B6D4), 'bg': const Color(0xFFECFEFF)},
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
    final tabs = ['All (179)', 'Pending (42)', 'Approved (128)', 'Rejected (9)'];

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
                      child: Image.asset(item['avatar'] as String, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person)),
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
                          setState(() => item['status'] = 'Approved');
                          _showSnackbar('${item['name']} approved successfully!', const Color(0xFF10B981));
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
                        setState(() => item['status'] = 'Rejected');
                        _showSnackbar('${item['name']} marked as rejected / resubmit.', const Color(0xFFEF4444));
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
