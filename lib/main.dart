// main.dart - VERSIÓN CORREGIDA
import 'dart:async';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Importaciones propias
import 'amplifyconfiguration.dart';
import 'models/ModelProvider.dart';
import 'AWSServicios/post_cubit.dart';
import 'AWSServicios/theme_cubit.dart';
import 'screens/main_screen.dart';
import 'package:proyectoscada/Control_Usuario/auth_cubit_dos.dart';
import 'package:proyectoscada/screens/register_screen.dart';
import 'services/fcm_service.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Configurar FCM para background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isConfigured = false;
  bool _notificationsInitialized = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _wasOffline = false;
  final FCMService _fcmService = FCMService();
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _configureAmplify();
    await _fcmService.initialize();

    setState(() {
      _isConfigured = true;
      _notificationsInitialized = true;
    });

    _initConnectivity();
    _listenToDataStoreHub();
    await _checkInitialNotification();
  }

  Future<void> _checkInitialNotification() async {
    try {
      RemoteMessage? initialMessage = await _fcmService.getInitialMessage();
      if (initialMessage != null) {
        safePrint('📱 App abierta desde notificación: ${initialMessage.notification?.title}');
      }
    } catch (e) {
      safePrint('❌ Error verificando notificación inicial: $e');
    }
  }

  Future<void> _configureAmplify() async {
    try {
      final datastorePlugin = AmplifyDataStore(modelProvider: ModelProvider.instance);
      final authPlugin = AmplifyAuthCognito();

      // API plugin simple - DataStore no lo necesita con modelProvider
      final apiPlugin = AmplifyAPI();

      await Amplify.addPlugin(authPlugin);
      await Amplify.addPlugin(datastorePlugin);
      await Amplify.addPlugin(apiPlugin);

      await Amplify.configure(amplifyconfig);
      safePrint('✅ Amplify configurado correctamente con Auth, DataStore y API');

    } on AmplifyAlreadyConfiguredException {
      safePrint('⚠️ Amplify ya fue configurado.');
    } catch (e) {
      safePrint('❌ Error al configurar Amplify: $e');
    }
  }

  // Escuchar eventos del Hub de DataStore (opcional - solo para logs)
  void _listenToDataStoreHub() {
    Amplify.Hub.listen(HubChannel.DataStore, (event) {
      safePrint('📡 DataStore Event: ${event.eventName}');

      // Solo registrar eventos, no tomar acciones críticas
      if (event.eventName == 'syncQueriesReady' || event.eventName == 'ready') {
        safePrint('✅ DataStore listo');
      }
    });
  }

  void _scheduleReconnection() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () {
      _reconnectAmplify();
    });
  }

  Future<void> _reconnectAmplify() async {
    try {
      safePrint('🔄 Intentando reconectar Amplify...');
      await Amplify.DataStore.stop();
      await Future.delayed(const Duration(seconds: 1));
      await Amplify.DataStore.start();
      safePrint('✅ Amplify reconectado correctamente');
    } catch (e) {
      safePrint('❌ Error reconectando Amplify: $e');
      _scheduleReconnection();
    }
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOffline = results.contains(ConnectivityResult.none);

      if (isOffline) {
        _wasOffline = true;
        _showStatusSnackbar(
          "Sin conexión a internet",
          Colors.red,
          Icons.wifi_off,
          isSticky: true,
        );
        safePrint('⚠️ Sin conexión a internet');
      } else {
        if (_wasOffline) {
          _showStatusSnackbar(
            "Conexión restaurada",
            Colors.green,
            Icons.wifi,
          );
          _wasOffline = false;
          safePrint('✅ Conexión a internet restaurada');
          _reconnectAmplify();
          _refreshFCMToken();
        }
      }
    });
  }

  Future<void> _refreshFCMToken() async {
    try {
      String? newToken = await _fcmService.getToken();
      if (newToken != null && newToken.isNotEmpty) {
        safePrint('🔔 Token FCM refrescado: $newToken');
      }
    } catch (e) {
      safePrint('❌ Error refrescando token FCM: $e');
    }
  }

  void _showStatusSnackbar(
      String message,
      Color color,
      IconData icon, {
        bool isSticky = false,
      }) {
    messengerKey.currentState?.hideCurrentSnackBar();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: isSticky ? const Duration(days: 1) : const Duration(seconds: 3),
        action: isSticky
            ? SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {
            messengerKey.currentState?.hideCurrentSnackBar();
          },
        )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _retryTimer?.cancel();
    _fcmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>(
      create: (_) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, theme) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => AuthCubit()),
              BlocProvider(
                create: (context) => PostCubit(),
                // No cargar aquí - se carga en MainScreen después de autenticación
              ),
            ],
            child: MaterialApp(
              scaffoldMessengerKey: messengerKey,
              debugShowCheckedModeBanner: false,
              theme: theme,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('es'), Locale('en')],
              home: _isConfigured && _notificationsInitialized
                  ? const AuthWrapper()
                  : const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Inicializando aplicación...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const MainScreen();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          return const LoginScreen();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar Sesión")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<AuthCubit>().login(
                  emailController.text,
                  passController.text,
                );
              },
              child: const Text("Entrar"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text("¿No tienes cuenta? Regístrate"),
            ),
          ],
        ),
      ),
    );
  }
}