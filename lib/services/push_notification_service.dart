import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../config/environment_config.dart';
import '../utils/brand_colors.dart';

/// Handler de mensajes en segundo plano. Debe ser función de nivel superior.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'devlokos_channel',
    'DevLokos',
    description: 'Canal de notificaciones de DevLokos',
    importance: Importance.high,
    playSound: true,
  );

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Callback para navegar cuando se toca una notificación (inyectado por la app).
  static void Function(String route)? _navigateToRoute;
  static String? _pendingRoute;

  /// Topic según entorno (all_users_prod | all_users_dev).
  static const String _topicProd = 'all_users_prod';
  static const String _topicDev = 'all_users_dev';

  /// Registra el handler de navegación. Debe llamarse cuando GoRouter esté montado.
  static void setNavigationHandler(void Function(String route) handler) {
    _navigateToRoute = handler;
    if (_pendingRoute != null) {
      handler(_pendingRoute!);
      _pendingRoute = null;
    }
  }

  /// Inicializa el servicio de push notifications.
  Future<void> initialize() async {
    if (kIsWeb) return;

    // Configurar notificaciones locales para Android (foreground)
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones en Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Solicitar permisos (iOS, Android 13+)
    await _requestPermissions();

    // Obtener token FCM
    await _getToken();

    // Suscribir al topic según entorno
    final topic = EnvironmentConfig.isDevelopment() ? _topicDev : _topicProd;
    await subscribeToTopic(topic);

    // Escuchar actualizaciones del token
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      print('FCM Token (actualizado): $token');
    });

    // Manejar mensajes en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Manejar cuando se abre la app desde una notificación
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      try {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      } catch (_) {
        // Android < 13 no requiere solicitud de permiso
      }
    }
  }

  Future<void> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        // Imprimir token en consola para desarrollo/debug
        debugPrint('FCM Token: $_fcmToken');
        print('═══════════════════════════════════════════════════════');
        print('FCM Token: $_fcmToken');
        print('═══════════════════════════════════════════════════════');
      }
    } catch (e) {
      debugPrint('Error al obtener FCM token: $e');
      print('Error al obtener FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    final data = message.data;
    final route = (data['route'] as String?) ?? _buildRouteFromData(data);

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'DevLokos',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android?.smallIcon ?? '@mipmap/launcher_icon',
            color: BrandColors.primaryOrange,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: route,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final route = response.payload?.trim();
    if (route != null && route.isNotEmpty) {
      _navigate(route);
    }
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final route = (data['route'] as String?) ?? _buildRouteFromData(data);
    if (route.isNotEmpty) {
      _navigate(route);
    }
  }

  String _buildRouteFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;
    if (type == 'course' && id != null) return '/course/$id';
    if (type == 'event' && id != null) return '/events/$id';
    return '';
  }

  void _navigate(String route) {
    if (_navigateToRoute != null) {
      _navigateToRoute!(route);
    } else {
      _pendingRoute = route;
    }
  }

  /// Suscribe al dispositivo a un topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Desuscribe del dispositivo de un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Elimina el token (por ejemplo, al cerrar sesión)
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    _fcmToken = null;
  }

  /// Verifica si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Solicita permiso de notificaciones (abre el diálogo del sistema)
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isIOS) {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      }
      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted == true;
      }
    } catch (_) {}
    return false;
  }
}
