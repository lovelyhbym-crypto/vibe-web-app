class WishlistItem {
  final String id;
  final String title;
  final double price;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt; // Renamed from achievedAt
  final String? comment; // Added

  WishlistItem({
    required this.id,
    required this.title,
    required this.price,
    required this.createdAt,
    required this.isCompleted,
    this.completedAt,
    this.comment,
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
  }) {
    return WishlistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      comment: comment ?? this.comment,
    );
  }
}
