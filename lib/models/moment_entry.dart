class MomentEntry {
  final String? id;
  final String? userId;
  final String title;
  final String content;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime createdAt;
  final DateTime updatedAt;

  MomentEntry({
    this.id,
    this.userId,
    required this.title,
    required this.content,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON으로부터 MomentEntry 객체 생성
  factory MomentEntry.fromJson(Map<String, dynamic> json) {
    return MomentEntry(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      content: json['content'],
      imagePath: json['image_path'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationName: json['location_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // MomentEntry를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // INSERT용 JSON (id, created_at 제외)
  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'content': content,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // copyWith 메서드 (불변 객체 업데이트용)
  MomentEntry copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MomentEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 