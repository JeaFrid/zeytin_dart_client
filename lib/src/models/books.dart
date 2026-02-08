import 'package:zeytin/src/models/user.dart';
import 'package:zeytin/src/utils/date_extensions.dart';


class ZeytinChapterModel {
  final String id;
  final String bookId;
  final String title;
  final String? description;
  final String content;
  final int order;
  final DateTime? publishedDate;
  final Map<String, dynamic>? moreData;

  ZeytinChapterModel({
    required this.id,
    required this.bookId,
    required this.title,
    this.description,
    required this.content,
    required this.order,
    this.publishedDate,
    this.moreData,
  });

  factory ZeytinChapterModel.empty() {
    return ZeytinChapterModel(
      id: '',
      bookId: '',
      title: '',
      content: '',
      order: 0,
      publishedDate: null,
      moreData: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "bookId": bookId,
      "title": title,
      "description": description,
      "content": content,
      "order": order,
      "publishedDate": publishedDate?.toIso8601String(),
      "moreData": moreData ?? {},
    };
  }

  factory ZeytinChapterModel.fromJson(Map<String, dynamic> data) {
    return ZeytinChapterModel(
      id: data["id"] ?? "",
      bookId: data["bookId"] ?? "",
      title: data["title"] ?? "",
      description: data["description"],
      content: data["content"] ?? "",
      order: data["order"] ?? 0,
      publishedDate: data["publishedDate"] != null
          ? DateTime.tryParse(data["publishedDate"])
          : null,
      moreData: data["moreData"] is Map
          ? Map<String, dynamic>.from(data["moreData"])
          : {},
    );
  }

  ZeytinChapterModel copyWith({
    String? id,
    String? bookId,
    String? title,
    String? description,
    String? content,
    int? order,
    DateTime? publishedDate,
    Map<String, dynamic>? moreData,
  }) {
    return ZeytinChapterModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      order: order ?? this.order,
      publishedDate: publishedDate ?? this.publishedDate,
      moreData: moreData ?? this.moreData,
    );
  }
}

class ZeytinBookModel {
  final String id;
  final String isbn;
  final String title;
  final String? subtitle;
  final List<ZeytinUserModel> authors;
  final List<String> likes;
  final String publisher;
  final String? picture;
  final String? description;
  final List<String> categories;
  final int pageCount;
  final double price;
  final String currency;
  final int stockCount;
  final double averageRating;
  final DateTime? publishedDate;
  final Map<String, dynamic>? moreData;

  ZeytinBookModel({
    required this.id,
    required this.isbn,
    required this.title,
    this.subtitle,
    required this.authors,
    required this.publisher,
    this.picture,
    this.description,
    this.categories = const [],
    this.pageCount = 0,
    this.price = 0.0,
    this.currency = 'USD',
    this.stockCount = 0,
    this.averageRating = 0.0,
    this.publishedDate,
    this.moreData,
    required this.likes,
  });

  factory ZeytinBookModel.empty() {
    return ZeytinBookModel(
      id: '',
      isbn: '',
      title: '',
      authors: [],
      likes: [],
      publisher: '',
    );
  }
  String? get formattedTime => publishedDate?.timeAgo;
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "isbn": isbn,
      "title": title,
      "subtitle": subtitle,
      "authors": authors.map((e) => e.toJson()).toList(),
      "publisher": publisher,
      "picture": picture,
      "description": description,
      "categories": categories,
      "likes": likes,
      "pageCount": pageCount,
      "price": price,
      "currency": currency,
      "stockCount": stockCount,
      "averageRating": averageRating,
      "publishedDate": publishedDate?.toIso8601String(),
      "moreData": moreData ?? {},
    };
  }

  factory ZeytinBookModel.fromJson(Map<String, dynamic> data) {
    return ZeytinBookModel(
      id: data["id"] ?? "",
      isbn: data["isbn"] ?? "",
      title: data["title"] ?? "",
      subtitle: data["subtitle"],
      authors: data["authors"] != null
          ? (data["authors"] as List)
                .map((e) => ZeytinUserModel.fromJson(e))
                .toList()
          : [],
      publisher: data["publisher"] ?? "",
      picture: data["picture"],
      description: data["description"],
      categories: List<String>.from(data["categories"] ?? []),
      likes: List<String>.from(data["likes"] ?? []),
      pageCount: data["pageCount"] ?? 0,
      price: (data["price"] ?? 0.0).toDouble(),
      currency: data["currency"] ?? "USD",
      stockCount: data["stockCount"] ?? 0,
      averageRating: (data["averageRating"] ?? 0.0).toDouble(),
      publishedDate: data["publishedDate"] != null
          ? DateTime.tryParse(data["publishedDate"])
          : null,
      moreData: data["moreData"] is Map
          ? Map<String, dynamic>.from(data["moreData"])
          : {},
    );
  }

  ZeytinBookModel copyWith({
    String? id,
    String? isbn,
    String? title,
    String? subtitle,
    List<ZeytinUserModel>? authors,
    List<String>? likes,
    String? publisher,
    String? picture,
    String? description,
    List<String>? categories,
    int? pageCount,
    double? price,
    String? currency,
    int? stockCount,
    double? averageRating,
    DateTime? publishedDate,
    Map<String, dynamic>? moreData,
  }) {
    return ZeytinBookModel(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      likes: likes ?? this.likes,
      authors: authors ?? this.authors,
      publisher: publisher ?? this.publisher,
      picture: picture ?? this.picture,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      pageCount: pageCount ?? this.pageCount,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      stockCount: stockCount ?? this.stockCount,
      averageRating: averageRating ?? this.averageRating,
      publishedDate: publishedDate ?? this.publishedDate,
      moreData: moreData ?? this.moreData,
    );
  }
}

class ZeytinBookCommentModel {
  final ZeytinUserModel? user;
  final String? text;
  final String? id;
  final String? bookID;
  final List<String>? likes;
  final Map<String, dynamic>? moreData;
  ZeytinBookCommentModel({
    this.user,
    this.text,
    this.likes,
    this.bookID,
    this.id,
    this.moreData,
  });

  Map<String, dynamic> toJson() {
    return {
      "user": user?.toJson() ?? {},
      "text": text ?? "",
      "id": id ?? "",
      "likes": likes ?? [],
      "bookID": bookID ?? "",
      "moreData": moreData ?? {},
    };
  }

  ZeytinBookCommentModel copyWith({
    ZeytinUserModel? user,
    String? text,
    List<String>? likes,
    String? bookID,
    String? id,
    Map<String, dynamic>? moreData,
  }) {
    return ZeytinBookCommentModel(
      user: user ?? this.user,
      text: text ?? this.text,
      likes: likes ?? this.likes,
      bookID: bookID ?? this.bookID,
      id: id ?? this.id,
      moreData: moreData ?? this.moreData,
    );
  }

  factory ZeytinBookCommentModel.fromJson(Map<String, dynamic> data) {
    return ZeytinBookCommentModel(
      user: data["user"] != null
          ? ZeytinUserModel.fromJson(data["user"])
          : null,
      text: data["text"],
      likes: (data["likes"] as List?)?.cast<String>() ?? [],
      bookID: data["bookID"] ?? "",
      id: data["id"],
      moreData: data["moreData"] ?? {},
    );
  }
}
