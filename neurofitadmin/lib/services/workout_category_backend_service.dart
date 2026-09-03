import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class WorkoutCategoryModel {
  String id;
  String name;
  String description;
  String mediaType; // 'image' | 'gif' | 'video'
  String mediaUrl;
  int sortOrder;
  bool isActive;

  WorkoutCategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.mediaType = 'image',
    this.mediaUrl = '',
    this.sortOrder = 1,
    this.isActive = true,
  });

  factory WorkoutCategoryModel.fromJson(Map<String, dynamic> json) {
    return WorkoutCategoryModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      mediaType: json['mediaType'] ?? 'image',
      mediaUrl: json['mediaUrl'] ?? '',
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] : int.tryParse(json['sortOrder']?.toString() ?? '1') ?? 1,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}

class WorkoutCategoryBackendService extends ChangeNotifier {
  static final WorkoutCategoryBackendService _instance = WorkoutCategoryBackendService._internal();
  factory WorkoutCategoryBackendService() => _instance;

  WorkoutCategoryBackendService._internal() {
    _initSocket();
  }

  final List<WorkoutCategoryModel> _categories = [];
  bool _isLoading = false;
  IO.Socket? _socket;

  List<WorkoutCategoryModel> get categories => List.unmodifiable(_categories);
  List<WorkoutCategoryModel> get activeCategories =>
      _categories.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;

  void _initSocket() {
    try {
      final socketUrl = ApiConstants.apiBaseUrl.replaceAll('/api', '');
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket?.on('workout_category_updated', (data) {
        debugPrint('⚡ [Workout Category Socket Event]: $data');
        fetchCategories(silent: true);
      });
    } catch (e) {
      debugPrint('⚠️ [Workout Category Socket Init Error]: $e');
    }
  }

  Future<void> fetchCategories({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-categories';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          _categories.clear();
          for (final item in decoded['data']) {
            _categories.add(WorkoutCategoryModel.fromJson(item));
          }
          _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Fetch Workout Categories Error]: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory(WorkoutCategoryModel cat) async {
    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-categories';
      final res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(cat.toJson()),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 201 || res.statusCode == 200) {
        await fetchCategories(silent: true);
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [Create Workout Category Error]: $e');
    }
    return false;
  }

  Future<bool> updateCategory(WorkoutCategoryModel cat) async {
    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-categories/${cat.id}';
      final res = await http
          .put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(cat.toJson()),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final idx = _categories.indexWhere((c) => c.id == cat.id);
        if (idx != -1) {
          _categories[idx] = cat;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [Update Workout Category Error]: $e');
    }
    return false;
  }

  Future<bool> toggleCategoryStatus(String id, bool currentStatus) async {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _categories[idx].isActive = !currentStatus;
      notifyListeners();
    }

    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-categories/$id/status';
      final res = await http
          .patch(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'isActive': !currentStatus}),
          )
          .timeout(const Duration(seconds: 6));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ [Toggle Workout Category Status Error]: $e');
      if (idx != -1) {
        _categories[idx].isActive = currentStatus;
        notifyListeners();
      }
      return false;
    }
  }

  Future<void> reorderCategoriesByIndex(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);

    final List<Map<String, dynamic>> orders = [];
    for (int i = 0; i < _categories.length; i++) {
      _categories[i].sortOrder = i + 1;
      orders.add({'id': _categories[i].id, 'sortOrder': i + 1});
    }
    notifyListeners();

    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-categories/reorder';
      await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'categoryOrders': orders}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('⚠️ [Reorder Workout Categories Error]: $e');
    }
  }

  Future<bool> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();

    try {
      final url = '${ApiConstants.apiBaseUrl}/workout-categories/$id';
      final res = await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ [Delete Workout Category Error]: $e');
      await fetchCategories(silent: true);
      return false;
    }
  }
}
