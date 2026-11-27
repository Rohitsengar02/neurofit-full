import 'package:flutter/material.dart';
import 'trainer_detail_bottom_sheet.dart';
import 'net_or_asset_image.dart';
import '../backend/admin_data.dart';

class TrainersListView extends StatefulWidget {
  final String selectedDateRange;
  final String viewMode; // 'all', 'premium', 'manage'
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const TrainersListView({
    super.key,
    required this.selectedDateRange,
    this.viewMode = 'all',
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<TrainersListView> createState() => _TrainersListViewState();
}

class _TrainersListViewState extends State<TrainersListView> {
  int _selectedFilterIndex = 0;
  String _searchQuery = '';
  bool _isGridView = false; // Toggle between beautiful rich list and grid

  List<String> get _specialties => ['All Specialties', ...{for (final t in _trainersList) '${t['category']}'}];

  List<Map<String, dynamic>> get _trainersList => AdminTrainers.I.withStatus('approved');

  void _changed() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    AdminTrainers.I.addListener(_changed);
    AdminTrainers.I.load();
  }

  @override
  void dispose() {
    AdminTrainers.I.removeListener(_changed);
    super.dispose();
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
    if (email == null || email.isEmpty) return;
    try {
      final who = await AdminTrainers.I.assign('${t['id']}', email);
      if (mounted) _showSnackbar('$who assigned to ${t['name']}', const Color(0xFF06B6D4));
    } catch (e) {
      if (mounted) _showSnackbar('$e', const Color(0xFFEF4444));
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedSection(0, _buildKpiCarousel()),
        const SizedBox(height: 16),
        _buildAnimatedSection(1, _buildSearchAndToggleBar()),
        const SizedBox(height: 12),
        _buildAnimatedSection(2, _buildSpecialtyChips()),
        const SizedBox(height: 16),
        _buildAnimatedSection(3, _buildTrainersFeed()),
      ],
    );
  }

