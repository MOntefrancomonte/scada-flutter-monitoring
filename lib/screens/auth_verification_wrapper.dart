// lib/screens/auth_verification_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:proyectoscada/Control_Usuario/auth_cubit_dos.dart';
import 'package:proyectoscada/screens/main_screen.dart';
import 'package:proyectoscada/screens/register_screen.dart';
import 'package:proyectoscada/main.dart';
class AuthVerificationWrapper extends StatefulWidget {
  final bool authVerified;

  const AuthVerificationWrapper({
    super.key,
    required this.authVerified,
  });

  @override
  State<AuthVerificationWrapper> createState() => _AuthVerificationWrapperState();
}

class _AuthVerificationWrapperState extends State<AuthVerificationWrapper> {
  bool _showingAuthDialog = false;

  @override
  void initState() {
    super.initState();

    // Verificar autenticación cuando se monta el widget
    if (!widget.authVerified && !_showingAuthDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAuthenticationRequiredDialog();
      });
    } else {
      // Si ya está verificado, verificar estado de auth
      context.read<AuthCubit>().checkAuthStatus();
    }
  }

  void _showAuthenticationRequiredDialog() {
    if (_showingAuthDialog) return;

    _showingAuthDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Autenticación Requerida'),
        content: const Text(
          'Para usar todas las funciones de la aplicación, '
              'incluyendo la sincronización en tiempo real, '
              'debes iniciar sesión con tus credenciales.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _showingAuthDialog = false;
              Navigator.pop(context);
              // Navegar a pantalla de login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Iniciar Sesión'),
          ),
          TextButton(
            onPressed: () {
              _showingAuthDialog = false;
              Navigator.pop(context);
              // Continuar en modo offline limitado
              _continueInLimitedMode();
            },
            child: const Text('Continuar en Modo Limitado'),
          ),
        ],
      ),
    );
  }

  void _continueInLimitedMode() {
    // Mostrar advertencia sobre limitaciones
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionando en modo limitado (sin sincronización)'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );

    // Navegar a pantalla principal con funcionalidad limitada
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si no está verificado, mostrar pantalla de login directamente
    if (!widget.authVerified) {
      return const LoginScreen();
    }

    // Si está verificado, usar el AuthWrapper normal
    return const AuthWrapper();
  }
}