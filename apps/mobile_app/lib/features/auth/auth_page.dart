import 'package:ezecute/core/api/api_service.dart';
import 'package:ezecute/data/app_data_store.dart';
import 'package:ezecute/features/onboarding/onboarding_page.dart';
import 'package:ezecute/routes/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthPage extends StatefulWidget {
  final bool initialIsLogin;
  final bool disableToggle;

  const AuthPage({
    super.key,
    this.initialIsLogin = true,
    this.disableToggle = false,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  late bool _isLogin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (email.isEmpty || password.isEmpty) return;
    if (!_isLogin && (firstName.isEmpty || lastName.isEmpty)) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      if (_isLogin) {
        await ApiService.login(email, password);
      } else {
        if (ApiService.isGuest) {
          await ApiService.upgrade(
            email,
            password,
            firstName: firstName,
            lastName: lastName,
          );
        } else {
          await ApiService.register(
            email,
            password,
            firstName: firstName,
            lastName: lastName,
          );
        }
      }

      await AppDataStore().refreshData();
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(true);
        } else {
          final store = AppDataStore();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => store.activeGoal != null
                  ? const AppShell()
                  : const OnboardingPage(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background decorative elements
          Positioned(
                top: -100.h,
                right: -100.w,
                child: Container(
                  width: 300.w,
                  height: 300.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 1.seconds)
              .scale(begin: const Offset(0.5, 0.5)),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 28.0.w,
                vertical: 40.0.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 60.h),
                  // Logo / Brand
                  Center(
                        child: Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: theme.colorScheme.primary,
                            size: 48.sp,
                          ),
                        ),
                      )
                      .animate()
                      .fade(duration: 600.ms)
                      .scale(curve: Curves.elasticOut),

                  SizedBox(height: 24.h),
                  Text(
                    'Ezecute Architect',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.2),

                  Text(
                    _isLogin
                        ? 'Welcome back, designer.'
                        : 'Build your future today.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ).animate().fade(delay: 400.ms).slideY(begin: 0.2),

                  SizedBox(height: 60.h),

                  // Input Fields
                  if (!_isLogin) ...[
                    _buildInputField(
                      controller: _firstNameController,
                      hint: "First name",
                      icon: Icons.person_outline_rounded,
                    ).animate().fade(delay: 500.ms).slideX(begin: 0.1),
                    SizedBox(height: 20.h),
                    _buildInputField(
                      controller: _lastNameController,
                      hint: "Last name",
                      icon: Icons.person_outline_rounded,
                    ).animate().fade(delay: 550.ms).slideX(begin: 0.1),
                    SizedBox(height: 20.h),
                  ],

                  _buildInputField(
                    controller: _emailController,
                    hint: "Email address",
                    icon: Icons.email_outlined,
                  ).animate().fade(delay: 600.ms).slideX(begin: 0.1),

                  SizedBox(height: 20.h),

                  _buildInputField(
                    controller: _passwordController,
                    hint: "Password",
                    icon: Icons.lock_outline_rounded,
                    obscure: true,
                  ).animate().fade(delay: 700.ms).slideX(begin: 0.1),

                  SizedBox(height: 40.h),

                  // Action Button
                  GestureDetector(
                    onTap: _isLoading ? null : _submit,
                    child: Container(
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isLogin ? 'Sign In' : 'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ).animate().fade(delay: 900.ms).scaleY(begin: 0.8),

                  SizedBox(height: 24.h),

                  // Toggle Login/Signup
                  if (!widget.disableToggle)
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isLogin = !_isLogin);
                      },
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: _isLogin
                                  ? "New here? "
                                  : "Already a member? ",
                            ),
                            TextSpan(
                              text: _isLogin ? "Create account" : "Sign in",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: 1100.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      obscureText: obscure,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          size: 20.sp,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
