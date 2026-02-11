import 'package:bloc/bloc.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

// --- ESTADO ---
// Definimos los posibles estados de la autenticación
abstract class AuthState {}

class AuthInitial extends AuthState {} // Estado inicial
class AuthLoading extends AuthState {} // Cargando (validando sesión)
class AuthAuthenticated extends AuthState { // Usuario logeado
  final AuthUser user;
  AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState {} // Usuario no logeado
class AuthError extends AuthState { // Ocurrió un error
  final String message;
  AuthError(this.message);
}

// --- CUBIT ---
// Esta es la clase que invocarás desde tu UI
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  // 1. Verificar si ya hay sesión iniciada al abrir la app
  Future<void> checkAuthStatus() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        final currentUser = await Amplify.Auth.getCurrentUser();
        emit(AuthAuthenticated(currentUser));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  // 2. Iniciar sesión con Email y Password
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final result = await Amplify.Auth.signIn(
        username: email.trim(),
        password: password,
      );

      if (result.isSignedIn) {
        final currentUser = await Amplify.Auth.getCurrentUser();
        emit(AuthAuthenticated(currentUser));
      } else {
        // En casos donde se requiere confirmar MFA o nueva contraseña
        emit(AuthError("Inicio de sesión incompleto. Verifique su correo."));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError("Ocurrió un error inesperado"));
    }
  }

  // 3. Cerrar sesión
  Future<void> logout() async {
    try {
      await Amplify.Auth.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError("Error al cerrar sesión"));
    }
  }
  // Dentro de tu clase AuthCubit

// 4. Registro de nuevo usuario
  Future<void> signUp(String email, String password) async {
    emit(AuthLoading());
    try {
      final userAttributes = {
        AuthUserAttributeKey.email: email.trim(),
      };

      final result = await Amplify.Auth.signUp(
        username: email.trim(),
        password: password,
        options: SignUpOptions(userAttributes: userAttributes),
      );

      if (result.isSignUpComplete) {
        // Caso raro donde no pide confirmación
        emit(AuthUnauthenticated());
      } else {
        // Estado personalizado para indicar que falta el código (opcional)
        // O simplemente manejarlo en la UI
        emit(AuthError("CONFIRMATION_REQUIRED"));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    }
  }

// 5. Confirmación del código enviado al correo
  Future<void> confirmSignUp(String email, String code) async {
    emit(AuthLoading());
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email.trim(),
        confirmationCode: code,
      );

      if (result.isSignUpComplete) {
        emit(AuthUnauthenticated()); // Ahora puede ir a logearse
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    }
  }

}