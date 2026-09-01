import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'category_backend_service.dart';

typedef ProductModel = ProductItem;
typedef ProductVariantModel = ProductVariant;

class ProductVariant {
  String variantId;
  String name;
  double price;
  int stock;
  String sku;
  String imageUrl;
  Uint8List? localBytes;

  ProductVariant({
    this.variantId = '',
    required this.name,
    required this.price,
    required this.stock,
    required this.sku,
    this.imageUrl = '',
    this.localBytes,
  });

  Map<String, dynamic> toJson() => {
    'variantId': variantId,
    'name': name,
    'price': price,
    'stock': stock,
    'sku': sku,
    'imageUrl': imageUrl,
  };

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    variantId: json['variantId'] ?? '',
    name: json['name'] ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    sku: json['sku'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
  );
}

class ProductItem {
  // Compatibility Getters & Setters
  int get totalStock => stock;
  set totalStock(int val) => stock = val;

  int get lowStockAlert => lowStockThreshold;
  set lowStockAlert(int val) => lowStockThreshold = val;

  String get subCategoryId => subcategoryId;
  set subCategoryId(String val) => subcategoryId = val;

  String get subCategoryName => subcategoryName;
  set subCategoryName(String val) => subcategoryName = val;

  String get stockStatus => stock <= 0 ? 'Out of Stock' : (stock <= lowStockThreshold ? 'Low Stock' : 'In Stock');
  set stockStatus(String val) {
    if (val == 'Out of Stock') stock = 0;
  }

  List<String> get galleryImages => additionalImages;
  set galleryImages(List<String> val) => additionalImages = val;

  String get category => categoryName;
  set category(String val) => categoryName = val;
  double get salePrice => price;
  set salePrice(double val) => price = val;
  double get basePrice => regularPrice > 0 ? regularPrice : price;
  set basePrice(double val) => regularPrice = val;
  List<String> get images => [mainImageUrl, ...additionalImages].where((s) => s.isNotEmpty).toList();
  set images(List<String> val) {
    if (val.isNotEmpty) {
      mainImageUrl = val.first;
      additionalImages = val.skip(1).toList();
    }
  }

  final String id;
  final String productId;
  String title;
  String description;
  String sku;
  String barcode;
  String categoryId;
  String categoryName;
  String subcategoryId;
  String subcategoryName;
  String? discountId;
  String? discountCode;
  double price;
  double regularPrice;
  double costPerItem;
  int stock;
  int lowStockThreshold;
  String brand;
  String vendor;
  List<String> tags;
  String status;
  bool isActive;
  String mainImageUrl;
  List<String> additionalImages;
  List<ProductVariant> variants;
  bool isFeatured;
  double rating;
  int reviewCount;
  double weightGrams;
  String dimensions;
  final DateTime createdAt;
  DateTime updatedAt;

