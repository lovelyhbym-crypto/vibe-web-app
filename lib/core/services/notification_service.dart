import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 시스템 초기화
  Future<void> init() async {
    try {
      debugPrint('🔔 [NOTIFICATION] 서비스 초기화 시작...');
      tz_data.initializeTimeZones();

      // 기기의 현재 타임존 가져오기 및 설정
      try {
        final timeZoneName = await FlutterTimezone.getLocalTimezone();
        // 타임존 이름이 객체인 경우와 문자열인 경우 모두 대응
        final String tzName = timeZoneName.toString();

        if (tzName.isEmpty) throw Exception('Empty timezone name');

        tz.setLocalLocation(tz.getLocation(tzName));
        debugPrint(
          '🔔 [NOTIFICATION] 타임존 설정 완료: $tzName (현재 시간: ${tz.TZDateTime.now(tz.local)})',
        );
      } catch (e) {
        debugPrint('⚠️ [NOTIFICATION] 타임존 설정 실패 ($e), 기본값(Asia/Seoul)으로 설정');
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
        } catch (_) {
          // 최후의 수단: UTC
          tz.setLocalLocation(tz.UTC);
        }
      }

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS/macOS 초기화 설정
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false, // 앱 시작 시 자동으로 묻지 않고 우리가 원할 때 묻기 위함
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings, // iOS 설정 주입
      );

      final bool? initialized = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('🔔 [NOTIFICATION] 알림 클릭됨: ${details.payload}');
        },
      );
      debugPrint('🔔 [NOTIFICATION] 플러그인 초기화 결과: $initialized');

      // 권한 요청 (알림 및 정확한 알람)
      await requestPermissions();

      debugPrint('🔔 [NOTIFICATION] 서비스 초기화 기본 완료');
    } catch (e, stack) {
      debugPrint('❌ [NOTIFICATION] 초기화 최종 실패: $e');
      debugPrint('❌ [NOTIFICATION] 스택트레이스: $stack');
    }
  }

  // 권한 요청 메서드 개선 (Android + iOS)
  Future<void> requestPermissions() async {
    // Android 권한 요청
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      // 1. 일반 알림 권한 요청 (Android 13+)
      final bool? granted = await androidImplementation
          .requestNotificationsPermission();
      debugPrint('🔔 [NOTIFICATION] 알림 권한 상태: $granted');

      // 2. 정확한 알람 권한 요청 (Android 12+)
      try {
        final bool? canScheduleExact = await androidImplementation
            .requestExactAlarmsPermission();
        debugPrint('🔔 [NOTIFICATION] 정확한 알람 권한 요청 결과: $canScheduleExact');

        if (canScheduleExact == false) {
          debugPrint('⚠️ [NOTIFICATION] 정확한 알람 권한이 거부되었습니다.');
          debugPrint(
            '⚠️ [NOTIFICATION] 설정 > 앱 > NERVE > 알람 및 리마인더에서 권한을 허용해주세요.',
          );
        }
      } catch (e) {
        debugPrint('⚠️ [NOTIFICATION] 정확한 알람 권한 요청 실패: $e');
        debugPrint(
          '💡 [NOTIFICATION] 설정 > 앱 > NERVE > 알람 및 리마인더에서 수동으로 권한을 허용해주세요.',
        );
      }
    }

    // iOS 권한 요청
    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🔔 [NOTIFICATION] iOS 알림 권한 상태: $granted');
    }
  }

  // 즉시 알림 발송
  Future<void> showImmediateRoast({
    required int id,
    required String title,
    required String body,
  }) async {
    debugPrint('🔔 [NOTIFICATION] 즉시 알림 발송 시도 (ID: $id)');

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'nerve_high_priority',
        'NERVE 알림',
        channelDescription: 'NERVE의 중요한 충동 제어 알림 채널입니다.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        fullScreenIntent: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(id, title, body, notificationDetails);
    debugPrint('🔔 [NOTIFICATION] 즉시 알림 발송 성공 (ID: $id)');
  }

  // 잠시 후 알림 발송
  Future<void> scheduleOneshotRoast({
    required int id,
    required int seconds,
    required String title,
    required String body,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(Duration(seconds: seconds));
      debugPrint(
        '🔔 [NOTIFICATION] $seconds초 뒤 알림 예약 시도 (ID: $id): $scheduledDate',
      );

      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'nerve_scheduled',
          'NERVE 예약 알림',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // 정확한 알람 권한 여부에 상관없이 일단 시도하고, 실패 시 폴백
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('🔔 [NOTIFICATION] $seconds초 뒤 알림 예약 성공 (ID: $id)');
    } catch (e) {
      if (e is PlatformException && e.code == 'exact_alarms_not_permitted') {
        debugPrint('⚠️ [NOTIFICATION] 정확한 알람 권한 없음. 인이그젝트(Inexact) 폴백 예약 시도.');
        final scheduledDate = tz.TZDateTime.now(
          tz.local,
        ).add(Duration(seconds: seconds));
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'nerve_scheduled_fallback',
              'NERVE 예약 알림 (폴백)',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        debugPrint('❌ [NOTIFICATION] 원샷 알림 예약 실패 (ID: $id): $e');
      }
    }
  }

  // 매일 정해진 시간 독설 발송
  Future<void> scheduleDailyRoast({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      final scheduleDate = _convertTime(hour, minute);
      debugPrint('🔔 [NOTIFICATION] 데일리 알림 예약 시도 (ID: $id): $scheduleDate');

      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'nerve_daily',
          'NERVE 정기 알림',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduleDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('🔔 [NOTIFICATION] 데일리 알림 예약 성공 (ID: $id)');
    } catch (e) {
      if (e is PlatformException && e.code == 'exact_alarms_not_permitted') {
        debugPrint('⚠️ [NOTIFICATION] 정확한 알람 권한 없음. 데일리 인이그젝트 폴백 예약 시도.');
        final scheduleDate = _convertTime(hour, minute);
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduleDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'nerve_daily_fallback',
              'NERVE 정기 알림 (폴백)',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        debugPrint('❌ [NOTIFICATION] 데일리 알림 예약 실패 (ID: $id): $e');
      }
    }
  }

  // 매분 반복 알림 (테스트용)
  Future<void> scheduleMinuteRoast({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      debugPrint('🔔 [NOTIFICATION] 매분 반복 알림 예약 시도 (ID: $id)');

      await _notifications.periodicallyShow(
        id,
        title,
        body,
        RepeatInterval.everyMinute,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'nerve_repeat',
            'NERVE 반복 테스트',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('🔔 [NOTIFICATION] 매분 반복 알림 예약 성공 (ID: $id)');
    } catch (e) {
      if (e is PlatformException && e.code == 'exact_alarms_not_permitted') {
        debugPrint('⚠️ [NOTIFICATION] 정확한 알람 권한 없음. 매분 인이그젝트 폴백 예약 시도.');
        await _notifications.periodicallyShow(
          id,
          title,
          body,
          RepeatInterval.everyMinute,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'nerve_repeat_fallback',
              'NERVE 반복 테스트 (폴백)',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        debugPrint('❌ [NOTIFICATION] 매분 반복 알림 예약 최종 실패 (ID: $id): $e');
      }
    }
  }

  tz.TZDateTime _convertTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
