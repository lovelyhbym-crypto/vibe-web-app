class WishlistModel {
  final String? id;
  final String title;
  final double price;
  final double totalGoal;
  final double savedAmount;
  final String? imageUrl;
  final bool isAchieved;
  final DateTime? achievedAt;
  final DateTime createdAt;

  WishlistModel({
    this.id,
    required this.title,
    required this.price,
    required this.totalGoal,
    this.savedAmount = 0,
    this.imageUrl,
    this.isAchieved = false,
    this.achievedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'price': price.toInt(),
      'total_goal': totalGoal.toInt(),
      'saved_amount': savedAmount.toInt(),
      'image_url': imageUrl,
      'is_achieved': isAchieved,
      'created_at': createdAt.toIso8601String(),
    };

    // Only include achieved_at if it exists and is not null
    if (achievedAt != null) {
      data['achieved_at'] = achievedAt!.toIso8601String();
    }

    // Include ID if it exists (though usually not for insert)
    if (id != null) {
      data['id'] = id;
    }

    return data;
  }

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      id: json['id']
          ?.toString(), // Do not generate UUID here, let it be null if missing to detect errors
      title: json['title'] as String,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      totalGoal: double.tryParse(json['total_goal']?.toString() ?? '0') ?? 0.0,
      savedAmount:
          double.tryParse(json['saved_amount']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url'] as String?,
      isAchieved: json['is_achieved'] as bool? ?? false,
      achievedAt: json['achieved_at'] != null
          ? DateTime.parse(json['achieved_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  WishlistModel copyWith({
    String? id,
    String? title,
    double? price,
    double? totalGoal,
    double? savedAmount,
    String? imageUrl,
    bool? isAchieved,
    DateTime? achievedAt,
    DateTime? createdAt,
  }) {
    return WishlistModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      totalGoal: totalGoal ?? this.totalGoal,
      savedAmount: savedAmount ?? this.savedAmount,
      imageUrl: imageUrl ?? this.imageUrl,
      isAchieved: isAchieved ?? this.isAchieved,
      achievedAt: achievedAt ?? this.achievedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
