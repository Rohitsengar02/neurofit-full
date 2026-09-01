import 'skeleton_loader.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/exercises_backend_service.dart';
import 'upload_progress_overlay.dart';

class FitnessExercisesView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const FitnessExercisesView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<FitnessExercisesView> createState() => _FitnessExercisesViewState();
}

class _FitnessExercisesViewState extends State<FitnessExercisesView> {
  

  @override
  void initState() {
    super.initState();
    _backendService.addListener(_onExServiceUpdate);
    if (_backendService.exercises.isEmpty) {
      _backendService.fetchExercisesFromFirestore();
    }
  }

  @override
  void dispose() {
    _backendService.removeListener(_onExServiceUpdate);
    super.dispose();
  }

  void _onExServiceUpdate() {
    if (mounted) setState(() {});
  }
  final ExercisesBackendService _backendService = ExercisesBackendService();
  String _selectedCategoryFilter = 'All';
  String _searchQuery = '';

  void _openAddCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddExerciseCategorySheet(
        onAdded: () => setState(() {}),
      ),
    );
  }

  void _openEditCategorySheet(ExerciseCategoryModel category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditExerciseCategorySheet(
        category: category,
        onUpdated: () => setState(() {}),
      ),
    );
  }

  void _openAddExerciseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddExerciseBottomSheet(
        onAdded: () => setState(() {}),
      ),
    );
  }

  void _openExerciseSlider(ExerciseModel exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExerciseDetailsSliderSheet(
        exercise: exercise,
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

    final categories = _backendService.categories;
    final exercises = _backendService.exercises.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.muscleGroup.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == 'All' ||
          e.categoryId == _selectedCategoryFilter;
      return matchesSearch && matchesCategory;
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercises Directory',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Categories, GIF animations & MP4 videos',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        foregroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _openAddCategorySheet,
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 15),
                      label: const Text('+ Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _openAddExerciseSheet,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Exercise', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. CATEGORIES CARDS CAROUSEL (ABOVE EXERCISES)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Muscle Group Categories', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                Text('Tap card to filter • Edit icon to manage', style: TextStyle(fontSize: 10, color: const Color(0xFF64748B).withOpacity(0.8))),
              ],
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  // 'All Exercises' Card
                  _buildAllCategoriesCard(),
                  ...categories.map((c) => _buildCategoryCard(c)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Search Bar
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Search movements, muscles (e.g. Incline Bench, Deadlift)...',
                  hintStyle: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Exercises Grid Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategoryFilter == 'All'
                      ? 'All Exercises (${exercises.length})'
                      : '${categories.firstWhere((c) => c.categoryId == _selectedCategoryFilter, orElse: () => categories.first).name} (${exercises.length})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                if (_selectedCategoryFilter != 'All')
                  GestureDetector(
                    onTap: () => setState(() => _selectedCategoryFilter = 'All'),
                    child: const Text('Clear Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // 2. EXERCISES GRID
            if (exercises.isEmpty)
              _buildEmptyState()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.76,
                ),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final ex = exercises[index];
                  return _buildExerciseCard(ex);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCategoriesCard() {
    final isSelected = _selectedCategoryFilter == 'All';

    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryFilter = 'All'),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: isSelected ? const Color(0xFF6366F1).withOpacity(0.3) : Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 16),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('All Exercises', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900)),
                  Text('${_backendService.exercises.length} Movements', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(ExerciseCategoryModel cat) {
    final isSelected = _selectedCategoryFilter == cat.categoryId;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryFilter = cat.categoryId),
      child: Container(
        width: 125,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Image from Cloudflare R2
            Image.network(
              cat.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: const Color(0xFF1E293B)),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(5)),
                        child: Text('${cat.exerciseCount} Moves', style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800)),
                      ),
                      // Edit Icon Trigger
                      GestureDetector(
                        onTap: () => _openEditCategorySheet(cat),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 11),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    cat.name,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: -0.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: const [
          Icon(Icons.fitness_center_rounded, size: 36, color: Color(0xFF6366F1)),
          SizedBox(height: 8),
          Text('No Exercises Found', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          SizedBox(height: 4),
          Text('Tap "+ Add Exercise" to upload GIF, MP4 video, or image movement demos.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseModel ex) {
    Color badgeColor = const Color(0xFF6366F1);
    if (ex.mediaType == 'video') badgeColor = const Color(0xFFEF4444);
    if (ex.mediaType == 'gif') badgeColor = const Color(0xFF10B981);

    return GestureDetector(
      onTap: () => _openExerciseSlider(ex),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                      color: Color(0xFF0F172A),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      ex.mediaUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Center(
                        child: Icon(Icons.fitness_center_rounded, size: 32, color: Color(0xFF6366F1)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        ex.mediaType.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        ex.difficulty,
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
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
                  Text(
                    ex.categoryName.toUpperCase(),
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF6366F1), letterSpacing: 0.4),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ex.title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ex.muscleGroup,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
// 3. EDIT / DELETE CATEGORY SHEET
// =========================================================================
class _EditExerciseCategorySheet extends StatefulWidget {
  final ExerciseCategoryModel category;
  final VoidCallback onUpdated;

  const _EditExerciseCategorySheet({required this.category, required this.onUpdated});

  @override
  State<_EditExerciseCategorySheet> createState() => _EditExerciseCategorySheetState();
}

class _EditExerciseCategorySheetState extends State<_EditExerciseCategorySheet> {
  late TextEditingController _nameCtrl;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _newImageBytes;
  XFile? _newImageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category.name);
  }

  void _pickNewImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1000, maxHeight: 1000, imageQuality: 88);
    if (f != null) {
      final b = await f.readAsBytes();
      setState(() {
        _newImageFile = f;
        _newImageBytes = b;
      });
    }
  }

  void _handleSave() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSaving = true);
    Navigator.pop(context);

    String? updatedUrl;
    if (_newImageBytes != null) {
      final notifier = UploadProgressNotifier();
      notifier.startUpload(_newImageFile?.name ?? 'category.jpg');
      updatedUrl = await ExercisesBackendService().createCategory(
        name: newName,
        imageFileName: _newImageFile?.name ?? 'category.jpg',
        imageBytes: _newImageBytes!,
      ).then((c) => c?.imageUrl);
      if (updatedUrl != null) notifier.completeUpload(updatedUrl);
    }

    await ExercisesBackendService().updateCategory(
      categoryId: widget.category.categoryId,
      newName: newName,
      newImageUrl: updatedUrl,
    );

    widget.onUpdated();
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Category?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text('Are you sure you want to delete "${widget.category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ExercisesBackendService().deleteCategory(widget.category.categoryId);
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
    return Container(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 44, height: 4.5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 16),
          const Text('Edit Exercise Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('ID: ${widget.category.categoryId} • ${widget.category.exerciseCount} Linked Exercises', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 16),

          // Image Preview
          GestureDetector(
            onTap: _pickNewImage,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _newImageBytes != null
                    ? Image.memory(_newImageBytes!, fit: BoxFit.cover)
                    : Image.network(widget.category.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: const Color(0xFF0F172A))),
              ),
            ),
          ),
          const SizedBox(height: 14),

          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Category Title')),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444)), foregroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _handleDelete,
                  child: const Text('Delete Category', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _isSaving ? null : _handleSave,
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 4. ADD EXERCISE CATEGORY SHEET
// =========================================================================
class _AddExerciseCategorySheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddExerciseCategorySheet({required this.onAdded});

  @override
  State<_AddExerciseCategorySheet> createState() => _AddExerciseCategorySheetState();
}

