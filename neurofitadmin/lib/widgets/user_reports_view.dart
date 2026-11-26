import 'package:flutter/material.dart';
import '../backend/admin_data.dart';
import '../backend/live_backend.dart';

class UserReportsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const UserReportsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<UserReportsView> createState() => _UserReportsViewState();
}

class _UserReportsViewState extends State<UserReportsView> {
  int _selectedFilter = 0; // 0=All, 1=Urgent, 2=Disputes, 3=Harassment, 4=Resolved
  String _searchQuery = '';

  final AdminList _src = AdminList.of('/community/admin/reports');

  static Map<String, dynamic> _row(Map<String, dynamic> x) {
    final count = (x['count'] as num? ?? 1).toInt();
    final urgent = count >= 3 || x['autoHidden'] == true;
    final status = x['status'] == 'resolved' ? 'Resolved' : (x['status'] == 'review' ? 'In Review' : 'Open');
    var cat = '${x['category'] ?? 'General'}';
    if ((x['targetType'] == 'order' || x['targetType'] == 'trainer') && !cat.contains('Dispute')) cat = '$cat Dispute';
    final id = '${x['id'] ?? ''}';
    final created = DateTime.tryParse('${x['createdAt'] ?? ''}');
    final age = created == null ? 0 : DateTime.now().difference(created.toLocal()).inMinutes;
    final left = (urgent ? 60 : 24 * 60) - age;
    final ev = (x['evidence'] as List? ?? const []).length;
    return {
      ...x,
      'docId': id,
      'id': '#${id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase()}',
      'title': '${x['title'] ?? 'Report'}',
      'category': cat,
      'severity': urgent ? 'Urgent' : 'Normal',
      'severityColor': urgent ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
      'severityBg': urgent ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
      'reporter': '${x['reporter'] ?? 'User'}${count > 1 ? ' +${count - 1} more' : ''}',
      'reported': '${x['reported'] ?? '-'}',
      'desc': '${x['description'] ?? ''}'.isEmpty ? 'No details given.' : '${x['description']}',
      'status': status,
      'statusColor': status == 'Resolved' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
      'sla': status == 'Resolved' ? 'Closed' : (left > 0 ? '${left >= 60 ? '${left ~/ 60}h ' : ''}${left % 60}m SLA remaining' : 'SLA passed'),
      'date': '${timeAgo(x['createdAt']?.toString())} · ${shortDate(x['createdAt']?.toString())}',
      'evidenceCount': x['autoHidden'] == true ? 'Post auto-hidden ($count reports)' : (ev > 0 ? '$ev attachment${ev == 1 ? '' : 's'}' : '$count report${count == 1 ? '' : 's'}'),
    };
  }

  List<Map<String, dynamic>> get _reportsList => [for (final x in _src.items) _row(x)];

