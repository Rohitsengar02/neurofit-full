import 'package:flutter/material.dart';
import 'user_detail_bottom_sheet.dart';

class ActiveUsersView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const ActiveUsersView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<ActiveUsersView> createState() => _ActiveUsersViewState();
}

class _ActiveUsersViewState extends State<ActiveUsersView> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _activeUsersList = const [
    {
      'name': 'Rohit Sharma',
      'email': 'rohit.s@gmail.com',
      'phone': '+91 99887 76655',
      'lastActive': '2 min ago',
      'streak': '🔥 24 Days',
      'workouts': '56 Done',
      'plan': 'Pro Member',
      'planColor': Color(0xFF10B981),
      'planBg': Color(0xFFECFDF5),
      'status': 'Online',
      'avatarBg': Color(0xFFDCFCE7),
      'img': 'assets/images/trainers_hero_banner.jpg',
    },
    {
      'name': 'Ananya Roy',
      'email': 'ananya.roy@gmail.com',
      'phone': '+91 98123 45678',
      'lastActive': 'Just now',
      'streak': '🔥 18 Days',
      'workouts': '42 Done',
      'plan': 'Pro Member',
      'planColor': Color(0xFF10B981),
      'planBg': Color(0xFFECFDF5),
      'status': 'Online',
      'avatarBg': Color(0xFFEDE9FE),
      'img': 'assets/images/athlete_transform_1787825621309.jpg',
    },
    {
      'name': 'Siddharth Rao',
      'email': 'sid.rao@gmail.com',
      'phone': '+91 87654 98765',
      'lastActive': '15 min ago',
      'streak': '🔥 32 Days',
      'workouts': '78 Done',
      'plan': 'Pro Member',
      'planColor': Color(0xFF10B981),
      'planBg': Color(0xFFECFDF5),
      'status': 'Active',
      'avatarBg': Color(0xFFFFEDD5),
      'img': 'assets/images/hero_banner_4.png',
    },
    {
      'name': 'Deepika Nair',
      'email': 'deepika.n@gmail.com',
      'phone': '+91 76543 87654',
      'lastActive': '1 hour ago',
      'streak': '🔥 14 Days',
      'workouts': '31 Done',
      'plan': 'Free Tier',
      'planColor': Color(0xFF3B82F6),
      'planBg': Color(0xFFEFF6FF),
      'status': 'Active',
      'avatarBg': Color(0xFFFEF3C7),
      'img': 'assets/images/hero_banner_1.png',
    },
    {
      'name': 'Manish Kulkarni',
      'email': 'manish.k@gmail.com',
      'phone': '+91 84321 76543',
      'lastActive': '3 hours ago',
      'streak': '🔥 9 Days',
      'workouts': '18 Done',
      'plan': 'Free Tier',
      'planColor': Color(0xFF3B82F6),
      'planBg': Color(0xFFEFF6FF),
      'status': 'Active',
      'avatarBg': Color(0xFFDBEAFE),
      'img': 'assets/images/workout_banner_1.png',
    },
    {
      'name': 'Sneha Kapoor',
      'email': 'sneha.k@gmail.com',
      'phone': '+91 73456 65432',
      'lastActive': 'Just now',
      'streak': '🔥 45 Days',
      'workouts': '95 Done',
      'plan': 'Pro Member',
      'planColor': Color(0xFF10B981),
      'planBg': Color(0xFFECFDF5),
      'status': 'Online',
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
      {'title': 'Active Today', 'val': '8,450', 'growth': '12.4% vs yesterday', 'icon': Icons.how_to_reg_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'DAU / MAU Ratio', 'val': '64.2%', 'growth': '+4.8% stickiness', 'icon': Icons.insights_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'title': 'Avg. Session', 'val': '28m 14s', 'growth': '+6.2% time spent', 'icon': Icons.timer_outlined, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
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
                    hintText: 'Search active users by name or email',
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
              _buildFilterDropdown('Activity Level'),
              const SizedBox(width: 8),
              _buildFilterDropdown('Streak Range'),
              const SizedBox(width: 8),
              _buildFilterDropdown('Plan Tier'),
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
    final filtered = _activeUsersList.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (u['name'] as String).toLowerCase().contains(q) ||
          (u['email'] as String).toLowerCase().contains(q);
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
          child: _buildActiveUserCard(u),
        );
      },
    );
  }

  Widget _buildActiveUserCard(Map<String, dynamic> u) {
    final bool isOnline = u['status'] == 'Online';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: u['avatarBg'] as Color, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: Image.asset(
                        u['img'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.person, size: 24, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  u['lastActive'] as String,
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: isOnline ? const Color(0xFF10B981) : const Color(0xFF64748B)),
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
              const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 2),
          Text(u['email'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(u['phone'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          const Spacer(),
          const Divider(height: 12, thickness: 0.8, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Streak', style: TextStyle(fontSize: 7.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                  Text(u['streak'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFF97316))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Workouts', style: TextStyle(fontSize: 7.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                  Text(u['workouts'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(color: u['planBg'] as Color, borderRadius: BorderRadius.circular(6)),
                child: Text(u['plan'] as String, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: u['planColor'] as Color)),
              ),
              Row(
                children: [
                  _buildMiniAction(Icons.chat_bubble_outline_rounded),
                  const SizedBox(width: 4),
                  _buildMiniAction(Icons.fitness_center_rounded),
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
