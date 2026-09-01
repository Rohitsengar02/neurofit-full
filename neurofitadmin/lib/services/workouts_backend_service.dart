import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'category_backend_service.dart';

class WorkoutModel {
  String id;
  String title;
  String category;
  int durationMinutes;
  int caloriesBurn;
  String level;
  String coach;
  String imageUrl;
  int exercisesCount;
  double completionRate;
  double rating;
  List<String> tags;
  bool isFeatured;
  DateTime? createdAt;

  WorkoutModel({
    required this.id,
    required this.title,
    required this.category,
    this.durationMinutes = 45,
    this.caloriesBurn = 350,
    this.level = 'Intermediate',
    this.coach = 'Coach Vikram',
    required this.imageUrl,
    this.exercisesCount = 6,
    this.completionRate = 92.0,
    this.rating = 4.9,
    List<String>? tags,
    this.isFeatured = true,
    this.createdAt,
  }) : tags = tags ?? [];

  factory WorkoutModel.fromFirestoreDoc(dynamic doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final name = doc['name'] as String? ?? '';
    final id = name.split('/').last;

    final tagsList = (fields['tags']?['arrayValue']?['values'] as List<dynamic>?)
            ?.map((t) => t['stringValue']?.toString() ?? '')
            .where((t) => t.isNotEmpty)
            .toList() ??
        [];

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
    fetchWorkoutsFromFirestore();
  }

  static const String projectId = "neurofit-52fe0";
  static const String apiKey = "AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg";
  static const String firestoreBase = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents";

  List<WorkoutModel> _workouts = [];
  List<WorkoutModel> get workouts => List.unmodifiable(_workouts);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchWorkoutsFromFirestore() async {
    _isLoading = true;
    notifyListeners();

    try {
      final Uri uri = Uri.parse('$firestoreBase/workouts?key=$apiKey&pageSize=100');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>? ?? [];

        final List<WorkoutModel> fetched = [];
        for (var doc in documents) {
          fetched.add(WorkoutModel.fromFirestoreDoc(doc));
        }

        _workouts = fetched;
        debugPrint('✅ [WORKOUTS LOADED FROM FIRESTORE] ${_workouts.length} live workouts');
      }
    } catch (e) {
      debugPrint('❌ Error loading workouts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addWorkout(WorkoutModel workout, {Uint8List? rawImageBytes, String? imageFileName}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String mainUrl = workout.imageUrl;
      if (rawImageBytes != null && imageFileName != null) {
        final uploadedUrl = await CategoryBackendService().uploadRawImageToR2(
          imageBytes: rawImageBytes,
          fileName: imageFileName,
        );
        if (uploadedUrl != null) mainUrl = uploadedUrl;
      }

      final fields = {
        'title': {'stringValue': workout.title},
        'category': {'stringValue': workout.category},
        'durationMinutes': {'integerValue': workout.durationMinutes.toString()},
        'caloriesBurn': {'integerValue': workout.caloriesBurn.toString()},
        'level': {'stringValue': workout.level},
        'coach': {'stringValue': workout.coach},
        'imageUrl': {'stringValue': mainUrl},
        'exercisesCount': {'integerValue': workout.exercisesCount.toString()},
        'completionRate': {'doubleValue': workout.completionRate},
        'rating': {'doubleValue': workout.rating},
        'tags': {'arrayValue': {'values': workout.tags.map((t) => {'stringValue': t}).toList()}},
        'isFeatured': {'booleanValue': workout.isFeatured},
      };

      final Uri uri = Uri.parse('$firestoreBase/workouts/${workout.id}?key=$apiKey');
      final res = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': fields}),
      );

      if (res.statusCode == 200) {
        await fetchWorkoutsFromFirestore();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding workout: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteWorkout(String workoutId) async {
    try {
      final Uri uri = Uri.parse('$firestoreBase/workouts/$workoutId?key=$apiKey');
      final res = await http.delete(uri);
      if (res.statusCode == 200) {
        _workouts.removeWhere((w) => w.id == workoutId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