  ProductItem({
    String? id,
    String? productId,
    required this.title,
    this.description = '',
    this.sku = '',
    this.barcode = '',
    this.categoryId = '',
    this.categoryName = 'General',
    this.subcategoryId = '',
    this.subcategoryName = '',
    this.discountId,
    this.discountCode,
    this.price = 0.0,
    this.regularPrice = 0.0,
    this.costPerItem = 0.0,
    this.stock = 0,
    this.lowStockThreshold = 5,
    this.brand = 'NeuroFit',
    this.vendor = 'Official Store',
    this.tags = const [],
    this.status = 'active',
    this.isActive = true,
    this.mainImageUrl = '',
    this.additionalImages = const [],
    this.variants = const [],
    this.isFeatured = false,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.weightGrams = 0.0,
    this.dimensions = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? productId ?? '',
        productId = productId ?? id ?? '',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ProductItem.fromMongoJson(Map<String, dynamic> json) {
    final vList = (json['variants'] as List<dynamic>? ?? [])
        .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
        .toList();

    final pId = json['id'] ?? json['productId'] ?? json['_id'] ?? '';
    return ProductItem(
      id: pId,
      productId: pId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      sku: json['sku'] ?? '',
      barcode: json['barcode'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? 'General',
      subcategoryId: json['subcategoryId'] ?? '',
      subcategoryName: json['subcategoryName'] ?? '',
      discountId: json['discountId'] ?? '',
      discountCode: json['discountCode'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      regularPrice: (json['regularPrice'] as num?)?.toDouble() ?? 0.0,
      costPerItem: (json['costPerItem'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 5,
      brand: json['brand'] ?? 'NeuroFit',
      vendor: json['vendor'] ?? 'Official Store',
      tags: (json['tags'] as List<dynamic>? ?? []).map((t) => t.toString()).toList(),
      status: json['status'] ?? 'active',
      isActive: (json['status'] ?? 'active') == 'active',
      mainImageUrl: json['mainImageUrl'] ?? '',
      additionalImages: (json['additionalImages'] as List<dynamic>? ?? []).map((i) => i.toString()).toList(),
      variants: vList,
    );
  }

  factory ProductItem.fromFirestoreDoc(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final String path = doc['name'] ?? '';
    final String autoId = path.split('/').last;

    List<ProductVariant> vars = [];
    if (fields['variants']?['arrayValue']?['values'] != null) {
      final list = fields['variants']['arrayValue']['values'] as List<dynamic>;
      for (var v in list) {
        final f = v['mapValue']?['fields'] as Map<String, dynamic>? ?? {};
        vars.add(ProductVariant(
          variantId: f['variantId']?['stringValue'] ?? '',
          name: f['name']?['stringValue'] ?? '',
          price: (f['price']?['doubleValue'] ?? f['price']?['integerValue'] ?? 0).toDouble(),
          stock: int.tryParse(f['stock']?['integerValue']?.toString() ?? '0') ?? 0,
          sku: f['sku']?['stringValue'] ?? '',
          imageUrl: f['imageUrl']?['stringValue'] ?? '',
        ));
      }
    }

    return ProductItem(
      id: autoId,
      title: fields['title']?['stringValue'] ?? '',
      description: fields['description']?['stringValue'] ?? '',
      sku: fields['sku']?['stringValue'] ?? '',
      barcode: fields['barcode']?['stringValue'] ?? '',
      categoryId: fields['categoryId']?['stringValue'] ?? '',
      categoryName: fields['categoryName']?['stringValue'] ?? 'General',
      subcategoryId: fields['subcategoryId']?['stringValue'] ?? '',
      subcategoryName: fields['subcategoryName']?['stringValue'] ?? '',
      discountId: fields['discountId']?['stringValue'],
      discountCode: fields['discountCode']?['stringValue'],
      price: (fields['price']?['doubleValue'] ?? fields['price']?['integerValue'] ?? 0).toDouble(),
      regularPrice: (fields['regularPrice']?['doubleValue'] ?? fields['regularPrice']?['integerValue'] ?? 0).toDouble(),
      costPerItem: (fields['costPerItem']?['doubleValue'] ?? fields['costPerItem']?['integerValue'] ?? 0).toDouble(),
      stock: int.tryParse(fields['stock']?['integerValue']?.toString() ?? '0') ?? 0,
      lowStockThreshold: int.tryParse(fields['lowStockThreshold']?['integerValue']?.toString() ?? '5') ?? 5,
      brand: fields['brand']?['stringValue'] ?? 'NeuroFit',
      vendor: fields['vendor']?['stringValue'] ?? 'Official Store',
      status: fields['status']?['stringValue'] ?? 'active',
      isActive: (fields['status']?['stringValue'] ?? 'active') == 'active',
      mainImageUrl: fields['mainImageUrl']?['stringValue'] ?? '',
      variants: vars,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'sku': sku,
    'barcode': barcode,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'subcategoryId': subcategoryId,
    'subcategoryName': subcategoryName,
    'discountId': discountId,
    'discountCode': discountCode,
    'price': price,
    'regularPrice': regularPrice,
    'costPerItem': costPerItem,
    'stock': stock,
    'lowStockThreshold': lowStockThreshold,
    'brand': brand,
    'vendor': vendor,
    'tags': tags,
    'status': status,
    'mainImageUrl': mainImageUrl,
    'additionalImages': additionalImages,
    'variants': variants.map((v) => v.toJson()).toList(),
    'isFeatured': isFeatured,
    'rating': rating,
    'reviewCount': reviewCount,
    'weightGrams': weightGrams,
    'dimensions': dimensions,
  };
}

class ProductsBackendService extends ChangeNotifier {
  static final ProductsBackendService _instance = ProductsBackendService._internal();
  factory ProductsBackendService() => _instance;

  ProductsBackendService._internal() {
    fetchProductsFromFirestore();
  }

  static const String projectId = "neurofit-52fe0";
  static const String apiKey = "AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg";
  static const String firestoreBase = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents";

  final List<ProductItem> _products = [];
  List<ProductItem> get products => List.unmodifiable(_products);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchProductsFromFirestore() async {
    _isLoading = true;
    notifyListeners();

    // 1. Fetch from MongoDB Atlas Backend
    final backendUrls = [
      'http://10.60.114.191:5000/api/products',
      'http://localhost:5000/api/products',
      'http://10.0.2.2:5000/api/products',
    ];

    for (final url in backendUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final items = data['data'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            _products.clear();
            for (var item in items) {
              _products.add(ProductItem.fromMongoJson(item));
            }
            _isLoading = false;
            notifyListeners();
            debugPrint('✅ [PRODUCTS LOADED FROM MONGODB ATLAS] ${_products.length} live products');
            return;
          }
        }
      } catch (_) {}
    }

    // 2. Fallback to Firestore
    try {
      final Uri uri = Uri.parse('$firestoreBase/products?key=$apiKey');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>?;
        if (documents != null) {
          final List<ProductItem> fetched = [];
          for (var doc in documents) {
            fetched.add(ProductItem.fromFirestoreDoc(doc));
          }
          fetched.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _products.clear();
          _products.addAll(fetched);
          debugPrint('✅ [PRODUCTS LOADED FROM FIRESTORE] ${_products.length} live products');
        }
      }
    } catch (e) {
      debugPrint('Fetch products error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(ProductItem product, {Uint8List? rawImageBytes, String? imageFileName}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String mainUrl = product.mainImageUrl;
      if (rawImageBytes != null && imageFileName != null) {
        final uploadedUrl = await CategoryBackendService().uploadRawImageToR2(
          imageBytes: rawImageBytes,
          fileName: imageFileName,
        );
        if (uploadedUrl != null) {
          mainUrl = uploadedUrl;
          product.mainImageUrl = uploadedUrl;
        }
      }

      // 1. Sync to MongoDB Atlas Backend
      final backendUrls = [
        'http://10.60.114.191:5000/api/products',
        'http://localhost:5000/api/products',
        'http://10.0.2.2:5000/api/products',
      ];

      for (final url in backendUrls) {
        try {
          final res = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(product.toJson()),
          ).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200 || res.statusCode == 201) {
            debugPrint('✅ [PRODUCT SAVED TO MONGODB ATLAS] ${product.title}');
            await fetchProductsFromFirestore();
            return true;
          }
        } catch (_) {}
      }

      // 2. Fallback to Firestore
      final fields = {
        'title': {'stringValue': product.title},
        'description': {'stringValue': product.description},
        'sku': {'stringValue': product.sku},
        'barcode': {'stringValue': product.barcode},
        'categoryId': {'stringValue': product.categoryId},
        'categoryName': {'stringValue': product.categoryName},
        'subcategoryId': {'stringValue': product.subcategoryId},
        'subcategoryName': {'stringValue': product.subcategoryName},
        'discountId': {'stringValue': product.discountId ?? ''},
        'discountCode': {'stringValue': product.discountCode ?? ''},
        'price': {'doubleValue': product.price},
        'regularPrice': {'doubleValue': product.regularPrice},
        'costPerItem': {'doubleValue': product.costPerItem},
        'stock': {'integerValue': product.stock.toString()},
        'lowStockThreshold': {'integerValue': product.lowStockThreshold.toString()},
        'brand': {'stringValue': product.brand},
        'vendor': {'stringValue': product.vendor},
        'tags': {'arrayValue': {'values': product.tags.map((t) => {'stringValue': t}).toList()}},
        'status': {'stringValue': product.status},
        'mainImageUrl': {'stringValue': mainUrl},
        'additionalImages': {'arrayValue': {'values': product.additionalImages.map((img) => {'stringValue': img}).toList()}},
        'variants': {
          'arrayValue': {
            'values': product.variants.map((v) => {
                  'mapValue': {
                    'fields': {
                      'variantId': {'stringValue': v.variantId},
                      'name': {'stringValue': v.name},
                      'price': {'doubleValue': v.price},
                      'stock': {'integerValue': v.stock.toString()},
                      'sku': {'stringValue': v.sku},
                      'imageUrl': {'stringValue': v.imageUrl},
                    }
                  }
                }).toList()
          }
        },
        'isFeatured': {'booleanValue': product.isFeatured},
        'rating': {'doubleValue': product.rating},
        'reviewCount': {'integerValue': product.reviewCount.toString()},
        'weightGrams': {'doubleValue': product.weightGrams},
        'dimensions': {'stringValue': product.dimensions},
      };

      final Uri uri = Uri.parse('$firestoreBase/products/${product.id}?key=$apiKey');
      final res = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': fields}),
      );

      if (res.statusCode == 200) {
        await fetchProductsFromFirestore();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct({
    ProductItem? product,
    String? title,
    String? brand,
    String? description,
    String? categoryId,
    String? categoryName,
    String? subCategoryId,
    String? subCategoryName,
    String? discountId,
    String? discountCode,
    double? price,
    double? regularPrice,
    int? totalStock,
    dynamic lowStockAlert,
    dynamic stockStatus,
    String? sku,
    String? mainImageFileName,
    Uint8List? mainImageBytes,
    List<dynamic>? galleryRawList,
    List<ProductVariant>? variants,
  }) async {
    if (product != null) {
      return addProduct(product);
    }

    final newId = 'prod_${DateTime.now().millisecondsSinceEpoch}';
    final p = ProductItem(
      id: newId,
      productId: newId,
      title: title ?? 'New Product',
      brand: brand ?? 'NeuroFit',
      description: description ?? '',
      categoryId: categoryId ?? '',
      categoryName: categoryName ?? 'General',
      subcategoryId: subCategoryId ?? '',
      subcategoryName: subCategoryName ?? '',
      discountId: discountId ?? '',
      discountCode: discountCode ?? '',
      price: price ?? 0.0,
      regularPrice: regularPrice ?? 0.0,
      stock: totalStock ?? 0,
      lowStockThreshold: (lowStockAlert is int) ? lowStockAlert : 5,
      sku: sku ?? 'NF-SKU-000',
      variants: variants ?? [],
    );

    return addProduct(p, rawImageBytes: mainImageBytes, imageFileName: mainImageFileName);
  }

  Future<bool> updateProduct(ProductItem product, {Uint8List? rawImageBytes, String? imageFileName}) {
    return addProduct(product, rawImageBytes: rawImageBytes, imageFileName: imageFileName);
  }

  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Delete from MongoDB Atlas Backend
      final backendUrls = [
        'http://10.60.114.191:5000/api/products/$productId',
        'http://localhost:5000/api/products/$productId',
        'http://10.0.2.2:5000/api/products/$productId',
      ];

      for (final url in backendUrls) {
        try {
          final res = await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200 || res.statusCode == 204) {
            debugPrint('✅ [PRODUCT DELETED FROM MONGODB ATLAS] $productId');
            _products.removeWhere((p) => p.id == productId);
            notifyListeners();
            return true;
          }
        } catch (_) {}
      }

      // 2. Fallback to Firestore
      final Uri uri = Uri.parse('$firestoreBase/products/$productId?key=$apiKey');
      final res = await http.delete(uri);
      if (res.statusCode == 200) {
        _products.removeWhere((p) => p.id == productId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
