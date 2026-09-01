import 'skeleton_loader.dart';
import 'package:flutter/material.dart';
import '../services/marketplace_home_layout_service.dart';
import '../services/banners_backend_service.dart';
import '../services/category_backend_service.dart';
import '../services/products_backend_service.dart';

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

  @override
  void initState() {
    super.initState();
    _layoutService.addListener(_onUpdate);
    _banService.addListener(_onUpdate);
    _catService.addListener(_onUpdate);
    _prodService.addListener(_onUpdate);

    if (_layoutService.sections.isEmpty) {
      _layoutService.fetchLayoutSectionsFromFirestore();
    }
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

  @override
  Widget build(BuildContext context) {
    final fadeAnim = widget.fadeAnimations.isNotEmpty
        ? widget.fadeAnimations[0]
        : const AlwaysStoppedAnimation(1.0);
    final slideAnim = widget.slideAnimations.isNotEmpty
        ? widget.slideAnimations[0]
        : const AlwaysStoppedAnimation(Offset.zero);

    final sections = _layoutService.sections;

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shop Home Layout CMS',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            '${sections.length} Configured Dynamic Sections',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => _openAddOrEditSectionModal(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Section', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Info Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF475569)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reorder sections using the Up/Down arrows. Sections render in the Athlete Mobile Shop screen in this exact sequence.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sections List
            if (_layoutService.isLoading && sections.isEmpty)
              const SkeletonListView(count: 4)
            else if (sections.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sections.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildSectionCard(sections[index], index, sections.length),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.dashboard_outlined, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          const Text('No Layout Sections Configured', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Tap "+ Add Section" above to design your shop home page.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildSectionCard(LayoutSectionModel s, int index, int totalCount) {
    Color typeColor = const Color(0xFF6366F1);
    IconData typeIcon = Icons.shopping_bag_rounded;
    if (s.type == 'banners') {
      typeColor = const Color(0xFFEC4899);
      typeIcon = Icons.view_carousel_rounded;
    } else if (s.type == 'categories') {
      typeColor = const Color(0xFFF59E0B);
      typeIcon = Icons.category_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.isActive ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Order Index Badge & Up/Down Arrows
          Column(
            children: [
              if (index > 0)
                GestureDetector(
                  onTap: () => _layoutService.reorderSections(index, index - 1),
                  child: const Icon(Icons.keyboard_arrow_up_rounded, size: 20, color: Color(0xFF64748B)),
                )
              else
                const SizedBox(height: 20),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
              if (index < totalCount - 1)
                GestureDetector(
                  onTap: () => _layoutService.reorderSections(index, index + 2),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                )
              else
                const SizedBox(height: 20),
            ],
          ),
          const SizedBox(width: 12),

          // Section Type Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Section Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s.type.toUpperCase(),
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: typeColor),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s.layoutMode == 'carousel' ? 'CAROUSEL' : (s.type == 'banners' ? '2x2 GRID' : '2-COL GRID'),
                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (s.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    s.subtitle,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _buildConfigSummary(s),
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF6366F1)),
            onPressed: () => _openAddOrEditSectionModal(sectionToEdit: s),
          ),
          Switch.adaptive(
            value: s.isActive,
            activeColor: const Color(0xFF10B981),
            onChanged: (v) {
              s.isActive = v;
              _layoutService.saveSection(s);
            },
          ),
        ],
      ),
    );
  }

  String _buildConfigSummary(LayoutSectionModel s) {
    if (s.type == 'products') {
      if (s.filterSource == 'category') {
        return 'Filtered: Category "${s.filterName}" • Max ${s.itemLimit} items';
      } else if (s.filterSource == 'subcategory') {
        return 'Filtered: Subcategory "${s.filterName}" • Max ${s.itemLimit} items';
      }
      return 'All Products • Max ${s.itemLimit} items';
    } else if (s.type == 'banners') {
      if (s.layoutMode == 'grid') {
        return '2x2 Grid • ${s.selectedItemIds.length} Banners Selected (Max 4)';
      }
      return 'Swipe Carousel • ${s.selectedItemIds.length} Banners Selected';
    } else {
      return s.filterSource == 'subcategories' ? 'Subcategories List' : 'All Categories';
    }
  }
}

