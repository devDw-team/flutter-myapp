class UsefulLink {
  final String? id;
  final String? userId;
  final String title;
  final String? description;
  final String url;
  final String category;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  UsefulLink({
    this.id,
    this.userId,
    required this.title,
    this.description,
    required this.url,
    this.category = 'general',
    this.tags = const [],
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON으로부터 UsefulLink 객체 생성
  factory UsefulLink.fromJson(Map<String, dynamic> json) {
    return UsefulLink(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      category: json['category'] ?? 'general',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isFavorite: json['is_favorite'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // UsefulLink를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'url': url,
      'category': category,
      'tags': tags,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // INSERT용 JSON (id, created_at 제외)
  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'category': category,
      'tags': tags,
      'is_favorite': isFavorite,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // copyWith 메서드 (불변 객체 업데이트용)
  UsefulLink copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? url,
    String? category,
    List<String>? tags,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UsefulLink(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}