import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../widgets/upload_progress_overlay.dart';
import 'category_backend_service.dart';


class ExerciseCategoryModel {
  final String categoryId;
  final String id;
  String name;
  String imageUrl;
  int exerciseCount;
  String status;
  final DateTime createdAt;
  DateTime updatedAt;

  ExerciseCategoryModel({
    required this.categoryId,
    String? id,
    required this.name,
    required this.imageUrl,
    this.exerciseCount = 0,
    this.status = 'Active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? categoryId,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestoreFields() {
    return {
      'categoryId': {'stringValue': categoryId},
      'id': {'stringValue': id},
      'name': {'stringValue': name},
      'title': {'stringValue': name},
      'imageUrl': {'stringValue': imageUrl},
      'exerciseCount': {'integerValue': exerciseCount.toString()},
      'status': {'stringValue': status},
      'createdAt': {'timestampValue': createdAt.toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': updatedAt.toUtc().toIso8601String()},
    };
  }

  factory ExerciseCategoryModel.fromFirestoreDoc(Map<String, dynamic> doc) {
    final String fullPath = doc['name'] ?? '';
    final String docId = fullPath.split('/').last;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final String cId = fields['categoryId']?['stringValue'] ?? fields['id']?['stringValue'] ?? docId;
    final String name = fields['name']?['stringValue'] ?? fields['title']?['stringValue'] ?? 'Category';
    final String imageUrl = fields['imageUrl']?['stringValue'] ?? '';
    final int count = int.tryParse(fields['exerciseCount']?['integerValue']?.toString() ?? '0') ?? 0;
    final String status = fields['status']?['stringValue'] ?? 'Active';

    return ExerciseCategoryModel(
      categoryId: cId,
      id: docId,
      name: name,
      imageUrl: imageUrl,
      exerciseCount: count,
      status: status,
    );
  }
}

class ExerciseModel {
  final String exerciseId;
  final String id;
  String title;
  String categoryId;
  String categoryName;
  String mediaType; // 'gif', 'video', 'image'
  String mediaUrl;
  String muscleGroup;
  String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  String equipment;
  String instructions;
  String status;
  bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;

  ExerciseModel({
    required this.exerciseId,
    String? id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    this.mediaType = 'gif',
    required this.mediaUrl,
    this.muscleGroup = 'Full Body',
    this.difficulty = 'Intermediate',
    this.equipment = 'Bodyweight',
    this.instructions = '',
    this.status = 'Active',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? exerciseId,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestoreFields() {
    return {
      'exerciseId': {'stringValue': exerciseId},
      'id': {'stringValue': id},
      'title': {'stringValue': title},
      'name': {'stringValue': title},
      'categoryId': {'stringValue': categoryId},
      'categoryName': {'stringValue': categoryName},
      'mediaType': {'stringValue': mediaType},
      'mediaUrl': {'stringValue': mediaUrl},
      'muscleGroup': {'stringValue': muscleGroup},
      'difficulty': {'stringValue': difficulty},
      'equipment': {'stringValue': equipment},
      'instructions': {'stringValue': instructions},
      'status': {'stringValue': status},
      'isActive': {'booleanValue': isActive},
      'createdAt': {'timestampValue': createdAt.toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': updatedAt.toUtc().toIso8601String()},
    };
  }

  factory ExerciseModel.fromFirestoreDoc(Map<String, dynamic> doc) {
    final String fullPath = doc['name'] ?? '';
    final String docId = fullPath.split('/').last;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final String eId = fields['exerciseId']?['stringValue'] ?? fields['id']?['stringValue'] ?? docId;
    final String title = fields['title']?['stringValue'] ?? fields['name']?['stringValue'] ?? 'Exercise';
    final String categoryId = fields['categoryId']?['stringValue'] ?? '';
    final String categoryName = fields['categoryName']?['stringValue'] ?? 'General';
    final String mediaType = fields['mediaType']?['stringValue'] ?? 'gif';
    final String mediaUrl = fields['mediaUrl']?['stringValue'] ?? '';
    final String muscleGroup = fields['muscleGroup']?['stringValue'] ?? 'Full Body';
    final String difficulty = fields['difficulty']?['stringValue'] ?? 'Intermediate';
    final String equipment = fields['equipment']?['stringValue'] ?? 'Barbell';
    final String instructions = fields['instructions']?['stringValue'] ?? '';
    final String status = fields['status']?['stringValue'] ?? 'Active';
    final bool isActive = fields['isActive']?['booleanValue'] ?? (status == 'Active');

    return ExerciseModel(
      exerciseId: eId,
      id: docId,
      title: title,
      categoryId: categoryId,
      categoryName: categoryName,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      muscleGroup: muscleGroup,
      difficulty: difficulty,
      equipment: equipment,
      instructions: instructions,
      status: status,
      isActive: isActive,
    );
  }
}

class ExercisesBackendService extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  static final ExercisesBackendService _instance = ExercisesBackendService._internal();
  factory ExercisesBackendService() => _instance;
  ExercisesBackendService._internal() {
    fetchCategoriesFromFirestore();
    fetchExercisesFromFirestore();
  }

  static const String firebaseProjectId = 'neurofit-52fe0';
  static const String firebaseApiKey = 'AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg';

  final List<ExerciseCategoryModel> _categories = [
    ExerciseCategoryModel(categoryId: 'excat_chest', name: 'Chest & Pecs', imageUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/gym_equipment.jpg', exerciseCount: 42),
    ExerciseCategoryModel(categoryId: 'excat_back', name: 'Back & Lats', imageUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/gym_equipment.jpg', exerciseCount: 38),
    ExerciseCategoryModel(categoryId: 'excat_legs', name: 'Legs & Glutes', imageUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/footwear.jpg', exerciseCount: 54),
    ExerciseCategoryModel(categoryId: 'excat_arms', name: 'Arms (Biceps & Triceps)', imageUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/whey_protein.jpg', exerciseCount: 48),
    ExerciseCategoryModel(categoryId: 'excat_shoulders', name: 'Shoulders & Delts', imageUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/gym_equipment.jpg', exerciseCount: 32),
    ExerciseCategoryModel(categoryId: 'excat_core', name: 'Abs & Core', imageUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/shaker.jpg', exerciseCount: 30),
  ];

  final List<ExerciseModel> _exercises = [
    ExerciseModel(
      exerciseId: 'ex_incline_dumbbell_press',
      title: 'Incline Dumbbell Chest Press',
      categoryId: 'excat_chest',
      categoryName: 'Chest & Pecs',
      mediaType: 'gif',
      mediaUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/gym_equipment.jpg',
      muscleGroup: 'Upper Chest & Front Deltoids',
      difficulty: 'Intermediate',
      equipment: 'Incline Bench & Dumbbells',
      instructions: 'Set bench to 30 degrees. Retract shoulder blades, press dumbbells upward in a slight arc, and control the eccentric descent for 3 seconds.',
      status: 'Active',
    ),
    ExerciseModel(
      exerciseId: 'ex_barbell_deadlift',
      title: 'Conventional Barbell Deadlift',
      categoryId: 'excat_back',
      categoryName: 'Back & Lats',
      mediaType: 'video',
      mediaUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/gym_equipment.jpg',
      muscleGroup: 'Hamstrings, Glutes & Erector Spinae',
      difficulty: 'Advanced',
      equipment: 'Olympic Barbell & Bumper Plates',
      instructions: 'Stand mid-foot under the bar. Grip bar just outside legs, engage lats, drive through the floor, and lock out hips with neutral spine.',
      status: 'Active',
    ),
    ExerciseModel(
      exerciseId: 'ex_bulgarian_split_squat',
      title: 'Dumbbell Bulgarian Split Squat',
      categoryId: 'excat_legs',
      categoryName: 'Legs & Glutes',
      mediaType: 'image',
      mediaUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/footwear.jpg',
      muscleGroup: 'Quadriceps, Gluteus Medius',
      difficulty: 'Intermediate',
      equipment: 'Flat Bench & Dumbbells',
      instructions: 'Elevate rear foot on bench. Descend vertically until front thigh is parallel with floor, driving through the heel on the concentric phase.',
      status: 'Active',
    ),
  ];

  List<ExerciseCategoryModel> get categories => List.unmodifiable(_categories);
  List<ExerciseModel> get exercises => List.unmodifiable(_exercises);

  /// Fetch Categories from Firestore
  Future<void> fetchCategoriesFromFirestore() async {
    try {
      

      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/exercise_categories?key=$firebaseApiKey',
      );

      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>?;
        if (documents != null && documents.isNotEmpty) {
          final List<ExerciseCategoryModel> fetched = [];
          for (var doc in documents) {
            fetched.add(ExerciseCategoryModel.fromFirestoreDoc(doc));
          }
          if (fetched.isNotEmpty) {
            _categories.clear();
            _categories.addAll(fetched); notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch exercise categories error: $e');
    }
  }

  /// Fetch Exercises from Firestore
  Future<void> fetchExercisesFromFirestore() async {
    try {
      

      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/exercises?key=$firebaseApiKey',
      );

      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>?;
        if (documents != null && documents.isNotEmpty) {
          final List<ExerciseModel> fetched = [];
          for (var doc in documents) {
            fetched.add(ExerciseModel.fromFirestoreDoc(doc));
          }
          if (fetched.isNotEmpty) {
            _exercises.clear();
            _exercises.addAll(fetched); notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch exercises error: $e');
    }
  }

  /// Create Exercise Category
  Future<ExerciseCategoryModel?> createCategory({
    required String name,
    required String imageFileName,
    required Uint8List imageBytes,
  }) async {
    final notifier = UploadProgressNotifier();
    try {
      notifier.startUpload(imageFileName);
      final imageUrl = await CategoryBackendService().uploadRawImageToR2(
        fileName: imageFileName,
        imageBytes: imageBytes,
        onProgress: (p, s) => notifier.updateProgress(p, customStatus: s),
      );
      if (imageUrl == null) throw Exception('Failed to upload category image to R2');

      final cId = 'excat_${DateTime.now().millisecondsSinceEpoch}';
      final newCat = ExerciseCategoryModel(
        categoryId: cId,
        id: cId,
        name: name,
        imageUrl: imageUrl,
        exerciseCount: 0,
        status: 'Active',
      );

      final Uri firestoreUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/exercise_categories/$cId?key=$firebaseApiKey',
      );

      final fsRes = await http.patch(
        firestoreUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': newCat.toFirestoreFields()}),
      );

      if (fsRes.statusCode < 200 || fsRes.statusCode >= 300) {
        throw Exception('Firestore write failed with status ${fsRes.statusCode}: ${fsRes.body}');
      }

      _categories.add(newCat);
      
      notifier.completeUpload(imageUrl);
      return newCat;
    } catch (e) {
      notifier.failUpload(e.toString());
      return null;
    }
  }

  /// Update Exercise Category
  Future<void> updateCategory({
    required String categoryId,
    required String newName,
    String? newImageUrl,
  }) async {
    final index = _categories.indexWhere((c) => c.categoryId == categoryId || c.id == categoryId);
    if (index != -1) {
      _categories[index].name = newName;
      if (newImageUrl != null && newImageUrl.isNotEmpty) {
        _categories[index].imageUrl = newImageUrl;
      }
      _categories[index].updatedAt = DateTime.now();

      try {
        final Uri firestoreUri = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/exercise_categories/$categoryId?key=$firebaseApiKey',
        );

        await http.patch(
          firestoreUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fields': _categories[index].toFirestoreFields()}),
        );

        
      } catch (e) {
        debugPrint('Update category error: $e');
      }
    }
  }

  /// Delete Exercise Category
  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c.categoryId == categoryId || c.id == categoryId);

    try {
      final Uri firestoreUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/exercise_categories/$categoryId?key=$firebaseApiKey',
      );
      await http.delete(firestoreUri);
      
    } catch (e) {
      debugPrint('Delete category error: $e');
    }
  }

  /// Create Exercise with GIF, MP4 Video, or Image
  Future<ExerciseModel?> createExercise({
    required String title,
    required String categoryId,
    required String categoryName,
    required String mediaType, // 'gif', 'video', 'image'
    required String muscleGroup,
    required String difficulty,
    required String equipment,
    required String instructions,
    required String mediaFileName,
    required Uint8List mediaBytes,
  }) async {
    final notifier = UploadProgressNotifier();
    try {
      notifier.startUpload(mediaFileName);

      final mediaUrl = await CategoryBackendService().uploadRawImageToR2(
        fileName: mediaFileName,
        imageBytes: mediaBytes,
        onProgress: (p, s) => notifier.updateProgress(p, customStatus: 'Streaming $mediaType media: $s'),
      );

      if (mediaUrl == null) throw Exception('Failed to upload $mediaType to Cloudflare R2');

      notifier.updateProgress(0.90, customStatus: 'Writing exercise to Firestore...');

      final eId = 'ex_${DateTime.now().millisecondsSinceEpoch}';
      final newExercise = ExerciseModel(
        exerciseId: eId,
        id: eId,
        title: title,
        categoryId: categoryId,
        categoryName: categoryName,
        mediaType: mediaType,
        mediaUrl: mediaUrl,
        muscleGroup: muscleGroup,
        difficulty: difficulty,
        equipment: equipment,
        instructions: instructions,
        status: 'Active',
        isActive: true,
      );

      final Uri firestoreUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/exercises/$eId?key=$firebaseApiKey',
      );

      final fsRes = await http.patch(
        firestoreUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': newExercise.toFirestoreFields()}),
      );

      if (fsRes.statusCode < 200 || fsRes.statusCode >= 300) {
        throw Exception('Firestore write failed with status ${fsRes.statusCode}: ${fsRes.body}');
      }

      // Increment category count
      final cIndex = _categories.indexWhere((c) => c.categoryId == categoryId);
      if (cIndex != -1) {
        _categories[cIndex].exerciseCount += 1;
      }

      _exercises.insert(0, newExercise);
      

      notifier.completeUpload(mediaUrl);
      return newExercise;
    } catch (e) {
      notifier.failUpload(e.toString());
      return null;
    }
  }

  /// Update Exercise
  Future<void> updateExercise(ExerciseModel ex) async {
    final index = _exercises.indexWhere((e) => e.exerciseId == ex.exerciseId || e.id == ex.exerciseId);
    if (index != -1) {
      _exercises[index] = ex;

      try {
        final Uri firestoreUri = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/exercises/${ex.exerciseId}?key=$firebaseApiKey',
        );

        await http.patch(
          firestoreUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fields': ex.toFirestoreFields()}),
        );

        
      } catch (e) {
        debugPrint('Update exercise error: $e');
      }
    }
  }

  /// Delete Exercise
  Future<void> deleteExercise(String exerciseId) async {
    _exercises.removeWhere((e) => e.exerciseId == exerciseId || e.id == exerciseId);

    try {
      final Uri firestoreUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/exercises/$exerciseId?key=$firebaseApiKey',
      );
      await http.delete(firestoreUri);
      
    } catch (e) {
      debugPrint('Delete exercise error: $e');
    }
  }
}
