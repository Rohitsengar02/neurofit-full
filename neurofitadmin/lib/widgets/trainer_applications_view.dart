import 'package:flutter/material.dart';

class TrainerApplicationsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const TrainerApplicationsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<TrainerApplicationsView> createState() => _TrainerApplicationsViewState();
}

class _TrainerApplicationsViewState extends State<TrainerApplicationsView> {
  int _selectedFilter = 0; // 0=All, 1=Pending, 2=Approved, 3=Rejected
  String _searchQuery = '';

  late List<Map<String, dynamic>> _applicationsList;

  @override
  void initState() {
    super.initState();

    _applicationsList = [
      {
        'id': 'APP-901',
        'name': 'Kavita Sharma',
        'email': 'kavita.coach@gmail.com',
        'phone': '+91 98765 43210',
        'experience': '6 Years Personal Training',
        'specialty': 'Female Strength & Glutes',
        'cert': 'ACE CPT + Pre/Postnatal Certified',
        'appliedDate': 'Today, 11:30 AM',
        'status': 'Pending Review',
        'statusColor': const Color(0xFFF59E0B),
        'avatar': 'assets/images/trainers_hero_banner.jpg',
      },
      {
        'id': 'APP-902',
        'name': 'Arjun Dasgupta',
        'email': 'arjun.d@gmail.com',
        'phone': '+91 91234 56789',
        'experience': '8 Years Powerlifting Coach',
        'specialty': 'Heavy Compounds & Barbell Mechanics',
        'cert': 'CSCS + USAPL Senior Coach',
        'appliedDate': 'Today, 9:15 AM',
        'status': 'Pending Review',
        'statusColor': const Color(0xFFF59E0B),
        'avatar': 'assets/images/athlete_transform_1787825621309.jpg',
      },
      {
        'id': 'APP-903',
        'name': 'Shreya Malhotra',
        'email': 'shreya.m@gmail.com',
        'phone': '+91 87654 32109',
        'experience': '4 Years Functional Movement',
        'specialty': 'Yoga & Calisthenics',
        'cert': 'Yoga Alliance RYT-500',
        'appliedDate': 'Yesterday, 4:20 PM',
        'status': 'Approved',
        'statusColor': const Color(0xFF10B981),
        'avatar': 'assets/images/hero_banner_1.png',
      },
      {
        'id': 'APP-904',
        'name': 'Rohan Kapoor',
        'email': 'rohan.k@gmail.com',
        'phone': '+91 76543 21098',
        'experience': '1 Year Gym Floor Trainer',
        'specialty': 'General Fitness',
        'cert': 'Unverified Certificate',
        'appliedDate': 'May 25, 2025',
        'status': 'Rejected',
        'statusColor': const Color(0xFFEF4444),
        'avatar': 'assets/images/hero_banner_4.png',
      },
    ];
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

  void _showApplicationModal(Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.assignment_ind_rounded, color: Color(0xFF06B6D4), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  Text('Application ID: ${app['id']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specialty: ${app['specialty']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text('Experience: ${app['experience']}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
            Text('Certification: ${app['cert']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF06B6D4))),
            Text('Email: ${app['email']} • Phone: ${app['phone']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => app['status'] = 'Approved');
              _showSnackbar('${app['name']} approved as verified coach!', const Color(0xFF10B981));
            },
            child: const Text('Approve Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
        _buildAnimatedSection(0, _buildKpiCarousel()),
        const SizedBox(height: 16),
        _buildAnimatedSection(1, _buildSearchAndFilterTabs()),
        const SizedBox(height: 16),
        _buildAnimatedSection(2, _buildApplicationsList()),
      ],
    );
  }

  Widget _buildKpiCarousel() {
    final kpis = [
      {'title': 'Pending Queue', 'val': '14 Apps', 'growth': 'Requires review', 'icon': Icons.pending_actions_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'title': 'Approved (7D)', 'val': '28 Coaches', 'growth': '92% Onboarded', 'icon': Icons.check_circle_outline_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'title': 'Rejected / Resubmit', 'val': '4 Apps', 'growth': 'Unverified certs', 'icon': Icons.highlight_off_rounded, 'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEF2F2)},
      {'title': 'Avg Turnaround', 'val': '6.4 hrs', 'growth': 'Fast verification', 'icon': Icons.speed_rounded, 'color': const Color(0xFF06B6D4), 'bg': const Color(0xFFECFEFF)},
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

  Widget _buildSearchAndFilterTabs() {
    final tabs = ['All (46)', 'Pending (14)', 'Approved (28)', 'Rejected (4)'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(hintText: 'Search applications by name, cert or specialty...', border: InputBorder.none, isDense: true),
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
                      color: isSelected ? const Color(0xFF06B6D4) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.grey.shade200),
                    ),
                    child: Text(
                      tabs[i],
                      style: TextStyle(fontSize: 10.5, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF64748B)),
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

  Widget _buildApplicationsList() {
    final filtered = _applicationsList.where((app) {
      if (_selectedFilter == 1 && !app['status'].toString().contains('Pending')) return false;
      if (_selectedFilter == 2 && !app['status'].toString().contains('Approved')) return false;
      if (_selectedFilter == 3 && !app['status'].toString().contains('Rejected')) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (app['name'] as String).toLowerCase().contains(q) ||
          (app['cert'] as String).toLowerCase().contains(q) ||
          (app['specialty'] as String).toLowerCase().contains(q);
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final app = filtered[i];
        final isPending = app['status'] == 'Pending Review';

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 22, backgroundImage: AssetImage(app['avatar'] as String)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text(app['specialty'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF06B6D4))),
                        Text('Cert: ${app['cert']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: (app['statusColor'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(app['status'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: app['statusColor'] as Color)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showApplicationModal(app),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                        alignment: Alignment.center,
                        child: const Text('Review Application', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                      ),
                    ),
                  ),
                  if (isPending) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => app['status'] = 'Approved');
                          _showSnackbar('${app['name']} approved!', const Color(0xFF10B981));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: const Text('Approve', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white)),
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
