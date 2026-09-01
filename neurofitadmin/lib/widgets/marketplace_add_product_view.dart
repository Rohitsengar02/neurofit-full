import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/category_backend_service.dart';
import '../services/discounts_backend_service.dart';
import '../services/products_backend_service.dart';

class MarketplaceAddProductView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;
  final ProductItem? productToEdit;
  final VoidCallback? onProductUpdated;

  const MarketplaceAddProductView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
    this.productToEdit,
    this.onProductUpdated,
  });

  @override
  State<MarketplaceAddProductView> createState() =>
      _MarketplaceAddProductViewState();
}

class _MarketplaceAddProductViewState extends State<MarketplaceAddProductView> {
  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _regularPriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _lowStockCtrl;
  late TextEditingController _descCtrl;

  final ImagePicker _picker = ImagePicker();

  // Media
  XFile? _mainImageFile;
  Uint8List? _mainImageBytes;
  String _existingMainImageUrl = '';
  final List<Map<String, dynamic>> _galleryList = []; // [{name, bytes, url}]

  // Dropdown States
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedSubCategoryId;
  String? _selectedSubCategoryName;
  String? _selectedDiscountId;
  String? _selectedDiscountCode;
  String _selectedStockStatus = 'In Stock';

  // Variants List
  final List<ProductVariant> _variants = [];

  bool _isPublishing = false;

  bool get isEditMode => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;

