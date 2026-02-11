import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// Importar Amplify solo para primer plano, no para background
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

// Anotación necesaria para que el código sea accesible desde background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // IMPORTANTE: No usar Amplify en background handler
  await Firebase.initializeApp();

  print("📱 [Background] Mensaje recibido: ${message.notification?.title}");

  // Inicializar notificaciones locales para background
  await _initializeLocalNotificationsForBackground();

  // Mostrar notificación
  await _showBackgroundNotification(message);
}

// Función auxiliar para inicializar notificaciones en background
@pragma('vm:entry-point')
Future<void> _initializeLocalNotificationsForBackground() async {
  const AndroidInitializationSettings androidInitializationSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: androidInitializationSettings);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  if (Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Este canal es para notificaciones importantes',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}

// Función auxiliar para mostrar notificaciones en background
@pragma('vm:entry-point')
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  // Extraer mensaje de data si notification está vacío
  String? title = message.notification?.title;
  String? body = message.notification?.body;

  // Si no hay notification, buscar en data
  if (title == null || body == null) {
    title = message.data['title'] ??
        message.data['message'] ??
        'Nueva notificación';
    body = message.data['body'] ??
        message.data['message'] ??
        'Tienes un nuevo mensaje';
  }

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'high_importance_channel',
    'Notificaciones Importantes',
    channelDescription: 'Este canal es para notificaciones importantes',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: message.data.toString(),
  );
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Stream para notificar cuando llega un mensaje en primer plano
  final StreamController<RemoteMessage> _messageStreamController =
  StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  // Inicializar el servicio de FCM
  Future<void> initialize() async {
    try {
      await _requestPermissions();
      await _setupLocalNotifications();
      await _setupFirebaseMessaging();
      await _getFCMToken();
      print('✅ FCM Service inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando FCM Service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📱 Permisos iOS: $settings');
    } else {
      final status = await Permission.notification.request();
      print('📱 Permisos Android: $status');
    }
  }

  Future<void> _setupLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
      InitializationSettings(android: androidInitializationSettings);

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          print('📱 Notificación tocada: ${details.payload}');
        },
      );

      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'Notificaciones Importantes',
          description: 'Este canal es para notificaciones importantes',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
    } catch (e) {
      print('❌ Error configurando notificaciones locales: $e');
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      // Configurar presentación de notificaciones en primer plano
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Configurar mensajes en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 [Foreground] Mensaje recibido: ${message.notification?.title}');
        print('📱 Datos: ${message.data}');

        // Mostrar notificación local
        _showNotification(message);

        // Notificar a los suscriptores
        _messageStreamController.add(message);
      });

      // Configurar cuando se abre la app desde una notificación
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 App abierta desde notificación: ${message.notification?.title}');
        _messageStreamController.add(message);
      });

      print('✅ Firebase Messaging configurado correctamente');
    } catch (e) {
      print('❌ Error configurando Firebase Messaging: $e');
    }
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('🔔 Token FCM obtenido: $_fcmToken');

      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        //await _saveFCMTokenToAWS(_fcmToken!);
      }

      // Escuchar cambios en el token
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 Token FCM actualizado: $newToken');
        _fcmToken = newToken;
        //await _saveFCMTokenToAWS(newToken);
      });
    } catch (e) {
      print('❌ Error obteniendo token FCM: $e');
    }
  }

  Future<void> _saveFCMTokenToAWS(String token) async {
    try {
      // Verificar si hay usuario autenticado antes de guardar
      final authSession = await Amplify.Auth.fetchAuthSession();
      if (authSession.isSignedIn) {
        final user = await Amplify.Auth.getCurrentUser();

        // Guardar token en atributos personalizados de Cognito
        await Amplify.Auth.updateUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.custom('fcm_token'),
          value: token,
        );

        print('✅ Token FCM guardado en AWS Cognito');
      } else {
        print('⚠️ No hay usuario autenticado, token FCM no guardado en AWS');
      }
    } on AuthException catch (e) {
      print('❌ Error de Auth al guardar token: $e');
    } catch (e) {
      print('❌ Error guardando token en AWS: $e');
    }
  }

  void _showNotification(RemoteMessage message) {
    try {
      // Extraer mensaje de data si notification está vacío
      String? title = message.notification?.title;
      String? body = message.notification?.body;

      // Si no hay notification, buscar en data
      if (title == null || body == null) {
        title = message.data['title'] ??
            message.data['message'] ??
            'Nueva notificación';
        body = message.data['body'] ??
            message.data['message'] ??
            'Tienes un nuevo mensaje';
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'high_importance_channel',
        'Notificaciones Importantes',
        channelDescription: 'Este canal es para notificaciones importantes',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: message.data.toString(),
      );

      // Debug: Imprimir toda la data recibida
      print('📱 Data completa recibida: ${message.data}');
    } catch (e) {
      print('❌ Error mostrando notificación: $e');
    }
  }

  // Método para suscribirse a temas
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Suscrito al tema: $topic');
    } catch (e) {
      print('❌ Error suscribiéndose al tema $topic: $e');
    }
  }

  // Método para desuscribirse de temas
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Desuscrito del tema: $topic');
    } catch (e) {
      print('❌ Error desuscribiéndose del tema $topic: $e');
    }
  }

  // Método para verificar si la app fue abierta desde una notificación
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      return await FirebaseMessaging.instance.getInitialMessage();
    } catch (e) {
      print('❌ Error obteniendo mensaje inicial: $e');
      return null;
    }
  }

  // Método para obtener el token actual
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ Error obteniendo token: $e');
      return null;
    }
  }

  // Método para limpiar
  void dispose() {
    _messageStreamController.close();
  }
}