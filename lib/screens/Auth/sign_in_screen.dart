import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:street_buddy/screens/Auth/signup/terms_and_policies_screen.dart';
import 'package:street_buddy/utils/styles.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String? _emailError;
  String? _passwordError;
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordHidden = true;
  bool _rememberMe = false;

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

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
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
                Color(0xFFFFDFC7), // Light peach#FFDFC7
                Color(0xFFFFDFC7), // Same peach
              ],
            ),
          ),
          child:
              Consumer<AuthenticationProvider>(builder: (context, auth, child) {
            return Stack(
              children: [
                // Background Vector decoration
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
                // Main content
                Column(
                  children: [
                    // Top section with logo and title
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 30,
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
                                'assets/icon/newlogo.png',
                                fit: BoxFit.contain,
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
                                  'Sign in to continue',
                                  style: AppTypography.body2.copyWith(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Email field
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
                                  controller: auth.emailController,
                                  hint: 'Enter your email',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter email';
                                    }
                                    return null;
                                  },
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
                                  controller: auth.passwordController,
                                  hint: 'Enter Your Password',
                                  isPassword: true,
                                  validator: _validatePassword,
                                  errorText: _passwordError,
                                ),
                                const SizedBox(height: AppSpacing.sm),

                                // Remember me and Forgot password row
                                _buildRememberMeAndForgotPassword(context),
                                _buildTermsAndPolicyCheck(context, auth),
                                const SizedBox(height: AppSpacing.sm),
                                _buildPrimaryButton(
                                    onPressed: () =>
                                        _handleSignIn(context, auth),
                                    text: 'Login',
                                    auth: auth),
                                // Spacing between primary and Google sign-in button
                                const SizedBox(height: AppSpacing.md),
                                _buildGoogleSignInButton(
                                    onPressed: () =>
                                        _handleGoogleSignIn(context, auth)),
                                const SizedBox(height: AppSpacing.md),
                                // Sign up link
                                GestureDetector(
                                  onTap: () {
                                    context.push('/signup');
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Don\'t have an account? ',
                                        style: AppTypography.body2.copyWith(
                                            color: Colors.grey[600],
                                            fontSize: 14),
                                      ),
                                      Text(
                                        'SignUp Here...',
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
            obscureText: isPassword ? _isPasswordHidden : false,
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
                          setState(
                              () => _isPasswordHidden = !_isPasswordHidden);
                        },
                        icon: Icon(
                          _isPasswordHidden
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

  Widget _buildPrimaryButton(
      {required VoidCallback onPressed,
      required String text,
      required AuthenticationProvider auth}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: auth.isTermsAccepted ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFED7014),
          foregroundColor: AppColors.buttonText,
          disabledBackgroundColor: const Color(0xFFED7014),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text, style: AppTypography.button2),
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Transform.scale(
              scale: 1.1,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: AppColors.primary2,
                checkColor: Colors.white,
                fillColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary2;
                    }
                    return Colors.transparent;
                  },
                ),
                side: BorderSide(
                  color: _rememberMe ? AppColors.primary2 : Colors.grey[400]!,
                  width: 2,
                ),
              ),
            ),
            Text(
              'Remember me',
              style: AppTypography.body2.copyWith(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            context.push('/forget');
          },
          child: Text(
            'Forgot Password?',
            style: AppTypography.body2.copyWith(
              color: AppColors.primary2,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton({required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.surfaceBackground,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        label: Text(
          'Login with Google',
          style: AppTypography.button2.copyWith(color: Colors.black),
        ),
        icon: Image.asset(
          'assets/google.png',
          width: 20,
        ),
      ),
    );
  }

  Widget _buildTermsAndPolicyCheck(
      BuildContext context, AuthenticationProvider auth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.scale(
          scale: 1.1,
          child: Checkbox(
            value: auth.isTermsAccepted,
            onChanged: (value) {
              auth.setTermsAccepted();
            },
            activeColor: AppColors.primary2,
            checkColor: Colors.white,
            fillColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary2;
                }
                return Colors.transparent;
              },
            ),
            side: BorderSide(
              color:
                  auth.isTermsAccepted ? AppColors.primary2 : Colors.grey[400]!,
              width: 2,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => const TermsAndPoliciesScreen()
                .showTermsAndPoliciesBottomSheet(context),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text.rich(
                  style: AppTypography.body2.copyWith(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  const TextSpan(children: [
                    TextSpan(
                      text: 'I agree to the ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        )),
                    TextSpan(text: ' and '),
                    TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        )),
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppColors.textLink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ])),
            ),
          ),
        )
      ],
    );
  }

  void _handleSignIn(BuildContext context, AuthenticationProvider auth) async {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate form inputs
    final emailError = _validateEmailOrPhone(auth.emailController.text);
    final passwordError = _validatePassword(auth.passwordController.text);

    // If there are validation errors, show them as SnackBar
    if (emailError != null || passwordError != null) {
      String errorMsg = '';
      if (emailError != null) errorMsg += emailError;
      if (passwordError != null) {
        if (errorMsg.isNotEmpty) errorMsg += '\n';
        errorMsg += passwordError;
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
      final identifier = auth.emailController.text.trim();
      debugPrint("identifier: $identifier");

      if (RegExp(r'^[\\d\\s\\-\\(\\)\\+]+$').hasMatch(identifier)) {
        // Removed phone sign in logic
        await auth.signInWithEmail(
          identifier,
          auth.passwordController.text,
        );
      } else {
        await auth.signInWithEmail(
          identifier,
          auth.passwordController.text,
        );
      }
    } catch (e) {
      // Handle different types of errors
      String errorMessage = 'Sign in failed';

      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No account found with this email/phone';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email format';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many failed attempts. Please try again later';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleGoogleSignIn(
      BuildContext context, AuthenticationProvider auth) async {
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error signing in with Google: ${e.toString()}')),
      );
      print(e.toString());
    }
  }
}
