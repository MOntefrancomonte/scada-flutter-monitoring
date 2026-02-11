// lib/services/auth_service.dart
// lib/services/auth_service.dart
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para comparar listas

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Verificar si el usuario está autenticado
  Future<bool> isUserAuthenticated() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (e) {
      safePrint('❌ Error verificando autenticación: $e');
      return false;
    }
  }

  // Obtener el token de acceso actual (forma actual)
  Future<String?> getAccessToken() async {
    try {
      // En la API moderna, obtenemos los tokens a través de fetchUserAttributes
      // o almacenando el token cuando hacemos login
      final authSession = await Amplify.Auth.fetchAuthSession();

      if (authSession.isSignedIn) {
        // Para AWS Amplify, podemos obtener el token JWT del usuario actual
        final result = await Amplify.Auth.fetchAuthSession(
          options: const FetchAuthSessionOptions(
            forceRefresh: false,
          ),
        );

        // En versiones recientes, el token se obtiene así:
        if (result is CognitoAuthSession) {
          // Algunas versiones tienen userPoolTokens, otras no
          // Intentamos obtener el token del usuario actual
          try {
            final currentUser = await Amplify.Auth.getCurrentUser();
            safePrint('✅ Usuario actual: ${currentUser.userId}');

            // Podemos obtener atributos que incluyan el token
            final attributes = await Amplify.Auth.fetchUserAttributes();
            final tokenAttribute = attributes.firstWhereOrNull(
                    (attr) => attr.userAttributeKey == CognitoUserAttributeKey.custom('accessToken')
            );

            if (tokenAttribute != null) {
              return tokenAttribute.value;
            }
          } catch (e) {
            safePrint('⚠️ No se pudo obtener token directamente: $e');
          }
        }
      }
      return null;
    } catch (e) {
      safePrint('❌ Error obteniendo token: $e');
      return null;
    }
  }

  // Obtener token JWT del ID token (forma más confiable)
  Future<String?> getIdToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) return null;

      // En algunas configuraciones, el ID token está disponible
      final authSession = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(
          forceRefresh: false,
        ),
      );

      // Intentar obtener el token del storage local
      return await _getTokenFromStorage();

    } catch (e) {
      safePrint('❌ Error obteniendo ID token: $e');
      return null;
    }
  }

  // Método para obtener token de storage local (si está disponible)
  Future<String?> _getTokenFromStorage() async {
    try {
      // Esto depende de cómo esté configurado Amplify
      // Podemos intentar obtener de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('cognito_id_token');
    } catch (e) {
      return null;
    }
  }

  // Refrescar el token si está cerca de expirar
  Future<bool> refreshTokenIfNeeded() async {
    try {
      final authSession = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(
          forceRefresh: true, // Forzar refresco para verificar validez
        ),
      );

      if (!authSession.isSignedIn) {
        safePrint('⚠️ Usuario no autenticado');
        return false;
      }

      safePrint('✅ Token válido y refrescado si era necesario');
      return true;

    } catch (e) {
      safePrint('❌ Error refrescando token: $e');

      // Si el error es de token expirado, forzar logout
      if (e.toString().contains('expired') ||
          e.toString().contains('invalid') ||
          e.toString().contains('401')) {
        safePrint('🔐 Token expirado o inválido, cerrando sesión...');
        await forceLogout();
        return false;
      }

      return false;
    }
  }

  // Verificar validez del token sin forzar refresh
  Future<bool> isTokenValid() async {
    try {
      final authSession = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(
          forceRefresh: false,
        ),
      );

      return authSession.isSignedIn;
    } catch (e) {
      safePrint('❌ Token inválido: $e');
      return false;
    }
  }

  // Forzar cierre de sesión y limpiar datos
  Future<void> forceLogout() async {
    try {
      await Amplify.Auth.signOut();
      safePrint('✅ Sesión cerrada forzosamente');

      // Limpiar tokens de storage local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cognito_id_token');
      await prefs.remove('cognito_access_token');

    } catch (e) {
      safePrint('❌ Error forzando cierre de sesión: $e');
    }
  }

  // Verificar permisos de usuario
  Future<Map<String, dynamic>> getUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final userInfo = <String, dynamic>{};

      for (final attribute in attributes) {
        userInfo[attribute.userAttributeKey.key] = attribute.value;
      }

      return userInfo;
    } catch (e) {
      safePrint('❌ Error obteniendo atributos de usuario: $e');
      return {};
    }
  }

  // Obtener información del usuario actual
  Future<Map<String, dynamic>> getCurrentUserInfo() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final attributes = await getUserAttributes();

      return {
        'userId': user.userId,
        'username': user.username,
        'attributes': attributes,
      };
    } catch (e) {
      safePrint('❌ Error obteniendo info de usuario: $e');
      return {};
    }
  }

  // Método para verificar conexión y autenticación completa
  Future<AuthStatus> checkAuthStatus() async {
    try {
      // 1. Verificar conexión a internet
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;

      if (!hasConnection) {
        return AuthStatus(
          isAuthenticated: false,
          isOnline: false,
          message: 'Sin conexión a internet',
          requiresLogin: false,
        );
      }

      // 2. Verificar autenticación
      final isAuthenticated = await isUserAuthenticated();

      if (!isAuthenticated) {
        return AuthStatus(
          isAuthenticated: false,
          isOnline: true,
          message: 'Usuario no autenticado',
          requiresLogin: true,
        );
      }

      // 3. Verificar validez del token
      final tokenValid = await isTokenValid();

      if (!tokenValid) {
        return AuthStatus(
          isAuthenticated: false,
          isOnline: true,
          message: 'Token expirado',
          requiresLogin: true,
        );
      }

      // 4. Obtener información del usuario
      final userInfo = await getCurrentUserInfo();

      return AuthStatus(
        isAuthenticated: true,
        isOnline: true,
        message: 'Autenticación exitosa',
        requiresLogin: false,
        userInfo: userInfo,
      );

    } catch (e) {
      safePrint('❌ Error en checkAuthStatus: $e');
      return AuthStatus(
        isAuthenticated: false,
        isOnline: false,
        message: 'Error: $e',
        requiresLogin: true,
      );
    }
  }

  // Guardar token en storage local (opcional)
  Future<void> saveTokenToStorage(String token, {bool isIdToken = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isIdToken ? 'cognito_id_token' : 'cognito_access_token';
      await prefs.setString(key, token);
      safePrint('✅ Token guardado en storage local');
    } catch (e) {
      safePrint('❌ Error guardando token: $e');
    }
  }
}

// Modelo para estado de autenticación
class AuthStatus {
  final bool isAuthenticated;
  final bool isOnline;
  final String message;
  final bool requiresLogin;
  final Map<String, dynamic>? userInfo;

  AuthStatus({
    required this.isAuthenticated,
    required this.isOnline,
    required this.message,
    required this.requiresLogin,
    this.userInfo,
  });
}