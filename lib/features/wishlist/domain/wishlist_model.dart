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
  final String? comment;

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
    this.comment,
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
      'comment': comment,
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
      comment: json['comment'] as String?,
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
    String? comment,
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
      comment: comment ?? this.comment,
    );
  }

  Map<String, int> calculateResistedCounts(List<dynamic> savings) {
    if (savings.isEmpty) return {};

    final start = createdAt;
    final end = achievedAt ?? DateTime.now();

    // Filter savings within the goal period
    final relevantSavings = savings.where((s) {
      // Handle both SavingModel and dynamic types safely if needed,
      // but assuming SavingModel or similar structure with createdAt property
      // We will access fields dynamically to avoid import cycles if SavingModel is in another package
      // but ideally this should import SavingModel if architecture permits.
      // For now, let's assume 's' has 'createdAt' and 'category'.
      final sCreatedAt = (s is Map)
          ? DateTime.parse(s['created_at'])
          : (s as dynamic).createdAt as DateTime;

      return sCreatedAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          sCreatedAt.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    final stats = <String, int>{};
    for (final s in relevantSavings) {
      final category = (s is Map)
          ? s['category'] as String
          : (s as dynamic).category as String;
      stats.update(category, (value) => value + 1, ifAbsent: () => 1);
    }
    return stats;
  }
}
