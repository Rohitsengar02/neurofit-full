import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../services/products_backend_service.dart';
import '../services/category_backend_service.dart';
import '../services/banners_backend_service.dart';
import '../services/workout_category_backend_service.dart';

class R2MediaLibraryPickerModal extends StatefulWidget {
  final Function(String selectedImageUrl) onImageSelected;

  const R2MediaLibraryPickerModal({
    super.key,
    required this.onImageSelected,
  });

  static void show(BuildContext context, {required Function(String selectedUrl) onImageSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => R2MediaLibraryPickerModal(onImageSelected: onImageSelected),
    );
  }

  @override
  State<R2MediaLibraryPickerModal> createState() => _R2MediaLibraryPickerModalState();
}

class _R2MediaLibraryPickerModalState extends State<R2MediaLibraryPickerModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _mediaFilter = 'all'; // 'all', 'images', 'videos'
  String? _currentlySelectedUrl;
  final List<String> _mediaUrls = [];
  bool _isLoadingR2 = true;
  bool _isUploadingNew = false;
  String _uploadStatusText = '';

  @override
  void initState() {
    super.initState();
    _loadMediaLibraryUrls();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi');
  }

  bool _isGifUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.gif');
  }

  Future<void> _pickAndUploadNewImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? file;
      try {
        file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      } catch (_) {}
      file ??= await picker.pickMedia();

      if (file != null) {
        setState(() {
          _isUploadingNew = true;
          _uploadStatusText = 'Uploading ${file!.name} to R2...';
        });
        final Uint8List bytes = await file.readAsBytes();
        final uploadedUrl = await CategoryBackendService().uploadRawImageToR2(
          fileName: file.name,
          imageBytes: bytes,
          onProgress: (prog, status) {
            if (mounted) setState(() => _uploadStatusText = status);
          },
        );
        if (uploadedUrl != null) {
          setState(() {
            _mediaUrls.remove(uploadedUrl);
            _mediaUrls.insert(0, uploadedUrl);
            _currentlySelectedUrl = uploadedUrl;
            _isUploadingNew = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF10B981),
                content: Text('✅ Image/GIF uploaded successfully to Cloudflare R2!'),
              ),
            );
          }
        } else {
          setState(() => _isUploadingNew = false);
        }
      }
    } catch (e) {
      setState(() => _isUploadingNew = false);
    }
  }

  Future<void> _pickAndUploadNewVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? file;
      try {
        file = await picker.pickVideo(source: ImageSource.gallery);
      } catch (_) {}
      file ??= await picker.pickMedia();

      if (file != null) {
        setState(() {
          _isUploadingNew = true;
          _uploadStatusText = 'Uploading video ${file!.name} to R2...';
        });
        final Uint8List bytes = await file.readAsBytes();
        final uploadedUrl = await CategoryBackendService().uploadRawImageToR2(
          fileName: file.name,
          imageBytes: bytes,
          onProgress: (prog, status) {
            if (mounted) setState(() => _uploadStatusText = status);
          },
        );
        if (uploadedUrl != null) {
          setState(() {
            _mediaUrls.remove(uploadedUrl);
            _mediaUrls.insert(0, uploadedUrl);
            _currentlySelectedUrl = uploadedUrl;
            _isUploadingNew = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF0284C7),
                content: Text('🎬 Video uploaded successfully to Cloudflare R2!'),
              ),
            );
          }
        } else {
          setState(() => _isUploadingNew = false);
        }
      }
    } catch (e) {
      setState(() => _isUploadingNew = false);
    }
  }

  Future<void> _loadMediaLibraryUrls() async {
    setState(() => _isLoadingR2 = true);
    final Set<String> urlSet = {};

    // 1. Fetch live objects directly from Cloudflare R2 bucket via Express API
    final backendUrls = [
      '${ApiConstants.apiBaseUrl}/media',
      ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/media'),
    ];

    for (final url in backendUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final items = data['data'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            for (var item in items) {
              if (item != null && item.toString().isNotEmpty) {
                urlSet.add(item.toString());
              }
            }
            break;
          }
        }
      } catch (_) {}
    }

    for (var prod in ProductsBackendService().products) {
      if (prod.images.isNotEmpty) {
        for (var img in prod.images) {
          if (img.isNotEmpty) urlSet.add(img);
        }
      }
    }
    for (var cat in CategoryBackendService().categories) {
      if (cat.imageUrl.isNotEmpty) urlSet.add(cat.imageUrl);
    }
    for (var sub in CategoryBackendService().subCategories) {
      if (sub.imageUrl.isNotEmpty) urlSet.add(sub.imageUrl);
    }
    for (var ban in BannersBackendService().banners) {
      if (ban.imageUrl.isNotEmpty) urlSet.add(ban.imageUrl);
    }
    for (var wcat in WorkoutCategoryBackendService().categories) {
      if (wcat.mediaUrl.isNotEmpty) urlSet.add(wcat.mediaUrl);
    }

    final validMedia = urlSet
        .where((u) => u.isNotEmpty && (u.contains('r2.dev') || u.contains('/uploads/') || u.contains('/media/') || u.contains('.')))
        .toList();

    if (mounted) {
      setState(() {
        _mediaUrls.clear();
        _mediaUrls.addAll(validMedia);
        if (_mediaUrls.isNotEmpty && _currentlySelectedUrl == null) {
          _currentlySelectedUrl = _mediaUrls.first;
        }
        _isLoadingR2 = false;
      });
    }
  }

  String _cleanFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final lastSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
      return lastSegment.split('?').first;
    } catch (_) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUrls = _mediaUrls.where((u) {
      if (_mediaFilter == 'images' && _isVideoUrl(u)) return false;
      if (_mediaFilter == 'videos' && !_isVideoUrl(u)) return false;
      if (_searchQuery.isEmpty) return true;
      return u.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final videoCount = _mediaUrls.where((u) => _isVideoUrl(u)).length;
    final imageCount = _mediaUrls.where((u) => !_isVideoUrl(u)).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),

          // Header Title + R2 CDN Badge + Upload Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF6366F1), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cloudflare R2 Media Library',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${filteredUrls.length} Media Assets Available ($videoCount Videos, $imageCount Images)',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Upload Image/GIF Button
                    ElevatedButton.icon(
                      onPressed: _isUploadingNew ? null : _pickAndUploadNewImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.image_rounded, size: 15),
                      label: const Text('Image/GIF', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),

                    // Upload Video Button
                    ElevatedButton.icon(
                      onPressed: _isUploadingNew ? null : _pickAndUploadNewVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.videocam_rounded, size: 16),
                      label: const Text('Upload Video', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),

                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Uploading Banner Indicator if in progress
          if (_isUploadingNew)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7))),
                  const SizedBox(width: 10),
                  Text(_uploadStatusText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                ],
              ),
            ),

          // Search Field & Format Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Search media by filename, .mp4, .gif, .png...',
                              hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Filter chips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', _mediaUrls.length),
                      _buildFilterChip('Images', 'images', imageCount),
                      _buildFilterChip('Videos', 'videos', videoCount),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Media Grid
          Expanded(
            child: _isLoadingR2
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2.5),
                        SizedBox(height: 12),
                        Text(
                          'Loading Live R2 Media Files...',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )
                : filteredUrls.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.perm_media_rounded, size: 48, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 10),
                            const Text('No uploaded R2 media found', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickAndUploadNewImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.upload_file_rounded, size: 16, color: Colors.white),
                                  label: const Text('Upload Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _pickAndUploadNewVideo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.videocam_rounded, size: 16, color: Colors.white),
                                  label: const Text('Upload Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredUrls.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          final url = filteredUrls[index];
                          final isSelected = _currentlySelectedUrl == url;
                          final isVideo = _isVideoUrl(url);
                          final isGif = _isGifUrl(url);

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _currentlySelectedUrl = url);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 3.0 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (isVideo)
                                      Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                          ),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF38BDF8), size: 24),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0284C7),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('VIDEO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Image.network(
                                        CategoryBackendService.getDisplayableImageUrl(url),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, _) => Container(
                                          color: const Color(0xFFF1F5F9),
                                          child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
                                        ),
                                      ),

                                    // Format indicator badge on top right
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isVideo
                                              ? const Color(0xFF0284C7)
                                              : (isGif ? const Color(0xFFEC4899) : const Color(0xFF10B981)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isVideo ? 'VIDEO' : (isGif ? 'GIF' : 'IMG'),
                                          style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Colors.white),
                                        ),
                                      ),
                                    ),

                                    if (isSelected)
                                      Container(
                                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                        child: const Center(
                                          child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                                        ),
                                      ),

                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.75),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _cleanFileName(url),
                                          style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Selection Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Selected Cloudflare R2 Asset:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentlySelectedUrl != null ? _cleanFileName(_currentlySelectedUrl!) : 'No Image Selected',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _currentlySelectedUrl == null
                      ? null
                      : () {
                          widget.onImageSelected(_currentlySelectedUrl!);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    _currentlySelectedUrl != null && _isVideoUrl(_currentlySelectedUrl!)
                        ? 'Use This Video'
                        : 'Use This Image',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _mediaFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _mediaFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
