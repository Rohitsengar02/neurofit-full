import 'skeleton_loader.dart';
import 'package:flutter/material.dart';
import '../services/programs_backend_service.dart';

class FitnessProgramsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const FitnessProgramsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<FitnessProgramsView> createState() => _FitnessProgramsViewState();
}

class _FitnessProgramsViewState extends State<FitnessProgramsView> {
  final ProgramsBackendService _programsService = ProgramsBackendService();
  int _selectedFilterIndex = 0;
  String _searchQuery = '';

  final List<String> _filterChips = [
    'All Programs',
    '12-Week Masteries',
    '8-Week Shreds',
    '4-Week Sprints',
  ];

  @override
  void initState() {
    super.initState();
    _programsService.addListener(_onServiceUpdate);
    if (_programsService.programs.isEmpty) {
      _programsService.fetchProgramsFromFirestore();
    }
  }

  @override
  void dispose() {
    _programsService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fadeAnim = widget.fadeAnimations.isNotEmpty
        ? widget.fadeAnimations[0]
        : const AlwaysStoppedAnimation(1.0);
    final slideAnim = widget.slideAnimations.isNotEmpty
        ? widget.slideAnimations[0]
        : const AlwaysStoppedAnimation(Offset.zero);

    final selectedType = _filterChips[_selectedFilterIndex];
    final programs = _programsService.programs.where((p) {
      final matchesType = _selectedFilterIndex == 0 || p.type == selectedType;
      final matchesSearch = _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.coach.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesType && matchesSearch;
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
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search periodized programs, trainers...',
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
                children: List.generate(_filterChips.length, (idx) {
                  final chip = _filterChips[idx];
                  final isSelected = _selectedFilterIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        idx == 0 ? '$chip (${_programsService.programs.length})' : chip,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilterIndex = idx);
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Programs Grid
            if (_programsService.isLoading && _programsService.programs.isEmpty)
              const SkeletonCardGrid(count: 4, childAspectRatio: 0.72)
            else if (programs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFF94A3B8), size: 36),
                    SizedBox(height: 10),
                    Text('No Fitness Programs in Firestore', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: programs.length,
                itemBuilder: (context, index) {
                  final p = programs[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Image.network(
                                p.imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: const Color(0xFF0F172A),
                                  child: const Center(child: Icon(Icons.workspace_premium_rounded, color: Colors.white70)),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(p.badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 12),
                                      const SizedBox(width: 2),
                                      Text('${p.rating}', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.type, style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(p.title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('₹${p.price.toInt()}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w900)),
                                  Text('${p.weeks} Weeks', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
