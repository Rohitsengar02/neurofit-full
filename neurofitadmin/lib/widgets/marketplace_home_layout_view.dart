import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/marketplace_home_layout_service.dart';
import '../services/banners_backend_service.dart';
import '../services/category_backend_service.dart';
import '../services/products_backend_service.dart';
import 'skeleton_loader.dart';

class MarketplaceHomeLayoutView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const MarketplaceHomeLayoutView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<MarketplaceHomeLayoutView> createState() => _MarketplaceHomeLayoutViewState();
}

class _MarketplaceHomeLayoutViewState extends State<MarketplaceHomeLayoutView> {
  final MarketplaceHomeLayoutService _layoutService = MarketplaceHomeLayoutService();
  final BannersBackendService _banService = BannersBackendService();
  final CategoryBackendService _catService = CategoryBackendService();
  final ProductsBackendService _prodService = ProductsBackendService();

  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _layoutService.addListener(_onUpdate);
    _banService.addListener(_onUpdate);
    _catService.addListener(_onUpdate);
    _prodService.addListener(_onUpdate);

    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _layoutService.fetchLayoutSectionsFromFirestore(),
      _banService.fetchBannersFromFirestore(),
      _catService.fetchCategoriesFromFirestore(),
      _prodService.fetchProductsFromFirestore(),
    ]);
  }

  @override
  void dispose() {
    _layoutService.removeListener(_onUpdate);
    _banService.removeListener(_onUpdate);
    _catService.removeListener(_onUpdate);
    _prodService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _openAddOrEditSectionModal({LayoutSectionModel? sectionToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddOrEditSectionModalBottomSheet(
        sectionToEdit: sectionToEdit,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _openPhonePreview() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => _PhoneMockupPreviewDialog(
        sections: _layoutService.activeSections,
        banners: _banService.banners,
        categories: _catService.categories,
        products: _prodService.products,
      ),
    );
  }

  void _deleteSection(LayoutSectionModel s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Section?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to remove "${s.title}" from the mobile shop layout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _layoutService.deleteSection(s.id);
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fadeAnim = widget.fadeAnimations.isNotEmpty ? widget.fadeAnimations[0] : const AlwaysStoppedAnimation(1.0);
    final slideAnim = widget.slideAnimations.isNotEmpty ? widget.slideAnimations[0] : const AlwaysStoppedAnimation(Offset.zero);

    final allSections = _layoutService.sections;
    final filteredSections = _filterType == 'all' ? allSections : allSections.where((s) => s.type == _filterType).toList();

    final int totalActive = allSections.where((s) => s.isActive).length;
    final int bannerCount = allSections.where((s) => s.type == 'banners').length;
    final int categoryCount = allSections.where((s) => s.type == 'categories').length;
    final int productCount = allSections.where((s) => s.type == 'products').length;

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================================================================
            // 1. HERO CMS CONTROL BAR & HEADER
            // =========================================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shop Home Layout CMS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$totalActive of ${allSections.length} Sections Live in App',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Live Phone Preview Button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF334155), width: 1.5),
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _openPhonePreview,
                            icon: const Icon(Icons.phone_iphone_rounded, size: 16, color: Color(0xFF38BDF8)),
                            label: const Text('Live Phone Preview', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 8),
                          // Add Section Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                            ),
                            onPressed: () => _openAddOrEditSectionModal(),
                            icon: const Icon(Icons.add_circle_rounded, size: 16),
                            label: const Text('Add Section', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Quick Category Filters & Counters (Scrollable Horizontal)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickStatBadge('All (${allSections.length})', 'all', Icons.grid_view_rounded, const Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        _buildQuickStatBadge('Banners ($bannerCount)', 'banners', Icons.view_carousel_rounded, const Color(0xFFEC4899)),
                        const SizedBox(width: 8),
                        _buildQuickStatBadge('Categories ($categoryCount)', 'categories', Icons.category_rounded, const Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        _buildQuickStatBadge('Products ($productCount)', 'products', Icons.shopping_bag_rounded, const Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Sequence & Instructions Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.swap_vert_rounded, size: 18, color: Color(0xFF6366F1)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use Up/Down arrows to reorder sections. Changes show up right away.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // =========================================================================
            // 2. SECTIONS LIST WITH RICH PREVIEWS
            // =========================================================================
            if (_layoutService.isLoading && allSections.isEmpty)
              const SkeletonListView(count: 4)
            else if (filteredSections.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSections.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildRichSectionCard(
                  filteredSections[index],
                  index,
                  filteredSections.length,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatBadge(String label, String typeKey, IconData icon, Color badgeColor) {
    final isSelected = _filterType == typeKey;
    return GestureDetector(
      onTap: () => setState(() => _filterType = typeKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.dashboard_customize_outlined, size: 44, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 14),
          const Text('No Sections Found', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          const Text('Tap "+ Add Section" to build your custom dynamic shop experience.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. RICH SECTION CARD WITH 3-DOTS DROPDOWN ACTIONS
  // =========================================================================
  Widget _buildRichSectionCard(LayoutSectionModel s, int index, int totalCount) {
    Color typeColor = const Color(0xFF10B981);
    IconData typeIcon = Icons.shopping_bag_rounded;
    String typeLabel = 'PRODUCTS';

    if (s.type == 'banners') {
      typeColor = const Color(0xFFEC4899);
      typeIcon = Icons.view_carousel_rounded;
      typeLabel = 'BANNERS';
    } else if (s.type == 'categories') {
      typeColor = const Color(0xFFF59E0B);
      typeIcon = Icons.category_rounded;
      typeLabel = 'CATEGORIES';
    }

    final isCarousel = s.layoutMode == 'carousel' || s.layoutMode == 'hero_carousel';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: s.isActive ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
          width: s.isActive ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: s.isActive ? 0.03 : 0.01),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Order Index & Up/Down Reorder Arrows
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0)
                      GestureDetector(
                        onTap: () => _layoutService.reorderSections(index, index - 1),
                        child: const Icon(Icons.arrow_drop_up_rounded, size: 22, color: Color(0xFF64748B)),
                      )
                    else
                      const SizedBox(height: 18),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: s.isActive ? [const Color(0xFF0F172A), const Color(0xFF334155)] : [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (index < totalCount - 1)
                      GestureDetector(
                        onTap: () => _layoutService.reorderSections(index, index + 2),
                        child: const Icon(Icons.arrow_drop_down_rounded, size: 22, color: Color(0xFF64748B)),
                      )
                    else
                      const SizedBox(height: 18),
                  ],
                ),
                const SizedBox(width: 10),

                // Component Type Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 10),

                // Section Details (with Wrap for Badges so it never overflows)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: typeColor),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isCarousel ? Icons.swipe_rounded : Icons.grid_view_rounded, size: 9, color: const Color(0xFF0F172A)),
                                const SizedBox(width: 3),
                                Text(
                                  isCarousel ? 'CAROUSEL' : (s.type == 'banners' ? '2x2 GRID' : '2-COL GRID'),
                                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                          if (!s.showTitle)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF64748B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('HEADING HIDDEN', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.title.isNotEmpty ? s.title : 'Untitled Section',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: s.isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (s.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          s.subtitle,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                // Live Switch & 3-Dots Dropdown Actions Menu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: 0.82,
                        child: Switch(
                          value: s.isActive,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (v) {
                            _layoutService.toggleSectionStatus(s.id, v);
                          },
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFF475569)),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                      onSelected: (action) {
                        if (action == 'edit') {
                          _openAddOrEditSectionModal(sectionToEdit: s);
                        } else if (action == 'preview') {
                          _openPhonePreview();
                        } else if (action == 'up' && index > 0) {
                          _layoutService.reorderSections(index, index - 1);
                        } else if (action == 'down' && index < totalCount - 1) {
                          _layoutService.reorderSections(index, index + 2);
                        } else if (action == 'toggle') {
                          _layoutService.toggleSectionStatus(s.id, !s.isActive);
                        } else if (action == 'delete') {
                          _deleteSection(s);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 18, color: Color(0xFF6366F1)),
                              SizedBox(width: 10),
                              Text('Edit Section', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'preview',
                          child: Row(
                            children: [
                              Icon(Icons.phone_iphone_rounded, size: 18, color: Color(0xFF0284C7)),
                              SizedBox(width: 10),
                              Text('Live App Preview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (index > 0)
                          const PopupMenuItem(
                            value: 'up',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_upward_rounded, size: 18, color: Color(0xFF475569)),
                                SizedBox(width: 10),
                                Text('Move Up', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                          ),
                        if (index < totalCount - 1)
                          const PopupMenuItem(
                            value: 'down',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward_rounded, size: 18, color: Color(0xFF475569)),
                                SizedBox(width: 10),
                                Text('Move Down', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                          ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: const [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                              SizedBox(width: 10),
                              Text('Delete Section', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFEF4444))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mini Visual Content Preview Strip (Scrollable to prevent any overflow)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(17)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Live Preview:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                  const SizedBox(width: 8),
                  _buildSectionMiniThumbnails(s),
                  const SizedBox(width: 10),
                  Text(
                    _buildConfigSummary(s),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionMiniThumbnails(LayoutSectionModel s) {
    if (s.type == 'banners') {
      final banners = _banService.banners;
      List<BannerModel> target = banners;
      if (s.selectedItemIds.isNotEmpty) {
        final sel = banners.where((b) => s.selectedItemIds.contains(b.bannerId) || s.selectedItemIds.contains(b.id)).toList();
        if (sel.isNotEmpty) {
          target = sel;
        }
      }
      if (target.isEmpty) {
        return const Text('No banners available', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)));
      }
      return SizedBox(
        height: 32,
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: target.take(6).length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final b = target[i];
            return Container(
              width: 58,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFF0F172A),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                CategoryBackendService.getDisplayableImageUrl(b.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Center(child: Icon(Icons.image_rounded, size: 14, color: Colors.white54)),
                ),
              ),
            );
          },
        ),
      );
    } else if (s.type == 'categories') {
      final cats = _catService.categories;
      if (cats.isEmpty) {
        return const Text('No categories available', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)));
      }
      return SizedBox(
        height: 32,
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: cats.take(8).length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final c = cats[i];
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                CategoryBackendService.getDisplayableImageUrl(c.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.fitness_center_rounded, size: 14, color: Color(0xFF64748B)),
                ),
              ),
            );
          },
        ),
      );
    } else {
      final prods = _prodService.products;
      List<ProductItem> target = prods;
      if (s.filterSource == 'category' && (s.filterId.isNotEmpty || s.filterName.isNotEmpty)) {
        final filtered = prods.where((p) => p.categoryId == s.filterId || p.categoryName.toLowerCase() == s.filterName.toLowerCase()).toList();
        if (filtered.isNotEmpty) {
          target = filtered;
        }
      }
      if (target.isEmpty && prods.isNotEmpty) {
        target = prods;
      }
      if (target.isEmpty) {
        return const Text('No products available', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)));
      }
      return SizedBox(
        height: 32,
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: target.take(8).length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final p = target[i];
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFFF1F5F9),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                CategoryBackendService.getDisplayableImageUrl(p.mainImageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.shopping_bag_rounded, size: 14, color: Color(0xFF64748B)),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  String _buildConfigSummary(LayoutSectionModel s) {
    if (s.type == 'products') {
      if (s.filterSource == 'category' && s.filterName.isNotEmpty) {
        return 'Category "${s.filterName}" • Max ${s.itemLimit}';
      }
      return 'All Products (${_prodService.products.length}) • Max ${s.itemLimit}';
    } else if (s.type == 'banners') {
      final total = s.selectedItemIds.isNotEmpty ? s.selectedItemIds.length : _banService.banners.length;
      return '$total Banners';
    } else {
      return 'All Categories (${_catService.categories.length})';
    }
  }
}

// =========================================================================
// 4. ADD / EDIT SECTION MODAL BOTTOM SHEET
// =========================================================================
class _AddOrEditSectionModalBottomSheet extends StatefulWidget {
  final LayoutSectionModel? sectionToEdit;
  final VoidCallback onSaved;
  const _AddOrEditSectionModalBottomSheet({this.sectionToEdit, required this.onSaved});

  @override
  State<_AddOrEditSectionModalBottomSheet> createState() => _AddOrEditSectionModalBottomSheetState();
}

class _AddOrEditSectionModalBottomSheetState extends State<_AddOrEditSectionModalBottomSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late String _type;
  late String _layoutMode;
  late String _filterSource;
  late int _itemLimit;
  late bool _isActive;

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  List<String> _selectedBannerIds = [];
  bool _showTitle = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.sectionToEdit;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _subtitleCtrl = TextEditingController(text: s?.subtitle ?? '');
    _showTitle = s?.showTitle ?? true;
    _type = s?.type ?? 'products';
    _layoutMode = s?.layoutMode ?? 'carousel';
    _filterSource = s?.filterSource ?? 'all';
    _itemLimit = s?.itemLimit ?? 10;
    _isActive = s?.isActive ?? true;

    if (s != null) {
      _selectedCategoryId = (s.filterId.isNotEmpty) ? s.filterId : null;
      _selectedCategoryName = s.filterName;
      _selectedBannerIds = List.from(s.selectedItemIds);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    final title = _showTitle ? _titleCtrl.text.trim() : (_titleCtrl.text.trim().isNotEmpty ? _titleCtrl.text.trim() : 'Section');
    if (_showTitle && title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a section title')));
      return;
    }

    if (_type == 'banners' && _layoutMode == 'grid' && _selectedBannerIds.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A 2x2 Banner Grid can have at most 4 banners')));
      return;
    }

    setState(() => _isSaving = true);

    final String sectionId = widget.sectionToEdit?.id ?? 'sec_${DateTime.now().millisecondsSinceEpoch}';
    final int sortOrder = widget.sectionToEdit?.sortOrder ?? (MarketplaceHomeLayoutService().sections.length + 1);

    final section = LayoutSectionModel(
      id: sectionId,
      sectionId: sectionId,
      title: title,
      subtitle: _subtitleCtrl.text.trim(),
      showTitle: _showTitle,
      type: _type,
      layoutMode: _layoutMode,
      filterSource: _filterSource,
      filterId: _filterSource == 'category' ? (_selectedCategoryId ?? '') : '',
      filterName: _filterSource == 'category' ? (_selectedCategoryName ?? '') : '',
      selectedItemIds: _selectedBannerIds,
      itemLimit: _itemLimit,
      sortOrder: sortOrder,
      isActive: _isActive,
    );

    await MarketplaceHomeLayoutService().saveSection(section);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sectionToEdit != null;
    final categories = CategoryBackendService().categories;
    final banners = BannersBackendService().banners;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 44, height: 4.5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Layout Section' : 'Add New Layout Section',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const Text('Configure section component, layout mode, and filters', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SECTION COMPONENT TYPE
                  const Text('1. Section Component Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildComponentTypeCard('products', '🛍️ Products', 'Catalog products', const Color(0xFF10B981)),
                      const SizedBox(width: 10),
                      _buildComponentTypeCard('banners', '🖼️ Banners', 'Promotional sliders', const Color(0xFFEC4899)),
                      const SizedBox(width: 10),
                      _buildComponentTypeCard('categories', '📂 Categories', 'Browse categories', const Color(0xFFF59E0B)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. DISPLAY LAYOUT MODE
                  const Text('2. Display Layout Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLayoutModeCard(
                          'carousel',
                          'Horizontal Carousel',
                          'Swipeable single row',
                          Icons.swipe_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildLayoutModeCard(
                          'grid',
                          _type == 'banners' ? '2x2 Banner Grid' : '2-Column Grid',
                          'Multi-row grid layout',
                          Icons.grid_view_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. TITLE & SUBTITLE
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Show Heading in App', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            Material(
                              color: Colors.transparent,
                              child: Switch(
                                value: _showTitle,
                                activeColor: const Color(0xFF10B981),
                                onChanged: (v) => setState(() => _showTitle = v),
                              ),
                            ),
                          ],
                        ),
                        if (_showTitle) ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: _titleCtrl,
                            decoration: InputDecoration(
                              labelText: 'Section Title',
                              hintText: 'e.g. Trending Essentials 🔥, Top Deals',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _subtitleCtrl,
                            decoration: InputDecoration(
                              labelText: 'Optional Tagline / Subtitle',
                              hintText: 'e.g. Top rated gear loved by athletes',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. TYPE SPECIFIC CONTROLS
                  if (_type == 'products') ...[
                    const Text('3. Products Filter & Source', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All Products', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          selected: _filterSource == 'all',
                          onSelected: (v) => setState(() => _filterSource = 'all'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('By Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          selected: _filterSource == 'category',
                          onSelected: (v) => setState(() => _filterSource = 'category'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_filterSource == 'category') ...[
                      Builder(
                        builder: (context) {
                          final hasMatch = categories.any((c) => c.categoryId == _selectedCategoryId);
                          final selectedVal = hasMatch ? _selectedCategoryId : (categories.isNotEmpty ? categories.first.categoryId : null);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedVal,
                                items: categories
                                    .map((c) => DropdownMenuItem(
                                          value: c.categoryId,
                                          child: Text(c.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedCategoryId = val;
                                      _selectedCategoryName = categories.firstWhere((c) => c.categoryId == val).name;
                                    });
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        const Text('Product Limit: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: [4, 6, 8, 10, 12, 16, 20].contains(_itemLimit) ? _itemLimit : 10,
                          items: [4, 6, 8, 10, 12, 16, 20]
                              .map((n) => DropdownMenuItem(value: n, child: Text('$n Items', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))))
                              .toList(),
                          onChanged: (v) => setState(() => _itemLimit = v ?? 10),
                        ),
                      ],
                    ),
                  ],

                  if (_type == 'banners') ...[
                    const Text('3. Select Banners to Include', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    if (banners.isEmpty)
                      const Text('No banners found. Create banners in the Banners sub-tab first.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: banners.map((b) {
                          final isSel = _selectedBannerIds.contains(b.bannerId) || _selectedBannerIds.contains(b.id);
                          return FilterChip(
                            avatar: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                CategoryBackendService.getDisplayableImageUrl(b.imageUrl),
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 14),
                              ),
                            ),
                            label: Text(b.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            selected: isSel,
                            onSelected: (sel) {
                              setState(() {
                                if (sel) {
                                  _selectedBannerIds.add(b.bannerId);
                                } else {
                                  _selectedBannerIds.remove(b.bannerId);
                                  _selectedBannerIds.remove(b.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],

                  const SizedBox(height: 30),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEditing ? 'Update Layout Section' : 'Save & Publish Section', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentTypeCard(String typeKey, String title, String subtitle, Color color) {
    final isSelected = _type == typeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = typeKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0), width: isSelected ? 2.0 : 1.0),
          ),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isSelected ? color : const Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutModeCard(String modeKey, String title, String subtitle, IconData icon) {
    final isSelected = _layoutMode == modeKey;
    return GestureDetector(
      onTap: () => setState(() => _layoutMode = modeKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A).withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155))),
                  Text(subtitle, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 5. LIVE PHONE PREVIEW DIALOG (INTERACTIVE ATHLETE APP MOCKUP)
// =========================================================================
class _PhoneMockupPreviewDialog extends StatelessWidget {
  final List<LayoutSectionModel> sections;
  final List<BannerModel> banners;
  final List<CategoryModel> categories;
  final List<ProductItem> products;

  const _PhoneMockupPreviewDialog({
    required this.sections,
    required this.banners,
    required this.categories,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          width: 380,
          height: 720,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(44),
            border: Border.all(color: const Color(0xFF334155), width: 6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Top Phone Notch & Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                color: Colors.white,
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 100,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Live Shop Preview', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Phone Body
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    itemCount: sections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) {
                      final sec = sections[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sec.showTitle && sec.title.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text(
                                sec.title,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
                              ),
                            ),
                          if (sec.type == 'banners')
                            SizedBox(
                              height: 100,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: banners.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (c, idx) => ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    CategoryBackendService.getDisplayableImageUrl(banners[idx].imageUrl),
                                    width: 220,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          else if (sec.type == 'categories')
                            SizedBox(
                              height: 60,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 10),
                                itemBuilder: (c, idx) => Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0)),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.network(
                                        CategoryBackendService.getDisplayableImageUrl(categories[idx].imageUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(categories[idx].name, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 140,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: products.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (c, idx) => Container(
                                  width: 100,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                        child: Image.network(
                                          CategoryBackendService.getDisplayableImageUrl(products[idx].mainImageUrl),
                                          width: 100,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(products[idx].title, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text('₹${products[idx].price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
