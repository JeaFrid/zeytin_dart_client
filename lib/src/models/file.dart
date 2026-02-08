enum ZeytinFileType {
  image("image"),
  video("video"),
  doc("doc"),
  url("url"),
  or("or");

  final String value;
  const ZeytinFileType(this.value);
}

class ZeytinFileModel {
  final String url;
  final ZeytinFileType type;
  final Map<String, dynamic> moreData;

  ZeytinFileModel({
    required this.url,
    required this.type,
    this.moreData = const {},
  });

  factory ZeytinFileModel.empty() {
    return ZeytinFileModel(url: '', type: ZeytinFileType.image, moreData: {});
  }

  factory ZeytinFileModel.fromJson(Map<String, dynamic> json) {
    return ZeytinFileModel(
      url: json['url']?.toString() ?? '',
      type: ZeytinFileType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => ZeytinFileType.image,
      ),
      moreData: json['moreData'] is Map
          ? Map<String, dynamic>.from(json['moreData'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'type': type.value, 'moreData': moreData};
  }

  ZeytinFileModel copyWith({
    String? url,
    ZeytinFileType? type,
    Map<String, dynamic>? moreData,
  }) {
    return ZeytinFileModel(
      url: url ?? this.url,
      type: type ?? this.type,
      moreData: moreData ?? this.moreData,
    );
  }
}
