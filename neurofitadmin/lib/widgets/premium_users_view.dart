import 'package:flutter/material.dart';
import 'user_detail_bottom_sheet.dart';

class PremiumUsersView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const PremiumUsersView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<PremiumUsersView> createState() => _PremiumUsersViewState();
}

class _PremiumUsersViewState extends State<PremiumUsersView> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _premiumUsersList = const [
    {
      'name': 'Dr. Vikram Seth',
      'email': 'vikram.seth@gmail.com',
      'phone': '+91 99112 23344',
      'tier': 'VIP Mentorship',
      'expiry': 'Renews in 45d',
      'trainer': 'Amit Sharma',
      'spend': '₹12,499',
      'badge': 'VIP',
      'badgeColor': Color(0xFFF59E0B),
      'badgeBg': Color(0xFFFEF3C7),
      'avatarBg': Color(0xFFFEF3C7),
      'img': 'assets/images/trainers_hero_banner.jpg',
    },
    {
      'name': 'Rhea Singhania',
      'email': 'rhea.s@gmail.com',
      'phone': '+91 98223 34455',
      'tier': 'Elite Annual',
      'expiry': 'Renews in 180d',
      'trainer': 'Priya Patel',
      'spend': '₹8,999',
      'badge': 'Elite',
      'badgeColor': Color(0xFF8B5CF6),
      'badgeBg': Color(0xFFF5F3FF),
      'avatarBg': Color(0xFFEDE9FE),
      'img': 'assets/images/athlete_transform_1787825621309.jpg',
    },
    {
      'name': 'Aditya Birla',
      'email': 'aditya.b@gmail.com',
      'phone': '+91 97334 45566',
      'tier': 'Pro Quarterly',
      'expiry': 'Renews in 24d',
      'trainer': 'Rahul Verma',
      'spend': '₹3,499',
      'badge': 'Pro',
      'badgeColor': Color(0xFF10B981),
      'badgeBg': Color(0xFFECFDF5),
      'avatarBg': Color(0xFFDCFCE7),
      'img': 'assets/images/hero_banner_4.png',
    },
    {
      'name': 'Kavita Chawla',
      'email': 'kavita.c@gmail.com',
      'phone': '+91 96445 56677',
      'tier': 'Elite Annual',
      'expiry': 'Renews in 92d',
      'trainer': 'Neha Singh',
      'spend': '₹8,999',
      'badge': 'Elite',
      'badgeColor': Color(0xFF8B5CF6),
      'badgeBg': Color(0xFFF5F3FF),
      'avatarBg': Color(0xFFFFEDD5),
      'img': 'assets/images/hero_banner_1.png',
    },
    {
      'name': 'Sameer Deshmukh',
      'email': 'sameer.d@gmail.com',
      'phone': '+91 95556 67788',
      'tier': 'VIP Mentorship',
      'expiry': 'Renews in 12d',
      'trainer': 'Amit Sharma',
      'spend': '₹12,499',
      'badge': 'VIP',
      'badgeColor': Color(0xFFF59E0B),
      'badgeBg': Color(0xFFFEF3C7),
      'avatarBg': Color(0xFFDBEAFE),
      'img': 'assets/images/workout_banner_1.png',
    },
    {
      'name': 'Meera Sen',
      'email': 'meera.sen@gmail.com',
      'phone': '+91 94667 78899',
      'tier': 'Pro Quarterly',
      'expiry': 'Renews in 60d',
      'trainer': 'Priya Patel',
      'spend': '₹3,499',
      'badge': 'Pro',
      'badgeColor': Color(0xFF10B981),
      'badgeBg': Color(0xFFECFDF5),
      'avatarBg': Color(0xFFF5F3FF),
      'img': 'assets/images/athlete_transform_1787825621309.jpg',
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedSection(0, _buildTopKpiCarousel()),
        const SizedBox(height: 16),
        _buildAnimatedSection(1, _buildSearchAndFilterBar()),
        const SizedBox(height: 18),
        _buildAnimatedSection(2, _buildUserGrid()),
      ],
    );
  }

  Widget _buildTopKpiCarousel() {
    final kpis = [
      {'title': 'Total Premium', 'val': '4,320', 'growth': '18.4% vs last month', 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFEF3C7)},
      {'title': 'Monthly MRR', 'val': '₹12,45,800', 'growth': '+21.7% growth', 'icon': Icons.monetization_on_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Renewal Rate', 'val': '88.6%', 'growth': 'High retention', 'icon': Icons.autorenew_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: kpis.map((k) {
          final Color color = k['color'] as Color;
          return Container(
            width: 148,
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
                    Expanded(child: Text(k['title'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(k['val'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.north_east_rounded, size: 10, color: Color(0xFF10B981)),
                    const SizedBox(width: 2),
                    Expanded(child: Text(k['growth'] as String, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
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
                    hintText: 'Search VIP & Premium members',
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
            children: [
              _buildFilterDropdown('Subscription Tier'),
              const SizedBox(width: 8),
              _buildFilterDropdown('Trainer Assigned'),
              const SizedBox(width: 8),
              _buildFilterDropdown('Expiry Range'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildUserGrid() {
    final filtered = _premiumUsersList.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (u['name'] as String).toLowerCase().contains(q) ||
          (u['email'] as String).toLowerCase().contains(q) ||
          (u['trainer'] as String).toLowerCase().contains(q);
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.74,
      ),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final u = filtered[i];
        return GestureDetector(
          onTap: () => showUserDetailModal(context, u),
          child: _buildPremiumUserCard(u),
        );
      },
    );
  }

  Widget _buildPremiumUserCard(Map<String, dynamic> u) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.shade200.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: u['avatarBg'] as Color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade300, width: 1.5),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: Image.asset(
                    u['img'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.person, size: 24, color: Color(0xFF64748B)),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: u['badgeBg'] as Color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: (u['badgeColor'] as Color).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 10, color: u['badgeColor'] as Color),
                    const SizedBox(width: 2),
                    Text(
                      u['badge'] as String,
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: u['badgeColor'] as Color),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.more_horiz_rounded, size: 14, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text(
                  u['name'] as String,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.verified_rounded, size: 13, color: Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 2),
          Text(u['email'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(u['tier'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6))),
          const Spacer(),
          const Divider(height: 12, thickness: 0.8, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trainer', style: TextStyle(fontSize: 7.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                  Text(u['trainer'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Lifetime Spend', style: TextStyle(fontSize: 7.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                  Text(u['spend'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                u['expiry'] as String,
                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
              ),
              Row(
                children: [
                  _buildMiniAction(Icons.chat_bubble_outline_rounded),
                  const SizedBox(width: 4),
                  _buildMiniAction(Icons.card_membership_rounded),
                  const SizedBox(width: 4),
                  _buildMiniAction(Icons.person_outline_rounded),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
      child: Icon(icon, size: 11, color: const Color(0xFF64748B)),
    );
  }
}
