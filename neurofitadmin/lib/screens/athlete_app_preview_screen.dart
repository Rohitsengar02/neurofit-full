import 'package:flutter/material.dart';
import '../services/banners_backend_service.dart';
import '../services/category_backend_service.dart';
import '../services/products_backend_service.dart';
import '../services/exercises_backend_service.dart';
import '../services/fitness_cms_backend_service.dart';
import '../services/plans_backend_service.dart';

class AthleteAppPreviewScreen extends StatefulWidget {
  const AthleteAppPreviewScreen({super.key});

  @override
  State<AthleteAppPreviewScreen> createState() => _AthleteAppPreviewScreenState();
}

class _AthleteAppPreviewScreenState extends State<AthleteAppPreviewScreen> {
  int _currentNavIndex = 0; // 0: Home, 1: Marketplace, 2: Fitness, 3: AI Coach, 4: Profile
  bool _isMobileFrame = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Column(
          children: [
            // Top Switcher Bar (Back to Admin HQ)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
              ),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Back to Admin HQ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                        SizedBox(width: 4),
                        Text('ATHLETE APP LIVE PREVIEW', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: _isMobileFrame ? 'Expand Fullscreen' : 'Mobile Phone Frame',
                    icon: Icon(_isMobileFrame ? Icons.fullscreen_rounded : Icons.phone_android_rounded, color: Colors.white70),
                    onPressed: () => setState(() => _isMobileFrame = !_isMobileFrame),
                  ),
                ],
              ),
            ),

            // Main Preview Area
            Expanded(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: _isMobileFrame ? 420 : double.infinity,
                    maxHeight: _isMobileFrame ? 860 : double.infinity,
                  ),
                  margin: _isMobileFrame ? const EdgeInsets.symmetric(vertical: 16) : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: const Color(0xFF030712),
                    borderRadius: _isMobileFrame ? BorderRadius.circular(36) : BorderRadius.zero,
                    border: _isMobileFrame ? Border.all(color: const Color(0xFF334155), width: 3) : null,
                    boxShadow: _isMobileFrame
                        ? [
                            BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10)),
                            BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 40),
                          ]
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Scaffold(
                    backgroundColor: const Color(0xFF030712),
                    body: _buildSelectedTabScreen(),
                    bottomNavigationBar: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B1120),
                        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
                      ),
                      child: BottomNavigationBar(
                        currentIndex: _currentNavIndex,
                        onTap: (idx) => setState(() => _currentNavIndex = idx),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        selectedItemColor: const Color(0xFF6366F1),
                        unselectedItemColor: const Color(0xFF64748B),
                        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 9.5),
                        type: BottomNavigationBarType.fixed,
                        items: const [
                          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Shop'),
                          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_rounded), label: 'Fitness'),
                          BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'AI Coach'),
                          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabScreen() {
    switch (_currentNavIndex) {
      case 0:
        return _buildAthleteHomeScreen();
      case 1:
        return _buildAthleteShopScreen();
      case 2:
        return _buildAthleteFitnessScreen();
      case 3:
        return _buildAthleteAiCoachScreen();
      case 4:
        return _buildAthleteProfileScreen();
      default:
        return _buildAthleteHomeScreen();
    }
  }

  // ================= 1. HOME SCREEN =================
  Widget _buildAthleteHomeScreen() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        // Athlete Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF6366F1), width: 2),
                    image: const DecorationImage(
                      image: NetworkImage('https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/whey_protein.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Welcome back,', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    Text('Rohit Sharma', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 16),
                  SizedBox(width: 4),
                  Text('14 Day Streak', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Live Step & Calorie Ring Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DAILY TARGETS', style: TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(4)),
                    child: const Text('78% COMPLETED', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricStat('8,420', 'Steps', 'Goal: 10k', Icons.directions_walk_rounded, const Color(0xFF10B981)),
                  _buildMetricStat('640', 'kcal', 'Burned', Icons.local_fire_department_rounded, const Color(0xFFEF4444)),
                  _buildMetricStat('2.4L', 'Water', 'Goal: 3.5L', Icons.water_drop_rounded, const Color(0xFF38BDF8)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick Routine Start
        const Text('Today\'s AI Workout', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/gym_equipment.jpg',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(width: 70, height: 70, color: const Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Hypertrophy Chest & Delts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5)),
                    SizedBox(height: 4),
                    Text('5 Exercises • 45 Mins • 4 Sets', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricStat(String val, String unit, String sub, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(unit, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w700)),
        Text(sub, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
      ],
    );
  }

  // ================= 2. SHOP / MARKETPLACE =================
  Widget _buildAthleteShopScreen() {
    final banners = BannersBackendService().banners;
    final categories = CategoryBackendService().categories;
    final products = ProductsBackendService().products;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Search & Filter
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
                child: Row(
                  children: const [
                    Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                    SizedBox(width: 8),
                    Text('Search Whey, Gear, Shoes...', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
              child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Live Hero Carousel Banner
        if (banners.isNotEmpty) ...[
          Container(
            height: 150,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFF0F172A)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Image.network(banners.first.imageUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: const Color(0xFF1E293B))),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.black.withOpacity(0.85), Colors.transparent]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(4)),
                        child: const Text('PROMOTED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 6),
                      Text(banners.first.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900), maxLines: 2),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Text(banners.first.buttonText, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Categories Row
        const Text('Explore Categories', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (c, i) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                width: 75,
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E293B))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(cat.imageUrl, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.category_rounded, color: Color(0xFF6366F1))),
                    ),
                    const SizedBox(height: 4),
                    Text(cat.name, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Featured Products Grid
        const Text('Popular Athlete Gear & Supplements', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.72),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Container(
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E293B))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(p.mainImageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: const Color(0xFF1E293B))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text('₹${p.price.toInt()}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w900)),
                            const SizedBox(width: 4),
                            Text('₹${p.regularPrice.toInt()}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ================= 3. FITNESS SCREEN =================
  Widget _buildAthleteFitnessScreen() {
    final cms = FitnessCmsBackendService().banners;
    final exercises = ExercisesBackendService().exercises;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text('Workout & Exercises Hub', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),

        if (cms.isNotEmpty) ...[
          Container(
            height: 140,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0xFF0F172A)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Image.network(cms.first.imageUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: const Color(0xFF1E293B))),
                Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.85), Colors.transparent]))),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(4)),
                        child: Text(cms.first.badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 4),
                      Text(cms.first.title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(cms.first.subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        const Text('Movement Library (GIF & Video Demos)', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exercises.length,
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final ex = exercises[index];
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E293B))),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(ex.mediaUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: const Color(0xFF1E293B))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text(ex.mediaType.toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontSize: 8, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 2),
                        Text(ex.title, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                        Text(ex.muscleGroup, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 14),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ================= 4. AI COACH SCREEN =================
  Widget _buildAthleteAiCoachScreen() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('NeuroFit AI Coach', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  Text('Online • Hypertrophy & Nutrition Expert', style: TextStyle(color: Color(0xFF10B981), fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildChatBubble('Hello Rohit! I have optimized your training split for high hypertrophy and chest recovery. What are your goals today?', false),
              _buildChatBubble('Can you give me a high-protein vegetarian meal plan for 2500 kcal?', true),
              _buildChatBubble('Here is your custom 2,500 kcal plan: 160g Protein, 280g Carbs, 65g Fats including Whey Isolate Shake, Tofu Lentil Bowl & Greek Yogurt snack.', false),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Color(0xFF0F172A), border: Border(top: BorderSide(color: Color(0xFF1E293B)))),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: const Color(0xFF030712), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF1E293B))),
                  child: const TextField(
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(hintText: 'Ask AI Coach anything...', hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12), border: InputBorder.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(String msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.4)),
      ),
    );
  }

  // ================= 5. PROFILE & SUBSCRIPTION =================
  Widget _buildAthleteProfileScreen() {
    final plans = PlansBackendService().plans;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6366F1), width: 2),
                  image: const DecorationImage(
                    image: NetworkImage('https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/whey_protein.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Rohit Sharma', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              const Text('rohit@athlete.neurofit.app', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(20)),
                child: const Text('PRO ATHLETE MEMBER', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text('Active Plan & Membership', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),

        if (plans.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plans.first.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(plans.first.tagline, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                const Divider(color: Color(0xFF334155), height: 20),
                ...plans.first.features.take(3).map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 6),
                      Text(f, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
