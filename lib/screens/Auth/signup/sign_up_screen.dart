import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/Auth/sign_up_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class SignUpScreen extends StatefulWidget {
  final bool initialIsPhoneSignUp;
  const SignUpScreen({
    super.key,
    this.initialIsPhoneSignUp = false,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String? _emailError;
  String? _passwordError;
  String? _retypePasswordError;
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordHidden = true;
  bool _isRetypePasswordHidden = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _retypePasswordController =
      TextEditingController();

  // Validation methods
  String? _validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateRetypePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _retypePasswordError = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _retypePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFDFC7), // Light peach
                Color(0xFFFFDFC7), // Same peach
              ],
            ),
          ),
          child: Consumer<SignUpProvider>(
              builder: (context, signUpProvider, child) {
            return Stack(
              children: [
                Positioned(
                  top: -80,
                  left: 200,
                  right: -70,
                  child: Image.asset(
                    'assets/Vector.png',
                    fit: BoxFit.fitWidth,
                    width: 100,
                  ),
                ),
                // Top section with logo and title
                Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 60,
                        ),
                        child: Row(
                          spacing: 10,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Street Buddy Logo
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                'assets/icon/logo.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'STREET BUDDY',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'SFUI',
                                  letterSpacing: -1),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom curved container
                    Expanded(
                      flex: 7,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 30,
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 20,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Welcome header
                                Text(
                                  'Welcome',
                                  style: AppTypography.headline.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Sign Up to continue',
                                  style: AppTypography.body2.copyWith(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Email or Phone field
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Email',
                                    style: AppTypography.body2.copyWith(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _buildTextField(
                                  controller: _emailController,
                                  hint: 'Enter your email',
                                  validator: _validateEmailOrPhone,
                                  errorText: _emailError,
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Password field
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Password',
                                    style: AppTypography.body2.copyWith(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _buildTextField(
                                  controller: _passwordController,
                                  hint: '••••••••••••••',
                                  isPassword: true,
                                  validator: _validatePassword,
                                  errorText: _passwordError,
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Retype Password field
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Retype Password',
                                    style: AppTypography.body2.copyWith(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _buildTextField(
                                  controller: _retypePasswordController,
                                  hint: '••••••••••••••',
                                  isPassword: true,
                                  isRetypePassword: true,
                                  validator: _validateRetypePassword,
                                  errorText: _retypePasswordError,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                _buildPrimaryButton(
                                    onPressed: () =>
                                        _handleSignUp(context, signUpProvider),
                                    text: 'Register'),
                                const SizedBox(height: AppSpacing.lg),
                                // Sign in link
                                GestureDetector(
                                  onTap: () {
                                    context.push('/signin');
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: AppTypography.body2.copyWith(
                                            color: Colors.grey[600],
                                            fontSize: 14),
                                      ),
                                      Text(
                                        'Login',
                                        style: AppTypography.body2.copyWith(
                                            color: AppColors.primary2,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool isRetypePassword = false,
    String? Function(String?)? validator,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            autovalidateMode: AutovalidateMode.disabled,
            obscureText: isPassword
                ? (isRetypePassword
                    ? _isRetypePasswordHidden
                    : _isPasswordHidden)
                : false,
            textAlignVertical: isPassword ? TextAlignVertical.center : null,
            style: AppTypography.body,
            onChanged: (value) {
              if (errorText != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _clearErrors();
                });
              }
            },
            decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: InputBorder.none,
                suffixIcon: isPassword
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            if (isRetypePassword) {
                              _isRetypePasswordHidden =
                                  !_isRetypePasswordHidden;
                            } else {
                              _isPasswordHidden = !_isPasswordHidden;
                            }
                          });
                        },
                        icon: Icon(
                          (isRetypePassword
                                  ? _isRetypePasswordHidden
                                  : _isPasswordHidden)
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      )
                    : null),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFED7014),
          foregroundColor: AppColors.buttonText,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text, style: AppTypography.button2),
      ),
    );
  }

  void _handleSignUp(
      BuildContext context, SignUpProvider signUpProvider) async {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
      _retypePasswordError = null;
    });

    // Validate form inputs
    final emailError = _validateEmailOrPhone(_emailController.text);
    final passwordError = _validatePassword(_passwordController.text);
    final retypePasswordError =
        _validateRetypePassword(_retypePasswordController.text);

    // If there are validation errors, show them as SnackBar
    if (emailError != null ||
        passwordError != null ||
        retypePasswordError != null) {
      String errorMsg = '';
      if (emailError != null) errorMsg += emailError;
      if (passwordError != null) {
        if (errorMsg.isNotEmpty) errorMsg += '\n';
        errorMsg += passwordError;
      }
      if (retypePasswordError != null) {
        if (errorMsg.isNotEmpty) errorMsg += '\n';
        errorMsg += retypePasswordError;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    try {
      final identifier = _emailController.text.trim();
      final password = _passwordController.text;

      // Set the values in the SignUpProvider
      if (identifier.contains('@')) {
        signUpProvider.emailController.text = identifier;
      } else {
        signUpProvider.phoneController.text = identifier;
      }
      signUpProvider.passwordController.text = password;
      signUpProvider.confPasswordController.text =
          password; // Set confirm password same as password

      // Navigate directly to birthday screen, skipping the password confirmation screen
      context.push('/signup/birthday');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
