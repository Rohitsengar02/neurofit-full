import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'category_backend_service.dart';

class WorkoutExerciseModel {
  String exerciseId;
  String title;
  String categoryId;
  String muscleGroup;
  String mediaUrl;
  String mediaType;
  int sets;
  int reps;
  int durationSeconds;
  int restSeconds;
  String instructions;

  WorkoutExerciseModel({
    required this.exerciseId,
    required this.title,
    this.categoryId = '',
    this.muscleGroup = '',
    this.mediaUrl = '',
    this.mediaType = 'image',
    this.sets = 3,
    this.reps = 12,
    this.durationSeconds = 0,
    this.restSeconds = 45,
    this.instructions = '',
  });

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseModel(
      exerciseId: (json['exerciseId'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      muscleGroup: (json['muscleGroup'] ?? '').toString(),
      mediaUrl: (json['mediaUrl'] ?? json['imageUrl'] ?? '').toString(),
      mediaType: (json['mediaType'] ?? 'image').toString(),
      sets: json['sets'] is int ? json['sets'] : int.tryParse(json['sets']?.toString() ?? '3') ?? 3,
      reps: json['reps'] is int ? json['reps'] : int.tryParse(json['reps']?.toString() ?? '12') ?? 12,
      durationSeconds: json['durationSeconds'] is int ? json['durationSeconds'] : int.tryParse(json['durationSeconds']?.toString() ?? '0') ?? 0,
      restSeconds: json['restSeconds'] is int ? json['restSeconds'] : int.tryParse(json['restSeconds']?.toString() ?? '45') ?? 45,
      instructions: (json['instructions'] ?? json['tip'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'title': title,
      'categoryId': categoryId,
      'muscleGroup': muscleGroup,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'sets': sets,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'restSeconds': restSeconds,
      'instructions': instructions,
    };
  }
}

class WorkoutDayModel {
  int dayNumber;
  int weekNumber;
  String title;
  String focus;
  int durationMinutes;
  int caloriesBurn;
  bool isRestDay;
  List<WorkoutExerciseModel> exercises;

  WorkoutDayModel({
    this.dayNumber = 1,
    this.weekNumber = 1,
    String? title,
    String? focus,
    this.durationMinutes = 45,
    this.caloriesBurn = 350,
    this.isRestDay = false,
    List<WorkoutExerciseModel>? exercises,
  })  : title = title ?? '',
        focus = focus ?? 'Full Body Focus',
        exercises = exercises ?? [];

  factory WorkoutDayModel.fromJson(Map<String, dynamic> json) {
    final List<WorkoutExerciseModel> exList = [];
    if (json['exercises'] is List) {
      for (var e in json['exercises']) {
        if (e != null && e is Map) {
          exList.add(WorkoutExerciseModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return WorkoutDayModel(
      dayNumber: json['dayNumber'] is int ? json['dayNumber'] : int.tryParse(json['dayNumber']?.toString() ?? '1') ?? 1,
      weekNumber: json['weekNumber'] is int ? json['weekNumber'] : int.tryParse(json['weekNumber']?.toString() ?? '1') ?? 1,
      title: (json['title'] ?? json['name'] ?? '').toString(),
      focus: (json['focus'] ?? 'Full Body Focus').toString(),
      durationMinutes: json['durationMinutes'] is int ? json['durationMinutes'] : int.tryParse(json['durationMinutes']?.toString() ?? '45') ?? 45,
      caloriesBurn: json['caloriesBurn'] is int ? json['caloriesBurn'] : int.tryParse(json['caloriesBurn']?.toString() ?? '350') ?? 350,
      isRestDay: json['isRestDay'] == true,
      exercises: exList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'weekNumber': weekNumber,
      'title': title,
      'focus': focus,
      'durationMinutes': durationMinutes,
      'caloriesBurn': caloriesBurn,
      'isRestDay': isRestDay,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class WorkoutModel {
  String id;
  String title;
  String subtitle;
  String description;
  String category;
  String workoutCategoryId;
  int durationMinutes;
  int caloriesBurn;
  String level;
  String coach;
  String imageUrl;
  String mediaType;
  int exercisesCount;
  double completionRate;
  double rating;
  List<String> tags;
  List<WorkoutExerciseModel> exercises;
  List<WorkoutDayModel> days;
  bool isFeatured;
  bool isActive;
  DateTime? createdAt;

  WorkoutModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.description = '',
    required this.category,
    this.workoutCategoryId = '',
    this.durationMinutes = 45,
    this.caloriesBurn = 350,
    this.level = 'Intermediate',
    this.coach = 'Coach Vikram',
    required this.imageUrl,
    this.mediaType = 'image',
    this.exercisesCount = 6,
    this.completionRate = 92.0,
    this.rating = 4.9,
    List<String>? tags,
    List<WorkoutExerciseModel>? exercises,
    List<WorkoutDayModel>? days,
    this.isFeatured = true,
    this.isActive = true,
    this.createdAt,
  })  : tags = tags ?? [],
        exercises = exercises ?? [],
        days = days ?? [];

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['imageUrl'] ?? json['mediaUrl'] ?? '').toString();
    String mType = (json['mediaType'] ?? 'image').toString();
    if (mType == 'image' && rawUrl.isNotEmpty) {
      final lower = rawUrl.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')) {
        mType = 'video';
      } else if (lower.endsWith('.gif')) {
        mType = 'gif';
      }
    }

    final List<WorkoutExerciseModel> exList = [];
    if (json['exercises'] is List) {
      for (var e in json['exercises']) {
        if (e != null && e is Map) {
          exList.add(WorkoutExerciseModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final List<WorkoutDayModel> dList = [];
    if (json['days'] is List) {
      for (var d in json['days']) {
        if (d != null && d is Map) {
          dList.add(WorkoutDayModel.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    }

    final List<String> tList = [];
    if (json['tags'] is List) {
      for (var t in json['tags']) {
        if (t != null && t.toString().isNotEmpty) {
          tList.add(t.toString());
        }
      }
    }

    return WorkoutModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'General').toString(),
      workoutCategoryId: (json['workoutCategoryId'] ?? '').toString(),
      durationMinutes: json['durationMinutes'] is int ? json['durationMinutes'] : int.tryParse(json['durationMinutes']?.toString() ?? '45') ?? 45,
      caloriesBurn: json['caloriesBurn'] is int ? json['caloriesBurn'] : int.tryParse(json['caloriesBurn']?.toString() ?? '350') ?? 350,
      level: (json['level'] ?? 'Intermediate').toString(),
      coach: (json['coach'] ?? 'Coach Vikram').toString(),
      imageUrl: rawUrl,
      mediaType: mType,
      exercisesCount: exList.isNotEmpty ? exList.length : (json['exercisesCount'] is int ? json['exercisesCount'] : int.tryParse(json['exercisesCount']?.toString() ?? '6') ?? 6),
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 92.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      tags: tList,
      exercises: exList,
      days: dList,
      isFeatured: json['isFeatured'] == true,
      isActive: json['isActive'] != false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'category': category,
      'workoutCategoryId': workoutCategoryId,
      'durationMinutes': durationMinutes,
      'caloriesBurn': caloriesBurn,
      'level': level,
      'coach': coach,
      'imageUrl': imageUrl,
      'mediaType': mediaType,
      'exercisesCount': exercises.isNotEmpty ? exercises.length : exercisesCount,
      'completionRate': completionRate,
      'rating': rating,
      'tags': tags,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'days': days.map((d) => d.toJson()).toList(),
      'isFeatured': isFeatured,
      'isActive': isActive,
    };
  }

  factory WorkoutModel.fromFirestore(Map<String, dynamic> fields, String id) {
    List<String> tagsList = [];
    if (fields['tags']?['arrayValue']?['values'] != null) {
      for (var val in fields['tags']['arrayValue']['values']) {
        if (val['stringValue'] != null) tagsList.add(val['stringValue']);
      }
    }

    return WorkoutModel(
      id: id,
      title: fields['title']?['stringValue'] ?? 'Untitled Workout',
      category: fields['category']?['stringValue'] ?? 'General',
      durationMinutes: int.tryParse(fields['durationMinutes']?['integerValue']?.toString() ?? '45') ?? 45,
      caloriesBurn: int.tryParse(fields['caloriesBurn']?['integerValue']?.toString() ?? '350') ?? 350,
      level: fields['level']?['stringValue'] ?? 'Intermediate',
      coach: fields['coach']?['stringValue'] ?? 'Coach Vikram',
      imageUrl: fields['imageUrl']?['stringValue'] ?? '',
      exercisesCount: int.tryParse(fields['exercisesCount']?['integerValue']?.toString() ?? '6') ?? 6,
      completionRate: (fields['completionRate']?['doubleValue'] as num?)?.toDouble() ?? 90.0,
      rating: (fields['rating']?['doubleValue'] as num?)?.toDouble() ?? 4.9,
      tags: tagsList,
      isFeatured: fields['isFeatured']?['booleanValue'] ?? false,
    );
  }
}

class WorkoutsBackendService extends ChangeNotifier {
  static final WorkoutsBackendService _instance = WorkoutsBackendService._internal();
  factory WorkoutsBackendService() => _instance;
  WorkoutsBackendService._internal() {
    _initSocket();
    fetchWorkouts();
  }

  IO.Socket? _socket;
  List<WorkoutModel> _workouts = [];
  List<WorkoutModel> get workouts => List.unmodifiable(_workouts);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _initSocket() {
    // Demo build: no live server to listen to.
    if (ApiConstants.demoMode) return;
    try {
      final socketUrl = ApiConstants.baseUrl;
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket?.onConnect((_) {
        debugPrint('⚡ [ADMIN WORKOUTS SOCKET CONNECTED] Realtime active');
      });

      _socket?.on('workout_created', (data) {
        if (data != null) {
          final newW = WorkoutModel.fromJson(Map<String, dynamic>.from(data));
          _workouts.removeWhere((w) => w.id == newW.id);
          _workouts.insert(0, newW);
          notifyListeners();
        }
      });

      _socket?.on('workout_updated', (data) {
        if (data != null) {
          final updatedW = WorkoutModel.fromJson(Map<String, dynamic>.from(data));
          final idx = _workouts.indexWhere((w) => w.id == updatedW.id);
          if (idx != -1) {
            _workouts[idx] = updatedW;
          } else {
            _workouts.insert(0, updatedW);
          }
          notifyListeners();
        }
      });

      _socket?.on('workout_deleted', (data) {
        if (data != null && data['id'] != null) {
          final id = data['id'].toString();
          _workouts.removeWhere((w) => w.id == id);
          notifyListeners();
        }
      });

      _socket?.on('workouts_updated', (data) {
        if (data is List) {
          _workouts.clear();
          for (var item in data) {
            _workouts.add(WorkoutModel.fromJson(Map<String, dynamic>.from(item)));
          }
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Error initializing admin workouts socket: $e');
    }
  }

  Future<void> fetchWorkouts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final baseUrl = ApiConstants.baseUrl;
      final response = await http.get(Uri.parse('$baseUrl/api/workouts')).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          _workouts.clear();
          for (var item in body['data']) {
            _workouts.add(WorkoutModel.fromJson(Map<String, dynamic>.from(item)));
          }
          debugPrint('✅ [WORKOUTS LOADED FROM BACKEND] ${_workouts.length} workouts');
        }
      }
    } catch (e) {
      debugPrint('Error fetching workouts from API, trying Firestore fallback: $e');
      await fetchWorkoutsFromFirestore();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWorkoutsFromFirestore() async {
    try {
      const projectId = "neurofit-52fe0";
      const apiKey = "AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg";
      final url = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/workouts?key=$apiKey";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['documents'] != null) {
          _workouts.clear();
          for (var doc in data['documents']) {
            final fields = doc['fields'];
            final id = doc['name'].toString().split('/').last;
            _workouts.add(WorkoutModel.fromFirestore(fields, id));
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching workouts from Firestore: $e");
    }
  }

  Future<bool> createWorkout(WorkoutModel workout) async {
    try {
      final baseUrl = ApiConstants.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/api/workouts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(workout.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchWorkouts();
        return true;
      }
    } catch (e) {
      debugPrint('Error creating workout: $e');
    }
    return false;
  }

  Future<bool> updateWorkout(String id, WorkoutModel workout) async {
    try {
      final baseUrl = ApiConstants.baseUrl;
      final response = await http.put(
        Uri.parse('$baseUrl/api/workouts/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(workout.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchWorkouts();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating workout: $e');
    }
    return false;
  }

  Future<bool> deleteWorkout(String id) async {
    try {
      final baseUrl = ApiConstants.baseUrl;
      final response = await http.delete(Uri.parse('$baseUrl/api/workouts/$id'));

      if (response.statusCode == 200) {
        _workouts.removeWhere((w) => w.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting workout: $e');
    }
    return false;
  }
}