  void _changed() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    _src.addListener(_changed);
    _src.load();
  }

  @override
  void dispose() {
    _src.removeListener(_changed);
    super.dispose();
  }

  Future<void> _resolve(Map<String, dynamic> r) async {
    try {
      await Api.send('PATCH', '/community/admin/reports/${r['docId']}', {'status': 'resolved'});
      await _src.load();
      _showSnackbar('Report ${r['id']} marked as resolved!', const Color(0xFF10B981));
    } catch (e) {
      _showSnackbar('Could not resolve: $e', const Color(0xFFEF4444));
    }
  }


  Widget _buildAnimatedSection(int index, Widget child) {
    final int safeIndex = index < widget.fadeAnimations.length ? index : widget.fadeAnimations.length - 1;
    return FadeTransition(
      opacity: widget.fadeAnimations[safeIndex],
      child: SlideTransition(
        position: widget.slideAnimations[safeIndex],
        child: child,
      ),
    );
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 12)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showReportDetailsDialog(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: (r['severityColor'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.report_problem_rounded, color: r['severityColor'] as Color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['id'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                  Text(r['category'] as String, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reporter: ${r['reporter']}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 2),
                  Text('Accused: ${r['reported']}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(r['desc'] as String, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.3)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(r['evidenceCount'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF06B6D4))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              _resolve(r);
            },
            child: const Text('Mark Resolved', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TOP KPI SUMMARY CARDS
        _buildAnimatedSection(0, _buildKpiCarousel()),
        const SizedBox(height: 16),

        // 2. SEARCH & FILTER TABS
        _buildAnimatedSection(1, _buildSearchAndFilterSection()),
        const SizedBox(height: 16),

        // 3. REPORTS FEED
        _buildAnimatedSection(2, _buildReportsList()),
      ],
    );
  }

  Widget _buildKpiCarousel() {
    final all = _reportsList;
    final open = all.where((r) => r['status'] != 'Resolved').toList();
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final resolved7 = all.where((r) => r['status'] == 'Resolved' && (DateTime.tryParse('${r['resolvedAt'] ?? ''}')?.isAfter(weekAgo) ?? false)).length;
    final times = [
      for (final r in all)
        if (r['resolvedAt'] != null && r['createdAt'] != null)
          DateTime.parse('${r['resolvedAt']}').difference(DateTime.parse('${r['createdAt']}')).inMinutes / 60
    ];
    final kpis = [
      {'title': 'Open Incidents', 'val': '${open.length}', 'growth': '${open.where((r) => r['severity'] == 'Urgent').length} High Priority', 'icon': Icons.warning_rounded, 'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEF2F2)},
      {'title': 'Resolved (7D)', 'val': '$resolved7', 'growth': '${all.where((r) => r['status'] == 'Resolved').length} resolved in total', 'icon': Icons.check_circle_outline_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Avg Resolution', 'val': times.isEmpty ? '-' : '${(times.reduce((a, b) => a + b) / times.length).toStringAsFixed(1)} hrs', 'growth': 'Target < 3.0h', 'icon': Icons.timer_outlined, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'title': 'Disputes Pending', 'val': '${open.where((r) => '${r['category']}'.contains('Dispute')).length}', 'growth': 'Store & Trainer', 'icon': Icons.storefront_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: kpis.map((k) {
          final Color color = k['color'] as Color;
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: k['bg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(k['icon'] as IconData, color: color, size: 14)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(k['title'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(k['val'] as String, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(k['growth'] as String, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    final all = _reportsList;
    final tabs = ['All (${all.length})', 'Urgent (${all.where((r) => r['severity'] == 'Urgent' && r['status'] != 'Resolved').length})', 'Disputes (${all.where((r) => '${r['category']}'.contains('Dispute')).length})', 'Resolved (${all.where((r) => r['status'] == 'Resolved').length})'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'Search incident by ticket ID, user or reason',
                    hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isSelected = _selectedFilter == i;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEF4444) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? const Color(0xFFEF4444) : Colors.grey.shade200),
                    ),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsList() {
    final filtered = _reportsList.where((r) {
      if (_selectedFilter == 1 && r['severity'] != 'Urgent') return false;
      if (_selectedFilter == 2 && !r['category'].toString().contains('Dispute')) return false;
      if (_selectedFilter == 3 && r['status'] != 'Resolved') return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (r['title'] as String).toLowerCase().contains(q) ||
          (r['id'] as String).toLowerCase().contains(q) ||
          (r['reporter'] as String).toLowerCase().contains(q) ||
          (r['reported'] as String).toLowerCase().contains(q);
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final r = filtered[i];
        final isOpen = r['status'] == 'In Review';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: r['severityBg'] as Color, borderRadius: BorderRadius.circular(6)),
                        child: Text(r['severity'] as String, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: r['severityColor'] as Color)),
                      ),
                      const SizedBox(width: 6),
                      Text(r['id'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                  Text(r['date'] as String, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Text(r['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text(r['desc'] as String, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.3)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('👤 ${r['reporter']}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const Icon(Icons.arrow_forward_rounded, size: 11, color: Color(0xFF94A3B8)),
                    Text('🚨 ${r['reported']}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showReportDetailsDialog(r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                        alignment: Alignment.center,
                        child: const Text('Investigate Details', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                      ),
                    ),
                  ),
                  if (isOpen) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _resolve(r);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: const Text('Resolve', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
