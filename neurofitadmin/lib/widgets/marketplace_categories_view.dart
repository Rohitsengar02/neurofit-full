

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/category_backend_service.dart';
import 'upload_progress_overlay.dart';
import 'r2_media_library_picker_modal.dart';

class MarketplaceCategoriesView extends StatefulWidget {
  final String selectedDateRange;
  final bool isSubCategories;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const MarketplaceCategoriesView({
    super.key,
    required this.selectedDateRange,
    this.isSubCategories = false,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<MarketplaceCategoriesView> createState() =>
      _MarketplaceCategoriesViewState();
}

class _MarketplaceCategoriesViewState extends State<MarketplaceCategoriesView> {
  final CategoryBackendService _catService = CategoryBackendService();

  @override
  void initState() {
    super.initState();
    _catService.addListener(_onCatUpdate);
    if (_catService.categories.isEmpty) {
      _catService.fetchCategoriesFromFirestore();
    }
  }

  @override
  void dispose() {
    _catService.removeListener(_onCatUpdate);
    super.dispose();
  }

  void _onCatUpdate() {
    if (mounted) setState(() {});
  }
  final CategoryBackendService _backendService = CategoryBackendService();
  String _searchQuery = '';
  String _selectedParentFilter = 'All';

  void _openAddModal() {
    if (widget.isSubCategories) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _AddSubCategoryBottomSheet(
          onSubCategoryAdded: () => setState(() {}),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _AddCategoryBottomSheet(
          onCategoryAdded: () => setState(() {}),
        ),
      );
    }
  }

  void _openCategorySlider(CategoryModel cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryDetailsSliderSheet(
        category: cat,
        onUpdated: () => setState(() {}),
      ),
    );
  }

