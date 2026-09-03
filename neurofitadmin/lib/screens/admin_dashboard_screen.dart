import 'athlete_app_preview_screen.dart';
import '../widgets/marketplace_banners_view.dart';
import '../widgets/marketplace_home_layout_view.dart';
import '../widgets/notifications_center_sheet.dart';
import '../widgets/admin_profile_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/dashboard_top_nav_widget.dart';
import '../widgets/dashboard_sub_nav_widget.dart';
import '../widgets/upload_progress_overlay.dart';
import '../widgets/analytics_overview_view.dart';
import '../widgets/user_analytics_view.dart';
import '../widgets/fitness_analytics_view.dart';
import '../widgets/nutrition_analytics_view.dart';
import '../widgets/trainers_analytics_view.dart';
import '../widgets/marketplace_analytics_view.dart';
import '../widgets/revenue_analytics_view.dart';
import '../widgets/orders_analytics_view.dart';
import '../widgets/reports_overview_view.dart';

import '../widgets/active_users_view.dart';
import '../widgets/new_users_view.dart';
import '../widgets/premium_users_view.dart';
import '../widgets/user_verification_view.dart';
import '../widgets/user_reports_view.dart';

import '../widgets/fitness_workouts_view.dart';
import '../widgets/fitness_exercises_view.dart';
import '../widgets/fitness_programs_view.dart';
import '../widgets/fitness_cms_view.dart';
import '../widgets/fitness_workout_layout_view.dart';
import '../widgets/fitness_workout_categories_view.dart';

import '../widgets/nutrition_recipes_view.dart';
import '../widgets/nutrition_food_items_view.dart';
import '../widgets/nutrition_diet_plans_view.dart';

import '../widgets/trainers_list_view.dart';
import '../widgets/trainer_applications_view.dart';

import '../widgets/marketplace_products_view.dart';
import '../widgets/marketplace_add_product_view.dart';
import '../widgets/marketplace_categories_view.dart';
import '../widgets/marketplace_orders_view.dart';
import '../widgets/marketplace_discounts_view.dart';
import '../widgets/marketplace_vendors_view.dart';

