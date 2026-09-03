import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class WorkoutBannerModel {
  String id;
  String bannerId;
  String title;
  String subtitle;
  String imageUrl;
  String mediaType; // 'image' | 'gif' | 'video'
  String targetType;
  String targetId;
  String targetName;
  String badge;
  String buttonText;
  bool showTitle;
  int sortOrder;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  WorkoutBannerModel({
    this.id = '',
    required this.bannerId,
    required this.title,
    this.subtitle = '',
    required this.imageUrl,
    this.mediaType = 'image',
    this.targetType = 'category',
    this.targetId = '',
    this.targetName = '',
    this.badge = '',
    this.buttonText = 'Explore',
    this.showTitle = true,
    this.sortOrder = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory WorkoutBannerModel.fromJson(Map<String, dynamic> json) {
    final String rawUrl = json['imageUrl']?.toString() ?? json['mediaUrl']?.toString() ?? '';
    String mType = json['mediaType']?.toString() ?? 'image';
    if (mType == 'image') {
      final lower = rawUrl.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm') || lower.endsWith('.avi')) {
        mType = 'video';
      } else if (lower.endsWith('.gif')) {
        mType = 'gif';
      }
    }

    return WorkoutBannerModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      bannerId: json['bannerId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      imageUrl: rawUrl,
      mediaType: mType,
      targetType: json['targetType']?.toString() ?? 'category',
      targetId: json['targetId']?.toString() ?? '',
      targetName: json['targetName']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
      buttonText: json['buttonText']?.toString() ?? 'Explore',
      showTitle: json['showTitle'] ?? true,
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder']
          : int.tryParse(json['sortOrder']?.toString() ?? '0') ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bannerId': bannerId,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'mediaType': mediaType,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'badge': badge,
      'buttonText': buttonText,
      'showTitle': showTitle,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}

class WorkoutBannersBackendService extends ChangeNotifier {
  static final WorkoutBannersBackendService _instance = WorkoutBannersBackendService._internal();
  factory WorkoutBannersBackendService() => _instance;
  WorkoutBannersBackendService._internal() {
    fetchWorkoutBanners();
    _initSocket();
  }

  final List<WorkoutBannerModel> _banners = [];
  bool _isLoading = false;
  IO.Socket? _socket;

  List<WorkoutBannerModel> get banners => List.unmodifiable(_banners);
  bool get isLoading => _isLoading;

  void _initSocket() {
    try {
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        debugPrint('⚡ [Admin WorkoutBanners Socket] Connected to $socketUri');
        _socket?.emit('join_admin_room', 'admin');
      });

      _socket?.on('workout_banner_created', (data) {
        debugPrint('🔔 [Admin WorkoutBanners Socket] Banner created: $data');
        if (data is Map) {
          final banner = WorkoutBannerModel.fromJson(Map<String, dynamic>.from(data));
          final idx = _banners.indexWhere((b) =>
              (b.id.isNotEmpty && b.id == banner.id) ||
              (b.bannerId.isNotEmpty && b.bannerId == banner.bannerId));
          if (idx == -1) {
            _banners.add(banner);
          } else {
            _banners[idx] = banner;
          }
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('workout_banner_updated', (data) {
        debugPrint('🔔 [Admin WorkoutBanners Socket] Banner updated: $data');
        if (data is Map) {
          final banner = WorkoutBannerModel.fromJson(Map<String, dynamic>.from(data));
          final idx = _banners.indexWhere((b) =>
              (b.id.isNotEmpty && b.id == banner.id) ||
              (b.bannerId.isNotEmpty && b.bannerId == banner.bannerId));
          if (idx != -1) {
            _banners[idx] = banner;
          } else {
            _banners.add(banner);
          }
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('workout_banner_deleted', (data) {
        debugPrint('🔔 [Admin WorkoutBanners Socket] Banner deleted: $data');
        if (data is Map) {
          final id = data['id']?.toString() ?? '';
          final bannerId = data['bannerId']?.toString() ?? '';
          _banners.removeWhere((b) =>
              (id.isNotEmpty && b.id == id) ||
              (bannerId.isNotEmpty && b.bannerId == bannerId));
          notifyListeners();
        }
      });

      _socket?.on('workout_banners_updated', (data) {
        debugPrint('🔔 [Admin WorkoutBanners Socket] Banners updated list received');
        if (data is List) {
          _banners.clear();
          for (var item in data) {
            if (item is Map) {
              _banners.add(WorkoutBannerModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.onDisconnect((_) {
        debugPrint('🔌 [Admin WorkoutBanners Socket] Disconnected');
      });
    } catch (e) {
      debugPrint('⚠️ [Admin WorkoutBanners Socket] Init error: $e');
    }
  }

  Future<void> fetchWorkoutBanners() async {
    _isLoading = true;
    notifyListeners();

    try {
      final baseUrl = ApiConstants.baseUrl;
      final response = await http.get(Uri.parse('$baseUrl/api/workout-banners'));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          _banners.clear();
          for (var item in body['data']) {
            _banners.add(WorkoutBannerModel.fromJson(item));
          }
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        }
      }
    } catch (e) {
      debugPrint('Error fetching workout banners from backend API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<WorkoutBannerModel?> createWorkoutBanner({
    required String title,
    required String subtitle,
    required String imageUrl,
    required String mediaType,
    required String targetType,
    required String targetId,
    required String targetName,
    required String badge,
    required String buttonText,
    required bool showTitle,
    required int sortOrder,
  }) async {
    try {
      final baseUrl = ApiConstants.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/api/workout-banners'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'subtitle': subtitle,
          'imageUrl': imageUrl,
          'mediaType': mediaType,
          'targetType': targetType,
          'targetId': targetId,
          'targetName': targetName,
          'badge': badge,
          'buttonText': buttonText,
          'showTitle': showTitle,
          'sortOrder': sortOrder,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final newBanner = WorkoutBannerModel.fromJson(body['data']);
          final idx = _banners.indexWhere((b) =>
              (b.id.isNotEmpty && b.id == newBanner.id) ||
              (b.bannerId.isNotEmpty && b.bannerId == newBanner.bannerId));
          if (idx == -1) {
            _banners.add(newBanner);
          } else {
            _banners[idx] = newBanner;
          }
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
          return newBanner;
        }
      }
    } catch (e) {
      debugPrint('Error creating workout banner: $e');
    }
    return null;
  }

  Future<bool> updateWorkoutBanner(WorkoutBannerModel banner) async {
    try {
      final baseUrl = ApiConstants.baseUrl;
      final bId = banner.id.isNotEmpty ? banner.id : banner.bannerId;
      final response = await http.put(
        Uri.parse('$baseUrl/api/workout-banners/$bId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(banner.toJson()),
      );

      if (response.statusCode == 200) {
        final idx = _banners.indexWhere((b) => b.id == banner.id || b.bannerId == banner.bannerId);
        if (idx != -1) {
          _banners[idx] = banner;
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error updating workout banner: $e');
    }
    return false;
  }

  Future<bool> deleteWorkoutBanner(String id) async {
    try {
      final baseUrl = ApiConstants.baseUrl;
      final response = await http.delete(Uri.parse('$baseUrl/api/workout-banners/$id'));
      if (response.statusCode == 200) {
        _banners.removeWhere((b) => b.id == id || b.bannerId == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting workout banner: $e');
    }
    return false;
  }
}
