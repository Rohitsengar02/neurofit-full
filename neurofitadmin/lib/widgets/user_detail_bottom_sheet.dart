import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import '../backend/live_backend.dart';
import 'net_or_asset_image.dart';

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

  Map<String, dynamic> _ov = {};
  String get _uid => (widget.user['uid'] ?? widget.user['id'] ?? '').toString();

  static String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'suspended':
      case 'banned':
        return 'Suspended';
      case 'inactive':
        return 'Inactive';
      case 'pending':
      case 'pending verification':
        return 'Pending Verification';
      default:
        return 'Active';
    }
  }

  @override
  void initState() {
    super.initState();
    _userStatus = _statusLabel((widget.user['status'] ?? 'Active').toString());
    _isVip = widget.user['isPremium'] == true || widget.user['badge'] == 'VIP' || (widget.user['plan'] ?? '').toString().contains('VIP');
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    if (_uid.isEmpty) return;
    try {
      final j = await Api.get('/admin/users/$_uid/overview');
      if (!mounted) return;
      setState(() {
        _ov = Map<String, dynamic>.from(j['data'] as Map);
        final u = Map<String, dynamic>.from(_ov['user'] as Map);
        _userStatus = _statusLabel((u['status'] ?? 'active').toString());
        _isVip = u['isPremium'] == true;
      });
    } catch (_) {}
  }

  Future<bool> _act(Future<void> Function() fn, String okMsg, Color color) async {
    try {
      await fn();
      _showActionSnackbar(okMsg, color);
      return true;
    } catch (e) {
      _showActionSnackbar('Could not update: $e', const Color(0xFFEF4444));
      return false;
    }
  }

  Map<String, dynamic> get _ou => _ov['user'] is Map ? Map<String, dynamic>.from(_ov['user']) : Map<String, dynamic>.from(widget.user);
  Map<String, dynamic> get _q => _ou['questionnaireData'] is Map ? Map<String, dynamic>.from(_ou['questionnaireData']) : {};
  String _qv(List<String> keys) {
    for (final k in keys) {
      final v = _q[k] ?? _ou[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return '';
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
              _act(() => Api.send('POST', '/notifications', {'userId': _uid, 'title': 'Account warning', 'body': textController.text.trim(), 'type': 'warning'}),
                  'Warning sent to ${widget.user['name']} in the app.', const Color(0xFFF59E0B));
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
              _act(() => Api.send('PATCH', '/users/$_uid/status', {'status': 'suspended'}),
                  '${widget.user['name']} has been suspended from the platform.', const Color(0xFFEF4444)).then((ok) {
                if (ok && mounted) setState(() => _userStatus = 'Suspended');
              });
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
                const map = {'Active': 'active', 'Pending Verification': 'pending', 'Inactive': 'inactive', 'Suspended': 'suspended'};
                _act(() => Api.send('PATCH', '/users/$_uid/status', {'status': map[selected] ?? 'active'}),
                    'User status successfully updated to "$selected"!', const Color(0xFF10B981)).then((ok) {
                  if (ok && mounted) setState(() => _userStatus = selected);
                });
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
    final u = {...widget.user, ..._ou};
    final name = (u['name'] ?? 'User Profile').toString();
    final email = (u['email'] ?? '').toString();
    final phone = (u['phone'] ?? '').toString().isEmpty ? 'No phone added' : u['phone'].toString();
    final img = ((u['photoUrl'] ?? '').toString().isNotEmpty ? u['photoUrl'] : (u['img'] ?? 'assets/images/trainers_hero_banner.jpg')).toString();

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
                        child: NetOrAssetImage(img, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, size: 30)),
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
        _buildInfoGrid(() {
          final gender = _qv(['gender']);
          final age = _qv(['age']);
          final h = double.tryParse(_qv(['height', 'heightCm']).replaceAll(RegExp(r'[^0-9.]'), ''));
          final w = double.tryParse(_qv(['weight', 'currentWeight', 'weightKg']).replaceAll(RegExp(r'[^0-9.]'), ''));
          String bmi = 'Not set';
          if (h != null && w != null && h > 0) {
            final b = w / ((h / 100) * (h / 100));
            bmi = '${b.toStringAsFixed(1)} (${b < 18.5 ? 'Underweight' : b < 25 ? 'Normal' : b < 30 ? 'Overweight' : 'Obese'})';
          }
          final t = _ov['targets'] is Map ? _ov['targets'] as Map : const {};
          final sub = _ov['subscription'] is Map ? _ov['subscription'] as Map : null;
          final addr = (u['addresses'] is List && (u['addresses'] as List).isNotEmpty) ? (u['addresses'] as List).first as Map : const {};
          final loc = [addr['city'], addr['state']].where((x) => x != null && x.toString().isNotEmpty).join(', ');
          return [
            {'label': 'Gender / Age', 'val': [if (gender.isNotEmpty) gender, if (age.isNotEmpty) '$age Yrs'].join(', ').ifEmpty('Not set'), 'icon': Icons.person_rounded},
            {'label': 'Height / Weight', 'val': [if (h != null) '${h.toStringAsFixed(0)} cm', if (w != null) '${w.toStringAsFixed(0)} kg'].join(' • ').ifEmpty('Not set'), 'icon': Icons.accessibility_new_rounded},
            {'label': 'BMI Status', 'val': bmi, 'icon': Icons.monitor_weight_outlined},
            {'label': 'Primary Goal', 'val': _qv(['goal', 'primaryGoal', 'fitnessGoal']).ifEmpty('Not set'), 'icon': Icons.flag_circle_rounded},
            {'label': 'Daily Calorie Goal', 'val': t['targetCalories'] == null ? '-' : '${fmtInt(t['targetCalories'] as num)} kcal', 'icon': Icons.local_fire_department_rounded},
            {'label': 'Assigned Trainer', 'val': (sub?['trainerName'] ?? 'None').toString(), 'icon': Icons.sports_gymnastics_rounded},
            {'label': 'Location', 'val': loc.ifEmpty('Not set'), 'icon': Icons.location_on_outlined},
            {'label': 'Sign-in Method', 'val': (u['authProvider'] ?? 'email').toString() == 'google' ? 'Google' : 'Email & password', 'icon': Icons.phone_iphone_rounded},
          ];
        }()),
        const SizedBox(height: 16),
        const Text('Account Metadata', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              _buildMetaRow('User ID', _uid),
              const Divider(height: 14, thickness: 0.6),
              _buildMetaRow('Acquisition Source', (u['authProvider'] ?? '') == 'google' ? 'Google sign-up' : 'Email sign-up'),
              const Divider(height: 14, thickness: 0.6),
              _buildMetaRow('Registration Date', shortDate(u['createdAt']?.toString()).ifEmpty((u['joined'] ?? '').toString())),
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
    final sub = _ov['subscription'] is Map ? Map<String, dynamic>.from(_ov['subscription']) : null;
    final active = sub != null && sub['status'] != 'cancelled' && (DateTime.tryParse(sub['until'] ?? '')?.isAfter(DateTime.now()) ?? false);
    final months = (sub?['months'] as num?)?.toInt() ?? 1;
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
                    child: Text(active ? 'ACTIVE PLAN' : (_isVip ? 'VIP MEMBER' : 'FREE PLAN'), style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  ),
                  Text(sub == null ? '₹0' : '${fmtInr(sub['amount'] as num? ?? 0)} / ${months == 12 ? 'Year' : months == 1 ? 'Month' : '$months Months'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 10),
              Text(sub == null ? 'No coaching plan' : '${sub['trainerName'] ?? 'Coach'} · ${sub['planName'] ?? ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 4),
              Text(sub == null ? 'The user has not subscribed to a coach yet' : '${active ? 'Active until' : 'Ended on'} ${shortDate(sub['until']?.toString())} • Payment ${sub['paymentStatus'] ?? 'pending'}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
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
        if (sub != null) _buildInvoiceItem('#${sub['id']}', '${sub['planName'] ?? 'Coaching'} plan with ${sub['trainerName'] ?? 'coach'}', fmtInr(sub['amount'] as num? ?? 0), (sub['paymentStatus'] ?? 'pending').toString().toUpperCase() == 'PAID' ? 'Paid' : 'Pending', shortDate(sub['createdAt']?.toString())),
        for (final o in (_ov['orders'] as List? ?? const []).take(3))
          _buildInvoiceItem('#${o['orderId']}', 'Store order (${(o['items'] as List?)?.length ?? 0} items)', fmtInr(num.tryParse('${o['totalAmount'] ?? 0}') ?? 0), (o['paymentStatus'] ?? 'Pending').toString(), shortDate(o['createdAt']?.toString())),
        if (sub == null && (_ov['orders'] as List? ?? const []).isEmpty)
          const Padding(padding: EdgeInsets.all(8), child: Text('No payments yet', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))),
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
                  children: [
                    const Text('Total Orders', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                    const SizedBox(height: 2),
                    Text('${_ov['orderCount'] ?? 0} Orders', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
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
                  children: [
                    const Text('Marketplace Spend', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9))),
                    const SizedBox(height: 2),
                    Text(fmtInr(_ov['spend'] as num? ?? 0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF5B21B6))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Recent Store Orders', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        for (final o in (_ov['orders'] as List? ?? const []))
          () {
            final items = (o['items'] as List?) ?? const [];
            final first = items.isNotEmpty && items.first is Map ? items.first as Map : const {};
            final title = items.isEmpty ? 'Order' : '${first['name'] ?? first['title'] ?? 'Item'}${items.length > 1 ? ' + ${items.length - 1} more' : ''}';
            final img = (first['imageUrl'] ?? first['image'] ?? first['mainImageUrl'] ?? 'assets/images/product_1.png').toString();
            return _buildOrderItem('#${o['orderId']}', title, fmtInr(num.tryParse('${o['totalAmount'] ?? 0}') ?? 0), (o['orderStatus'] ?? '').toString(), shortDate(o['createdAt']?.toString()), img);
          }(),
        if ((_ov['orders'] as List? ?? const []).isEmpty)
          const Padding(padding: EdgeInsets.all(8), child: Text('No orders yet', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))),
      ],
    );
  }

  // TAB 4: FITNESS ACTIVITY
  Widget _buildFitnessActivityTab(Map<String, dynamic> u) {
    final w = _ov['workouts'] is Map ? Map<String, dynamic>.from(_ov['workouts']) : <String, dynamic>{};
    final mins = (w['minutes'] as num?) ?? 0;
    const colors = [Color(0xFF10B981), Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFFF97316), Color(0xFFEF4444)];
    final recent = (w['recent'] as List?) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatBox('Workouts', '${w['completed'] ?? 0}', '', Icons.fitness_center_rounded, const Color(0xFF10B981)),
            _buildStatBox('Streak', '${w['streak'] ?? 0}d', 'Active', Icons.local_fire_department_rounded, const Color(0xFFF97316)),
            _buildStatBox('Calories', fmtShort(w['calories'] as num? ?? 0), 'Burned', Icons.bolt_rounded, const Color(0xFF8B5CF6)),
            _buildStatBox('Time', mins >= 60 ? '${(mins / 60).toStringAsFixed(1)}h' : '${mins}m', 'Total', Icons.timer_outlined, const Color(0xFF3B82F6)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Recent Logged Sessions', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        for (var i = 0; i < recent.length; i++)
          _buildActivityItem(
            '${recent[i]['workoutTitle'] ?? 'Workout'} · Day ${recent[i]['dayNumber'] ?? 1}',
            '${(((recent[i]['totalDurationSeconds'] as num?) ?? 0) / 60).round()} mins • ${recent[i]['dayCompleted'] == true ? 'completed' : 'in progress'}',
            timeAgo(recent[i]['at']?.toString()),
            colors[i % colors.length],
          ),
        if (recent.isEmpty)
          const Padding(padding: EdgeInsets.all(8), child: Text('No workouts logged yet', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))),
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
            child: NetOrAssetImage(img, width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag)),
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
                    final next = !_isVip;
                    _act(() => Api.send('PUT', '/users/$_uid', {'isPremium': next}),
                        next ? '$name promoted to VIP status!' : 'VIP status removed from $name.', const Color(0xFFF59E0B)).then((ok) {
                      if (ok && mounted) setState(() => _isVip = next);
                    });
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


extension _IfEmpty on String {
  String ifEmpty(String other) => trim().isEmpty ? other : this;
}
