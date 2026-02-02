import 'package:flutter/foundation.dart';

class SavingModel {
  final String id;
  final String category;
  final int amount;
  final DateTime createdAt;
  final String? note; // Added for Victory Logging and general notes

  final List<String> wishlistIds;

  SavingModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.createdAt,
    this.note,
    this.wishlistIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'note': note,
      'wishlist_ids': wishlistIds,
    };
  }

  factory SavingModel.fromJson(Map<String, dynamic> json) {
    // 1. Strict ID parsing to String (default to '')
    final String parsedId = (json['id'] ?? json['ID'] ?? json['uuid'] ?? '')
        .toString();

    // 2. Critical Log
    if (parsedId.isEmpty || parsedId == 'null') {
      debugPrint('CRITICAL: Map keys are: ${json.keys}');
    }

    return SavingModel(
      id: parsedId == 'null'
          ? ''
          : parsedId, // Handle literal 'null' string case if toString() did it
      category: json['category'] as String,
      amount: int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      note: json['note'] as String?,
      wishlistIds:
          (json['wishlist_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