class _AddExerciseCategorySheetState extends State<_AddExerciseCategorySheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  XFile? _imageFile;
  bool _isProcessing = false;

  void _pickImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1000, maxHeight: 1000, imageQuality: 85);
    if (f != null) {
      final b = await f.readAsBytes();
      setState(() {
        _imageFile = f;
        _imageBytes = b;
      });
    }
  }

  void _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select category image and enter title')));
      return;
    }

    setState(() => _isProcessing = true);
    Navigator.pop(context);

    final res = await ExercisesBackendService().createCategory(
      name: name,
      imageFileName: _imageFile?.name ?? 'ex_category.jpg',
      imageBytes: _imageBytes!,
    );

    if (res != null) {
      widget.onAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 44, height: 4.5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 16),
          const Text('Create Exercise Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Organize workout movement directory by muscle groups', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 110,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35))),
              child: _imageBytes != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF6366F1), size: 26),
                        SizedBox(height: 4),
                        Text('Select Category Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Category Name (e.g. Chest & Pecs, Glutes, Hamstrings)')),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _isProcessing ? null : _submit,
              child: const Text('Save Category & Sync R2', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 5. ADD EXERCISE BOTTOM SHEET
// =========================================================================
class _AddExerciseBottomSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddExerciseBottomSheet({required this.onAdded});

  @override
  State<_AddExerciseBottomSheet> createState() => _AddExerciseBottomSheetState();
}

