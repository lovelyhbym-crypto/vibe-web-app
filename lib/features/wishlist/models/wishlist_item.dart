class WishlistItem {
  final String id;
  final String title;
  final double price;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt; // Renamed from achievedAt
  final String? comment;
  final double blurLevel;
  final bool isBroken;
  final DateTime? lastSavedAt;

  WishlistItem({
    required this.id,
    required this.title,
    required this.price,
    required this.createdAt,
    required this.isCompleted,
    this.completedAt,
    this.comment,
    this.blurLevel = 0.0,
    this.isBroken = false,
    this.lastSavedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      comment: json['comment'] as String?,
      blurLevel: (json['blur_level'] as num?)?.toDouble() ?? 0.0,
      isBroken: json['is_broken'] as bool? ?? false,
      lastSavedAt: json['last_saved_at'] != null
          ? DateTime.parse(json['last_saved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'comment': comment,
      'blur_level': blurLevel,
      'is_broken': isBroken,
      'last_saved_at': lastSavedAt?.toIso8601String(),
    };
  }

  WishlistItem copyWith({
    String? id,
    String? title,
    double? price,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? completedAt,
    String? comment,
    double? blurLevel,
    bool? isBroken,
    DateTime? lastSavedAt,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      comment: comment ?? this.comment,
      blurLevel: blurLevel ?? this.blurLevel,
      isBroken: isBroken ?? this.isBroken,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  /// 나태의 안개 농도 계산
  /// lastSavedAt으로부터 현재까지 경과된 날(days) 1일당 +2.0 (최대 10.0)
  double calculateCurrentBlur() {
    if (lastSavedAt == null) return 0.0;

    final now = DateTime.now();
    final difference = now.difference(lastSavedAt!);
    final days = difference.inDays;

    double calculatedBlur = days * 2.0;
    return calculatedBlur.clamp(0.0, 10.0);
  }
}
