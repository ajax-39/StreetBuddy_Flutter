import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/Auth/sign_up_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class UsernameScreen extends StatelessWidget {
  const UsernameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                    color: AppColors.textPrimary,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create a username',
                            style: AppTypography.headline,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Add a username or use our suggestion. You can change this at any time.',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ), 
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: provider.usernameController,
                            decoration: InputDecoration(
                              hintText: 'Username',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: _buildSuffixIcon(provider),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                            ),
                            onChanged: (value) {
                              provider.debounceUsernameCheck(value);
                            },
                          ),
                          if (provider.usernameController.text.isNotEmpty &&
                              provider.usernameSuggestions.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'The username ${provider.usernameController.text} is not available.',
                              style: AppTypography.caption.copyWith(
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...provider.usernameSuggestions.map(
                              (suggestion) => GestureDetector(
                                onTap: () {
                                  provider.setUsername(suggestion);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        suggestion,
                                        style: AppTypography.body,
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  (provider.usernameController.text.isEmpty ||
                                          provider.isUsernameExists ||
                                          provider.isCheckingUsername)
                                      ? null
                                      : () {
                                          context.push('/signup/terms');
                                        },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    AppColors.buttonDisabled,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Next',
                                style: AppTypography.button,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                context.go('/signin');
                              },
                              child: const Text(
                                'I already have an account',
                                style: AppTypography.link,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Icon(
      provider.isUsernameExists ? Icons.cancel : Icons.check_circle_outline,
      color: provider.isUsernameExists ? Colors.red : Colors.green,
    );
  }
}
