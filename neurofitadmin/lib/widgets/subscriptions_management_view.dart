import 'package:flutter/material.dart';
import '../services/plans_backend_service.dart';

class SubscriptionsManagementView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const SubscriptionsManagementView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<SubscriptionsManagementView> createState() =>
      _SubscriptionsManagementViewState();
}

class _SubscriptionsManagementViewState extends State<SubscriptionsManagementView> {
  final PlansBackendService _backendService = PlansBackendService();
  bool _isYearlyBilling = true;

  void _openCreatePlanSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlanFormSliderSheet(
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _openEditPlanSheet(SubscriptionPlanModel plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlanFormSliderSheet(
        planToEdit: plan,
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

    final plans = _backendService.plans;

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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Subscription Plans',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tiered pricing, features & active subscriber sync',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: _openCreatePlanSheet,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Create Plan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Billing Frequency Switcher Strip
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isYearlyBilling = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isYearlyBilling ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: !_isYearlyBilling
                              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            'Monthly Billing',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: !_isYearlyBilling ? FontWeight.w900 : FontWeight.w600,
                              color: !_isYearlyBilling ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isYearlyBilling = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isYearlyBilling ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _isYearlyBilling
                              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
                              : [],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Yearly Pass',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _isYearlyBilling ? FontWeight.w900 : FontWeight.w600,
                                  color: _isYearlyBilling ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'SAVE UP TO 40%',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subscription Plans Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plans.length,
              separatorBuilder: (c, i) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _buildPlanCard(plan);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanModel plan) {
    final bool isDeactivated = plan.status == 'Deactivated';
    final double price = _isYearlyBilling ? plan.yearlyPrice : plan.monthlyPrice;
    final String period = _isYearlyBilling ? '/ Year' : '/ Month';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: plan.isPopular ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          width: plan.isPopular ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.isPopular ? const Color(0xFF6366F1).withOpacity(0.08) : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: plan.isPopular ? const Color(0xFF6366F1).withOpacity(0.05) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan.badge.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: plan.isPopular ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            plan.badge,
                            style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        plan.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDeactivated ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.tagline,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF6366F1)),
                  onPressed: () => _openEditPlanSheet(plan),
                ),
              ],
            ),
          ),

          // Price & Metrics Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price == 0 ? 'FREE' : '₹${price.toInt()}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    if (price > 0) ...[
                      const SizedBox(width: 4),
                      Text(period, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${plan.subscribersCount} Active Athletes',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // Features List
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('INCLUDED FEATURES', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                const SizedBox(height: 8),
                ...plan.features.map((feat) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feat,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 4. PLAN CREATE & EDIT SLIDER SHEET (DYNAMIC FEATURES BUILDER)
// =========================================================================
class _PlanFormSliderSheet extends StatefulWidget {
  final SubscriptionPlanModel? planToEdit;
  final VoidCallback onSaved;

  const _PlanFormSliderSheet({this.planToEdit, required this.onSaved});

  @override
  State<_PlanFormSliderSheet> createState() => _PlanFormSliderSheetState();
}

class _PlanFormSliderSheetState extends State<_PlanFormSliderSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _badgeCtrl;
  late TextEditingController _monthlyPriceCtrl;
  late TextEditingController _yearlyPriceCtrl;
  final TextEditingController _newFeatureCtrl = TextEditingController();

  late List<String> _features;
  late bool _isPopular;
  late String _status;
  bool _isSaving = false;

  bool get isEditMode => widget.planToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.planToEdit;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _taglineCtrl = TextEditingController(text: p?.tagline ?? '');
    _badgeCtrl = TextEditingController(text: p?.badge ?? '');
    _monthlyPriceCtrl = TextEditingController(text: p != null ? p.monthlyPrice.toInt().toString() : '499');
    _yearlyPriceCtrl = TextEditingController(text: p != null ? p.yearlyPrice.toInt().toString() : '4499');

    _features = p != null ? List<String>.from(p.features) : [
      'Unlimited AI Hypertrophy & Strength Coach',
      '200+ Masterclass Video Programs with Form Scanner',
      'Complete Nutrition & Macro Food Scanner',
    ];
    _isPopular = p?.isPopular ?? false;
    _status = p?.status ?? 'Active';
  }

  void _addFeature() {
    final f = _newFeatureCtrl.text.trim();
    if (f.isNotEmpty) {
      setState(() {
        _features.add(f);
        _newFeatureCtrl.clear();
      });
    }
  }

  void _handleSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter plan title')));
      return;
    }

    setState(() => _isSaving = true);
    Navigator.pop(context);

    final mPrice = double.tryParse(_monthlyPriceCtrl.text.trim()) ?? 0.0;
    final yPrice = double.tryParse(_yearlyPriceCtrl.text.trim()) ?? 0.0;

    if (isEditMode) {
      final p = widget.planToEdit!;
      p.name = name;
      p.title = name;
      p.tagline = _taglineCtrl.text.trim();
      p.badge = _badgeCtrl.text.trim();
      p.monthlyPrice = mPrice;
      p.yearlyPrice = yPrice;
      p.features = _features;
      p.isPopular = _isPopular;
      p.status = _status;
      p.isActive = (_status == 'Active');
      p.updatedAt = DateTime.now();

      await PlansBackendService().updatePlan(p);
      widget.onSaved();
    } else {
      await PlansBackendService().createPlan(
        name: name,
        tagline: _taglineCtrl.text.trim(),
        badge: _badgeCtrl.text.trim(),
        monthlyPrice: mPrice,
        yearlyPrice: yPrice,
        features: _features,
        isPopular: _isPopular,
      );
      widget.onSaved();
    }
  }

  void _handleDelete() {
    if (widget.planToEdit == null) return;
    Navigator.pop(context);
    PlansBackendService().deletePlan(widget.planToEdit!.planId);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 44, height: 4.5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEditMode ? 'Edit Subscription Plan' : 'Create Subscription Plan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const Text('Saved to Firestore subscription_plans collection', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Plan Name (e.g. NeuroFit Pro Athlete)')),
                  const SizedBox(height: 10),

                  TextField(controller: _taglineCtrl, decoration: const InputDecoration(labelText: 'Tagline / Short Summary')),
                  const SizedBox(height: 10),

                  TextField(controller: _badgeCtrl, decoration: const InputDecoration(labelText: 'Badge Tag (e.g. 🔥 MOST POPULAR)')),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: TextField(controller: _monthlyPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Price (₹)'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _yearlyPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Yearly Price (₹)'))),
                    ],
                  ),
                  const SizedBox(height: 14),

                  SwitchListTile.adaptive(
                    title: const Text('Highlight as Most Popular Plan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    subtitle: const Text('Adds glowing primary border on athlete checkout', style: TextStyle(fontSize: 11)),
                    value: _isPopular,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (v) => setState(() => _isPopular = v),
                  ),
                  const SizedBox(height: 14),

                  // Features Builder
                  const Text('Plan Features Builder', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newFeatureCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Access to 250+ Masterclasses',
                            hintStyle: TextStyle(fontSize: 12),
                          ),
                          onSubmitted: (v) => _addFeature(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        onPressed: _addFeature,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ..._features.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                            GestureDetector(
                              onTap: () => setState(() => _features.removeAt(entry.key)),
                              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      if (isEditMode) ...[
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444)), foregroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: _handleDelete,
                            child: const Text('Delete Plan', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _handleSave,
                          child: Text(isEditMode ? 'Save Plan Updates' : 'Publish Subscription Plan', style: const TextStyle(fontWeight: FontWeight.w800)),
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