import '../widgets/subscriptions_management_view.dart';
import '../widgets/subscribers_directory_view.dart';
import '../widgets/generic_category_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  int _selectedCategoryIndex = 0;
  int _selectedSubActionIndex = 0;
  String _selectedDateRange = 'Last 30 Days';
  bool _isLoading = false;
  bool _isSubNavLoading = false;

  late AnimationController _staggerController;
  late AnimationController _subNavStaggerController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  // 9 PRIMARY MAIN CATEGORIES
    final List<Map<String, dynamic>> _primaryCategories = const [
    {
      'name': 'Overview',
      'icon': Icons.space_dashboard_rounded,
      'color': Color(0xFF6366F1),
    },
    {
      'name': 'Users',
      'icon': Icons.people_alt_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'name': 'Fitness',
      'icon': Icons.fitness_center_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'name': 'Nutrition',
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'name': 'Trainers',
      'icon': Icons.sports_gymnastics_rounded,
      'color': Color(0xFF06B6D4),
    },
    {
      'name': 'Marketplace',
      'icon': Icons.storefront_rounded,
      'color': Color(0xFFEC4899),
    },
    {
      'name': 'Financials',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'name': 'Subscriptions',
      'icon': Icons.card_membership_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'name': 'Reports',
      'icon': Icons.insights_rounded,
      'color': Color(0xFFEF4444),
    },
  ];

  // SUB-ACTIONS MAP FOR ALL 9 CATEGORIES
    final Map<String, List<Map<String, dynamic>>> _categorySubActions = {
    'Overview': [
      {
        'title': 'Overview',
        'icon': Icons.space_dashboard_rounded,
        'color': Color(0xFF6366F1),
      },
      {
        'title': 'Revenue',
        'icon': Icons.account_balance_wallet_rounded,
        'color': Color(0xFF10B981),
      },
      {
        'title': 'Users',
        'icon': Icons.people_alt_rounded,
        'color': Color(0xFF3B82F6),
      },
      {
        'title': 'Fitness',
        'icon': Icons.fitness_center_rounded,
        'color': Color(0xFF8B5CF6),
      },
      {
        'title': 'Nutrition',
        'icon': Icons.restaurant_rounded,
        'color': Color(0xFF10B981),
      },
      {
        'title': 'Trainers',
        'icon': Icons.sports_gymnastics_rounded,
        'color': Color(0xFF06B6D4),
      },
      {
        'title': 'Marketplace',
        'icon': Icons.storefront_rounded,
        'color': Color(0xFFEC4899),
      },
      {
        'title': 'Orders',
        'icon': Icons.shopping_bag_rounded,
        'color': Color(0xFFE11D48),
      },
      {
        'title': 'Reports',
        'icon': Icons.analytics_rounded,
        'color': Color(0xFFEF4444),
      },
    ],
    'Users': [
      {
        'title': 'Analytics',
        'icon': Icons.insights_rounded,
        'color': Color(0xFF3B82F6),
      },
      {
        'title': 'Active Users',
        'icon': Icons.bolt_rounded,
        'color': Color(0xFF10B981),
      },
      {
        'title': 'New Users',
        'icon': Icons.person_add_rounded,
        'color': Color(0xFF06B6D4),
      },
      {
        'title': 'VIP Users',
        'icon': Icons.workspace_premium_rounded,
        'color': Color(0xFFF59E0B),
      },
      {
        'title': 'Verification',
        'icon': Icons.verified_user_rounded,
        'color': Color(0xFF8B5CF6),
        'badge': '8',
        'badgeColor': Color(0xFF3B82F6),
      },
      {
        'title': 'Reports',
        'icon': Icons.report_problem_rounded,
        'color': Color(0xFFEF4444),
        'badge': '3',
        'badgeColor': Color(0xFFEF4444),
      },
    ],
    'Fitness': [
      {
        'title': 'Workout Layout',
        'icon': Icons.dashboard_customize_rounded,
        'color': Color(0xFF10B981),
      },
      {
        'title': 'Categories',
        'icon': Icons.category_rounded,
        'color': Color(0xFFF59E0B),
      },
      {
        'title': 'Analytics',
        'icon': Icons.insights_rounded,
        'color': Color(0xFF8B5CF6),
      },
      {
        'title': 'Workouts',
        'icon': Icons.fitness_center_rounded,
        'color': Color(0xFF3B82F6),
      },
      {
        'title': 'Exercises',
        'icon': Icons.sports_gymnastics_rounded,
        'color': Color(0xFF10B981),
      },
      {
        'title': 'Programs',
        'icon': Icons.calendar_today_rounded,
        'color': Color(0xFFF59E0B),
      },
      {
        'title': 'CMS & Banners',
        'icon': Icons.view_carousel_rounded,
        'color': Color(0xFF06B6D4),
      },
    ],
    'Nutrition': [
      {
        'title': 'Analytics',
        'icon': Icons.insights_rounded,
        'color': Color(0xFF10B981),
      },
      {
        'title': 'Recipes',
        'icon': Icons.menu_book_rounded,
        'color': Color(0xFF10B981),
      },
      {
        'title': 'Food Items',
        'icon': Icons.kitchen_rounded,
        'color': Color(0xFF3B82F6),
      },
      {
        'title': 'Diet Plans',
        'icon': Icons.restaurant_menu_rounded,
        'color': Color(0xFF8B5CF6),
      },
    ],
    'Trainers': [
      {
        'title': 'Analytics',
        'icon': Icons.insights_rounded,
        'color': Color(0xFF06B6D4),
      },
      {
        'title': 'All Coaches',
        'icon': Icons.groups_rounded,
        'color': Color(0xFF3B82F6),
      },
      {
        'title': 'Applications',
        'icon': Icons.assignment_ind_rounded,
        'color': Color(0xFFF59E0B),
        'badge': '14',
        'badgeColor': Color(0xFFEF4444),
      },
      {
        'title': 'Premium',
        'icon': Icons.workspace_premium_rounded,
        'color': Color(0xFFF59E0B),
      },
      {
        'title': 'Manage',
        'icon': Icons.manage_accounts_rounded,
        'color': Color(0xFF10B981),
      },
    ],
    'Marketplace': [
      {
        'title': 'Home Layout',
        'icon': Icons.dashboard_customize_rounded,
        'color': Color(0xFF10B981),
      },
      {
        'title': 'Content Update',
        'icon': Icons.view_carousel_rounded,
        'color': Color(0xFFF59E0B),
      },
      {
        'title': 'Analytics',
        'icon': Icons.insights_rounded,
        'color': Color(0xFFEC4899),
      },
      {
        'title': 'Products',
        'icon': Icons.inventory_2_rounded,
        'color': Color(0xFF3B82F6),
      },
      {
        'title': 'Add Item',
        'icon': Icons.add_business_rounded,
        'color': Color(0xFF10B981),
      },
      {
        'title': 'Categories',
        'icon': Icons.category_rounded,
        'color': Color(0xFF8B5CF6),
      },
      {
        'title': 'Sub Categories',
        'icon': Icons.account_tree_rounded,
        'color': Color(0xFF06B6D4),
      },
      {
        'title': 'Orders',
        'icon': Icons.local_shipping_rounded,
        'color': Color(0xFFF59E0B),
      },
      {
        'title': 'Discounts',
        'icon': Icons.discount_rounded,
        'color': Color(0xFFE11D48),
      },
      {
        'title': 'Vendors',
        'icon': Icons.store_mall_directory_rounded,
        'color': Color(0xFF16A34A),
      },
      {
        'title': 'Customers',
        'icon': Icons.people_alt_rounded,
        'color': Color(0xFF6366F1),
      },
    ],
    'Financials': [
      {
        'title': 'Revenue',
        'icon': Icons.insights_rounded,
        'color': Color(0xFF10B981),
      },
      {
        'title': 'Orders GMV',
        'icon': Icons.shopping_cart_checkout_rounded,
        'color': Color(0xFFF59E0B),
      },
      {
        'title': 'Subscriptions',
        'icon': Icons.card_membership_rounded,
        'color': Color(0xFF8B5CF6),
      },
      {
        'title': 'Subscribers',
        'icon': Icons.people_alt_rounded,
        'color': Color(0xFF3B82F6),
      },
    ],
    'Subscriptions': [
      {
        'title': 'Manage Plans',
        'icon': Icons.card_membership_rounded,
        'color': Color(0xFF8B5CF6),
      },
      {
        'title': 'Subscribers',
        'icon': Icons.groups_rounded,
        'color': Color(0xFF3B82F6),
      },
      {
        'title': 'Revenue',
        'icon': Icons.account_balance_wallet_rounded,
        'color': Color(0xFF10B981),
      },
    ],
    'Reports': [
      {
        'title': 'Overview',
        'icon': Icons.insights_rounded,
        'color': Color(0xFFEF4444),
      },
      {
        'title': 'Moderation',
        'icon': Icons.report_problem_rounded,
        'color': Color(0xFFEF4444),
        'badge': '3',
      },
      {
        'title': 'Verification',
        'icon': Icons.verified_user_rounded,
        'color': Color(0xFF3B82F6),
        'badge': '8',
      },
    ],
  };

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _subNavStaggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimations = List.generate(
      6,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            index * 0.12,
            (index * 0.12) + 0.4 > 1.0 ? 1.0 : (index * 0.12) + 0.4,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _slideAnimations = List.generate(
      6,
      (index) => Tween<Offset>(begin: const Offset(0.0, 0.08), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _staggerController,
              curve: Interval(
                index * 0.12,
                (index * 0.12) + 0.4 > 1.0 ? 1.0 : (index * 0.12) + 0.4,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
    );

    _staggerController.forward();
    _subNavStaggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _subNavStaggerController.dispose();
    super.dispose();
  }

  void _onCategorySelected(int index) {
    if (_selectedCategoryIndex == index) return;
    setState(() {
      _selectedCategoryIndex = index;
      _selectedSubActionIndex = 0;
      _isSubNavLoading = true;
    });

    _subNavStaggerController.reset();
    _staggerController.reset();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isSubNavLoading = false;
        });
        _subNavStaggerController.forward();
        _staggerController.forward();
      }
    });
  }

  void _onSubActionSelected(int index) {
    if (_selectedSubActionIndex == index) return;
    setState(() {
      _selectedSubActionIndex = index;
    });
    _staggerController.reset();
    _staggerController.forward();
  }

  void _onDateRangeChanged(String newRange) {
    setState(() {
      _selectedDateRange = newRange;
      _isLoading = true;
    });
    _staggerController.reset();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _staggerController.forward();
      }
    });
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationsCenterSheet(),
    );
  }

  void _showAdminProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AdminProfileBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = _primaryCategories[_selectedCategoryIndex];
    final String currentCategoryName = currentCategory['name'] as String;
    final Color activeCatColor = currentCategory['color'] as Color;
    final currentSubActions = _categorySubActions[currentCategoryName] ?? [];

    final String selectedSubActionTitle =
        currentSubActions.isNotEmpty &&
            _selectedSubActionIndex < currentSubActions.length
        ? currentSubActions[_selectedSubActionIndex]['title'] as String
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            // Top App Bar Header (Logo, Name, Notifications with Badge, Date Picker, Profile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  // 1. NeuroFit Logo Image & App Name
                  Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'NEUROFIT',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Admin HQ',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),



                  // 2. Date Range Picker
                  GestureDetector(
                    onTap: _openDatePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedDateRange,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Notification Bell with Badge
                  GestureDetector(
                    onTap: _showNotificationsModal,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 17,
                            color: Color(0xFF334155),
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3.5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 4. Admin Profile Avatar
                  GestureDetector(
                    onTap: _showAdminProfileModal,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF6366F1),
                              width: 1.2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/trainers_hero_banner.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.person,
                                size: 18,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Full Vertically Scrollable Screen (Tabs + Content Scroll Together)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                        strokeWidth: 2.5,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Horizontal Primary Category Tabs
                          DashboardTopNavWidget(
                            primaryCategories: _primaryCategories,
                            selectedCategoryIndex: _selectedCategoryIndex,
                            onCategorySelected: _onCategorySelected,
                          ),

                          // 2. HR Divider between Main Tabs and Sub Tabs Only
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF1F5F9),
                          ),

                          // 3. Secondary Dynamic Sub Navigation Bar
                          DashboardSubNavWidget(
                            subActions: currentSubActions,
                            selectedSubActionIndex: _selectedSubActionIndex,
                            activeCatColor: activeCatColor,
                            isSubNavLoading: _isSubNavLoading,
                            subNavStaggerController: _subNavStaggerController,
                            onSubActionSelected: _onSubActionSelected,
                          ),

                          // 4. Dynamic Main Body Content
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            child: _buildDynamicBodyContent(
                              currentCategoryName,
                              selectedSubActionTitle,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
          const BottomRightUploadOverlay(),
        ],
      ),
    );
  }

    Widget _buildDynamicBodyContent(String categoryName, String subActionTitle) {
    if (categoryName == 'Overview') {
      if (subActionTitle == 'Revenue' || subActionTitle == 'Revenue Analytics') {
        return RevenueAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Users' || subActionTitle == 'Users Analytics') {
        return UserAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Fitness' || subActionTitle == 'Fitness Analytics') {
        return FitnessAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Nutrition' || subActionTitle == 'Nutrition Analytics') {
        return NutritionAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Trainers' || subActionTitle == 'Trainers Analytics') {
        return TrainersAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Marketplace' || subActionTitle == 'Marketplace Analytics') {
        return MarketplaceAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Orders' || subActionTitle == 'Orders Analytics') {
        return OrdersAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Reports' || subActionTitle == 'Reports Overview') {
        return ReportsOverviewView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      }
      return AnalyticsOverviewView(
        selectedDateRange: _selectedDateRange,
        fadeAnimations: _fadeAnimations,
        slideAnimations: _slideAnimations,
      );
    }

    if (categoryName == 'Users') {
      if (subActionTitle == 'Analytics' || subActionTitle == 'User Analytics') {
        return UserAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Active Users') {
        return ActiveUsersView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'New Users' || subActionTitle == 'New Registrations') {
        return NewUsersView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'VIP Users' || subActionTitle == 'VIP Platinum' || subActionTitle == 'Premium') {
        return PremiumUsersView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Verification' || subActionTitle == 'User Verification') {
        return UserVerificationView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Reports' || subActionTitle == 'Reports & Issues') {
        return UserReportsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      }
      return ActiveUsersView(
        selectedDateRange: _selectedDateRange,
        fadeAnimations: _fadeAnimations,
        slideAnimations: _slideAnimations,
      );
    }

    if (categoryName == 'Fitness') {
      if (subActionTitle == 'Workout Layout' || subActionTitle == 'Layout Studio') {
        return FitnessWorkoutLayoutView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Categories' || subActionTitle == 'Workout Categories') {
        return FitnessWorkoutCategoriesView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Analytics' || subActionTitle == 'Fitness Analytics') {
        return FitnessAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Workouts') {
        return FitnessWorkoutsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Exercises') {
        return FitnessExercisesView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Programs') {
        return FitnessProgramsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'CMS & Banners' || subActionTitle == 'Content Management') {
        return FitnessCmsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      }
      return FitnessAnalyticsView(
        selectedDateRange: _selectedDateRange,
        fadeAnimations: _fadeAnimations,
        slideAnimations: _slideAnimations,
      );
    }

    if (categoryName == 'Nutrition') {
      if (subActionTitle == 'Analytics' || subActionTitle == 'Nutrition Analytics') {
        return NutritionAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Recipes') {
        return NutritionRecipesView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Food Items' || subActionTitle == 'Food Database') {
        return NutritionFoodItemsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Diet Plans' || subActionTitle == 'Meal Plans') {
        return NutritionDietPlansView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      }
      return NutritionAnalyticsView(
        selectedDateRange: _selectedDateRange,
        fadeAnimations: _fadeAnimations,
        slideAnimations: _slideAnimations,
      );
    }

    if (categoryName == 'Trainers') {
      if (subActionTitle == 'Analytics' || subActionTitle == 'Trainer Analytics') {
        return TrainersAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'All Coaches' || subActionTitle == 'All Trainers') {
        return TrainersListView(
          selectedDateRange: _selectedDateRange,
          viewMode: 'all',
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Applications' || subActionTitle == 'Trainer Applications') {
        return TrainerApplicationsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Premium' || subActionTitle == 'Premium Trainers') {
        return TrainersListView(
          selectedDateRange: _selectedDateRange,
          viewMode: 'premium',
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Manage' || subActionTitle == 'Manage Trainers') {
        return TrainersListView(
          selectedDateRange: _selectedDateRange,
          viewMode: 'manage',
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      }
      return TrainersAnalyticsView(
        selectedDateRange: _selectedDateRange,
        fadeAnimations: _fadeAnimations,
        slideAnimations: _slideAnimations,
      );
    }

    if (categoryName == 'Marketplace') {
      if (subActionTitle == 'Home Layout' || subActionTitle == 'Home CMS') {
        return MarketplaceHomeLayoutView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Content Update' || subActionTitle == 'Banners & Content') {
        return MarketplaceBannersView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Analytics' || subActionTitle == 'Marketplace Analytics') {
        return MarketplaceAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Products') {
        return MarketplaceProductsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Add Item' || subActionTitle == 'Add Product') {
        return MarketplaceAddProductView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Categories') {
        return MarketplaceCategoriesView(
          selectedDateRange: _selectedDateRange,
          isSubCategories: false,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Sub Categories') {
        return MarketplaceCategoriesView(
          selectedDateRange: _selectedDateRange,
          isSubCategories: true,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Orders') {
        return MarketplaceOrdersView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Discounts') {
        return MarketplaceDiscountsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Vendors') {
        return MarketplaceVendorsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Customers') {
        return MarketplaceCustomersView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      }
      return MarketplaceAnalyticsView(
        selectedDateRange: _selectedDateRange,
        fadeAnimations: _fadeAnimations,
        slideAnimations: _slideAnimations,
      );
    }

    if (categoryName == 'Financials' || categoryName == 'Revenue') {
      if (subActionTitle == 'Orders GMV' || subActionTitle == 'Orders Analytics' || subActionTitle == 'Orders') {
        return OrdersAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Subscriptions') {
        return SubscriptionsManagementView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Subscribers') {
        return SubscribersDirectoryView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      }
      return RevenueAnalyticsView(
        selectedDateRange: _selectedDateRange,
        fadeAnimations: _fadeAnimations,
        slideAnimations: _slideAnimations,
      );
    }

    if (categoryName == 'Subscriptions') {
      if (subActionTitle == 'Subscribers') {
        return SubscribersDirectoryView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Revenue') {
        return RevenueAnalyticsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      }
      return SubscriptionsManagementView(
        selectedDateRange: _selectedDateRange,
        fadeAnimations: _fadeAnimations,
        slideAnimations: _slideAnimations,
      );
    }

    if (categoryName == 'Reports') {
      if (subActionTitle == 'Moderation') {
        return UserReportsView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      } else if (subActionTitle == 'Verification') {
        return UserVerificationView(
          selectedDateRange: _selectedDateRange,
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
        );
      }
      return ReportsOverviewView(
        selectedDateRange: _selectedDateRange,
        fadeAnimations: _fadeAnimations,
        slideAnimations: _slideAnimations,
      );
    }

    return GenericCategoryView(
      categoryName: categoryName,
      subActionTitle: subActionTitle,
      categoryColor: const Color(0xFF6366F1),
      fadeAnimations: _fadeAnimations,
      slideAnimations: _slideAnimations,
    );
  }

  void _openDatePicker() {
    final ranges = [
      'Today',
      'Yesterday',
      'Last 7 Days',
      'Last 30 Days',
      'This Month',
      'Last Month',
      'Custom Range',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Analytics Time Period',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
            ...ranges.map((r) {
              final isSelected = _selectedDateRange == r;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF94A3B8),
                  size: 18,
                ),
                title: Text(
                  r,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF475569),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (r == 'Custom Range') {
                    _buildCustomDatePickerModal();
                  } else {
                    _onDateRangeChanged(r);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _buildCustomDatePickerModal() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      final formatted =
          '${formatter.format(picked.start)} - ${formatter.format(picked.end)}';
      _onDateRangeChanged(formatted);
    }
  }
}