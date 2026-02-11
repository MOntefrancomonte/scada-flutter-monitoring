import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthState {
  final User? user;
  final String? error;
  AuthState({this.user, this.error});
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> loginWithMicrosoft() async {
    try {
      // 1. Definimos el Provider indicando que es de Microsoft
      final OAuthProvider microsoftProvider = OAuthProvider("microsoft.com");

      // 2. Configuramos parámetros personalizados
      // Reemplaza "common" por tu Tenant ID si solo quieres permitir usuarios de tu empresa
      microsoftProvider.setCustomParameters({

        "tenant": "0552c251-aaeb-4ed5-9d6f-ef5964715148", // "common" permite cuentas personales y de trabajo
        //"prompt": "select_account", // Fuerza a elegir cuenta si hay varias iniciadas
      });

      // 3. (Opcional) Definir alcances/scopes
      //microsoftProvider.addScope('mail.read');
      //microsoftProvider.addScope('calendars.read');

      // 4. Ejecutar el inicio de sesión
      UserCredential userCredential = await _auth.signInWithProvider(microsoftProvider);

      emit(AuthState(user: userCredential.user));
    } catch (e) {
      emit(AuthState(error: e.toString()));
      print("----------");
      print(e.toString());
      print("----------");
    }
  }

}