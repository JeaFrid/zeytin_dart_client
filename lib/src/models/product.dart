import 'package:zeytin/src/models/user.dart';

class ZeytinProductCommentModel {
  final String id;
  final String productId;
  final ZeytinUserModel? user;
  final String text;
  final double rating;
  final List<String> images;
  final List<String> likes;
  final DateTime? createdAt;
  final Map<String, dynamic> moreData;

  ZeytinProductCommentModel({
    required this.id,
    required this.productId,
    this.user,
    required this.text,
    this.rating = 0.0,
    this.images = const [],
    this.likes = const [],
    this.createdAt,
    this.moreData = const {},
  });

  factory ZeytinProductCommentModel.empty() {
    return ZeytinProductCommentModel(id: '', productId: '', text: '');
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "productId": productId,
      "user": user?.toJson() ?? {},
      "text": text,
      "rating": rating,
      "images": images,
      "likes": likes,
      "createdAt": createdAt?.toIso8601String(),
      "moreData": moreData,
    };
  }

  factory ZeytinProductCommentModel.fromJson(Map<String, dynamic> data) {
    return ZeytinProductCommentModel(
      id: data["id"] ?? "",
      productId: data["productId"] ?? "",
      user: data["user"] != null
          ? ZeytinUserModel.fromJson(data["user"])
          : null,
      text: data["text"] ?? "",
      rating: (data["rating"] ?? 0.0).toDouble(),
      images: List<String>.from(data["images"] ?? []),
      likes: List<String>.from(data["likes"] ?? []),
      createdAt: data["createdAt"] != null
          ? DateTime.tryParse(data["createdAt"])
          : null,
      moreData: data["moreData"] is Map
          ? Map<String, dynamic>.from(data["moreData"])
          : {},
    );
  }

  ZeytinProductCommentModel copyWith({
    String? id,
    String? productId,
    ZeytinUserModel? user,
    String? text,
    double? rating,
    List<String>? images,
    List<String>? likes,
    DateTime? createdAt,
    Map<String, dynamic>? moreData,
  }) {
    return ZeytinProductCommentModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      user: user ?? this.user,
      text: text ?? this.text,
      rating: rating ?? this.rating,
      images: images ?? this.images,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      moreData: moreData ?? this.moreData,
    );
  }
}

class ZeytinProductModel {
  final String id;
  final String storeId;
  final String title;
  final String description;
  final String category;
  final String brand;
  final List<String> images;
  final String? thumbnail;
  final double price;
  final double discountedPrice;
  final String currency;
  final int stock;
  final String sku;
  final int viewCount;
  final double averageRating;
  final List<String> likes;
  final List<ZeytinProductCommentModel> comments;
  final bool isActive;
  final List<String> tags;
  final DateTime? createdAt;
  final Map<String, dynamic> moreData;

  ZeytinProductModel({
    required this.id,
    required this.storeId,
    required this.title,
    this.description = '',
    this.category = '',
    this.brand = '',
    this.images = const [],
    this.thumbnail,
    this.price = 0.0,
    this.discountedPrice = 0.0,
    this.currency = 'USD',
    this.stock = 0,
    this.sku = '',
    this.viewCount = 0,
    this.averageRating = 0.0,
    this.likes = const [],
    this.comments = const [],
    this.isActive = true,
    this.tags = const [],
    this.createdAt,
    this.moreData = const {},
  });

  factory ZeytinProductModel.empty() {
    return ZeytinProductModel(id: '', storeId: '', title: '');
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "storeId": storeId,
      "title": title,
      "description": description,
      "category": category,
      "brand": brand,
      "images": images,
      "thumbnail": thumbnail,
      "price": price,
      "discountedPrice": discountedPrice,
      "currency": currency,
      "stock": stock,
      "sku": sku,
      "viewCount": viewCount,
      "averageRating": averageRating,
      "likes": likes,
      "comments": comments.map((e) => e.toJson()).toList(),
      "isActive": isActive,
      "tags": tags,
      "createdAt": createdAt?.toIso8601String(),
      "moreData": moreData,
    };
  }

  factory ZeytinProductModel.fromJson(Map<String, dynamic> data) {
    return ZeytinProductModel(
      id: data["id"] ?? "",
      storeId: data["storeId"] ?? "",
      title: data["title"] ?? "",
      description: data["description"] ?? "",
      category: data["category"] ?? "",
      brand: data["brand"] ?? "",
      images: List<String>.from(data["images"] ?? []),
      thumbnail: data["thumbnail"],
      price: (data["price"] ?? 0.0).toDouble(),
      discountedPrice: (data["discountedPrice"] ?? 0.0).toDouble(),
      currency: data["currency"] ?? "USD",
      stock: data["stock"] ?? 0,
      sku: data["sku"] ?? "",
      viewCount: data["viewCount"] ?? 0,
      averageRating: (data["averageRating"] ?? 0.0).toDouble(),
      likes: List<String>.from(data["likes"] ?? []),
      comments: data["comments"] != null
          ? (data["comments"] as List)
                .map((e) => ZeytinProductCommentModel.fromJson(e))
                .toList()
          : [],
      isActive: data["isActive"] ?? true,
      tags: List<String>.from(data["tags"] ?? []),
      createdAt: data["createdAt"] != null
          ? DateTime.tryParse(data["createdAt"])
          : null,
      moreData: data["moreData"] is Map
          ? Map<String, dynamic>.from(data["moreData"])
          : {},
    );
  }

  ZeytinProductModel copyWith({
    String? id,
    String? storeId,
    String? title,
    String? description,
    String? category,
    String? brand,
    List<String>? images,
    String? thumbnail,
    double? price,
    double? discountedPrice,
    String? currency,
    int? stock,
    String? sku,
    int? viewCount,
    double? averageRating,
    List<String>? likes,
    List<ZeytinProductCommentModel>? comments,
    bool? isActive,
    List<String>? tags,
    DateTime? createdAt,
    Map<String, dynamic>? moreData,
  }) {
    return ZeytinProductModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      images: images ?? this.images,
      thumbnail: thumbnail ?? this.thumbnail,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      currency: currency ?? this.currency,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      viewCount: viewCount ?? this.viewCount,
      averageRating: averageRating ?? this.averageRating,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      moreData: moreData ?? this.moreData,
    );
  }
}
