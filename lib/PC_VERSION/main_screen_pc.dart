
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:proyectoscada/Control_Usuario/auth_cubit_dos.dart';
import 'package:proyectoscada/amplifyconfiguration.dart';
import 'package:proyectoscada/screens/register_screen.dart';
import '../AWSServicios/theme_cubit.dart';
import '../PC_VERSION/screens/main_dashboard.dart';

import 'package:amplify_flutter/amplify_flutter.dart' hide Amplify;
import 'package:amplify_api/amplify_api.dart';

import 'package:flutter/gestures.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(const MyApp());
}

Future<void> _configureAmplify() async {
  try {
    if (Amplify.isConfigured) return;

    final api = AmplifyAPI();
    final authPlugin = AmplifyAuthCognito();
    await Amplify.addPlugins([api, authPlugin]);
    await Amplify.configure(amplifyconfig);

    safePrint('✅ Amplify configurado correctamente en Windows');
  } on Exception catch (e) {
    safePrint('❌ Error configurando Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthCubit()), // <--- Agregar este
          BlocProvider(create: (context) => ThemeCubit())],
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, theme) {
          return MaterialApp(
            title: 'Sistema de Gestión de Consumos',
            debugShowCheckedModeBanner: false,
            theme: theme.copyWith(
              scaffoldBackgroundColor: Colors.grey[50],
            ),
              home: const AuthWrapper(),
            //home: const MainDashboard(),
          );
        },
      ),
    );
  }

}

// 🔥🔥 3. WIDGET "WRAPPER" QUE DECIDE QUÉ PANTALLA MOSTRAR
// Este widget escucha al AuthCubit y decide si muestra Login o Main
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Apenas carga este widget (significa que Amplify ya está listo),
    // le pedimos al Cubit que verifique si hay usuario guardado.
    context.read<AuthCubit>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          // ✅ SI ESTÁ AUTENTICADO -> PANTALLA PRINCIPAL
          return const MainDashboard();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          // ❌ SI NO ESTÁ AUTENTICADO -> PANTALLA DE LOGIN
          return const LoginScreen();
        }

        // ⏳ MIENTRAS CARGA (AuthLoading o AuthInitial)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Gestión de Consumos - Ingreso'),
      ),
      body: Row(
        children: [
          // Panel izquierdo (Login)
          Expanded(
            flex: 1,
            child: Center(
              child: Card(
                elevation: 3,
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Iniciar Sesión',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: passController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 24),

                        FilledButton(
                          onPressed: () {
                            context.read<AuthCubit>().login(
                              emailController.text,
                              passController.text,
                            );
                          },
                          child: const Text('Entrar'),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text('¿Eres de Kubiec? Regístrate'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Divider central (como tu layout principal)
          const VerticalDivider(thickness: 1, width: 1),

          // Panel derecho (Logo / Imagen)
          Expanded(
            flex: 1,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Image.asset(
                  'assets/icons/app/appname.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