class _AddExerciseBottomSheetState extends State<_AddExerciseBottomSheet> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _muscleCtrl = TextEditingController(text: 'Upper Chest & Front Delts');
  final TextEditingController _equipmentCtrl = TextEditingController(text: 'Dumbbells & Incline Bench');
  final TextEditingController _instructionsCtrl = TextEditingController(
    text: 'Set bench to 30 degrees. Retract scapula, maintain controlled cadence, and lock out with full chest contraction.',
  );
  final ImagePicker _picker = ImagePicker();

  String _selectedMediaType = 'gif'; // 'gif', 'video', 'image'
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String _selectedDifficulty = 'Intermediate';

  Uint8List? _mediaBytes;
  XFile? _mediaFile;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final categories = ExercisesBackendService().categories;
    if (categories.isNotEmpty) {
      _selectedCategoryId = categories.first.categoryId;
      _selectedCategoryName = categories.first.name;
    }
  }

  void _pickMedia() async {
    if (_selectedMediaType == 'video') {
      final f = await _picker.pickVideo(source: ImageSource.gallery);
      if (f != null) {
        final b = await f.readAsBytes();
        setState(() {
          _mediaFile = f;
          _mediaBytes = b;
        });
      }
    } else {
      final f = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 88);
      if (f != null) {
        final b = await f.readAsBytes();
        setState(() {
          _mediaFile = f;
          _mediaBytes = b;
        });
      }
    }
  }

  void _submitExercise() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter exercise movement title'), backgroundColor: Color(0xFFEF4444)));
      return;
    }
    if (_mediaBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select ${_selectedMediaType.toUpperCase()} file'), backgroundColor: const Color(0xFFEF4444)));
      return;
    }

    final categories = ExercisesBackendService().categories;
    final catId = _selectedCategoryId ?? (categories.isNotEmpty ? categories.first.categoryId : 'excat_chest');
    final catName = _selectedCategoryName ?? (categories.isNotEmpty ? categories.first.name : 'Chest & Pecs');

    setState(() => _isProcessing = true);

    // Ensure filename extension matches media type
    String extension = 'jpg';
    if (_selectedMediaType == 'gif') extension = 'gif';
    if (_selectedMediaType == 'video') extension = 'mp4';

    final rawName = _mediaFile?.name ?? 'exercise';
    final cleanBase = rawName.split('.').first;
    final finalFileName = '${cleanBase}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    final res = await ExercisesBackendService().createExercise(
      title: title,
      categoryId: catId,
      categoryName: catName,
      mediaType: _selectedMediaType,
      muscleGroup: _muscleCtrl.text.trim().isNotEmpty ? _muscleCtrl.text.trim() : 'Full Body',
      difficulty: _selectedDifficulty,
      equipment: _equipmentCtrl.text.trim().isNotEmpty ? _equipmentCtrl.text.trim() : 'Bodyweight',
      instructions: _instructionsCtrl.text.trim(),
      mediaFileName: finalFileName,
      mediaBytes: _mediaBytes!,
    );

    setState(() => _isProcessing = false);

    if (res != null) {
      Navigator.pop(context);
      widget.onAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exercise "$title" saved to Firestore & Cloudflare R2!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save exercise. Please check network/R2 connection.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ExercisesBackendService().categories;

    return Container(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 44, height: 4.5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            const Text('Upload New Exercise Movement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            const Text('Upload GIF animation, MP4 video demo, or image with Cloudflare R2', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 16),

            // Extension Type
            const Text('Select Media Extension Type', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('GIF (.gif)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    selected: _selectedMediaType == 'gif',
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    onSelected: (v) => setState(() {
                      _selectedMediaType = 'gif';
                      _mediaBytes = null;
                    }),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Video (.mp4)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    selected: _selectedMediaType == 'video',
                    selectedColor: const Color(0xFFEF4444).withOpacity(0.2),
                    onSelected: (v) => setState(() {
                      _selectedMediaType = 'video';
                      _mediaBytes = null;
                    }),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Image (.jpg)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    selected: _selectedMediaType == 'image',
                    selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                    onSelected: (v) => setState(() {
                      _selectedMediaType = 'image';
                      _mediaBytes = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Media Box
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                width: double.infinity,
                height: 130,
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35))),
                child: _mediaBytes != null
                    ? Stack(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_mediaBytes!, width: double.infinity, height: double.infinity, fit: BoxFit.cover)),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                              child: Text('${_selectedMediaType.toUpperCase()} Selected • Tap to Change', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_selectedMediaType == 'video' ? Icons.videocam_rounded : Icons.animation_rounded, size: 30, color: const Color(0xFF6366F1)),
                          const SizedBox(height: 6),
                          Text('Select ${_selectedMediaType.toUpperCase()} File', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                          const Text('Cloudflare R2 Bucket Upload', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),

            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Exercise Movement Title (e.g. Incline DB Press)', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            const SizedBox(height: 12),

            const Text('Exercise Category', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCategoryId,
                  items: categories.map((c) => DropdownMenuItem(value: c.categoryId, child: Text(c.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryId = val;
                      _selectedCategoryName = categories.firstWhere((c) => c.categoryId == val).name;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: TextField(controller: _muscleCtrl, decoration: const InputDecoration(labelText: 'Target Muscles', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _equipmentCtrl, decoration: const InputDecoration(labelText: 'Equipment', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))))),
              ],
            ),
            const SizedBox(height: 12),

            const Text('Difficulty Level', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(
              children: ['Beginner', 'Intermediate', 'Advanced'].map((diff) {
                final isSel = _selectedDifficulty == diff;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(diff, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600)),
                    selected: isSel,
                    onSelected: (v) => setState(() => _selectedDifficulty = diff),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            TextField(controller: _instructionsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Coaching Form Cues & Steps', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isProcessing ? null : _submitExercise,
                child: const Text('Save Exercise & Sync Cloudflare R2', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 6. EXERCISE DETAILS SLIDER SHEET
// =========================================================================
class _ExerciseDetailsSliderSheet extends StatefulWidget {
  final ExerciseModel exercise;
  final VoidCallback onUpdated;
  const _ExerciseDetailsSliderSheet({required this.exercise, required this.onUpdated});

  @override
  State<_ExerciseDetailsSliderSheet> createState() => _ExerciseDetailsSliderSheetState();
}

class _ExerciseDetailsSliderSheetState extends State<_ExerciseDetailsSliderSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _muscleCtrl;
  late TextEditingController _equipmentCtrl;
  late TextEditingController _instructionsCtrl;
  late String _status;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.exercise.title);
    _muscleCtrl = TextEditingController(text: widget.exercise.muscleGroup);
    _equipmentCtrl = TextEditingController(text: widget.exercise.equipment);
    _instructionsCtrl = TextEditingController(text: widget.exercise.instructions);
    _status = widget.exercise.status;
  }

  void _handleSave() async {
    Navigator.pop(context);
    widget.exercise.title = _titleCtrl.text.trim();
    widget.exercise.muscleGroup = _muscleCtrl.text.trim();
    widget.exercise.equipment = _equipmentCtrl.text.trim();
    widget.exercise.instructions = _instructionsCtrl.text.trim();
    widget.exercise.status = _status;
    widget.exercise.updatedAt = DateTime.now();

    await ExercisesBackendService().updateExercise(widget.exercise);
    widget.onUpdated();
  }

  void _handleDelete() {
    Navigator.pop(context);
    ExercisesBackendService().deleteExercise(widget.exercise.exerciseId);
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                    const Text('Exercise Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('${widget.exercise.categoryName} • Media: ${widget.exercise.mediaType.toUpperCase()}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(widget.exercise.mediaUrl, width: double.infinity, height: 160, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),

                  TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Exercise Title')),
                  const SizedBox(height: 10),
                  TextField(controller: _muscleCtrl, decoration: const InputDecoration(labelText: 'Target Muscles')),
                  const SizedBox(height: 10),
                  TextField(controller: _equipmentCtrl, decoration: const InputDecoration(labelText: 'Equipment')),
                  const SizedBox(height: 10),
                  TextField(controller: _instructionsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Coaching Form Cues')),
                  const SizedBox(height: 14),

                  SwitchListTile.adaptive(
                    title: Text(_status == 'Active' ? 'Status: Active (Visible to Athletes)' : 'Status: Deactivated', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    value: _status == 'Active',
                    activeColor: const Color(0xFF10B981),
                    onChanged: (v) => setState(() => _status = v ? 'Active' : 'Deactivated'),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444)), foregroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _handleDelete,
                          child: const Text('Delete Exercise', style: TextStyle(fontWeight: FontWeight.w800)),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
