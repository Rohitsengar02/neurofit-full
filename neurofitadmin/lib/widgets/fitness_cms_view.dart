import 'skeleton_loader.dart';
import 'r2_media_library_picker_modal.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/fitness_cms_backend_service.dart';
import '../services/category_backend_service.dart';
import '../services/workout_banners_backend_service.dart';
import 'upload_progress_overlay.dart';

class FitnessCmsView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const FitnessCmsView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<FitnessCmsView> createState() => _FitnessCmsViewState();
}

class _FitnessCmsViewState extends State<FitnessCmsView> {
  

  @override
  void initState() {
    super.initState();
    _backendService.addListener(_onCmsServiceUpdate);
    WorkoutBannersBackendService().addListener(_onCmsServiceUpdate);
    _backendService.fetchCmsItemsFromFirestore();
    WorkoutBannersBackendService().fetchWorkoutBanners();
  }

  @override
  void dispose() {
    _backendService.removeListener(_onCmsServiceUpdate);
    WorkoutBannersBackendService().removeListener(_onCmsServiceUpdate);
    super.dispose();
  }

  void _onCmsServiceUpdate() {
    if (mounted) setState(() {});
  }

  final FitnessCmsBackendService _backendService = FitnessCmsBackendService();
  int _activeTab = 0; // 0 = Hero Banners, 1 = Workout Spotlights

