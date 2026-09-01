import 'skeleton_loader.dart';
import 'marketplace_add_product_view.dart';
import 'package:flutter/material.dart';
import '../services/products_backend_service.dart';

class MarketplaceProductsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const MarketplaceProductsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<MarketplaceProductsView> createState() =>
      _MarketplaceProductsViewState();
}

class _MarketplaceProductsViewState extends State<MarketplaceProductsView> {


  @override
  void initState() {
    super.initState();
    _backendService.addListener(_onServiceUpdate);
    if (_backendService.products.isEmpty) {
      _backendService.fetchProductsFromFirestore();
    }
  }

  @override
  void dispose() {
    _backendService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }
  final ProductsBackendService _backendService = ProductsBackendService();
  String _searchQuery = '';
  String _stockFilter = 'All';

  void _openProductSlider(ProductItem product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductDetailsSliderSheet(
        product: product,
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

    final products = _backendService.products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStock = _stockFilter == 'All' ||
          (_stockFilter == 'In Stock' && p.stockStatus == 'In Stock') ||
          (_stockFilter == 'Low Stock' && p.totalStock <= p.lowStockThreshold);
      return matchesSearch && matchesStock;
    }).toList();

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar & Filter Chips
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Search products, brands, categories...',
                  hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('All Products (${_backendService.products.length})', 'All'),
                  _buildFilterChip('In Stock', 'In Stock'),
                  _buildFilterChip('Low Stock Alert', 'Low Stock'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Products Grid
            if (_backendService.isLoading && _backendService.products.isEmpty)
              const SkeletonCardGrid(count: 6, childAspectRatio: 0.68)
            else if (products.isEmpty)
              _buildEmptyState()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return _buildProductCard(p);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String val) {
    final isSelected = _stockFilter == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF475569))),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF6366F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0))),
        onSelected: (v) => setState(() => _stockFilter = val),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: const [
          Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF6366F1)),
          SizedBox(height: 12),
          Text('No Marketplace Products Found', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          SizedBox(height: 4),
          Text('Add new items in the "Add Item" tab to publish to store.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductItem p) {
    final bool isLowStock = p.totalStock <= p.lowStockThreshold;

    return GestureDetector(
      onTap: () => _openProductSlider(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Product Image with R2 CDN Badge
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
                    child: Image.network(
                      p.mainImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Center(
                        child: Icon(Icons.shopping_bag_rounded, size: 36, color: Color(0xFF6366F1)),
                      ),
                    ),
                  ),

                  // Category Pill
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.categoryName,
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Variants Count Badge
                  if (p.variants.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${p.variants.length} Vars',
                          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details Footer
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.brand.toUpperCase(),
                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF6366F1), fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.title,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Price Row
                  Row(
                    children: [
                      Text('₹${p.price.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      if (p.regularPrice > p.price) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${p.regularPrice.toInt()}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Stock Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${p.totalStock} in stock',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isLowStock ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isLowStock ? const Color(0xFFEF4444).withOpacity(0.12) : const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isLowStock ? 'Low Stock' : p.stockStatus,
                          style: TextStyle(
                            color: isLowStock ? const Color(0xFFEF4444) : const Color(0xFF10B981),
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
// 3. PRODUCT DETAILS SLIDER SHEET (SWIPEABLE GALLERY CAROUSEL + FULL INFO)
// =========================================================================
class _ProductDetailsSliderSheet extends StatefulWidget {
  final ProductItem product;
  final VoidCallback onUpdated;

  const _ProductDetailsSliderSheet({required this.product, required this.onUpdated});

  @override
  State<_ProductDetailsSliderSheet> createState() => _ProductDetailsSliderSheetState();
}

class _ProductDetailsSliderSheetState extends State<_ProductDetailsSliderSheet> {
  int _currentCarouselIndex = 0;
  late TextEditingController _titleCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late String _stockStatus;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.product.title);
    _priceCtrl = TextEditingController(text: widget.product.price.toInt().toString());
    _stockCtrl = TextEditingController(text: widget.product.totalStock.toString());
    _stockStatus = widget.product.stockStatus;
  }

  void _handleSave() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    Navigator.pop(context);

    widget.product.title = title;
    widget.product.price = double.tryParse(_priceCtrl.text.trim()) ?? widget.product.price;
    widget.product.totalStock = int.tryParse(_stockCtrl.text.trim()) ?? widget.product.totalStock;
    widget.product.stockStatus = _stockStatus;
    widget.product.updatedAt = DateTime.now();

    await ProductsBackendService().updateProduct(widget.product);
    widget.onUpdated();
  }

  void _handleDelete() {
    Navigator.pop(context);
    ProductsBackendService().deleteProduct(widget.product.productId);
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> allImages = [
      widget.product.mainImageUrl,
      ...widget.product.galleryImages,
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(width: 44, height: 4.5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Product Details & Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('${widget.product.brand} • ID: ${widget.product.productId}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SWIPEABLE GALLERY CAROUSEL
                  SizedBox(
                    height: 220,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: PageView.builder(
                            itemCount: allImages.length,
                            onPageChanged: (i) => setState(() => _currentCarouselIndex = i),
                            itemBuilder: (context, index) {
                              return Image.network(
                                allImages[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (c, e, s) => Container(
                                  color: const Color(0xFF0F172A),
                                  child: const Center(child: Icon(Icons.shopping_bag_rounded, size: 48, color: Color(0xFF6366F1))),
                                ),
                              );
                            },
                          ),
                        ),

                        // Carousel Dots Indicator
                        if (allImages.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: allImages.asMap().entries.map((entry) {
                                final isSelected = _currentCarouselIndex == entry.key;
                                return Container(
                                  width: isSelected ? 18 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        // Photo Counter Badge
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              '${_currentCarouselIndex + 1} / ${allImages.length} Photos',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. CATEGORY & DISCOUNT BADGES
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(widget.product.categoryName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                      ),
                      if (widget.product.subCategoryName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: Text(widget.product.subCategoryName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                        ),
                      ],
                      if (widget.product.discountCode != null && widget.product.discountCode!.isNotEmpty) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_offer_rounded, size: 12, color: Color(0xFFD97706)),
                              const SizedBox(width: 4),
                              Text(widget.product.discountCode!, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. EDITABLE TITLE & PRICING
                  const Text('Product Title', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  TextField(controller: _titleCtrl, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selling Price (₹)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            TextField(controller: _priceCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stock Quantity', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            TextField(controller: _stockCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. DESCRIPTION
                  const Text('Product Description', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Text(widget.product.description, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)),
                  ),
                  const SizedBox(height: 18),

                  // 5. VARIANTS BREAKDOWN
                  if (widget.product.variants.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Product Variations (${widget.product.variants.length})', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                        const Text('Dedicated Stock & SKU', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.product.variants.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final v = widget.product.variants[index];
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  v.imageUrl.isNotEmpty ? v.imageUrl : widget.product.mainImageUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(width: 36, height: 36, color: const Color(0xFFE2E8F0), child: const Icon(Icons.style_rounded, size: 18)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                    Text('₹${v.price.toInt()} • ${v.stock} in stock • SKU: ${v.sku}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 6. STOCK STATUS SELECTOR
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Inventory Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _stockStatus,
                            items: ['In Stock', 'Out of Stock', 'Backorder'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)))).toList(),
                            onChanged: (val) => setState(() => _stockStatus = val!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 7. FULL EDIT & DELETE ACTIONS
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close slider
                      // Open Full Add/Edit Product Screen modal
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => Container(
                          height: MediaQuery.of(ctx).size.height * 0.92,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              Container(width: 44, height: 4.5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  child: MarketplaceAddProductView(
                                    selectedDateRange: 'All Time',
                                    fadeAnimations: const [AlwaysStoppedAnimation(1.0)],
                                    slideAnimations: const [AlwaysStoppedAnimation(Offset.zero)],
                                    productToEdit: widget.product,
                                    onProductUpdated: () {
                                      Navigator.pop(ctx);
                                      widget.onUpdated();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_document, size: 18),
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Edit in Full Product Form', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444)), foregroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _handleDelete,
                          child: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _handleSave,
                          child: const Text('Quick Save', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
