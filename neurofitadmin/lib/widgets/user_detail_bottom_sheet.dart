import 'package:flutter/material.dart';

void showUserDetailModal(BuildContext context, Map<String, dynamic> user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (ctx) => UserDetailBottomSheet(user: user),
  );
}

class UserDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailBottomSheet({super.key, required this.user});

  @override
  State<UserDetailBottomSheet> createState() => _UserDetailBottomSheetState();
}

class _UserDetailBottomSheetState extends State<UserDetailBottomSheet> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0=Personal Info, 1=Subscription & Payments, 2=Shopping, 3=Fitness Activity
  late String _userStatus;
  late bool _isVip;

  @override
  void initState() {
    super.initState();
    _userStatus = widget.user['status'] ?? 'Active';
    _isVip = widget.user['badge'] == 'VIP' || (widget.user['plan'] ?? '').toString().contains('VIP');
  }

  void _showActionSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 12)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWarningDialog() {
    final textController = TextEditingController(text: 'Violation of community guidelines or missed activity logs.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 8),
            Text('Issue User Warning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send a formal administrative warning to ${widget.user['name']}:', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Enter reason for warning...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              _showActionSnackbar('Warning notification sent to ${widget.user['name']} via Push & Email!', const Color(0xFFF59E0B));
            },
            child: const Text('Send Warning', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('Suspend User Account?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          'Are you sure you want to suspend ${widget.user['name']}? They will be immediately logged out and blocked from booking workouts and placing orders.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _userStatus = 'Suspended';
              });
              _showActionSnackbar('${widget.user['name']} has been suspended from the platform.', const Color(0xFFEF4444));
            },
            child: const Text('Confirm Suspend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog() {
    String selected = _userStatus;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Update User Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Active', 'Pending Verification', 'Inactive', 'Suspended'].map((status) {
              return RadioListTile<String>(
                title: Text(status, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                value: status,
                groupValue: selected,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) {
                  if (val != null) {
                    setDlgState(() => selected = val);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _userStatus = selected);
                _showActionSnackbar('User status successfully updated to "$selected"!', const Color(0xFF10B981));
              },
              child: const Text('Save Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final name = u['name'] ?? 'User Profile';
    final email = u['email'] ?? 'user@neurofit.com';
    final phone = u['phone'] ?? '+91 98765 43210';
    final img = u['img'] ?? 'assets/images/trainers_hero_banner.jpg';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // 1. DRAG HANDLE
          const SizedBox(height: 10),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),

          // 2. USER HEADER PROFILE BANNER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _isVip ? const Color(0xFFF59E0B) : const Color(0xFF10B981), width: 2),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: Image.asset(img, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, size: 30)),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _userStatus == 'Suspended' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _userStatus == 'Suspended' ? Icons.close_rounded : Icons.check_rounded,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                          if (_isVip) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                children: const [
                                  Icon(Icons.workspace_premium_rounded, size: 10, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 2),
                                  Text('VIP', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. TAB PILLS (Personal Info, Subscription & Payments, Shopping, Fitness)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildTabPill(0, 'Personal Info', Icons.person_outline_rounded),
                  const SizedBox(width: 6),
                  _buildTabPill(1, 'Subscription & Payments', Icons.credit_card_rounded),
                  const SizedBox(width: 6),
                  _buildTabPill(2, 'Shopping & Orders', Icons.shopping_bag_outlined),
                  const SizedBox(width: 6),
                  _buildTabPill(3, 'Fitness Activity', Icons.fitness_center_rounded),
                ],
              ),
            ),
          ),
          const Divider(height: 20, thickness: 0.8, color: Color(0xFFF1F5F9)),

          // 4. TAB CONTENT VIEW
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                if (_selectedTab == 0) _buildPersonalInfoTab(u),
                if (_selectedTab == 1) _buildSubscriptionTab(u),
                if (_selectedTab == 2) _buildShoppingTab(u),
                if (_selectedTab == 3) _buildFitnessActivityTab(u),
              ],
            ),
          ),

          // 5. STICKY ADMIN ACTION BUTTONS
          _buildAdminActionFooter(name),
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: PERSONAL INFO
  Widget _buildPersonalInfoTab(Map<String, dynamic> u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Profile & Demographics', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        _buildInfoGrid([
          {'label': 'Gender / Age', 'val': 'Male, 28 Yrs', 'icon': Icons.person_rounded},
          {'label': 'Height / Weight', 'val': '178 cm • 76 kg', 'icon': Icons.accessibility_new_rounded},
          {'label': 'BMI Status', 'val': '24.0 (Normal)', 'icon': Icons.monitor_weight_outlined},
          {'label': 'Primary Goal', 'val': 'Weight Loss & Tone', 'icon': Icons.flag_circle_rounded},
          {'label': 'Daily Calorie Goal', 'val': '2,200 kcal', 'icon': Icons.local_fire_department_rounded},
          {'label': 'Assigned Trainer', 'val': u['trainer'] ?? 'Amit Sharma', 'icon': Icons.sports_gymnastics_rounded},
          {'label': 'Location', 'val': 'Mumbai, Maharashtra', 'icon': Icons.location_on_outlined},
          {'label': 'Platform / OS', 'val': 'iPhone 15 • iOS 18.2', 'icon': Icons.phone_iphone_rounded},
        ]),
        const SizedBox(height: 16),
        const Text('Account Metadata', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              _buildMetaRow('User ID', 'USR-8947219'),
              const Divider(height: 14, thickness: 0.6),
              _buildMetaRow('Acquisition Source', u['source'] ?? 'Mobile App (Organic)'),
              const Divider(height: 14, thickness: 0.6),
              _buildMetaRow('Registration Date', u['joined'] ?? 'May 20, 2025'),
              const Divider(height: 14, thickness: 0.6),
              _buildMetaRow('Current Status', _userStatus, color: _userStatus == 'Suspended' ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 2: SUBSCRIPTION & PAYMENTS
  Widget _buildSubscriptionTab(Map<String, dynamic> u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF65D300), borderRadius: BorderRadius.circular(6)),
                    child: const Text('ACTIVE PLAN', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  ),
                  const Text('₹12,499 / Year', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 10),
              Text(u['plan'] ?? 'Pro Elite Membership', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Renews automatically on Nov 26, 2025 • Auto-Debit via UPI', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Billing & Invoices', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            Text('Download All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 10),
        _buildInvoiceItem('#INV-9821', 'Annual Subscription Renewal', '₹12,499', 'Paid', 'May 20, 2025'),
        _buildInvoiceItem('#INV-8734', 'Personal Mentorship Add-on', '₹3,999', 'Paid', 'Apr 15, 2025'),
        _buildInvoiceItem('#INV-7612', 'Custom Nutrition Plan (12 Wk)', '₹1,499', 'Paid', 'Mar 10, 2025'),
      ],
    );
  }

  // TAB 3: SHOPPING & ORDERS
  Widget _buildShoppingTab(Map<String, dynamic> u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Total Orders', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                    SizedBox(height: 2),
                    Text('8 Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Marketplace Spend', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9))),
                    SizedBox(height: 2),
                    Text('₹14,392', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF5B21B6))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Recent Store Orders', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        _buildOrderItem('#ORD-8742', 'Whey Protein Isolate 1kg (Chocolate)', '₹2,499', 'Delivered', 'May 24, 2025', 'assets/images/nutrifit_whey_protein.jpg'),
        _buildOrderItem('#ORD-8620', 'Creatine Monohydrate 250g + Shaker', '₹1,899', 'Delivered', 'May 10, 2025', 'assets/images/product_1.png'),
        _buildOrderItem('#ORD-8410', 'Resistance Band Set (5 Levels)', '₹799', 'Delivered', 'Apr 28, 2025', 'assets/images/product_2.png'),
      ],
    );
  }

  // TAB 4: FITNESS ACTIVITY
  Widget _buildFitnessActivityTab(Map<String, dynamic> u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatBox('Workouts', '78', '+14.2%', Icons.fitness_center_rounded, const Color(0xFF10B981)),
            _buildStatBox('Streak', '24d', 'Active', Icons.local_fire_department_rounded, const Color(0xFFF97316)),
            _buildStatBox('Calories', '48.5K', 'Burned', Icons.bolt_rounded, const Color(0xFF8B5CF6)),
            _buildStatBox('Time', '64.5h', 'Total', Icons.timer_outlined, const Color(0xFF3B82F6)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Recent Logged Sessions', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        _buildActivityItem('Full Body Strength & Core', '48 mins • 420 kcal burned', 'Today, 7:30 AM', const Color(0xFF10B981)),
        _buildActivityItem('High Intensity HIIT Blast', '35 mins • 380 kcal burned', 'Yesterday, 8:00 AM', const Color(0xFF8B5CF6)),
        _buildActivityItem('Yoga & Flexibility Routine', '45 mins • 210 kcal burned', 'May 24, 6:45 AM', const Color(0xFF3B82F6)),
      ],
    );
  }

  // HELPER WIDGETS
  Widget _buildInfoGrid(List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: items.map((it) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(it['icon'] as IconData, size: 14, color: const Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(it['label'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(it['val'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetaRow(String k, String v, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        Text(v, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color ?? const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildInvoiceItem(String id, String desc, String amt, String status, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text('$id • $date', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text(status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String id, String title, String amt, String status, String date, String img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(img, width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$id • $date', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(amt, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String val, String sub, IconData icon, Color color) {
    return Container(
      width: 76,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          Text(label, style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String desc, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 4, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text(desc, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // 5. STICKY ADMIN ACTION FOOTER
  Widget _buildAdminActionFooter(String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  label: _isVip ? 'Remove VIP' : '👑 Make VIP',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    setState(() => _isVip = !_isVip);
                    _showActionSnackbar(_isVip ? '$name promoted to VIP status!' : 'VIP status removed from $name.', const Color(0xFFF59E0B));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBtn(
                  label: '🔄 Status',
                  color: const Color(0xFF3B82F6),
                  onTap: _showUpdateStatusDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBtn(
                  label: '⚠️ Warning',
                  color: const Color(0xFFF97316),
                  onTap: _showWarningDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBtn(
                  label: '🚫 Suspend',
                  color: const Color(0xFFEF4444),
                  onTap: _showSuspendDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