  Widget _buildKpiCarousel() {
    final all = _trainersList;
    final vip = all.where((t) => t['isPremium'] == true).length;
    final rev = all.fold<num>(0, (a, t) => a + (t['revenue30d'] as num? ?? 0));
    final rated = all.where((t) => (t['reviews'] as num? ?? 0) > 0).toList();
    final avgRating = rated.isEmpty ? 0.0 : rated.fold<double>(0, (a, t) => a + (t['rating'] is num ? (t['rating'] as num).toDouble() : double.tryParse('${t['rating']}'.split(' ').first) ?? 0)) / rated.length;
    final newThisMonth = all.where((t) => DateTime.tryParse('${t['reviewedAt'] ?? ''}')?.isAfter(DateTime.now().subtract(const Duration(days: 30))) ?? false).length;
    final kpis = [
      {'title': 'Total Coaches', 'val': '${all.length} Active', 'growth': '+$newThisMonth New this month', 'icon': Icons.sports_gymnastics_rounded, 'color': const Color(0xFF06B6D4), 'bg': const Color(0xFFECFEFF)},
      {'title': 'VIP Mentors', 'val': '$vip Coaches', 'growth': 'Marked VIP by admin', 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Avg Monthly Rev', 'val': '${fmtInr(all.isEmpty ? 0 : rev / all.length)} / coach', 'growth': '${fmtInr(rev)} last 30 days', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Client Rating', 'val': rated.isEmpty ? 'New' : '${avgRating.toStringAsFixed(2)} ★', 'growth': '${rated.fold<num>(0, (a, t) => a + (t['reviews'] as num? ?? 0))} reviews', 'icon': Icons.star_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
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

  Widget _buildSearchAndToggleBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
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
                    decoration: const InputDecoration(hintText: 'Search coach by name, specialty, certification...', border: InputBorder.none, isDense: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _isGridView = !_isGridView),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
            child: Icon(_isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded, size: 18, color: const Color(0xFF06B6D4)),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_specialties.length, (i) {
          final isSelected = _selectedFilterIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF06B6D4) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.grey.shade200),
                ),
                child: Text(
                  _specialties[i],
                  style: TextStyle(fontSize: 10.5, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTrainersFeed() {
    final filtered = _trainersList.where((t) {
      if (widget.viewMode == 'premium' && t['isPremium'] != true) return false;
      if (_selectedFilterIndex > 0 && _selectedFilterIndex < _specialties.length) {
        final spec = _specialties[_selectedFilterIndex];
        if (t['category'] != spec) return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (t['name'] as String).toLowerCase().contains(q) ||
          (t['specialty'] as String).toLowerCase().contains(q) ||
          (t['certifications'] as String).toLowerCase().contains(q);
    }).toList();

    if (_isGridView) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.70,
        ),
        itemCount: filtered.length,
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () => showTrainerDetailModal(context, filtered[i]),
          child: _buildTrainerGridCard(filtered[i]),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final t = filtered[i];
        return GestureDetector(
          onTap: () => showTrainerDetailModal(context, t),
          child: _buildRichTrainerListCard(t),
        );
      },
    );
  }

  Widget _buildRichTrainerListCard(Map<String, dynamic> t) {
    final bool isVip = t['isPremium'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isVip ? Colors.amber.shade200.withOpacity(0.8) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: isVip ? Colors.amber.withOpacity(0.06) : Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row with Avatar, Name, Tier Badge & Online Status
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isVip ? Colors.amber.shade400 : Colors.grey.shade200, width: 2),
                      ),
                      child: ClipOval(
                        child: NetOrAssetImage(
                          t['img'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.person, size: 30),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
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
                              t['name'] as String,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF06B6D4)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(t['specialty'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF06B6D4))),
                      const SizedBox(height: 2),
                      Text('📜 ${t['certifications']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: t['tierBg'] as Color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (t['tierColor'] as Color).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          if (isVip) ...[
                            Icon(Icons.workspace_premium_rounded, size: 11, color: t['tierColor'] as Color),
                            const SizedBox(width: 2),
                          ],
                          Text(t['tier'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: t['tierColor'] as Color)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${t['rating']} (${t['reviewsCount']})', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
                  ],
                ),
              ],
            ),
          ),

          // Bio Snippet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              t['bio'] as String,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),

          // 3 Metric Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInlineMetric('Active Trainees', '${t['clientsCount']}', t['clientGrowth'] as String, const Color(0xFF3B82F6)),
                  _buildInlineDivider(),
                  _buildInlineMetric('Monthly Revenue', t['monthlyRevenue'] as String, 'Gross GMV', const Color(0xFF10B981)),
                  _buildInlineDivider(),
                  _buildInlineMetric('Transformation', t['successRate'] as String, 'Success Rate', const Color(0xFF8B5CF6)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Pricing & Quick Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1-on-1 Monthly Mentorship', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                    Text(t['monthlyRate'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  ],
                ),
                Row(
                  children: [
                    _buildCardActionBtn('Assign', Icons.person_add_alt_1_rounded, const Color(0xFF06B6D4), () {
                      _assign(t);
                    }),
                    const SizedBox(width: 6),
                    _buildCardActionBtn('View Profile', Icons.arrow_forward_rounded, const Color(0xFF0F172A), () {
                      showTrainerDetailModal(context, t);
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerGridCard(Map<String, dynamic> t) {
    final bool isVip = t['isPremium'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isVip ? Colors.amber.shade200 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: const Color(0xFFE2E8F0), backgroundImage: '${t['img']}'.startsWith('http') ? NetworkImage(t['img'] as String) : null, child: '${t['img']}'.startsWith('http') ? null : const Icon(Icons.person, size: 20, color: Color(0xFF64748B))),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(t['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (isVip) ...[
                          const SizedBox(width: 2),
                          const Icon(Icons.workspace_premium_rounded, size: 12, color: Color(0xFFF59E0B)),
                        ],
                      ],
                    ),
                    Text(t['rating'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(t['specialty'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF06B6D4)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('Trainees: ${t['clientsCount']} • ${t['successRate']} SLA', style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B))),
          const Spacer(),
          const Divider(height: 10, thickness: 0.7, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t['monthlyRate'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
              const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineMetric(String label, String val, String sub, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildInlineDivider() {
    return Container(width: 1, height: 24, color: Colors.grey.shade300);
  }

  Widget _buildCardActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}