    _nameCtrl = TextEditingController(text: p?.title ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? 'NeuroFit Pro');
    _skuCtrl = TextEditingController(text: p?.sku ?? 'NEURO-PRO-01');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toInt().toString() : '3499');
    _regularPriceCtrl = TextEditingController(text: p != null ? p.regularPrice.toInt().toString() : '4499');
    _stockCtrl = TextEditingController(text: p != null ? p.totalStock.toString() : '100');
    _lowStockCtrl = TextEditingController(text: p != null ? p.lowStockAlert.toString() : '10');
    _descCtrl = TextEditingController(
      text: p?.description ?? 'Ultra-pure isolate formula engineered for maximum protein synthesis, rapid muscle recovery, and zero bloat.',
    );

    if (p != null) {
      _existingMainImageUrl = p.mainImageUrl;
      _selectedCategoryId = p.categoryId;
      _selectedCategoryName = p.categoryName;
      _selectedSubCategoryId = p.subCategoryId;
      _selectedSubCategoryName = p.subCategoryName;
      _selectedDiscountId = p.discountId ?? '';
      _selectedDiscountCode = p.discountCode;
      _selectedStockStatus = p.stockStatus;

      // Copy Gallery
      for (final gUrl in p.galleryImages) {
        _galleryList.add({
          'name': gUrl.split('/').last,
          'bytes': null,
          'url': gUrl,
        });
      }

      // Copy Variants
      _variants.addAll(p.variants);
    } else {
      _initDefaults();
    }
  }

  void _initDefaults() {
    final categories = CategoryBackendService().categories;
    if (categories.isNotEmpty) {
      _selectedCategoryId = categories.first.categoryId;
      _selectedCategoryName = categories.first.name;
      _updateSubCategoryForParent(_selectedCategoryId!);
    }
    _selectedDiscountId = '';
    _selectedDiscountCode = null;
  }

  void _updateSubCategoryForParent(String parentCatId) {
    final subCats = CategoryBackendService()
        .subCategories
        .where((s) => s.parentCategoryId == parentCatId)
        .toList();
    if (subCats.isNotEmpty) {
      _selectedSubCategoryId = subCats.first.subCategoryId;
      _selectedSubCategoryName = subCats.first.name;
    } else {
      _selectedSubCategoryId = '';
      _selectedSubCategoryName = 'General';
    }
  }

  void _pickMainImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 88);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _mainImageFile = file;
        _mainImageBytes = bytes;
      });
    }
  }

  void _pickGalleryImages() async {
    final List<XFile> files = await _picker.pickMultiImage(maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
    if (files.isNotEmpty) {
      for (final f in files) {
        final bytes = await f.readAsBytes();
        setState(() {
          _galleryList.add({
            'name': f.name,
            'bytes': bytes,
            'url': null,
          });
        });
      }
    }
  }

  void _openAddVariantSheet() {
    final nameCtrl = TextEditingController(text: 'Flavour / Size Variant');
    final priceCtrl = TextEditingController(text: _priceCtrl.text);
    final stockCtrl = TextEditingController(text: '50');
    final skuCtrl = TextEditingController(text: '${_skuCtrl.text}-V${_variants.length + 1}');
    Uint8List? variantBytes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 44, height: 4.5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              const Text('Add Product Variant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              const Text('Add flavour, size, weight, or color with dedicated pricing & stock', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  final f = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
                  if (f != null) {
                    final b = await f.readAsBytes();
                    setModalState(() => variantBytes = b);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35)),
                  ),
                  child: variantBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(variantBytes!, fit: BoxFit.cover),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_rounded, color: Color(0xFF6366F1), size: 22),
                            SizedBox(width: 8),
                            Text('Upload Variant Image (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),

              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Variant Name (e.g. Chocolate 2kg / XL)', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Variant Price (₹)', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Inventory Units', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                ],
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    final vName = nameCtrl.text.trim();
                    final vPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    final vStock = int.tryParse(stockCtrl.text.trim()) ?? 0;
                    if (vName.isEmpty) return;

                    setState(() {
                      _variants.add(ProductVariant(
                        variantId: 'var_${DateTime.now().millisecondsSinceEpoch}',
                        name: vName,
                        price: vPrice,
                        stock: vStock,
                        sku: skuCtrl.text.trim(),
                        localBytes: variantBytes,
                      ));
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Variant to Product', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveOrPublishProduct() async {
    final title = _nameCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter product title'), backgroundColor: Color(0xFFEF4444)));
      return;
    }
    if (_mainImageBytes == null && _existingMainImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select main product image'), backgroundColor: Color(0xFFEF4444)));
      return;
    }
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select product category'), backgroundColor: Color(0xFFEF4444)));
      return;
    }

    setState(() => _isPublishing = true);

    if (isEditMode) {
      // 1. UPDATE EXISTING PRODUCT
      final prod = widget.productToEdit!;
      prod.title = title;
      prod.brand = _brandCtrl.text.trim();
      prod.description = _descCtrl.text.trim();
      prod.categoryId = _selectedCategoryId!;
      prod.categoryName = _selectedCategoryName ?? 'Category';
      prod.subCategoryId = _selectedSubCategoryId ?? '';
      prod.subCategoryName = _selectedSubCategoryName ?? '';
      prod.discountId = (_selectedDiscountId != null && _selectedDiscountId!.isNotEmpty) ? _selectedDiscountId : null;
      prod.discountCode = _selectedDiscountCode;
      prod.price = double.tryParse(_priceCtrl.text.trim()) ?? prod.price;
      prod.regularPrice = double.tryParse(_regularPriceCtrl.text.trim()) ?? prod.regularPrice;
      prod.totalStock = int.tryParse(_stockCtrl.text.trim()) ?? prod.totalStock;
      prod.lowStockAlert = int.tryParse(_lowStockCtrl.text.trim()) ?? prod.lowStockAlert;
      prod.stockStatus = _selectedStockStatus;
      prod.sku = _skuCtrl.text.trim();
      prod.variants = _variants;
      prod.updatedAt = DateTime.now();

      // If new main image picked, upload to R2
      if (_mainImageBytes != null) {
        final newMainUrl = await CategoryBackendService().uploadRawImageToR2(
          fileName: _mainImageFile?.name ?? 'product_main.jpg',
          imageBytes: _mainImageBytes!,
        );
        if (newMainUrl != null) prod.mainImageUrl = newMainUrl;
      }

      // Upload any new gallery images
      final List<String> updatedGalleryUrls = [];
      for (final g in _galleryList) {
        if (g['url'] != null) {
          updatedGalleryUrls.add(g['url']);
        } else if (g['bytes'] != null) {
          final gUrl = await CategoryBackendService().uploadRawImageToR2(
            fileName: g['name'] ?? 'gallery.jpg',
            imageBytes: g['bytes'],
          );
          if (gUrl != null) updatedGalleryUrls.add(gUrl);
        }
      }
      prod.galleryImages = updatedGalleryUrls;

      await ProductsBackendService().updateProduct(prod);
      setState(() => _isPublishing = false);

      if (widget.onProductUpdated != null) {
        widget.onProductUpdated!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated product "$title" in Firestore & Cloudflare R2!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // 2. CREATE NEW PRODUCT
      final res = await ProductsBackendService().createProduct(
        title: title,
        brand: _brandCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName ?? 'Category',
        subCategoryId: _selectedSubCategoryId ?? '',
        subCategoryName: _selectedSubCategoryName ?? '',
        discountId: (_selectedDiscountId != null && _selectedDiscountId!.isNotEmpty) ? _selectedDiscountId : null,
        discountCode: _selectedDiscountCode,
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        regularPrice: double.tryParse(_regularPriceCtrl.text.trim()) ?? 0.0,
        totalStock: int.tryParse(_stockCtrl.text.trim()) ?? 100,
        lowStockAlert: int.tryParse(_lowStockCtrl.text.trim()) ?? 10,
        stockStatus: _selectedStockStatus,
        sku: _skuCtrl.text.trim(),
        mainImageFileName: _mainImageFile?.name ?? 'product_main.jpg',
        mainImageBytes: _mainImageBytes!,
        galleryRawList: _galleryList.where((g) => g['bytes'] != null).toList(),
        variants: _variants,
      );

      setState(() => _isPublishing = false);

      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "$title" published to Cloudflare R2 & Firestore!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryBackendService().categories;
    final subCats = CategoryBackendService()
        .subCategories
        .where((s) => s.parentCategoryId == _selectedCategoryId)
        .toList();
    final discounts = DiscountsBackendService().discounts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEditMode ? Icons.edit_note_rounded : Icons.add_shopping_cart_rounded,
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditMode ? 'Edit Product & Inventory' : 'Add Marketplace Item',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isEditMode ? 'Modify title, media, categories, variants & pricing' : 'Media gallery, variants & inventory sync',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(7)),
                child: const Text('R2 + FIRESTORE', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // 1. MEDIA SECTION
          const Text('1. Product Media & Images (Cloudflare R2)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),

          // Main Image Area
          GestureDetector(
            onTap: () => _pickMainImage(ImageSource.gallery),
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35), width: 1.5),
              ),
              child: (_mainImageBytes != null)
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(_mainImageBytes!, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(8)),
                            child: const Text('New Image • Tap to Change', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    )
                  : (_existingMainImageUrl.isNotEmpty)
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(_existingMainImageUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(8)),
                                child: const Text('Current Image • Tap to Change', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate_rounded, size: 30, color: Color(0xFF6366F1)),
                            SizedBox(height: 6),
                            Text('Tap to select Main Cover Image', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                            Text('High-resolution product showcase photo', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary Gallery Row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gallery (${_galleryList.length} Added)',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: _pickGalleryImages,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 14, color: Color(0xFF6366F1)),
                      SizedBox(width: 4),
                      Text('+ Add Photos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_galleryList.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _galleryList.length,
                separatorBuilder: (c, i) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final g = _galleryList[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: g['bytes'] != null
                            ? Image.memory(g['bytes'], width: 70, height: 70, fit: BoxFit.cover)
                            : Image.network(g['url'], width: 70, height: 70, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _galleryList.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),

          // 2. PRODUCT DETAILS & PRICING
          const Text('2. Product Information & Pricing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),

          _buildFieldLabel('Product Title'),
          TextField(controller: _nameCtrl, decoration: _inputDecor('e.g. Gold Standard 100% Isolate Whey Protein 2kg')),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Selling Price (₹)'),
                    TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: _inputDecor('3499')),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Regular M.R.P (₹)'),
                    TextField(controller: _regularPriceCtrl, keyboardType: TextInputType.number, decoration: _inputDecor('4499')),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Brand / Vendor'),
                    TextField(controller: _brandCtrl, decoration: _inputDecor('NeuroFit Pro')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildFieldLabel('Detailed Product Description'),
          TextField(controller: _descCtrl, maxLines: 3, decoration: _inputDecor('Enter product details, nutrition specs, or size guide...')),
          const SizedBox(height: 20),

          // 3. CATEGORIZATION & DISCOUNT DROPDOWNS
          const Text('3. Categorization & Discount Rules', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),

          Row(
            children: [
              // Category Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Category'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: (categories.any((c) => c.categoryId == _selectedCategoryId))
                              ? _selectedCategoryId
                              : (categories.isNotEmpty ? categories.first.categoryId : ''),
                          items: categories.isEmpty
                              ? [const DropdownMenuItem<String>(value: '', child: Text('No Categories', style: TextStyle(fontSize: 11.5)))]
                              : categories.map((c) => DropdownMenuItem<String>(value: c.categoryId, child: Text(c.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) {
                            if (val != null && val.isNotEmpty) {
                              setState(() {
                                _selectedCategoryId = val;
                                _selectedCategoryName = categories.firstWhere((c) => c.categoryId == val).name;
                                _updateSubCategoryForParent(val);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Sub-Category Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Sub-Category'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: (subCats.any((s) => s.subCategoryId == _selectedSubCategoryId))
                              ? _selectedSubCategoryId
                              : '',
                          items: [
                            const DropdownMenuItem<String>(value: '', child: Text('General (None)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                            ...subCats.map((sc) => DropdownMenuItem<String>(value: sc.subCategoryId, child: Text(sc.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedSubCategoryId = val ?? '';
                              _selectedSubCategoryName = (val != null && val.isNotEmpty && subCats.any((s) => s.subCategoryId == val))
                                  ? subCats.firstWhere((s) => s.subCategoryId == val).name
                                  : 'General';
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildFieldLabel('Applicable Promo Discount (Optional)'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: (discounts.any((d) => d.discountId == _selectedDiscountId))
                    ? _selectedDiscountId
                    : '',
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('None (Standard Price)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  ...discounts.map((d) => DropdownMenuItem<String>(
                        value: d.discountId,
                        child: Text('${d.code} • ${d.title} (${d.type == 'percentage' ? '${d.value.toInt()}% Off' : '₹${d.value.toInt()} Flat'})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (val) {
                  setState(() {
                    if (val != null && val.isNotEmpty && discounts.any((d) => d.discountId == val)) {
                      _selectedDiscountId = val;
                      _selectedDiscountCode = discounts.firstWhere((d) => d.discountId == val).code;
                    } else {
                      _selectedDiscountId = null;
                      _selectedDiscountCode = null;
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. VARIANTS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('4. Product Variants & Options', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openAddVariantSheet,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Variant', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_variants.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: const Center(
                child: Text('No custom variants added yet. Tap "+ Add Variant" for flavours, sizes, or colors.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _variants.length,
              separatorBuilder: (c, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final v = _variants[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      if (v.localBytes != null)
                        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(v.localBytes!, width: 40, height: 40, fit: BoxFit.cover))
                      else if (v.imageUrl.isNotEmpty)
                        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(v.imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 40, height: 40, color: const Color(0xFFE2E8F0))))
                      else
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.style_rounded, color: Color(0xFF64748B), size: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                            Text('₹${v.price.toInt()} • Stock: ${v.stock} units • SKU: ${v.sku}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                        onPressed: () => setState(() => _variants.removeAt(index)),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),

          // 5. INVENTORY
          const Text('5. Inventory & Stock Controls', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Total Stock Available'),
                    TextField(controller: _stockCtrl, keyboardType: TextInputType.number, decoration: _inputDecor('100')),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Low Stock Threshold'),
                    TextField(controller: _lowStockCtrl, keyboardType: TextInputType.number, decoration: _inputDecor('10')),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Stock Status'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedStockStatus,
                          items: ['In Stock', 'Out of Stock', 'Backorder'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)))).toList(),
                          onChanged: (val) => setState(() => _selectedStockStatus = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // SUBMIT / UPDATE BUTTON
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isPublishing ? null : _saveOrPublishProduct,
              child: _isPublishing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Syncing with R2 & Firestore...', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                      ],
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isEditMode ? Icons.save_rounded : Icons.cloud_upload_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isEditMode ? 'Save & Update Product in Store' : 'Publish Product to Marketplace',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
    );
  }
}
