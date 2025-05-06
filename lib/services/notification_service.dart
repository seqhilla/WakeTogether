import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String? selectedPayload;
  static Function(String?)? onNotificationTap;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    // Bildirime tıklandığında tetiklenecek
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        selectedPayload = response.payload;
        if (onNotificationTap != null) {
          onNotificationTap!(response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Uygulama kapalıyken tıklanan bildirimi kontrol et
    final NotificationAppLaunchDetails? launchDetails =
    await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      selectedPayload = launchDetails.notificationResponse?.payload;
      if (onNotificationTap != null) {
        onNotificationTap!(launchDetails.notificationResponse?.payload);
      }
    }

    _initialized = true;
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Bildirimleri',
      channelDescription: 'Alarm durumu değişiklikleri için bildirimler',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      fullScreenIntent: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static String? checkAndClearPayload() {
    final payload = selectedPayload;
    selectedPayload = null;
    return payload;
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Arka planda bildirime tıklandığında çalışacak
  NotificationService.selectedPayload = response.payload;
}