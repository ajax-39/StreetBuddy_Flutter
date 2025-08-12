import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/Auth/sign_up_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a username';
    }
    if (!RegExp(r'^[a-z0-9_.]{3,}$').hasMatch(value)) {
      return 'Username must be at least 3 characters and only contain a-z, 0-9, _ or .';
    }
    return null;
  }

  void _handleNext(BuildContext context, SignUpProvider provider) {
    final username = provider.usernameController.text.trim();
    final usernameError = _validateUsername(username);
    if (usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(usernameError),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() {
        _autoValidate = true;
      });
      return;
    }
    if (provider.isUsernameExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username is already taken'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    context.push('/signup/addstatecity');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/city_images/mumbai/page2.jpg',
            fit: BoxFit.fill,
          ),
          Consumer<SignUpProvider>(builder: (context, provider, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SafeArea(
                  child: SingleChildScrollView(
                    reverse: true,
                    padding: EdgeInsets.only(
                      top: 0,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(15),
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
                        ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: AppSpacing.blur,
                                sigmaY: AppSpacing.blur),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _formKey,
                                autovalidateMode: _autoValidate
                                    ? AutovalidateMode.always
                                    : AutovalidateMode.disabled,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create a username',
                                      style: AppTypography.body2.copyWith(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    TextFormField(
                                      controller: provider.usernameController,
                                      validator: _validateUsername,
                                      decoration: InputDecoration(
                                        hintText: 'Username',
                                        filled: true,
                                        fillColor: AppColors.surfaceBackground,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                            width: 1,
                                          ),
                                        ),
                                        suffixIcon: _buildSuffixIcon(provider),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.sm,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        provider.debounceUsernameCheck(value);
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp('[a-z0-9_.]')),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: (provider.usernameController
                                                    .text.isEmpty ||
                                                provider.isUsernameExists ||
                                                provider.isCheckingUsername)
                                            ? null
                                            : () =>
                                                _handleNext(context, provider),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary2,
                                          disabledBackgroundColor:
                                              AppColors.buttonDisabled,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: AppSpacing.md,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                        ),
                                        child: Text(
                                          'Next',
                                          style: AppTypography.button2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          context.go('/signin');
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'I have an account? ',
                                              style: AppTypography.body2
                                                  .copyWith(
                                                      color: Colors.white,
                                                      fontSize: 12),
                                            ),
                                            Text(
                                              'Sign In',
                                              style: AppTypography.body2
                                                  .copyWith(
                                                      color: AppColors.textLink,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
            );
          })
        ],
      ),
    );
  }

  Widget _buildSuffixIcon(SignUpProvider provider) {
    if (provider.usernameController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    if (provider.isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(14.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 1,
          ),
        ),
      );
    }

    return Icon(
      provider.isUsernameExists ? Icons.cancel : Icons.done,
      color: provider.isUsernameExists ? Colors.red : Colors.green,
    );
  }
}
