import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'category_backend_service.dart';

class ProgramModel {
  String id;
  String title;
  String type;
  int weeks;
  int workoutsPerWeek;
  String level;
  String coach;
  int enrolledCount;
  double rating;
  double price;
  String badge;
  String imageUrl;
  String description;
  List<String> features;
  DateTime? createdAt;

  ProgramModel({
    required this.id,
    required this.title,
    required this.type,
    this.weeks = 8,
    this.workoutsPerWeek = 5,
    this.level = 'Advanced',
    this.coach = 'Coach Priya & Vikram',
    this.enrolledCount = 1420,
    this.rating = 4.95,
    this.price = 1999.0,
    this.badge = 'BESTSELLER',
    required this.imageUrl,
    this.description = '',
    List<String>? features,
    this.createdAt,
  }) : features = features ?? [];

  factory ProgramModel.fromFirestoreDoc(dynamic doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final name = doc['name'] as String? ?? '';
    final id = name.split('/').last;

    final featList = (fields['features']?['arrayValue']?['values'] as List<dynamic>?)
            ?.map((f) => f['stringValue']?.toString() ?? '')
            .where((f) => f.isNotEmpty)
            .toList() ??
        [];

    return ProgramModel(
      id: id,
      title: fields['title']?['stringValue'] ?? 'Untitled Program',
      type: fields['type']?['stringValue'] ?? '8-Week Shreds',
      weeks: int.tryParse(fields['weeks']?['integerValue']?.toString() ?? '8') ?? 8,
      workoutsPerWeek: int.tryParse(fields['workoutsPerWeek']?['integerValue']?.toString() ?? '5') ?? 5,
      level: fields['level']?['stringValue'] ?? 'Advanced',
      coach: fields['coach']?['stringValue'] ?? 'Coach Priya & Vikram',
      enrolledCount: int.tryParse(fields['enrolledCount']?['integerValue']?.toString() ?? '1420') ?? 1420,
      rating: (fields['rating']?['doubleValue'] as num?)?.toDouble() ?? 4.95,
      price: (fields['price']?['doubleValue'] as num?)?.toDouble() ?? 1999.0,
      badge: fields['badge']?['stringValue'] ?? 'BESTSELLER',
      imageUrl: fields['imageUrl']?['stringValue'] ?? '',
      description: fields['description']?['stringValue'] ?? '',
      features: featList,
    );
  }
}

class ProgramsBackendService extends ChangeNotifier {
  static final ProgramsBackendService _instance = ProgramsBackendService._internal();
  factory ProgramsBackendService() => _instance;
  ProgramsBackendService._internal() {
    fetchProgramsFromFirestore();
  }

  static const String projectId = "neurofit-52fe0";
  static const String apiKey = "AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg";
  static const String firestoreBase = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents";

  List<ProgramModel> _programs = [];
  List<ProgramModel> get programs => List.unmodifiable(_programs);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchProgramsFromFirestore() async {
    _isLoading = true;
    notifyListeners();

    try {
      final Uri uri = Uri.parse('$firestoreBase/fitness_programs?key=$apiKey&pageSize=100');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>? ?? [];

        final List<ProgramModel> fetched = [];
        for (var doc in documents) {
          fetched.add(ProgramModel.fromFirestoreDoc(doc));
        }

        _programs = fetched;
        debugPrint('✅ [PROGRAMS LOADED FROM FIRESTORE] ${_programs.length} live programs');
      }
    } catch (e) {
      debugPrint('❌ Error loading programs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProgram(ProgramModel program, {Uint8List? rawImageBytes, String? imageFileName}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String mainUrl = program.imageUrl;
      if (rawImageBytes != null && imageFileName != null) {
        final uploadedUrl = await CategoryBackendService().uploadRawImageToR2(
          imageBytes: rawImageBytes,
          fileName: imageFileName,
        );
        if (uploadedUrl != null) mainUrl = uploadedUrl;
      }

      final fields = {
        'title': {'stringValue': program.title},
        'type': {'stringValue': program.type},
        'weeks': {'integerValue': program.weeks.toString()},
        'workoutsPerWeek': {'integerValue': program.workoutsPerWeek.toString()},
        'level': {'stringValue': program.level},
        'coach': {'stringValue': program.coach},
        'enrolledCount': {'integerValue': program.enrolledCount.toString()},
        'rating': {'doubleValue': program.rating},
        'price': {'doubleValue': program.price},
        'badge': {'stringValue': program.badge},
        'imageUrl': {'stringValue': mainUrl},
        'description': {'stringValue': program.description},
        'features': {'arrayValue': {'values': program.features.map((f) => {'stringValue': f}).toList()}},
      };

      final Uri uri = Uri.parse('$firestoreBase/fitness_programs/${program.id}?key=$apiKey');
      final res = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': fields}),
      );

      if (res.statusCode == 200) {
        await fetchProgramsFromFirestore();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding program: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProgram(String programId) async {
    try {
      final Uri uri = Uri.parse('$firestoreBase/fitness_programs/$programId?key=$apiKey');
      final res = await http.delete(uri);
      if (res.statusCode == 200) {
        _programs.removeWhere((p) => p.id == programId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
