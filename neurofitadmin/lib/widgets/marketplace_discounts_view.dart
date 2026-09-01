import 'skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/discounts_backend_service.dart';

class MarketplaceDiscountsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const MarketplaceDiscountsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<MarketplaceDiscountsView> createState() =>
      _MarketplaceDiscountsViewState();
}

class _MarketplaceDiscountsViewState extends State<MarketplaceDiscountsView> {
  final DiscountsBackendService _discService = DiscountsBackendService();

  @override
  void initState() {
    super.initState();
    _discService.addListener(_onDiscUpdate);
    if (_discService.discounts.isEmpty) {
      _discService.fetchDiscountsFromFirestore();
    }
  }

  @override
  void dispose() {
    _discService.removeListener(_onDiscUpdate);
    super.dispose();
  }

  void _onDiscUpdate() {
    if (mounted) setState(() {});
  }
  final DiscountsBackendService _backendService = DiscountsBackendService();
  String _searchQuery = '';
  String _typeFilter = 'All';

  void _openAddDiscountModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddDiscountBottomSheet(
        onDiscountAdded: () => setState(() {}),
      ),
    );
  }

  void _openDiscountSlider(DiscountModel discount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DiscountDetailsSliderSheet(
        discount: discount,
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

    final discounts = _backendService.discounts.where((d) {
      final matchesSearch = _searchQuery.isEmpty ||
          d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _typeFilter == 'All' ||
          (_typeFilter == 'Active' && d.status == 'Active') ||
          (_typeFilter == 'percentage' && d.type == 'percentage') ||
          (_typeFilter == 'fixed' && d.type == 'fixed');
      return matchesSearch && matchesType;
    }).toList();

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Action Bar
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
                      decoration: const InputDecoration(
                        hintText: 'Search promo codes or titles...',
                        hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _openAddDiscountModal,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Discount', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('All Discounts', 'All'),
                  _buildFilterChip('Active Only', 'Active'),
                  _buildFilterChip('Percentage (%)', 'percentage'),
                  _buildFilterChip('Fixed Cost (₹)', 'fixed'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Discounts List
            if (_discService.isLoading && discounts.isEmpty)
              const SkeletonListView(count: 4)
            else if (discounts.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: discounts.length,
                separatorBuilder: (c, i) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = discounts[index];
                  return _buildDiscountCard(item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
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
          side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
        ),
        onSelected: (val) => setState(() => _typeFilter = value),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.local_offer_rounded, size: 36, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 12),
          const Text('No Discounts Found', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Create promo coupons for percentage or fixed price reductions.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildDiscountCard(DiscountModel d) {
    final bool isDeactivated = d.status == 'Deactivated';
    final bool isPercentage = d.type == 'percentage';
    final double usagePercent = (d.maxUses > 0) ? (d.usedCount / d.maxUses).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => _openDiscountSlider(d),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDeactivated ? const Color(0xFFE2E8F0) : const Color(0xFF6366F1).withOpacity(0.3),
            width: isDeactivated ? 1.0 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isDeactivated ? Colors.black.withOpacity(0.02) : const Color(0xFF6366F1).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Section (Badge, Code Pill, Value & Status)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Icon Container with Discount Type
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isPercentage
                          ? const Color(0xFF6366F1).withOpacity(0.12)
                          : const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        isPercentage ? '${d.value.toInt()}%' : '₹${d.value.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isPercentage ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Code
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isDeactivated ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Promo Code Badge with Copy
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.confirmation_number_outlined, color: Color(0xFFF59E0B), size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    d.code,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPercentage ? 'Percentage Off' : 'Fixed Discount',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Pill & Edit Icon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isDeactivated
                              ? const Color(0xFF94A3B8).withOpacity(0.15)
                              : const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          d.status,
                          style: TextStyle(
                            color: isDeactivated ? const Color(0xFF64748B) : const Color(0xFF10B981),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                    ],
                  ),
                ],
              ),
            ),

            // Dashed Divider / Card Separator
            Container(
              height: 1,
              color: const Color(0xFFF1F5F9),
            ),

            // Bottom Usage Counter Strip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Usage: ${d.usedCount} of ${d.maxUses} used',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                      ),
                      Text(
                        d.minOrderValue > 0 ? 'Min: ₹${d.minOrderValue.toInt()}' : 'No Minimum',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: usagePercent,
                      minHeight: 4.5,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usagePercent >= 0.9 ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                      ),
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
}

// =========================================================================
// 3. ADD DISCOUNT MODAL SHEET (FIXED / % TOGGLE, TITLE, CODE, USES COUNT)
// =========================================================================
class _AddDiscountBottomSheet extends StatefulWidget {
  final VoidCallback onDiscountAdded;

  const _AddDiscountBottomSheet({required this.onDiscountAdded});

  @override
  State<_AddDiscountBottomSheet> createState() => _AddDiscountBottomSheetState();
}

class _AddDiscountBottomSheetState extends State<_AddDiscountBottomSheet> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _valueCtrl = TextEditingController(text: '20');
  final TextEditingController _maxUsesCtrl = TextEditingController(text: '500');
  final TextEditingController _minOrderCtrl = TextEditingController(text: '0');

  String _selectedType = 'percentage'; // 'percentage' or 'fixed'
  bool _isProcessing = false;

  void _submitDiscount() async {
    final title = _titleCtrl.text.trim();
    final code = _codeCtrl.text.trim().toUpperCase();
    final val = double.tryParse(_valueCtrl.text.trim()) ?? 0.0;
    final maxUses = int.tryParse(_maxUsesCtrl.text.trim()) ?? 500;
    final minOrder = double.tryParse(_minOrderCtrl.text.trim()) ?? 0.0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter discount title')));
      return;
    }
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter promo code')));
      return;
    }
    if (val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid discount value')));
      return;
    }

    setState(() => _isProcessing = true);
    Navigator.pop(context);

    final res = await DiscountsBackendService().createDiscount(
      title: title,
      code: code,
      type: _selectedType,
      value: val,
      minOrderValue: minOrder,
      maxUses: maxUses,
    );

    if (res != null) {
      widget.onDiscountAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created promo coupon "$code" successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 18),
            const Text('Create Discount Promo Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            const Text('Saved to Firestore discounts collection & cached with Redis', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),

            // Discount Type Switcher (Percentage % vs Fixed Cost ₹)
            const Text('Discount Type', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = 'percentage'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == 'percentage' ? const Color(0xFF6366F1) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedType == 'percentage' ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.percent_rounded, size: 16, color: _selectedType == 'percentage' ? Colors.white : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text('Percentage (%)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _selectedType == 'percentage' ? Colors.white : const Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = 'fixed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == 'fixed' ? const Color(0xFF10B981) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedType == 'fixed' ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.currency_rupee_rounded, size: 16, color: _selectedType == 'fixed' ? Colors.white : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text('Fixed Amount (₹)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _selectedType == 'fixed' ? Colors.white : const Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Discount Title
            const Text('Promotion Title', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Summer Olympia Flash Sale',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 14),

            // Coupon Code & Discount Value Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Coupon Code', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. SUMMER20',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedType == 'percentage' ? 'Percentage (%)' : 'Amount (₹)', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: _selectedType == 'percentage' ? '20' : '500',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Max Uses & Min Order Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Max Uses Limit', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _maxUsesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '500',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Min Order (₹)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _minOrderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                onPressed: _isProcessing ? null : _submitDiscount,
                child: const Text('Create Discount & Save to Firestore', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 4. DISCOUNT DETAILS & MANAGEMENT SLIDER SHEET
// =========================================================================
class _DiscountDetailsSliderSheet extends StatefulWidget {
  final DiscountModel discount;
  final VoidCallback onUpdated;

  const _DiscountDetailsSliderSheet({required this.discount, required this.onUpdated});

  @override
  State<_DiscountDetailsSliderSheet> createState() => _DiscountDetailsSliderSheetState();
}

class _DiscountDetailsSliderSheetState extends State<_DiscountDetailsSliderSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _maxUsesCtrl;
  late TextEditingController _minOrderCtrl;
  late String _currentType;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.discount.title);
    _codeCtrl = TextEditingController(text: widget.discount.code);
    _valueCtrl = TextEditingController(text: widget.discount.value.toString());
    _maxUsesCtrl = TextEditingController(text: widget.discount.maxUses.toString());
    _minOrderCtrl = TextEditingController(text: widget.discount.minOrderValue.toString());
    _currentType = widget.discount.type;
    _currentStatus = widget.discount.status;
  }

  void _handleSave() async {
    final title = _titleCtrl.text.trim();
    final code = _codeCtrl.text.trim().toUpperCase();
    final val = double.tryParse(_valueCtrl.text.trim()) ?? widget.discount.value;
    final max = int.tryParse(_maxUsesCtrl.text.trim()) ?? widget.discount.maxUses;
    final min = double.tryParse(_minOrderCtrl.text.trim()) ?? widget.discount.minOrderValue;

    Navigator.pop(context);

    await DiscountsBackendService().updateDiscount(
      discountId: widget.discount.discountId,
      title: title,
      code: code,
      type: _currentType,
      value: val,
      minOrderValue: min,
      maxUses: max,
      status: _currentStatus,
    );

    widget.onUpdated();
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Promo Discount?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text('Are you sure you want to permanently delete coupon "${widget.discount.code}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              DiscountsBackendService().deleteDiscount(widget.discount.discountId);
              widget.onUpdated();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDeactivated = _currentStatus == 'Deactivated';

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
                    const Text('Discount Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('ID: ${widget.discount.discountId} • Live Firestore', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                  // Promo Code Big Display Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PROMO CODE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                            const SizedBox(height: 2),
                            Text(widget.discount.code, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Color(0xFFF59E0B)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.discount.code));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied code to clipboard!')));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  const Text('Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  TextField(controller: _titleCtrl, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),

                  // Discount Value
                  const Text('Discount Value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  TextField(controller: _valueCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),

                  // Max Uses Limit
                  const Text('Max Usage Limit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  TextField(controller: _maxUsesCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),

                  // Active / Deactivate Switch
                  SwitchListTile.adaptive(
                    title: Text(isDeactivated ? 'Status: Inactive' : 'Status: Active', style: TextStyle(fontWeight: FontWeight.w800, color: isDeactivated ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
                    subtitle: Text(isDeactivated ? 'Coupons will be rejected at checkout' : 'Active and applicable at athlete checkout', style: const TextStyle(fontSize: 11)),
                    value: !isDeactivated,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (v) => setState(() => _currentStatus = v ? 'Active' : 'Deactivated'),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444)), foregroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _handleDelete,
                          child: const Text('Delete Discount', style: TextStyle(fontWeight: FontWeight.w800)),
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
