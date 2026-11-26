import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import '../backend/live_backend.dart';
import 'net_or_asset_image.dart';

void showTrainerDetailModal(BuildContext context, Map<String, dynamic> t) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (ctx) => _TrainerDetailBottomSheet(trainer: t),
  );
}

class _TrainerDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> trainer;
  const _TrainerDetailBottomSheet({required this.trainer});

  @override
  State<_TrainerDetailBottomSheet> createState() => _TrainerDetailBottomSheetState();
}

class _TrainerDetailBottomSheetState extends State<_TrainerDetailBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  Map<String, dynamic> _d = {};
  List<Map<String, dynamic>> get _clients => [for (final c in (_d['clients'] as List? ?? const [])) Map<String, dynamic>.from(c as Map)];

  Future<void> _load() async {
    try {
      final j = await Api.get('/admin/trainers/${widget.trainer['id']}/detail');
      if (mounted) setState(() => _d = Map<String, dynamic>.from(j['data'] as Map));
    } catch (_) {}
  }

  Future<void> _act(Future<void> Function() f, String ok, Color color) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      await f();
      messenger.showSnackBar(SnackBar(content: Text(ok), backgroundColor: color, behavior: SnackBarBehavior.floating));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _assign(Map<String, dynamic> t) async {
    final ctrl = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign trainee to ${t['name']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        content: TextField(controller: ctrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: "Trainee's email")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Assign')),
        ],
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;
    await _act(() async { await AdminTrainers.I.assign('${t['id']}', email); }, 'Trainee assigned to ${t['name']}', const Color(0xFF06B6D4));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final t = widget.trainer;
    final bool isVip = (t['tier'] ?? '').toString().contains('VIP') || (t['isPremium'] == true);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),

          // Header Profile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isVip ? Colors.amber.shade400 : Colors.grey.shade200, width: 2),
                      ),
                      child: ClipOval(
                        child: NetOrAssetImage(t['img'] as String, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, size: 36)),
                      ),
                    ),
                    if (isVip)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                          child: const Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              t['name'] as String,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF06B6D4)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(t['specialty'] as String? ?? '', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF06B6D4))),
                      Text('${t['rating']} (${t['reviewsCount']}) • ${t['experience'] ?? ''}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab Bar (Overview & Pricing, Enrolled Trainees, Packages, Performance)
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF0F172A),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF06B6D4),
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            tabs: [
              const Tab(text: 'Overview & Rates'),
              Tab(text: 'Premium Trainees (${_d['active'] ?? t['clientsCount'] ?? 0})'),
              const Tab(text: 'Packages & Services'),
              const Tab(text: 'Performance & Reviews'),
            ],
          ),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(t),
                _buildTraineesTab(),
                _buildPackagesTab(t),
                _buildPerformanceTab(t),
              ],
            ),
          ),

          // Bottom Sticky Admin Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _assign(t),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 14, color: Colors.white),
                    label: const Text('Assign Trainee', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVip ? const Color(0xFF64748B) : const Color(0xFFF59E0B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _act(() => AdminTrainers.I.setVip('${t['id']}', !isVip), '${t['name']} VIP status updated!', const Color(0xFFF59E0B)),
                    icon: Icon(isVip ? Icons.star_border_rounded : Icons.workspace_premium_rounded, size: 14, color: Colors.white),
                    label: Text(isVip ? 'Remove VIP' : '👑 Set as VIP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _act(() => AdminTrainers.I.setStatus('${t['id']}', t['rawStatus'] == 'suspended' ? 'approve' : 'suspend'),
                      t['rawStatus'] == 'suspended' ? 'Trainer ${t['name']} reactivated.' : 'Trainer ${t['name']} suspended.', const Color(0xFFEF4444)),
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                    child: const Icon(Icons.block_flipped, size: 16, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> t) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // 4 KPI Stat Counters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard('Active Clients', '${_d['active'] ?? t['clientsCount'] ?? 0} Athletes', Icons.groups_rounded, const Color(0xFF3B82F6)),
            _buildStatCard('Monthly Rev.', fmtInr(t['revenue30d'] as num? ?? 0), Icons.account_balance_wallet_rounded, const Color(0xFF10B981)),
            _buildStatCard('Check-ins', fmtInt(_clients.fold<num>(0, (a, c) => a + (c['checkins'] as num? ?? 0))), Icons.done_all_rounded, const Color(0xFF8B5CF6)),
            _buildStatCard('Retention', fmtPct(_d['retention'] as num? ?? 0), Icons.speed_rounded, const Color(0xFF06B6D4)),
          ],
        ),
        const SizedBox(height: 16),

        // Pricing Rates Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Trainer Pricing Rates & Commission', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  Text('Edit Rates', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF06B6D4))),
                ],
              ),
              const Divider(height: 16, thickness: 0.8, color: Color(0xFFE2E8F0)),
              for (final p in (t['plans'] as List? ?? const []))
                if (p is Map) _buildPriceRow('${p['name']} plan (${p['months']} mo)', fmtInr(p['price'] as num? ?? 0), '85% Payout to Coach'),
              _buildPriceRow('Platform Commission Split', '15% Flat', 'Auto deducted on payout'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Certifications & Education
        const Text('Certifications & Credentials', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in (t['certifications'] is List ? t['certifications'] as List : const []))
              _buildCertBadge('📜 ${c is Map ? (c['name'] ?? c['title'] ?? '') : c}'),
            if (t['certifications'] is! List || (t['certifications'] as List).isEmpty) _buildCertBadge('No certificates uploaded'),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow(String title, String price, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
        ],
      ),
    );
  }

  Widget _buildCertBadge(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Text(title, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
    );
  }

  Widget _buildTraineesTab() {
    final clients = [
      for (final c in _clients)
        {'name': c['name'], 'plan': c['planName'], 'streak': '${c['active'] == true ? '🔥' : '⏸'} ${c['days']} Days', 'adherence': '${c['adherence']}%', 'avatar': c['photo'] ?? ''},
    ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: clients.length,
      itemBuilder: (ctx, i) {
        final c = clients[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: const Color(0xFFE2E8F0), backgroundImage: '${c['avatar']}'.startsWith('http') ? NetworkImage('${c['avatar']}') : null, child: '${c['avatar']}'.startsWith('http') ? null : const Icon(Icons.person, size: 18, color: Color(0xFF64748B))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('${c['plan']} • ${c['streak']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                child: Text('Adherence: ${c['adherence']}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPackagesTab(Map<String, dynamic> t) {
    final packages = [
      for (final p in (t['plans'] as List? ?? const []))
        if (p is Map)
          {'name': '${p['name']} · ${p['months']} month${p['months'] == 1 ? '' : 's'}', 'price': fmtInr(p['price'] as num? ?? 0), 'features': [for (final f in (p['perks'] as List? ?? const [])) '$f']},
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: packages.map((pkg) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(pkg['name'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                Text(pkg['price'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF06B6D4))),
              ],
            ),
            const SizedBox(height: 8),
            ...(pkg['features'] as List<String>).map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(f, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                ],
              ),
            )),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPerformanceTab(Map<String, dynamic> t) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              _buildMetricRow('Clients Checking In', fmtPct(_d['engaged'] as num? ?? 0), const Color(0xFF10B981)),
              _buildMetricRow('Monthly Client Retention', fmtPct(_d['retention'] as num? ?? 0), const Color(0xFF3B82F6)),
              _buildMetricRow('Avg. Response Time to Trainees', _d['replyMinutes'] == null ? '-' : '${_d['replyMinutes']} mins', const Color(0xFF06B6D4)),
              _buildMetricRow('Overall Satisfaction Score', '${t['rating']} / 5.0', const Color(0xFFF59E0B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          Text(val, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon, Color color) {
    return Container(
      width: 76,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
          Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
