import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/otp_option_widget.dart';
import 'package:street_buddy/provider/Auth/otp_provider.dart';

class OTPScreen extends StatelessWidget {
  final String identifier;

  const OTPScreen({
    super.key,
    required this.identifier,
  });

  Future<void> _sendOTP(BuildContext context) async {
    try {
      final otpProvider = context.read<OTPProvider>();
      final bool isEmail = identifier.contains('@');

      if (isEmail) {
        await otpProvider.sendOTPViaEmail(identifier);
      } else {
        await otpProvider.sendOTPViaSMS(identifier);
      }

      otpProvider.setInitialOTPSent();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification code sent to $identifier')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error sending verification code: ${e.toString()}')),
      );
    }
  }

  Future<void> _verifyOTP(BuildContext context) async {
    final otpProvider = context.read<OTPProvider>();

    if (otpProvider.otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the verification code')),
      );
      return;
    }

    try {
      final bool isValid =
          await otpProvider.verifyOTP(otpProvider.otpController.text);

      if (isValid) {
        otpProvider.reset();
        context.go('/signup/birthday');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid verification code')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying code: ${e.toString()}')),
      );
    }
  }

  void _handleConfirmByMobile(BuildContext context) {
    final bool isCurrentlyEmail = identifier.contains('@');

    context.go('/signup', extra: isCurrentlyEmail);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final otpProvider = context.read<OTPProvider>();
      if (!otpProvider.hasInitialOTPSent && !otpProvider.isLoading) {
        _sendOTP(context);
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CircleAvatar(
                      backgroundColor: AppColors.surfaceBackground,
                      child: IconButton(
                        color: AppColors.primary2,
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                ),
              ),
              Spacer(),
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: AppSpacing.blur, sigmaY: AppSpacing.blur),
                  child: SizedBox(
                    height: 500,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Consumer<OTPProvider>(
                          builder: (context, otpProvider, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OTP',
                              style: AppTypography.body2
                                  .copyWith(fontSize: 16, color: Colors.white),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: otpProvider.otpController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: otpProvider.isLoading
                                    ? null
                                    : () => _verifyOTP(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary2,
                                  foregroundColor: AppColors.buttonText,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child: otpProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text('Verify'),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: otpProvider.isLoading
                                    ? null
                                    : () {
                                        showOTPOptionsBottomSheet(
                                          context: context,
                                          identifier: identifier,
                                          onResendCode: () => _sendOTP(context),
                                          onChangeEmail: () {
                                            context.pop();
                                            final bool isCurrentlyEmail =
                                                identifier.contains('@');

                                            context.go('/signup',
                                                extra: !isCurrentlyEmail);
                                          },
                                          onConfirmByMobile: () {
                                            context
                                                .pop(); // Close the bottom sheet
                                            _handleConfirmByMobile(context);
                                          },
                                        );
                                      },
                                child: const Text(
                                  "Resend OTP",
                                  style: TextStyle(color: AppColors.textLink),
                                ),
                              ),
                            ),
                            // const SizedBox(height: AppSpacing.xl),
                            Spacer(),
                            GestureDetector(
                              onTap: () => context.go('/signin'),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'I have an account? ',
                                      style: AppTypography.body2.copyWith(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                    Text(
                                      'Sign In',
                                      style: AppTypography.body2.copyWith(
                                          color: AppColors.textLink,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
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

  Widget buildO(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final otpProvider = context.read<OTPProvider>();
      if (!otpProvider.hasInitialOTPSent && !otpProvider.isLoading) {
        _sendOTP(context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<OTPProvider>(
        builder: (context, otpProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the confirmation code',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'To confirm your account, enter the 6-digit code we sent to ${identifier.contains('@') ? identifier : '+$identifier'}.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: otpProvider.otpController,
                  decoration: InputDecoration(
                    labelText: 'Confirmation code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: otpProvider.isLoading
                        ? null
                        : () => _verifyOTP(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: otpProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Verify'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: otpProvider.isLoading
                        ? null
                        : () {
                            showOTPOptionsBottomSheet(
                              context: context,
                              identifier: identifier,
                              onResendCode: () => _sendOTP(context),
                              onChangeEmail: () {
                                context.pop();
                                final bool isCurrentlyEmail =
                                    identifier.contains('@');

                                context.go('/signup', extra: !isCurrentlyEmail);
                              },
                              onConfirmByMobile: () {
                                context.pop(); // Close the bottom sheet
                                _handleConfirmByMobile(context);
                              },
                            );
                          },
                    child: const Text(
                      "I didn't get the code",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
