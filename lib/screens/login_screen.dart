import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

enum _AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    final success = _mode == _AuthMode.signIn
        ? await auth.signIn(email: email, password: password)
        : await auth.signUp(email: email, password: password);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mode == _AuthMode.signIn ? 'Signed in.' : 'Account created.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (!success && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  Future<void> _forgotPassword(AuthProvider auth) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email above first, then tap "Forgot password?".')),
      );
      return;
    }
    final success = await auth.sendPasswordResetEmail(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Password reset email sent.' : (auth.errorMessage ?? 'Could not send reset email.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == _AuthMode.signIn;

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.neonGreen, AppColors.neonGreenBright],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.cloud_sync_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  isSignIn ? 'Welcome back' : 'Create your account',
                  style: AppTextStyles.heading(size: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sync your scan history across devices.',
                  style: AppTextStyles.body(size: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                Text('Email', style: AppTextStyles.body(size: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: AppTextStyles.body(size: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'you@example.com',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Password', style: AppTextStyles.body(size: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: AppTextStyles.body(size: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'At least 6 characters',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ),

                if (isSignIn) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) => TextButton(
                        onPressed: auth.busy ? null : () => _forgotPassword(auth),
                        child: Text('Forgot password?', style: AppTextStyles.body(size: 12, color: AppColors.neonGreen)),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: auth.busy ? null : () => _submit(auth),
                        child: auth.busy
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : Text(isSignIn ? 'Sign In' : 'Create Account'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = isSignIn ? _AuthMode.signUp : _AuthMode.signIn),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.body(size: 13, color: AppColors.textSecondary),
                        children: [
                          TextSpan(text: isSignIn ? "Don't have an account? " : 'Already have an account? '),
                          TextSpan(
                            text: isSignIn ? 'Create one' : 'Sign in',
                            style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.neonGreen),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'An account is optional — the app works fully offline without one. Sign in only if you want your scan history synced across devices.',
                          style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}