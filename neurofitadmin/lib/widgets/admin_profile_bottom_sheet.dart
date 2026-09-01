import 'package:flutter/material.dart';

class AdminProfileBottomSheet extends StatefulWidget {
  const AdminProfileBottomSheet({super.key});

  @override
  State<AdminProfileBottomSheet> createState() => _AdminProfileBottomSheetState();
}

class _AdminProfileBottomSheetState extends State<AdminProfileBottomSheet> {
  bool _biometricsEnabled = true;
  bool _realTimeAlerts = true;
  bool _autoBackups = true;

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
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Top Admin Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF6366F1), width: 2),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/trainers_hero_banner.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.white, size: 30),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
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
                                const Text(
                                  'Rohit Singhania',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'MASTER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Chief Systems Architect & Administrator',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(Icons.email_outlined, size: 11, color: Color(0xFF6366F1)),
                                SizedBox(width: 4),
                                Text(
                                  'admin@neurofit.app',
                                  style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Matrix Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildProfileStat('Actions Taken', '1,420', const Color(0xFF6366F1))),
                      Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),
                      Expanded(child: _buildProfileStat('Approvals', '348', const Color(0xFF10B981))),
                      Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),
                      Expanded(child: _buildProfileStat('Security Level', 'Level 5 HQ', const Color(0xFFF59E0B))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 1: Security & Quick Toggles
                const Text(
                  'SYSTEM PREFERENCES & SECURITY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.6),
                ),
                const SizedBox(height: 10),
                _buildToggleTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Admin Access',
                  subtitle: 'Require TouchID / FaceID to approve high-value transactions',
                  value: _biometricsEnabled,
                  onChanged: (v) => setState(() => _biometricsEnabled = v),
                ),
                _buildToggleTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Real-Time Critical Notifications',
                  subtitle: 'Push instant alerts for trainer applications & disputes',
                  value: _realTimeAlerts,
                  onChanged: (v) => setState(() => _realTimeAlerts = v),
                ),
                _buildToggleTile(
                  icon: Icons.cloud_sync_rounded,
                  title: 'Automated Nightly Backups',
                  subtitle: 'Sync encrypted PostgreSQL database snapshots to AWS S3',
                  value: _autoBackups,
                  onChanged: (v) => setState(() => _autoBackups = v),
                ),

                const SizedBox(height: 18),
                const Text(
                  'COMMAND ACTIONS & SESSIONS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.6),
                ),
                const SizedBox(height: 10),

                _buildActionTile(
                  icon: Icons.vpn_key_rounded,
                  title: 'API Keys & Webhooks Hub',
                  subtitle: 'Manage Stripe, Razorpay & Firebase service tokens',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API Tokens & Webhooks are in active synchronization.')),
                    );
                  },
                ),
                _buildActionTile(
                  icon: Icons.history_edu_rounded,
                  title: 'Export Audit Log (CSV / JSON)',
                  subtitle: 'Download complete timestamped administrative trail',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Audit log generated and ready for export.')),
                    );
                  },
                ),
                _buildActionTile(
                  icon: Icons.devices_rounded,
                  title: 'Active Master Sessions (2 Nodes)',
                  subtitle: 'Bengaluru HQ (MacBook Pro) • Mumbai Edge Server',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {},
                ),

                const SizedBox(height: 14),

                // Sign Out Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF2F2),
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Securely signed out of Admin Console.'), backgroundColor: Color(0xFF0F172A)),
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Sign Out of Admin Console',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
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

  Widget _buildProfileStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF6366F1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
      ),
    );
  }
}
