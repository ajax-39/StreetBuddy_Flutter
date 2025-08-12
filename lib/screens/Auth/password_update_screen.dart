import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/custom_overlay_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordUpdateScreen extends StatefulWidget {
  final String code;
  const PasswordUpdateScreen({super.key, required this.code});

  @override
  State<PasswordUpdateScreen> createState() => _PasswordUpdateScreenState();
}

class _PasswordUpdateScreenState extends State<PasswordUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String mail = '';
  bool _isLoading = false;
  bool _isSessionReady = false;

  @override
  void initState() {
    super.initState();
    _exchangeCodeForSession();
  }

  Future<void> _exchangeCodeForSession() async {
    try {
      debugPrint('Exchanging code for session: ${widget.code}');
      final response = await Supabase.instance.client.auth
          .exchangeCodeForSession(widget.code);

      if (mounted) {
        setState(() {
          mail = response.session.user.email ?? '';
          _isSessionReady = true;
        });

        // Show success message for auto sign-in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Successfully signed in! Please update your password.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exchanging code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid or expired reset link: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        context.go('/signin');
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Use the user's session to update their password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Password updated successfully! Please sign in with your new password.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // Force sign out the user after password update for security
        await Supabase.instance.client.auth.signOut();

        // Navigate to sign in screen
        context.go('/signin');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating password: ${error.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSessionReady) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/city_images/mumbai/page2.jpg',
              fit: BoxFit.fill,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Signing you in...',
                    style: AppTypography.body.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/city_images/mumbai/page2.jpg',
            fit: BoxFit.fill,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomOverlayContainer(
                height: 550,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Your Password',
                          style: AppTypography.headline
                              .copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'You have been automatically signed in. Please create a new password for your account.',
                          style:
                              AppTypography.body2.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Account: $mail',
                          style: AppTypography.body2
                              .copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: true,
                          style: AppTypography.body,
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            hintText: 'New Password',
                            hintStyle: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _confirmPasswordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: true,
                          style: AppTypography.body,
                          validator: _validateConfirmPassword,
                          decoration: InputDecoration(
                            hintText: 'Confirm New Password',
                            hintStyle: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updatePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary2,
                              disabledBackgroundColor: AppColors.buttonDisabled,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Update Password',
                                    style: AppTypography.button2,
                                  ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.pushReplacement('/signin'),
                          child: Text(
                            'Back to Login',
                            style: AppTypography.link2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
