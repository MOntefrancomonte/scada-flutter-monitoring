import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:proyectoscada/Control_Usuario/auth_cubit_dos.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isWaitingForCode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Gestión de Consumos - Kubiec'),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError &&
              state.message == "CONFIRMATION_REQUIRED") {
            setState(() => _isWaitingForCode = true);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            return Row(
              children: [
                // FORMULARIO
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.all(32),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isWaitingForCode
                                    ? 'Confirmar Cuenta'
                                    : 'Crear Cuenta',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              if (!_isWaitingForCode) ...[
                                TextField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Contraseña',
                                    prefixIcon: Icon(Icons.lock),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                FilledButton(
                                  onPressed: () {
                                    context.read<AuthCubit>().signUp(
                                      _emailController.text,
                                      _passwordController.text,
                                    );
                                  },
                                  child: const Text('Registrarse'),
                                ),
                              ] else ...[
                                Text(
                                  'Ingresa el código enviado a tu correo',
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),

                                TextField(
                                  controller: _codeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Código de verificación',
                                    prefixIcon: Icon(Icons.verified),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                FilledButton(
                                  onPressed: () {
                                    context.read<AuthCubit>().confirmSignUp(
                                      _emailController.text,
                                      _codeController.text,
                                    );
                                  },
                                  child: const Text('Confirmar Cuenta'),
                                ),
                              ],

                              const SizedBox(height: 12),

                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // PANEL DERECHO SOLO EN DESKTOP
                if (isDesktop) ...[
                  const VerticalDivider(thickness: 1, width: 1),
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
              ],
            );
          },
        ),
      ),
    );
  }
}