// =========================================================================
// ADD / EDIT SECTION MODAL BOTTOM SHEET
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
  String? _selectedSubcategoryId;
  String? _selectedSubcategoryName;
  List<String> _selectedBannerIds = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.sectionToEdit;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _subtitleCtrl = TextEditingController(text: s?.subtitle ?? '');
    _type = s?.type ?? 'products';
    _layoutMode = s?.layoutMode ?? 'carousel';
    _filterSource = s?.filterSource ?? 'all';
    _itemLimit = s?.itemLimit ?? 10;
    _isActive = s?.isActive ?? true;

    if (s != null) {
      _selectedCategoryId = s.filterId;
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
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
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
      title: title,
      subtitle: _subtitleCtrl.text.trim(),
      type: _type,
      layoutMode: _layoutMode,
      filterSource: _filterSource,
      filterId: _filterSource == 'category' ? (_selectedCategoryId ?? '') : (_filterSource == 'subcategory' ? (_selectedSubcategoryId ?? '') : ''),
      filterName: _filterSource == 'category' ? (_selectedCategoryName ?? '') : (_filterSource == 'subcategory' ? (_selectedSubcategoryName ?? '') : ''),
      selectedItemIds: _type == 'banners' ? _selectedBannerIds : [],
      itemLimit: _itemLimit,
      sortOrder: sortOrder,
      isActive: _isActive,
      createdAt: widget.sectionToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final ok = await MarketplaceHomeLayoutService().saveSection(section);
    setState(() => _isSaving = false);

    if (ok && mounted) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.sectionToEdit != null ? '✅ Section Updated & Synced to Shop' : '✅ Section Created & Synced to Shop'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _delete() async {
    if (widget.sectionToEdit == null) return;
    Navigator.pop(context);
    await MarketplaceHomeLayoutService().deleteSection(widget.sectionToEdit!.id);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sectionToEdit != null;
    final categories = CategoryBackendService().categories;
    final banners = BannersBackendService().banners;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Section Configuration' : 'Add Shop Section',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. SECTION TYPE SELECTOR
            const Text('Section Component Type', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildTypeChip('products', '🛍️ Products'),
                const SizedBox(width: 8),
                _buildTypeChip('banners', '🖼️ Banners'),
                const SizedBox(width: 8),
                _buildTypeChip('categories', '📂 Categories'),
              ],
            ),
            const SizedBox(height: 14),

            // 2. LAYOUT MODE SELECTOR
            const Text('Display Layout Mode', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Horizontal Carousel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    selected: _layoutMode == 'carousel',
                    onSelected: (v) => setState(() => _layoutMode = 'carousel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                      child: Text(_type == 'banners' ? '2x2 Grid (4 Banners)' : '2-Column Grid', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    selected: _layoutMode == 'grid',
                    onSelected: (v) => setState(() => _layoutMode = 'grid'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. TITLE & SUBTITLE
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Section Heading (e.g. Top Whey Deals, Best Sellers)',
                filled: true,
                fillColor: Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _subtitleCtrl,
              decoration: const InputDecoration(
                labelText: 'Optional Subheading / Tagline',
                filled: true,
                fillColor: Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 14),

            // 4. CONDITIONAL CONTROLS BASED ON TYPE
            if (_type == 'products') ...[
              const Text('Filter Source', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Products', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                    selected: _filterSource == 'all',
                    onSelected: (v) => setState(() => _filterSource = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('By Category', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                    selected: _filterSource == 'category',
                    onSelected: (v) => setState(() => _filterSource = 'category'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_filterSource == 'category') ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCategoryId ?? (categories.isNotEmpty ? categories.first.categoryId : null),
                      items: categories
                          .map((c) => DropdownMenuItem(
                                value: c.categoryId,
                                child: Text(c.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedCategoryName = categories.firstWhere((c) => c.categoryId == val).name;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              Row(
                children: [
                  const Text('Max Products Limit: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _itemLimit,
                    items: [4, 6, 8, 10, 12, 16, 20]
                        .map((num) => DropdownMenuItem(value: num, child: Text('$num Products', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _itemLimit = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ] else if (_type == 'banners') ...[
              Text(
                _layoutMode == 'grid'
                    ? 'Select up to 4 Banners for 2x2 Grid:'
                    : 'Select Banners for Swipeable Carousel:',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: banners.map((b) {
                  final isSelected = _selectedBannerIds.contains(b.bannerId);
                  return FilterChip(
                    avatar: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(b.imageUrl, width: 24, height: 24, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, size: 14)),
                    ),
                    label: Text(b.title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_layoutMode == 'grid' && _selectedBannerIds.length >= 4) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 4 banners allowed for 2x2 Grid')));
                            return;
                          }
                          _selectedBannerIds.add(b.bannerId);
                        } else {
                          _selectedBannerIds.remove(b.bannerId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _submit,
                child: Text(
                  isEditing ? 'Update Section & Sync Shop' : 'Save Section & Sync Shop',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String typeKey, String label) {
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
        selected: _type == typeKey,
        onSelected: (v) {
          setState(() {
            _type = typeKey;
            if (_type == 'banners' && _layoutMode == 'grid' && _selectedBannerIds.length > 4) {
              _selectedBannerIds = _selectedBannerIds.take(4).toList();
            }
          });
        },
      ),
    );
  }
}