  void _openSubCategorySlider(SubCategoryModel sub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SubCategoryDetailsSliderSheet(
        subCategory: sub,
        onUpdated: () => setState(() {}),
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

    final categories = _backendService.categories.where((cat) {
      if (_searchQuery.isEmpty) return true;
      return cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final subCategories = _backendService.subCategories.where((sub) {
      final matchesSearch = _searchQuery.isEmpty ||
          sub.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          sub.parentCategoryName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesParent = _selectedParentFilter == 'All' ||
          sub.parentCategoryId == _selectedParentFilter;
      return matchesSearch && matchesParent;
    }).toList();

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Action Bar with Search, Dropdown, and Add Button
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: widget.isSubCategories
                            ? 'Search sub-categories...'
                            : 'Search marketplace categories...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _openAddModal,
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                  label: Text(
                    widget.isSubCategories ? 'Add Sub-Category' : 'Add Category',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            // Parent Category Filter Dropdown Bar (For Sub-Categories View)
            if (widget.isSubCategories && _backendService.categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterPill('All Categories', 'All'),
                    ..._backendService.categories.map((c) => _buildFilterPill(c.name, c.categoryId)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Grid Rendering (Categories or SubCategories)
            if (widget.isSubCategories) ...[
              if (subCategories.isEmpty)
                _buildEmptyState('No sub-categories found', 'Tap "+ Add Sub-Category" to create one in categories sub-collection.')
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.80,
                  ),
                  itemCount: subCategories.length,
                  itemBuilder: (context, index) {
                    final sub = subCategories[index];
                    return _buildSubCategoryCard(sub);
                  },
                ),
            ] else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return _buildCategoryCard(cat);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String title, String id) {
    final isSelected = _selectedParentFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF6366F1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          ),
        ),
        onSelected: (val) {
          setState(() {
            _selectedParentFilter = id;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_tree_rounded, size: 36, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel cat) {
    final bool isDeactivated = cat.status == 'Deactivated';

    return GestureDetector(
      onTap: () => _openCategorySlider(cat),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDeactivated ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
            width: isDeactivated ? 1.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                      color: Color(0xFF0F172A),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Opacity(
                      opacity: isDeactivated ? 0.45 : 1.0,
                      child: Image.network(
                        CategoryBackendService.getDisplayableImageUrl(cat.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF1E293B),
                            child: const Center(
                              child: Icon(Icons.fitness_center_rounded, size: 36, color: Color(0xFF10B981)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('R2 CDN', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isDeactivated ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${cat.subCount} Sub-items', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDeactivated ? const Color(0xFF94A3B8).withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cat.status,
                          style: TextStyle(
                            color: isDeactivated ? const Color(0xFF64748B) : const Color(0xFF10B981),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryCard(SubCategoryModel sub) {
    final bool isDeactivated = sub.status == 'Deactivated';

    return GestureDetector(
      onTap: () => _openSubCategorySlider(sub),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDeactivated ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                      color: Color(0xFF0F172A),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Opacity(
                      opacity: isDeactivated ? 0.45 : 1.0,
                      child: Image.network(
                        CategoryBackendService.getDisplayableImageUrl(sub.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Icon(Icons.account_tree_rounded, size: 28, color: Color(0xFF6366F1)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sub.parentCategoryName,
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 11),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: isDeactivated ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${sub.itemCount} Items', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isDeactivated ? const Color(0xFF94A3B8).withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sub.status,
                          style: TextStyle(
                            color: isDeactivated ? const Color(0xFF64748B) : const Color(0xFF10B981),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
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
// 3. ADD SUB-CATEGORY BOTTOM SHEET (WITH MAIN CATEGORY DROPDOWN + IMAGE)
// =========================================================================
class _AddSubCategoryBottomSheet extends StatefulWidget {
  final VoidCallback onSubCategoryAdded;

  const _AddSubCategoryBottomSheet({required this.onSubCategoryAdded});

  @override
  State<_AddSubCategoryBottomSheet> createState() =>
      _AddSubCategoryBottomSheetState();
}

class _AddSubCategoryBottomSheetState extends State<_AddSubCategoryBottomSheet> {
  final TextEditingController _titleCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _selectedParentId;
  String? _selectedParentName;
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final categories = CategoryBackendService().categories;
    if (categories.isNotEmpty) {
      _selectedParentId = categories.first.categoryId;
      _selectedParentName = categories.first.name;
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Sub-Category Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF6366F1)),
                title: const Text('Photo Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF10B981)),
                title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImage = file;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String? _selectedR2Url;

  void _openR2MediaLibrary() {
    R2MediaLibraryPickerModal.show(
      context,
      onImageSelected: (url) {
        setState(() {
          _selectedR2Url = url;
          _imageBytes = null;
        });
      },
    );
  }

  void _submitSubCategory() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter sub-category title')));
      return;
    }
    if (_selectedParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select parent category')));
      return;
    }
    if (_imageBytes == null && _selectedR2Url == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select or pick an image')));
      return;
    }

    setState(() => _isProcessing = true);
    Navigator.pop(context);

    bool ok = false;
    if (_selectedR2Url != null) {
      ok = await CategoryBackendService().createSubCategoryWithUrl(
        parentCategoryId: _selectedParentId!,
        parentCategoryName: _selectedParentName ?? 'Category',
        name: title,
        slug: title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
        imageUrl: _selectedR2Url!,
      );
    } else {
      final newSub = await CategoryBackendService().createSubCategoryWithImage(
        parentCategoryId: _selectedParentId!,
        parentCategoryName: _selectedParentName ?? 'Category',
        title: title,
        fileName: _selectedImage?.name ?? 'subcategory.jpg',
        imageBytes: _imageBytes!,
      );
      ok = newSub != null;
    }

    if (ok) {
      widget.onSubCategoryAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryBackendService().categories;

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
          const SizedBox(height: 18),
          const Text(
            'Create New Sub-Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Saved to categories/{categoryId}/subcategories sub-collection & cached in Redis',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),

          // Main Category Dropdown Selector
          const Text('Select Parent Main Category', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedParentId,
                items: categories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.categoryId,
                    child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedParentId = val;
                    _selectedParentName = categories.firstWhere((c) => c.categoryId == val).name;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Image Box
          GestureDetector(
            onTap: _showImageSourcePicker,
            child: Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35), width: 1.5),
              ),
              child: _selectedR2Url != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            CategoryBackendService.getDisplayableImageUrl(_selectedR2Url!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Change R2 Image', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    )
                  : (_imageBytes != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(_imageBytes!, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
                                child: const Text('Change', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF6366F1), size: 28),
                            SizedBox(height: 6),
                            Text('Tap to pick sub-category image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            Text('Uploaded to R2 uploads folder', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          ],
                        )),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openR2MediaLibrary,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: Color(0xFF6366F1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.cloud_done_rounded, size: 18, color: Color(0xFF6366F1)),
              label: const Text(
                '+ Select from Cloudflare R2 Media Library',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title Field
          const Text('Sub-Category Title', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Whey Isolate, Creatine, Straps',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isProcessing ? null : _submitSubCategory,
              child: const Text('Save to Sub-Collection & Sync R2', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 4. SUB-CATEGORY DETAILS & MANAGEMENT SLIDER
// =========================================================================
class _SubCategoryDetailsSliderSheet extends StatefulWidget {
  final SubCategoryModel subCategory;
  final VoidCallback onUpdated;

  const _SubCategoryDetailsSliderSheet({required this.subCategory, required this.onUpdated});

  @override
  State<_SubCategoryDetailsSliderSheet> createState() => _SubCategoryDetailsSliderSheetState();
}

class _SubCategoryDetailsSliderSheetState extends State<_SubCategoryDetailsSliderSheet> {
  late TextEditingController _nameCtrl;
  late String _currentStatus;
  Uint8List? _newImageBytes;
  XFile? _newImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.subCategory.name);
    _currentStatus = widget.subCategory.status;
  }

  void _pickNewImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 88);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _newImageFile = file;
        _newImageBytes = bytes;
      });
    }
  }

  void _handleSave() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;

    Navigator.pop(context);

    String? updatedUrl;
    if (_newImageBytes != null) {
      final notifier = UploadProgressNotifier();
      notifier.startUpload(_newImageFile?.name ?? 'updated_subcategory.jpg');
      updatedUrl = await CategoryBackendService().uploadRawImageToR2(
        fileName: _newImageFile?.name ?? 'subcategory.jpg',
        imageBytes: _newImageBytes!,
        onProgress: (p, s) => notifier.updateProgress(p, customStatus: s),
      );
      if (updatedUrl != null) notifier.completeUpload(updatedUrl);
    }

    await CategoryBackendService().updateSubCategory(
      subId: widget.subCategory.subCategoryId,
      parentCategoryId: widget.subCategory.parentCategoryId,
      newName: newName,
      newImageUrl: updatedUrl,
      newStatus: _currentStatus,
    );

    widget.onUpdated();
  }

  void _handleDelete() {
    Navigator.pop(context);
    CategoryBackendService().deleteSubCategory(
      subId: widget.subCategory.subCategoryId,
      parentCategoryId: widget.subCategory.parentCategoryId,
    );
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                    const Text('Sub-Category Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('Parent: ${widget.subCategory.parentCategoryName}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 170,
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
                        clipBehavior: Clip.antiAlias,
                        child: _newImageBytes != null
                            ? Image.memory(_newImageBytes!, fit: BoxFit.cover)
                            : Image.network(
                                CategoryBackendService.getDisplayableImageUrl(widget.subCategory.imageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Center(
                                  child: Icon(Icons.account_tree_rounded, size: 40, color: Color(0xFF6366F1)),
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85), foregroundColor: Colors.white),
                          onPressed: _pickNewImage,
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: const Text('Change Image', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Sub-Category Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  TextField(controller: _nameCtrl, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  SwitchListTile.adaptive(
                    title: Text(_currentStatus == 'Active' ? 'Status: Active' : 'Status: Inactive', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    subtitle: const Text('Toggle visibility in mobile athlete app', style: TextStyle(fontSize: 11)),
                    value: _currentStatus == 'Active',
                    activeColor: const Color(0xFF10B981),
                    onChanged: (v) => setState(() => _currentStatus = v ? 'Active' : 'Deactivated'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444)), foregroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _handleDelete,
                          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _handleSave,
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 5. ADD CATEGORY & DETAILS SLIDER IMPLEMENTATIONS
// =========================================================================
class _AddCategoryBottomSheet extends StatefulWidget {
  final VoidCallback onCategoryAdded;
  const _AddCategoryBottomSheet({required this.onCategoryAdded});

  @override
  State<_AddCategoryBottomSheet> createState() => _AddCategoryBottomSheetState();
}

class _AddCategoryBottomSheetState extends State<_AddCategoryBottomSheet> {
  final TextEditingController _titleCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isProcessing = false;

  void _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedImage = file;
        _imageBytes = bytes;
      });
    }
  }

  void _submitCategory() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _imageBytes == null) return;

    setState(() => _isProcessing = true);
    Navigator.pop(context);

    final newCat = await CategoryBackendService().createCategoryWithImage(
      title: title,
      fileName: _selectedImage?.name ?? 'category.jpg',
      imageBytes: _imageBytes!,
    );

    if (newCat != null) widget.onCategoryAdded();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 44, height: 4.5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 18),
          const Text('Create New Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35), width: 1.5)),
              child: _imageBytes != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF6366F1), size: 28),
                        SizedBox(height: 6),
                        Text('Tap to pick category image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Category Title', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(controller: _titleCtrl, decoration: InputDecoration(hintText: 'e.g. Whey Protein & Supplements', filled: true, fillColor: const Color(0xFFF8FAFC), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _isProcessing ? null : _submitCategory,
              child: const Text('Upload to R2 & Save Category', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDetailsSliderSheet extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback onUpdated;
  const _CategoryDetailsSliderSheet({required this.category, required this.onUpdated});

  @override
  State<_CategoryDetailsSliderSheet> createState() => _CategoryDetailsSliderSheetState();
}

class _CategoryDetailsSliderSheetState extends State<_CategoryDetailsSliderSheet> {
  late TextEditingController _nameCtrl;
  late String _currentStatus;
  Uint8List? _newImageBytes;
  XFile? _newImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category.name);
    _currentStatus = widget.category.status;
  }

  void _pickNewImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 88);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _newImageFile = file;
        _newImageBytes = bytes;
      });
    }
  }

  void _handleSave() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;

    Navigator.pop(context);

    String? updatedUrl;
    if (_newImageBytes != null) {
      final notifier = UploadProgressNotifier();
      notifier.startUpload(_newImageFile?.name ?? 'category.jpg');
      updatedUrl = await CategoryBackendService().uploadRawImageToR2(
        fileName: _newImageFile?.name ?? 'category.jpg',
        imageBytes: _newImageBytes!,
        onProgress: (p, s) => notifier.updateProgress(p, customStatus: s),
      );
      if (updatedUrl != null) notifier.completeUpload(updatedUrl);
    }

    await CategoryBackendService().updateCategory(
      id: widget.category.id,
      newName: newName,
      newImageUrl: updatedUrl,
      newStatus: _currentStatus,
    );

    widget.onUpdated();
  }

  void _handleDelete() {
    Navigator.pop(context);
    CategoryBackendService().deleteCategory(widget.category.id);
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                    const Text('Category Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('ID: ${widget.category.id}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
                        clipBehavior: Clip.antiAlias,
                        child: _newImageBytes != null
                            ? Image.memory(_newImageBytes!, fit: BoxFit.cover)
                            : Image.network(
                                CategoryBackendService.getDisplayableImageUrl(widget.category.imageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Center(
                                  child: Icon(Icons.cloud_done_rounded, size: 40, color: Color(0xFF6366F1)),
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85), foregroundColor: Colors.white),
                          onPressed: _pickNewImage,
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: const Text('Change Image', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Category Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  TextField(controller: _nameCtrl, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  SwitchListTile.adaptive(
                    title: Text(_currentStatus == 'Active' ? 'Status: Active' : 'Status: Inactive', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    subtitle: const Text('Visible to athletes in marketplace', style: TextStyle(fontSize: 11)),
                    value: _currentStatus == 'Active',
                    activeColor: const Color(0xFF10B981),
                    onChanged: (v) => setState(() => _currentStatus = v ? 'Active' : 'Deactivated'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444)), foregroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _handleDelete,
                          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _handleSave,
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
