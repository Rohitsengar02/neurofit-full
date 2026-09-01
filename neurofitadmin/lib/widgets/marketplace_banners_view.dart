import 'skeleton_loader.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/banners_backend_service.dart';
import '../services/category_backend_service.dart';
import '../services/products_backend_service.dart';

class MarketplaceBannersView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const MarketplaceBannersView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<MarketplaceBannersView> createState() => _MarketplaceBannersViewState();
}

class _MarketplaceBannersViewState extends State<MarketplaceBannersView> {
  final BannersBackendService _banService = BannersBackendService();

  @override
  void initState() {
    super.initState();
    _banService.addListener(_onBanUpdate);
    if (_banService.banners.isEmpty) {
      _banService.fetchBannersFromFirestore();
    }
  }

  @override
  void dispose() {
    _banService.removeListener(_onBanUpdate);
    super.dispose();
  }

  void _onBanUpdate() {
    if (mounted) setState(() {});
  }

  void _openAddOrEditBannerModal({BannerModel? bannerToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddOrEditBannerModalBottomSheet(
        bannerToEdit: bannerToEdit,
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

    final banners = _banService.banners;

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
                          color: const Color(0xFF6366F1)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.view_carousel_rounded,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Banners',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${banners.length} Live Banners in Firestore',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _openAddOrEditBannerModal(),
                    icon: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 16,
                    ),
                    label: const Text(
                      'Add Banner',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Carousel Preview
            if (banners.isNotEmpty) ...[
              const Text(
                'Athlete App Carousel Live Preview',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              _buildLiveCarouselPreview(banners),
              const SizedBox(height: 18),
            ],

            const Text(
              'All Active Promotional Banners',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),

            // Banners List
            if (_banService.isLoading && banners.isEmpty)
              const SkeletonListView(count: 3)
            else if (banners.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: banners.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildBannerCard(banners[index]),
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
          const Icon(Icons.image_outlined, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          const Text(
            'No Promotional Banners Found',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "+ Add Banner" above to create high-impact carousel cards.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCarouselPreview(List<BannerModel> banners) {
    final firstBanner = banners.first;
    return Container(
      height: 155,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.network(
            firstBanner.imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                Container(color: const Color(0xFF1E293B)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (firstBanner.badge.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      firstBanner.badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                SizedBox(
                  width: 220,
                  child: Text(
                    firstBanner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 220,
                  child: Text(
                    firstBanner.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    firstBanner.buttonText,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(BannerModel b) {
    return GestureDetector(
      onTap: () => _openAddOrEditBannerModal(bannerToEdit: b),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                b.imageUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 76,
                  height: 76,
                  color: const Color(0xFF0F172A),
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (b.badge.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            b.badge,
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: b.isActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFF94A3B8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          b.status,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: b.isActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b.subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target: ${b.targetType.toUpperCase()} • ${b.targetName}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6366F1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                size: 20,
                color: Color(0xFF6366F1),
              ),
              onPressed: () => _openAddOrEditBannerModal(bannerToEdit: b),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// UNIFIED ADD & EDIT BANNER MODAL (FULL CONTROLS, R2 IMAGE PICKER, TARGETS)
// =========================================================================
class _AddOrEditBannerModalBottomSheet extends StatefulWidget {
  final BannerModel? bannerToEdit;
  final VoidCallback onSaved;
  const _AddOrEditBannerModalBottomSheet({
    this.bannerToEdit,
    required this.onSaved,
  });

  @override
  State<_AddOrEditBannerModalBottomSheet> createState() =>
      _AddOrEditBannerModalBottomSheetState();
}

class _AddOrEditBannerModalBottomSheetState
    extends State<_AddOrEditBannerModalBottomSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _btnTextCtrl;
  late TextEditingController _badgeCtrl;
  late TextEditingController _discountCodeCtrl;
  late String _targetType;
  late String _status;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _newImageBytes;
  String? _newImageFileName;
  bool _isProcessing = false;

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedProductId;
  String? _selectedProductName;

  @override
  void initState() {
    super.initState();
    final b = widget.bannerToEdit;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _subtitleCtrl = TextEditingController(text: b?.subtitle ?? '');
    _btnTextCtrl = TextEditingController(text: b?.buttonText ?? 'Shop Now');
    _badgeCtrl = TextEditingController(text: b?.badge ?? '🔥 FLAT 25% OFF');
    _discountCodeCtrl = TextEditingController(text: b?.discountCode ?? '');
    _targetType = b?.targetType ?? 'category';
    _status = b?.status ?? 'Active';

    if (b != null) {
      if (b.targetType == 'category') {
        _selectedCategoryId = b.targetId;
        _selectedCategoryName = b.targetName;
      } else if (b.targetType == 'product') {
        _selectedProductId = b.targetId;
        _selectedProductName = b.targetName;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _btnTextCtrl.dispose();
    _badgeCtrl.dispose();
    _discountCodeCtrl.dispose();
    super.dispose();
  }

  void _pickImage() async {
    final f = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      maxHeight: 800,
      imageQuality: 88,
    );
    if (f != null) {
      final b = await f.readAsBytes();
      setState(() {
        _newImageBytes = b;
        _newImageFileName = f.name;
      });
    }
  }

  void _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter banner title')),
      );
      return;
    }

    if (widget.bannerToEdit == null && _newImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a banner image from gallery'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final targetId = _targetType == 'category'
        ? (_selectedCategoryId ?? '')
        : (_selectedProductId ?? '');
    final targetName = _targetType == 'category'
        ? (_selectedCategoryName ?? 'All Categories')
        : (_selectedProductName ?? 'Featured Product');

    bool ok = false;
    if (widget.bannerToEdit != null) {
      // UPDATE EXISTING BANNER
      ok = await BannersBackendService().updateBanner(
        bannerId: widget.bannerToEdit!.bannerId,
        title: title,
        subtitle: _subtitleCtrl.text.trim(),
        targetType: _targetType,
        targetId: targetId,
        targetName: targetName,
        buttonText: _btnTextCtrl.text.trim(),
        badge: _badgeCtrl.text.trim(),
        discountCode: _discountCodeCtrl.text.trim(),
        status: _status,
        newImageBytes: _newImageBytes,
        newImageFileName: _newImageFileName,
      );
    } else {
      // CREATE NEW BANNER
      ok = await BannersBackendService().createBanner(
        title: title,
        subtitle: _subtitleCtrl.text.trim(),
        targetType: _targetType,
        targetId: targetId,
        targetName: targetName,
        buttonText: _btnTextCtrl.text.trim(),
        badge: _badgeCtrl.text.trim(),
        discountCode: _discountCodeCtrl.text.trim(),
        imageFileName:
            _newImageFileName ??
            'banner_${DateTime.now().millisecondsSinceEpoch}.jpg',
        imageBytes: _newImageBytes!,
      );
    }

    setState(() => _isProcessing = false);

    if (ok && mounted) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.bannerToEdit != null
                ? '✅ Banner Updated & Synced to R2'
                : '✅ Banner Created & Synced to R2',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _handleDelete() async {
    if (widget.bannerToEdit == null) return;
    Navigator.pop(context);
    await BannersBackendService().deleteBanner(widget.bannerToEdit!.bannerId);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryBackendService().categories;
    final products = ProductsBackendService().products;
    final isEditing = widget.bannerToEdit != null;

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
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Promotional Banner' : 'Create Hero Banner',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                    ),
                    onPressed: _handleDelete,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload image to Cloudflare R2 bucket & configure deep-link routing',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // Image Picker & Preview
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  ),
                ),
                child: _newImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_newImageBytes!, fit: BoxFit.cover),
                      )
                    : (isEditing && widget.bannerToEdit!.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                widget.bannerToEdit!.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 28,
                                  color: Color(0xFF6366F1),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Select Banner Image from Gallery',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Cloudflare R2 Bucket High-Res Upload',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            )),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Banner Headline / Main Title',
                filled: true,
                fillColor: Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _subtitleCtrl,
              decoration: const InputDecoration(
                labelText: 'Subtitle / Tagline Description',
                filled: true,
                fillColor: Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Target Type Selector
            const Text(
              'Select Routing Target',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    selected: _targetType == 'category',
                    onSelected: (v) => setState(() => _targetType = 'category'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text(
                        'Product',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    selected: _targetType == 'product',
                    onSelected: (v) => setState(() => _targetType = 'product'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Target Selector Dropdown
            if (_targetType == 'category') ...[
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
                    value:
                        _selectedCategoryId ??
                        (categories.isNotEmpty
                            ? categories.first.categoryId
                            : null),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.categoryId,
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                        _selectedCategoryName = categories
                            .firstWhere((c) => c.categoryId == val)
                            .name;
                      });
                    },
                  ),
                ),
              ),
            ] else ...[
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
                    value:
                        _selectedProductId ??
                        (products.isNotEmpty ? products.first.id : null),
                    items: products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedProductId = val;
                        _selectedProductName = products
                            .firstWhere((p) => p.id == val)
                            .title;
                      });
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _badgeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Badge (e.g. 🔥 25% OFF)',
                      filled: true,
                      fillColor: Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _discountCodeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Promo Code (e.g. GOLD25)',
                      filled: true,
                      fillColor: Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _btnTextCtrl,
              decoration: const InputDecoration(
                labelText: 'Action Button Label (e.g. Shop Now)',
                filled: true,
                fillColor: Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            if (isEditing) ...[
              SwitchListTile.adaptive(
                title: Text(
                  _status == 'Active'
                      ? 'Status: Active (Visible on Shop)'
                      : 'Status: Deactivated',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                value: _status == 'Active',
                activeColor: const Color(0xFF10B981),
                onChanged: (v) =>
                    setState(() => _status = v ? 'Active' : 'Deactivated'),
              ),
              const SizedBox(height: 10),
            ],

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessing ? null : _submit,
                child: Text(
                  isEditing
                      ? 'Update Banner & Sync Cloudflare R2'
                      : 'Save Banner & Sync Cloudflare R2',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
