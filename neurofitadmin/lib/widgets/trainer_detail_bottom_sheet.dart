import 'package:flutter/material.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                        child: Image.asset(t['img'] as String, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, size: 36)),
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
                      Text(t['specialty'] as String? ?? 'Hypertrophy & Fat Loss', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF06B6D4))),
                      Text('${t['rating']} (340+ Reviews) • ${t['experience'] ?? "6+ Years Exp"}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
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
            tabs: const [
              Tab(text: 'Overview & Rates'),
              Tab(text: 'Premium Trainees (48)'),
              Tab(text: 'Packages & Services'),
              Tab(text: 'Performance & Reviews'),
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
                    onPressed: () {
                      Navigator.pop(context);
                      _showSnackbar('Assign Trainee modal opened for ${t['name']}', const Color(0xFF06B6D4));
                    },
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
                    onPressed: () {
                      Navigator.pop(context);
                      _showSnackbar('${t['name']} VIP status updated!', const Color(0xFFF59E0B));
                    },
                    icon: Icon(isVip ? Icons.star_border_rounded : Icons.workspace_premium_rounded, size: 14, color: Colors.white),
                    label: Text(isVip ? 'Remove VIP' : '👑 Set as VIP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSnackbar('Trainer ${t['name']} suspended.', const Color(0xFFEF4444));
                  },
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
            _buildStatCard('Active Clients', '48 Athletes', Icons.groups_rounded, const Color(0xFF3B82F6)),
            _buildStatCard('Monthly Rev.', '₹1,84,000', Icons.account_balance_wallet_rounded, const Color(0xFF10B981)),
            _buildStatCard('Sessions Done', '1,420', Icons.done_all_rounded, const Color(0xFF8B5CF6)),
            _buildStatCard('Client SLA', '98.2%', Icons.speed_rounded, const Color(0xFF06B6D4)),
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
              _buildPriceRow('1-on-1 Monthly VIP Mentorship', t['monthlyRate'] ?? '₹9,999 / mo', '85% Payout to Coach'),
              _buildPriceRow('Custom Workout & Diet Protocol', t['planRate'] ?? '₹3,499 / plan', '80% Payout to Coach'),
              _buildPriceRow('Live Video Consultation (45m)', t['callRate'] ?? '₹1,299 / session', '90% Payout to Coach'),
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
            _buildCertBadge('📜 ACE Certified Personal Trainer'),
            _buildCertBadge('🏋️ CSCS Strength & Conditioning'),
            _buildCertBadge('🥗 Precision Nutrition Level 1'),
            _buildCertBadge('🩺 CPR & AED First Aid Certified'),
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
      {'name': 'Dr. Vikram Seth', 'plan': 'VIP Mentorship', 'streak': '🔥 45 Days', 'adherence': '96%', 'avatar': 'assets/images/trainers_hero_banner.jpg'},
      {'name': 'Rhea Singhania', 'plan': 'Elite Annual', 'streak': '🔥 32 Days', 'adherence': '94%', 'avatar': 'assets/images/athlete_transform_1787825621309.jpg'},
      {'name': 'Karan Mehta', 'plan': 'Pro Quarterly', 'streak': '🔥 28 Days', 'adherence': '88%', 'avatar': 'assets/images/hero_banner_4.png'},
      {'name': 'Pooja Mehta', 'plan': 'VIP Mentorship', 'streak': '🔥 19 Days', 'adherence': '92%', 'avatar': 'assets/images/hero_banner_1.png'},
      {'name': 'Siddharth Rao', 'plan': 'Custom Protocol', 'streak': '🔥 14 Days', 'adherence': '85%', 'avatar': 'assets/images/workout_banner_1.png'},
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
              CircleAvatar(radius: 18, backgroundImage: AssetImage(c['avatar'] as String)),
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
      {'name': 'Gold 1-on-1 Monthly Mentorship', 'price': t['monthlyRate'] ?? '₹9,999', 'features': ['Daily WhatsApp check-in', 'Custom progressive workout split', 'Weekly macro adjustments', 'Form audit videos']},
      {'name': 'Hypertrophy Transformation Plan', 'price': t['planRate'] ?? '₹3,499', 'features': ['12-Week complete workout PDF', 'Personalized meal schedule', 'Exercise replacement guide']},
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
              _buildMetricRow('Client Transformation Rate', '94.2%', const Color(0xFF10B981)),
              _buildMetricRow('Monthly Client Retention', '88.6%', const Color(0xFF3B82F6)),
              _buildMetricRow('Avg. Response Time to Trainees', '14 mins', const Color(0xFF06B6D4)),
              _buildMetricRow('Overall Satisfaction Score', '4.95 / 5.0', const Color(0xFFF59E0B)),
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