  void _openAddCmsModal(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddFitnessCmsBottomSheet(
        initialType: type,
        onAdded: () => setState(() {}),
      ),
    );
  }

  void _openEditSlider(FitnessCmsItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FitnessCmsEditSliderSheet(
        item: item,
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

    final dbBanners = WorkoutBannersBackendService().banners.map((wb) => FitnessCmsItemModel(
      itemId: wb.bannerId,
      id: wb.id,
      type: 'banner',
      title: wb.title,
      subtitle: wb.subtitle,
      imageUrl: wb.imageUrl,
      targetType: wb.targetType,
      targetId: wb.targetId,
      targetName: wb.targetName,
      badge: wb.badge,
      buttonText: wb.buttonText,
      sortOrder: wb.sortOrder,
      status: wb.isActive ? 'Active' : 'Inactive',
      isActive: wb.isActive,
      createdAt: wb.createdAt,
      updatedAt: wb.updatedAt,
    )).toList();

    final banners = dbBanners;
    final spotlights = _backendService.spotlights;

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
                        'Fitness CMS & Spotlights',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Hero carousels, workout highlights & programs',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _openAddCmsModal(
                    _activeTab == 0 ? 'banner' : 'spotlight',
                  ),
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                  label: Text(
                    _activeTab == 0 ? 'Add Banner' : 'Add Spotlight',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Switcher Strip (Hero Banners vs Spotlights)
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
                      onTap: () => setState(() => _activeTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeTab == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _activeTab == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            'Top Hero Banners (${banners.length})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _activeTab == 0
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: _activeTab == 0
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeTab == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _activeTab == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            'Workout Spotlights (${spotlights.length})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _activeTab == 1
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: _activeTab == 1
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Preview Card
            if (_activeTab == 0 && banners.isNotEmpty) ...[
              const Text(
                'Athlete Mobile Hero Carousel Preview',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              _buildLiveBannerPreview(banners.first),
              const SizedBox(height: 18),
            ] else if (_activeTab == 1 && spotlights.isNotEmpty) ...[
              const Text(
                'Athlete Workout Spotlight Card Preview',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              _buildLiveSpotlightPreview(spotlights.first),
              const SizedBox(height: 18),
            ],

            Text(
              _activeTab == 0 ? 'All Hero Banners' : 'All Workout Spotlights',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),

            // Items List
            if (_activeTab == 0) ...[
              if (_backendService.isLoading && banners.isEmpty)
                const SkeletonListView(count: 3)
              else if (banners.isEmpty)
                _buildEmptyState('No Fitness Banners Configured')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: banners.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildCmsCard(banners[index]),
                ),
            ] else ...[
              if (_backendService.isLoading && spotlights.isEmpty)
                const SkeletonListView(count: 3)
              else if (spotlights.isEmpty)
                _buildEmptyState('No Workout Spotlights Configured')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: spotlights.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildCmsCard(spotlights[index]),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBannerPreview(FitnessCmsItemModel b) {
    return Container(
      height: 155,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.network(
            b.imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                Container(color: const Color(0xFF1E293B)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    b.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 220,
                  child: Text(
                    b.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 200,
                  child: Text(
                    b.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    b.buttonText,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
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

  Widget _buildLiveSpotlightPreview(FitnessCmsItemModel s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              s.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (c, e, st) => Container(
                width: 80,
                height: 80,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    s.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  s.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Routes To: ${s.targetType.toUpperCase()} • ${s.targetName}',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.view_carousel_rounded,
            size: 36,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "+ Add" to create featured routines, categories & programs.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCmsCard(FitnessCmsItemModel item) {
    final bool isDeactivated = item.status == 'Deactivated';

    return GestureDetector(
      onTap: () => _openEditSlider(item),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Builder(builder: (context) {
              final isVid = item.imageUrl.toLowerCase().endsWith('.mp4') || item.imageUrl.toLowerCase().endsWith('.mov') || item.imageUrl.toLowerCase().endsWith('.webm');
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isVid
                    ? Container(
                        width: 68,
                        height: 68,
                        color: const Color(0xFF0F172A),
                        child: const Center(
                          child: Icon(Icons.play_arrow_rounded, color: Color(0xFF38BDF8), size: 28),
                        ),
                      )
                    : Image.network(
                        CategoryBackendService.getDisplayableImageUrl(item.imageUrl),
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 68,
                          height: 68,
                          color: const Color(0xFF0F172A),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
              );
            }),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${item.targetType.toUpperCase()}: ${item.targetName}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6366F1),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isDeactivated
                              ? const Color(0xFF94A3B8).withOpacity(0.15)
                              : const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: isDeactivated
                                ? const Color(0xFF64748B)
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 4. ADD FITNESS CMS BOTTOM SHEET (CATEGORIES, WORKOUTS, PROGRAMS DROPDOWNS)
// =========================================================================
class _AddFitnessCmsBottomSheet extends StatefulWidget {
  final String initialType; // 'banner' or 'spotlight'
  final VoidCallback onAdded;

  const _AddFitnessCmsBottomSheet({
    required this.initialType,
    required this.onAdded,
  });

  @override
  State<_AddFitnessCmsBottomSheet> createState() =>
      _AddFitnessCmsBottomSheetState();
}

class _AddFitnessCmsBottomSheetState extends State<_AddFitnessCmsBottomSheet> {
  late String _type; // 'banner' or 'spotlight'
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _subtitleCtrl = TextEditingController();
  final TextEditingController _badgeCtrl = TextEditingController(
    text: '🔥 FEATURED',
  );
  final TextEditingController _buttonTextCtrl = TextEditingController(
    text: 'Start Workout',
  );
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  XFile? _imageFile;
  String _targetType = 'category'; // 'category', 'workout', 'program'
  String _selectedTargetId = 'cat_hypertrophy';
  String _selectedTargetName = 'Hypertrophy & Muscle Build';
  bool _isProcessing = false;

  final List<Map<String, String>> _fitnessCategories = [
    {'id': 'cat_hypertrophy', 'name': 'Hypertrophy & Muscle Build'},
    {'id': 'cat_fatloss_hiit', 'name': 'Fat Loss & HIIT Conditioning'},
    {'id': 'cat_strength_power', 'name': 'Strength & Olympic Powerlifting'},
    {'id': 'cat_core_abs', 'name': 'Core & Six-Pack Shred'},
    {'id': 'cat_mobility_yoga', 'name': 'Mobility, Posture & Yoga'},
  ];

  final List<Map<String, String>> _sampleWorkouts = [
    {
      'id': 'work_chest_incline',
      'name': 'Incline Dumbbell Hyper-Chest Routine',
    },
    {'id': 'work_deadlift_pro', 'name': 'Heavy Deadlift Form & Power Routine'},
    {'id': 'work_squat_quads', 'name': 'High-Bar Olympic Squats Leg Day'},
    {'id': 'work_hiit_fatburner', 'name': '20-Min Tabata Full-Body Fat Burner'},
    {'id': 'work_arms_biceps', 'name': 'Arm Cannon Biceps & Triceps Blast'},
  ];

  final List<Map<String, String>> _samplePrograms = [
    {'id': 'prog_12wk_mass', 'name': '12-Week Classic Mass Builder'},
    {'id': 'prog_30day_shred', 'name': '30-Day Lean Shred Masterclass'},
    {'id': 'prog_power_vanguard', 'name': '8-Week Powerlifting Vanguard'},
    {
      'id': 'prog_bodyweight_beast',
      'name': 'Calisthenics & Bodyweight Athlete',
    },
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (_type == 'banner') {
      _titleCtrl.text = 'Hypertrophy Upper Body Blitz';
      _subtitleCtrl.text = '45 Mins • Advanced Level • Chest & Back';
      _buttonTextCtrl.text = 'Start Routine';
    } else {
      _titleCtrl.text = 'Conventional Deadlift Mastery';
      _subtitleCtrl.text = 'Biomechanics & Posterior Chain Activation';
      _buttonTextCtrl.text = 'View Technique';
      _badgeCtrl.text = '👑 SPOTLIGHT';
    }
  }

  void _pickImage() async {
    final f = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      maxHeight: 800,
      imageQuality: 88,
    );
    if (f != null) {
      final b = await f.readAsBytes();
      setState(() {
        _imageFile = f;
        _imageBytes = b;
      });
    }
  }

  String? _selectedR2Url;

  void _openR2MediaPicker() {
    R2MediaLibraryPickerModal.show(
      context,
      onImageSelected: (url) {
        setState(() {
          _selectedR2Url = url;
          _imageBytes = null;
          _imageFile = null;
        });
      },
    );
  }

  void _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter banner title')),
      );
      return;
    }

    if (_imageBytes == null && _selectedR2Url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or upload media for this banner')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    Navigator.pop(context);

    String finalImageUrl = _selectedR2Url ?? '';
    if (finalImageUrl.isEmpty && _imageBytes != null) {
      final notifier = UploadProgressNotifier();
      notifier.startUpload(_imageFile?.name ?? 'fitness_cms.jpg');
      final uploadedUrl = await CategoryBackendService().uploadRawImageToR2(
        fileName: _imageFile?.name ?? 'fitness_cms.jpg',
        imageBytes: _imageBytes!,
        onProgress: (p, s) => notifier.updateProgress(p, customStatus: s),
      );
      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
        notifier.completeUpload(uploadedUrl);
      } else {
        notifier.failUpload('Failed to upload media');
        return;
      }
    }

    final isVideo = finalImageUrl.toLowerCase().endsWith('.mp4') ||
        finalImageUrl.toLowerCase().endsWith('.mov') ||
        finalImageUrl.toLowerCase().endsWith('.webm');
    final isGif = finalImageUrl.toLowerCase().endsWith('.gif');
    final mType = isVideo ? 'video' : (isGif ? 'gif' : 'image');

    if (_type == 'banner') {
      await WorkoutBannersBackendService().createWorkoutBanner(
        title: title,
        subtitle: _subtitleCtrl.text.trim(),
        imageUrl: finalImageUrl,
        mediaType: mType,
        targetType: _targetType,
        targetId: _selectedTargetId,
        targetName: _selectedTargetName,
        badge: _badgeCtrl.text.trim(),
        buttonText: _buttonTextCtrl.text.trim(),
        showTitle: true,
        sortOrder: WorkoutBannersBackendService().banners.length + 1,
      );
    } else {
      await FitnessCmsBackendService().createCmsItemWithUrl(
        type: _type,
        title: title,
        subtitle: _subtitleCtrl.text.trim(),
        targetType: _targetType,
        targetId: _selectedTargetId,
        targetName: _selectedTargetName,
        badge: _badgeCtrl.text.trim(),
        buttonText: _buttonTextCtrl.text.trim(),
        sortOrder: FitnessCmsBackendService().spotlights.length + 1,
        imageUrl: finalImageUrl,
      );
    }
    widget.onAdded();
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
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _type == 'banner'
                  ? 'Create Hero Banner'
                  : 'Create Workout Spotlight',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload photo to Cloudflare R2 & configure deep-link routing',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // Content Type Switcher
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text(
                        'Hero Banner (Carousel)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    selected: _type == 'banner',
                    onSelected: (v) => setState(() => _type = 'banner'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text(
                        'Workout Spotlight (Card)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    selected: _type == 'spotlight',
                    onSelected: (v) => setState(() => _type = 'spotlight'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Image Picker Box
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                  ),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 28,
                            color: Color(0xFF6366F1),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Select Image from Gallery',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Cloudflare R2 Bucket Upload',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title / Routine Headline',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _subtitleCtrl,
              decoration: const InputDecoration(
                labelText: 'Subtitle / Tagline',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Routing Target Type Selector (Category vs Workout vs Program)
            const Text(
              'Select Routing Target',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    selected: _targetType == 'category',
                    onSelected: (v) => setState(() {
                      _targetType = 'category';
                      _selectedTargetId = _fitnessCategories.first['id']!;
                      _selectedTargetName = _fitnessCategories.first['name']!;
                    }),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text(
                        'Workout',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    selected: _targetType == 'workout',
                    onSelected: (v) => setState(() {
                      _targetType = 'workout';
                      _selectedTargetId = _sampleWorkouts.first['id']!;
                      _selectedTargetName = _sampleWorkouts.first['name']!;
                    }),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text(
                        'Program',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    selected: _targetType == 'program',
                    onSelected: (v) => setState(() {
                      _targetType = 'program';
                      _selectedTargetId = _samplePrograms.first['id']!;
                      _selectedTargetName = _samplePrograms.first['name']!;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Dropdown based on Target Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedTargetId,
                  items:
                      (_targetType == 'category'
                              ? _fitnessCategories
                              : (_targetType == 'workout'
                                    ? _sampleWorkouts
                                    : _samplePrograms))
                          .map(
                            (item) => DropdownMenuItem(
                              value: item['id'],
                              child: Text(
                                item['name']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTargetId = val!;
                      final list = (_targetType == 'category'
                          ? _fitnessCategories
                          : (_targetType == 'workout'
                                ? _sampleWorkouts
                                : _samplePrograms));
                      _selectedTargetName = list.firstWhere(
                        (i) => i['id'] == val,
                      )['name']!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _badgeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Badge Tag (e.g. 🔥 HOT)',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _buttonTextCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Button Label (e.g. Start)',
                      filled: true,
                      fillColor: Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Banner Media File (Video / GIF / Image)',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  if (_selectedR2Url != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        CategoryBackendService.getDisplayableImageUrl(_selectedR2Url!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, _) => Container(width: 48, height: 48, color: const Color(0xFF0F172A), child: const Icon(Icons.play_arrow_rounded, color: Colors.white)),
                      ),
                    )
                  else if (_imageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_imageBytes!, width: 48, height: 48, fit: BoxFit.cover),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.perm_media_rounded, color: Colors.grey),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedR2Url != null
                          ? _selectedR2Url!.split('/').last
                          : (_imageFile != null ? _imageFile!.name : 'No media attached yet'),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openR2MediaPicker,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.cloud_done_rounded, size: 15, color: Color(0xFF0284C7)),
                    label: const Text('R2 Media', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessing ? null : _submit,
                child: const Text(
                  'Save to Firestore & Sync R2',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 5. EDIT SLIDER SHEET (FITNESS CMS)
// =========================================================================
class _FitnessCmsEditSliderSheet extends StatefulWidget {
  final FitnessCmsItemModel item;
  final VoidCallback onUpdated;

  const _FitnessCmsEditSliderSheet({
    required this.item,
    required this.onUpdated,
  });

  @override
  State<_FitnessCmsEditSliderSheet> createState() =>
      _FitnessCmsEditSliderSheetState();
}

class _FitnessCmsEditSliderSheetState
    extends State<_FitnessCmsEditSliderSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _badgeCtrl;
  late TextEditingController _buttonCtrl;
  late String _status;
  String? _selectedR2Url;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item.title);
    _subtitleCtrl = TextEditingController(text: widget.item.subtitle);
    _badgeCtrl = TextEditingController(text: widget.item.badge);
    _buttonCtrl = TextEditingController(text: widget.item.buttonText);
    _status = widget.item.status;
    _selectedR2Url = widget.item.imageUrl;
  }

  void _openR2MediaPicker() {
    R2MediaLibraryPickerModal.show(
      context,
      onImageSelected: (url) {
        setState(() {
          _selectedR2Url = url;
        });
      },
    );
  }

  void _handleSave() async {
    Navigator.pop(context);

    final title = _titleCtrl.text.trim();
    final subtitle = _subtitleCtrl.text.trim();
    final badge = _badgeCtrl.text.trim();
    final buttonText = _buttonCtrl.text.trim();
    final imageUrl = _selectedR2Url ?? widget.item.imageUrl;

    final isVideo = imageUrl.toLowerCase().endsWith('.mp4') || imageUrl.toLowerCase().endsWith('.mov') || imageUrl.toLowerCase().endsWith('.webm');
    final isGif = imageUrl.toLowerCase().endsWith('.gif');
    final mediaType = isVideo ? 'video' : (isGif ? 'gif' : 'image');

    if (widget.item.type == 'banner') {
      final bId = widget.item.itemId.isNotEmpty ? widget.item.itemId : widget.item.id;
      final bannerModel = WorkoutBannerModel(
        id: widget.item.id,
        bannerId: bId,
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        mediaType: mediaType,
        targetType: widget.item.targetType,
        targetId: widget.item.targetId,
        targetName: widget.item.targetName,
        badge: badge,
        buttonText: buttonText,
        showTitle: true,
        sortOrder: widget.item.sortOrder,
        isActive: (_status == 'Active'),
      );
      await WorkoutBannersBackendService().updateWorkoutBanner(bannerModel);
    } else {
      await FitnessCmsBackendService().updateCmsItem(
        itemId: widget.item.itemId,
        title: title,
        subtitle: subtitle,
        targetType: widget.item.targetType,
        targetId: widget.item.targetId,
        targetName: widget.item.targetName,
        badge: badge,
        buttonText: buttonText,
        newImageUrl: imageUrl,
        status: _status,
      );
    }
    widget.onUpdated();
  }

  void _handleDelete() async {
    Navigator.pop(context);
    if (widget.item.type == 'banner') {
      final bId = widget.item.itemId.isNotEmpty ? widget.item.itemId : widget.item.id;
      await WorkoutBannersBackendService().deleteWorkoutBanner(bId);
    } else {
      await FitnessCmsBackendService().deleteCmsItem(widget.item.itemId);
    }
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = _selectedR2Url ?? widget.item.imageUrl;
    final isVideo = mediaUrl.toLowerCase().endsWith('.mp4') || mediaUrl.toLowerCase().endsWith('.mov') || mediaUrl.toLowerCase().endsWith('.webm');

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit ${widget.item.type.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 16, color: Color(0xFFF1F5F9)),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (isVideo
                                ? Container(
                                    width: 80,
                                    height: 65,
                                    color: const Color(0xFF0F172A),
                                    child: const Center(
                                      child: Icon(Icons.play_arrow_rounded, color: Color(0xFF38BDF8), size: 28),
                                    ),
                                  )
                                : Image.network(
                                    CategoryBackendService.getDisplayableImageUrl(mediaUrl),
                                    width: 80,
                                    height: 65,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 80,
                                      height: 65,
                                      color: const Color(0xFF0F172A),
                                      child: const Icon(Icons.broken_image, color: Colors.white),
                                    ),
                                  )),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mediaUrl.split('/').last,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                OutlinedButton.icon(
                                  onPressed: _openR2MediaPicker,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF0284C7)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  icon: const Icon(Icons.cloud_done_rounded, size: 15, color: Color(0xFF0284C7)),
                                  label: const Text('Change Media (R2)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _subtitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle / Tagline',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _badgeCtrl,
                      decoration: const InputDecoration(labelText: 'Badge Tag'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _buttonCtrl,
                      decoration: const InputDecoration(labelText: 'Button Text'),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _status == 'Active'
                                ? 'Status: Active (Visible on Home)'
                                : 'Status: Deactivated',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Switch.adaptive(
                            value: _status == 'Active',
                            activeTrackColor: const Color(0xFF10B981),
                            onChanged: (v) =>
                                setState(() => _status = v ? 'Active' : 'Deactivated'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            foregroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _handleDelete,
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _handleSave,
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
