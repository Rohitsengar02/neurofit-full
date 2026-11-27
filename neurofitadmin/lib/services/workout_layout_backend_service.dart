import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class WorkoutLayoutSectionModel {
  String id;
  String sectionId;
  String title;
  String subtitle;
  bool showTitle;
  String type; // 'hero_banners', 'categories', 'popular_programs', 'bento_spotlight', 'muscle_groups', 'celebrity_coaches', 'equipment_training', 'trending_challenges', 'audio_beats', 'custom_banner', 'exercise_grid', 'single_workout_card'
  String layoutMode; // 'carousel', 'grid', 'bento', 'hero_carousel', 'card_list', 'square_cards'
  String filterSource; // 'all', 'featured', 'category', 'level', 'equipment', 'selected_ids', 'custom'
  String filterId;
  String filterName;
  List<String> selectedItemIds;
  int itemLimit;
  int sortOrder;
  bool isActive;
  String customBannerImageUrl;
  String customBannerVideoUrl;
  String customBannerTargetType;
  String customBannerTargetId;
  String customBannerButtonText;
  String customBannerBadge;
  DateTime? createdAt;
  DateTime? updatedAt;

  WorkoutLayoutSectionModel({
    required this.id,
    String? sectionId,
    required this.title,
    this.subtitle = '',
    this.showTitle = true,
    required this.type,
    this.layoutMode = 'carousel',
    this.filterSource = 'all',
    this.filterId = '',
    this.filterName = '',
    List<String>? selectedItemIds,
    this.itemLimit = 10,
    this.sortOrder = 1,
    this.isActive = true,
    this.customBannerImageUrl = '',
    this.customBannerVideoUrl = '',
    this.customBannerTargetType = 'program',
    this.customBannerTargetId = '',
    this.customBannerButtonText = 'Start Workout',
    this.customBannerBadge = '',
    this.createdAt,
    this.updatedAt,
  })  : sectionId = sectionId ?? id,
        selectedItemIds = selectedItemIds ?? [];

  factory WorkoutLayoutSectionModel.fromJson(Map<String, dynamic> json) {
    final secId = json['id'] ?? json['sectionId'] ?? json['_id'] ?? 'sec_${DateTime.now().millisecondsSinceEpoch}';

    List<String> ids = [];
    if (json['selectedItemIds'] != null && json['selectedItemIds'] is List) {
      ids = (json['selectedItemIds'] as List).map((e) => e.toString()).toList();
    }

    return WorkoutLayoutSectionModel(
      id: secId,
      sectionId: json['sectionId'] ?? secId,
      title: json['title'] ?? 'Section',
      subtitle: json['subtitle'] ?? '',
      showTitle: json['showTitle'] ?? json['showHeading'] ?? true,
      type: json['type'] ?? 'popular_programs',
      layoutMode: json['layoutMode'] ?? 'carousel',
      filterSource: json['filterSource'] ?? 'all',
      filterId: json['filterId'] ?? '',
      filterName: json['filterName'] ?? '',
      selectedItemIds: ids,
      itemLimit: (json['itemLimit'] as num?)?.toInt() ?? 10,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? (json['displayOrder'] as num?)?.toInt() ?? 1,
      isActive: json['isActive'] ?? true,
      customBannerImageUrl: json['customBannerImageUrl'] ?? '',
      customBannerVideoUrl: json['customBannerVideoUrl'] ?? '',
      customBannerTargetType: json['customBannerTargetType'] ?? 'program',
      customBannerTargetId: json['customBannerTargetId'] ?? '',
      customBannerButtonText: json['customBannerButtonText'] ?? 'Start Workout',
      customBannerBadge: json['customBannerBadge'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sectionId': sectionId,
      'title': title,
      'subtitle': subtitle,
      'showTitle': showTitle,
      'type': type,
      'layoutMode': layoutMode,
      'filterSource': filterSource,
      'filterId': filterId,
      'filterName': filterName,
      'selectedItemIds': selectedItemIds,
      'itemLimit': itemLimit,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'customBannerImageUrl': customBannerImageUrl,
      'customBannerVideoUrl': customBannerVideoUrl,
      'customBannerTargetType': customBannerTargetType,
      'customBannerTargetId': customBannerTargetId,
      'customBannerButtonText': customBannerButtonText,
      'customBannerBadge': customBannerBadge,
    };
  }
}

class WorkoutLayoutBackendService extends ChangeNotifier {
  static final WorkoutLayoutBackendService _instance = WorkoutLayoutBackendService._internal();
  factory WorkoutLayoutBackendService() => _instance;

  WorkoutLayoutBackendService._internal() {
    fetchLayoutSections();
    _initSocket();
  }

  IO.Socket? _socket;

  void _initSocket() {
    // Demo build: no live server to listen to.
    if (ApiConstants.demoMode) return;
    try {
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        debugPrint('⚡ [WorkoutLayout Socket] Connected to $socketUri');
        _socket?.emit('join_admin_room');
      });

      _socket?.on('workout_layout_updated', (data) {
        debugPrint('🔔 [WorkoutLayout Socket] Real-time layout update event received: $data');
        fetchLayoutSections(silent: true);
      });

      _socket?.onDisconnect((_) {
        debugPrint('🔌 [WorkoutLayout Socket] Disconnected');
      });
    } catch (e) {
      debugPrint('⚠️ [WorkoutLayout Socket] Init error: $e');
    }
  }

  final List<WorkoutLayoutSectionModel> _sections = [];
  List<WorkoutLayoutSectionModel> get sections => List.unmodifiable(_sections);
  List<WorkoutLayoutSectionModel> get activeSections =>
      _sections.where((s) => s.isActive).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchLayoutSections({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-layout';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final rawList = (body['data'] ?? body) as List<dynamic>? ?? [];

        final fetched = rawList.map((item) {
          return WorkoutLayoutSectionModel.fromJson(Map<String, dynamic>.from(item as Map));
        }).toList();

        fetched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        _sections.clear();
        _sections.addAll(fetched);
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('⚠️ [WorkoutLayout Fetch Error]: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createSection(WorkoutLayoutSectionModel section) async {
    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-layout';
      final res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(section.toJson()),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchLayoutSections(silent: true);
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [Create Workout Section Error]: $e');
    }
    return false;
  }

  Future<bool> updateSection(WorkoutLayoutSectionModel section) async {
    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-layout/${section.id}';
      final res = await http
          .put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(section.toJson()),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        await fetchLayoutSections(silent: true);
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [Update Workout Section Error]: $e');
    }
    return false;
  }

  Future<bool> toggleSectionStatus(String sectionId, bool currentStatus) async {
    final idx = _sections.indexWhere((s) => s.id == sectionId);
    if (idx != -1) {
      _sections[idx].isActive = !currentStatus;
      notifyListeners();
    }

    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-layout/$sectionId/status';
      final res = await http
          .patch(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'isActive': !currentStatus}),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [Toggle Workout Section Status Error]: $e');
    }

    if (idx != -1) {
      _sections[idx].isActive = currentStatus;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteSection(String sectionId) async {
    _sections.removeWhere((s) => s.id == sectionId);
    notifyListeners();

    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-layout/$sectionId';
      final res = await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ [Delete Workout Section Error]: $e');
      await fetchLayoutSections(silent: true);
      return false;
    }
  }

  Future<bool> reorderSections(List<WorkoutLayoutSectionModel> reordered) async {
    _sections.clear();
    _sections.addAll(reordered);
    for (int i = 0; i < _sections.length; i++) {
      _sections[i].sortOrder = i + 1;
    }
    notifyListeners();

    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-layout/reorder';
      final res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sectionIds': _sections.map((s) => s.id).toList(),
            }),
          )
          .timeout(const Duration(seconds: 6));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ [Reorder Workout Sections Error]: $e');
      return false;
    }
  }

  Future<void> reorderSectionsByIndex(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _sections.removeAt(oldIndex);
    _sections.insert(newIndex, item);

    final List<Map<String, dynamic>> orders = [];
    for (int i = 0; i < _sections.length; i++) {
      _sections[i].sortOrder = i + 1;
      orders.add({'id': _sections[i].id, 'sortOrder': i + 1});
    }
    notifyListeners();

    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-layout/reorder';
      await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sectionOrders': orders}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('⚠️ [Reorder Workout Sections Error]: $e');
    }
  }
}
