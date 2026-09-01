import 'package:flutter/material.dart';

class MoreBottomSliderSheet extends StatelessWidget {
  const MoreBottomSliderSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => const MoreBottomSliderSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Top Drag Handle & Title Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Explore All Modules',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Everything you need is here',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings_outlined, color: Color(0xFF0F172A), size: 22),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A), size: 22),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Scrollable Categorized Grids
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                  children: [
                    // Top Hero Banner
                    _buildHeroBanner(context),
                    const SizedBox(height: 24),

                    // 1. Fitness Category (3x2 Grid)
                    _buildCategorySection(
                      context,
                      title: 'Fitness',
                      icon: Icons.fitness_center_rounded,
                      color: const Color(0xFF22C55E),
                      items: [
                        {'title': 'Challenges', 'icon': Icons.emoji_events_outlined},
                        {'title': 'Streak', 'icon': Icons.local_fire_department_outlined},
                        {'title': 'AI Coach', 'icon': Icons.smart_toy_outlined},
                        {'title': 'Manual Workout', 'icon': Icons.sports_gymnastics_rounded},
                        {'title': 'Workout History', 'icon': Icons.history_rounded},
                        {'title': 'Programs', 'icon': Icons.assignment_outlined},
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. Shop Category (3x2 Grid)
                    _buildCategorySection(
                      context,
                      title: 'Shop',
                      icon: Icons.shopping_bag_outlined,
                      color: const Color(0xFF22C55E),
                      items: [
                        {'title': 'Shop', 'icon': Icons.storefront_outlined},
                        {'title': 'Orders', 'icon': Icons.inventory_2_outlined},
                        {'title': 'Wishlist', 'icon': Icons.favorite_border_rounded},
                        {'title': 'Cart', 'icon': Icons.shopping_cart_outlined, 'badge': '1'},
                        {'title': 'Categories', 'icon': Icons.grid_view_rounded},
                        {'title': 'Offers', 'icon': Icons.discount_outlined},
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. Trainers Category (3x2 Grid)
                    _buildCategorySection(
                      context,
                      title: 'Trainers',
                      icon: Icons.person_search_outlined,
                      color: const Color(0xFF22C55E),
                      items: [
                        {'title': 'Find Trainer', 'icon': Icons.search_rounded},
                        {'title': 'My Trainer', 'icon': Icons.badge_outlined},
                        {'title': 'Plans', 'icon': Icons.receipt_long_outlined},
                        {'title': 'Sessions', 'icon': Icons.calendar_month_outlined},
                        {'title': 'Bookings', 'icon': Icons.confirmation_number_outlined},
                        {'title': 'Messages', 'icon': Icons.chat_bubble_outline_rounded},
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 4. Community Category (3x2 Grid)
                    _buildCategorySection(
                      context,
                      title: 'Community',
                      icon: Icons.groups_outlined,
                      color: const Color(0xFF22C55E),
                      items: [
                        {'title': 'Community', 'icon': Icons.forum_outlined},
                        {'title': 'Groups', 'icon': Icons.group_work_outlined},
                        {'title': 'Friends', 'icon': Icons.person_add_alt_1_outlined},
                        {'title': 'Leaderboard', 'icon': Icons.leaderboard_outlined},
                        {'title': 'My Posts', 'icon': Icons.article_outlined},
                        {'title': 'Activity Feed', 'icon': Icons.sensors_rounded},
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 5. Rewards Category (3x2 Grid)
                    _buildCategorySection(
                      context,
                      title: 'Rewards',
                      icon: Icons.card_giftcard_rounded,
                      color: const Color(0xFF22C55E),
                      items: [
                        {'title': 'Rewards', 'icon': Icons.redeem_rounded},
                        {'title': 'Badges', 'icon': Icons.military_tech_outlined},
                        {'title': 'Achievements', 'icon': Icons.workspace_premium_outlined},
                        {'title': 'XP & Points', 'icon': Icons.star_border_rounded},
                        {'title': 'Streak Rewards', 'icon': Icons.timer_outlined},
                        {'title': 'Redeem', 'icon': Icons.discount_outlined},
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hero Banner matching screenshot
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Athlete Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/hero_banner_4.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (ctx, err, st) => Image.asset(
                  'assets/images/workout_banner_1.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),

            // Left Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.96),
                      Colors.white.withOpacity(0.85),
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // Foreground Text & Button
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: 'Transform Your Body\n'),
                        TextSpan(
                          text: 'Transform Your Life',
                          style: TextStyle(color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(
                    width: 170,
                    child: Text(
                      'Stay consistent, stay strong with NeuroFit.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF65D300),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF65D300).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Explore Programs',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF0F172A)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Category Header + 3x2 Grid
  Widget _buildCategorySection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF65D300), size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening all $title modules...'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF0F172A),
                  ),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF22C55E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3x2 Grid of Icon Cards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.08,
          ),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            final badge = item['badge'] as String?;

            return GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Navigating to ${item['title']}...'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.015),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF65D300).withOpacity(0.35), width: 1.2),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: const Color(0xFF65D300),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Red Cart Badge
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
