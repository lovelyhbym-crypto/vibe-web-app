// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: json['id'] as String,
      hasFreePass: json['hasFreePass'] as bool? ?? true,
      failedCount: (json['failed_count'] as num?)?.toInt() ?? 0,
      nickname: json['nickname'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hasFreePass': instance.hasFreePass,
      'failed_count': instance.failedCount,
      'nickname': instance.nickname,
      'created_at': instance.createdAt?.toIso8601String(),
    };
