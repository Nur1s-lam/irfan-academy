import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gold_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _AuthHeader(),
                const SizedBox(height: 44),
                Text(
                  'Добро пожаловать',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Войдите в свой аккаунт',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.inkSoft),
                ),
                const SizedBox(height: 34),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: authInputDecoration(
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Введите email';
                    }
                    if (!email.contains('@')) {
                      return 'Email должен содержать @';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _signIn(),
                  decoration:
                      authInputDecoration(
                        label: 'Пароль',
                        icon: Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.inkFaint,
                          ),
                        ),
                      ),
                  validator: (value) {
                    final password = value ?? '';
                    if (password.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (password.length < 6) {
                      return 'Минимум 6 символов';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                _isLoading
                    ? const GoldLoader()
                    : GoldButton(
                        label: 'Войти',
                        icon: Icons.login_rounded,
                        onPressed: _signIn,
                      ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _isLoading ? null : _openRegister,
                  child: const Text('Нет аккаунта? Зарегистрироваться'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.gold, AppTheme.goldDeep],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldDeep.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: AppTheme.surface,
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Irfan Academy',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: AppTheme.ink),
        ),
        const SizedBox(height: 4),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'عرفان أكاديمية',
            style: AppTheme.arabicText(fontSize: 22, color: AppTheme.goldDeep),
          ),
        ),
      ],
    );
  }
}

InputDecoration authInputDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppTheme.goldDeep),
    filled: true,
    fillColor: AppTheme.surface,
    labelStyle: const TextStyle(color: AppTheme.inkSoft),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.gold, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB3261E)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.4),
    ),
  );
}

class GoldLoader extends StatelessWidget {
  const GoldLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 52,
      child: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
    );
  }
}
