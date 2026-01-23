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
  final DateTime? targetDate;
  final String? comment;
  final bool isRepresentative;
  final double blurLevel;
  final bool isBroken;
  final int brokenImageIndex; // Added for random broken image logic
  final DateTime? lastSavedAt;
  final DateTime? brokenAt;
  final double questSavedAmount;
  final int consecutiveValidDays;
  final DateTime? lastQuestSavingDate;
  final double penaltyAmount;
  final String? penaltyText;
  final DateTime? lastOpenedAt;
  final DateTime? lastSurvivalCheckAt;

  WishlistModel({
    this.id,
    required this.title,
    required this.price,
    required this.totalGoal,
    this.savedAmount = 0,
    this.imageUrl,
    this.isAchieved = false,
    this.achievedAt,
    this.targetDate,
    DateTime? createdAt,
    this.comment,
    this.isRepresentative = false,
    this.blurLevel = 0.0,
    this.isBroken = false,
    this.brokenImageIndex = 0, // Default 0
    this.lastSavedAt,
    this.brokenAt,
    this.questSavedAmount = 0.0,
    this.consecutiveValidDays = 0,
    this.lastQuestSavingDate,
    this.penaltyAmount = 0.0,
    this.penaltyText,
    this.lastOpenedAt,
    this.lastSurvivalCheckAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// (totalGoal - savedAmount) / (남은 일수)를 계산
  /// 남은 일수가 0 이하이거나 targetDate가 없으면 적절히 처리
  double get dailyQuota {
    if (targetDate == null || isAchieved) return 0;

    final remainingAmount = totalGoal - savedAmount;
    if (remainingAmount <= 0) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      targetDate!.year,
      targetDate!.month,
      targetDate!.day,
    );

    final daysLeft = target.difference(today).inDays;

    if (daysLeft <= 0) {
      // 이미 목표 날짜이거나 지난 경우, 남은 금액 전체가 오늘의 할당량
      return remainingAmount;
    }

    return remainingAmount / daysLeft;
  }

  // Helper to safely parse strings to DateTime?
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'price': price.toInt(),
      'total_goal': totalGoal.toInt(),
      'saved_amount': savedAmount.toInt(),
      'image_url': imageUrl,
      'is_achieved': isAchieved,
      'created_at': createdAt.toIso8601String(),
      'comment': penaltyText, // Save penaltyText to the comment column
      'is_representative': isRepresentative,
      'blur_level': blurLevel,
      'is_broken': isBroken,
      'broken_image_index': brokenImageIndex,
      'quest_saved_amount': questSavedAmount,
      'consecutive_valid_days': consecutiveValidDays,
      'penalty_amount': penaltyAmount,
      // 'penalty_text': penaltyText, // Mapped to 'comment' column
    };

    if (targetDate != null) {
      data['target_date'] = targetDate!.toIso8601String();
    }

    if (achievedAt != null) {
      data['achieved_at'] = achievedAt!.toIso8601String();
    }

    if (lastSavedAt != null) {
      data['last_saved_at'] = lastSavedAt!.toIso8601String();
    }

    if (brokenAt != null) {
      data['broken_at'] = brokenAt!.toIso8601String();
    }

    if (lastQuestSavingDate != null) {
      data['last_quest_saving_date'] = lastQuestSavingDate!.toIso8601String();
    }

    if (lastOpenedAt != null) {
      data['last_opened_at'] = lastOpenedAt!.toIso8601String();
    }

    if (lastSurvivalCheckAt != null) {
      data['last_survival_check_at'] = lastSurvivalCheckAt!.toIso8601String();
    }

    // Include ID if it exists (though usually not for insert)
    if (id != null) {
      data['id'] = id;
    }

    return data;
  }

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      id: json['id']?.toString(),
      title: json['title'] as String,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      totalGoal: double.tryParse(json['total_goal']?.toString() ?? '0') ?? 0.0,
      savedAmount:
          double.tryParse(json['saved_amount']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url'] as String?,
      isAchieved: json['is_achieved'] as bool? ?? false,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      achievedAt: json['achieved_at'] != null
          ? DateTime.parse(json['achieved_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      comment: null, // Comment is now used for penaltyText
      penaltyText: json['comment'] as String?, // Read from comment column
      isRepresentative: json['is_representative'] as bool? ?? false,
      blurLevel: (json['blur_level'] as num?)?.toDouble() ?? 0.0,
      isBroken: json['is_broken'] as bool? ?? false,
      brokenImageIndex: (json['broken_image_index'] as num?)?.toInt() ?? 0,
      lastSavedAt: json['last_saved_at'] != null
          ? DateTime.parse(json['last_saved_at'] as String)
          : null,
      brokenAt: json['broken_at'] != null
          ? DateTime.parse(json['broken_at'] as String)
          : null,
      questSavedAmount: (json['quest_saved_amount'] as num?)?.toDouble() ?? 0.0,
      consecutiveValidDays: (json['consecutive_valid_days'] as int?) ?? 0,
      lastQuestSavingDate: json['last_quest_saving_date'] != null
          ? DateTime.parse(json['last_quest_saving_date'] as String)
          : null,
      penaltyAmount: (json['penalty_amount'] as num?)?.toDouble() ?? 0.0,
      // penaltyText: json['penalty_text'] as String?, // Mapped from 'comment'
      lastOpenedAt: _parseDateTime(json['last_opened_at']),
      lastSurvivalCheckAt: _parseDateTime(json['last_survival_check_at']),
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
    DateTime? targetDate,
    DateTime? createdAt,
    String? comment,
    bool? isRepresentative,
    double? blurLevel,
    bool? isBroken,
    int? brokenImageIndex,
    DateTime? lastSavedAt,
    DateTime? brokenAt,
    double? questSavedAmount,
    int? consecutiveValidDays,
    DateTime? lastQuestSavingDate,
    double? penaltyAmount,
    String? penaltyText,
    DateTime? lastOpenedAt,
    DateTime? lastSurvivalCheckAt,
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
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      comment: comment ?? this.comment,
      isRepresentative: isRepresentative ?? this.isRepresentative,
      blurLevel: blurLevel ?? this.blurLevel,
      isBroken: isBroken ?? this.isBroken,
      brokenImageIndex: brokenImageIndex ?? this.brokenImageIndex,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      brokenAt: brokenAt ?? this.brokenAt,
      questSavedAmount: questSavedAmount ?? this.questSavedAmount,
      consecutiveValidDays: consecutiveValidDays ?? this.consecutiveValidDays,
      lastQuestSavingDate: lastQuestSavingDate ?? this.lastQuestSavingDate,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      penaltyText: penaltyText ?? this.penaltyText,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      lastSurvivalCheckAt: lastSurvivalCheckAt ?? this.lastSurvivalCheckAt,
    );
  }

  /// 나태의 안개 농도 계산 (가중 처벌 로직)
  /// 공식: (미접속 일수 * 4.0) + (접속했으나 저축 안 한 일수 * 2.0)
  /// lastSurvivalCheckAt이 오늘 날짜라면 -2.0 차감
  double calculateCurrentBlur() {
    if (lastSavedAt == null) return 0.0;

    final now = DateTime.now();

    // lastOpenedAt이 없거나, lastSavedAt보다 이르면 lastSavedAt을 기준점으로 사용
    // (저축한 이후로 앱을 한 번도 안 켰다는 의미)
    final effectiveLastOpen =
        (lastOpenedAt != null && lastOpenedAt!.isAfter(lastSavedAt!))
        ? lastOpenedAt!
        : lastSavedAt!;

    // 1. 접속했으나 저축 안 한 일수 (Save ~ Open) : 차분히 쌓이는 안개 (2.0)
    // lastSavedAt -> effectiveLastOpen 까지의 기간
    final openedDays = effectiveLastOpen.difference(lastSavedAt!).inDays;

    // 2. 미접속 일수 (Open ~ Now) : 급격히 쌓이는 안개 (4.0)
    // lastOpenedAt이 어제보다 이전이라면 '미접속 상태'로 간주 (즉, 차이가 2일 이상 등)
    // effectiveLastOpen -> now 까지의 기간
    final notOpenedDays = now.difference(effectiveLastOpen).inDays;

    double calculatedBlur = (openedDays * 2.0) + (notOpenedDays * 4.0);

    // 3. Survival Check Bonus
    // 오늘 생존 신고를 했다면 2.0 차감
    if (lastSurvivalCheckAt != null) {
      final today = DateTime(now.year, now.month, now.day);
      final checkDay = DateTime(
        lastSurvivalCheckAt!.year,
        lastSurvivalCheckAt!.month,
        lastSurvivalCheckAt!.day,
      );
      if (today.isAtSameMomentAs(checkDay)) {
        calculatedBlur -= 2.0;
      }
    }

    // 최소 0.0 ~ 최대 10.0 제한
    return calculatedBlur.clamp(0.0, 10.0);
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
