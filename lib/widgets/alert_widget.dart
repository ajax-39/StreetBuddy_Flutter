import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/utils/styles.dart';

class AccountBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final List<AccountSheetAction>? actions;

  const AccountBottomSheet({
    super.key,
    required this.title,
    required this.message,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.1,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  if (actions != null) ...[
                    const SizedBox(height: 24),
                    ...actions!.map((action) {
                      if (action.isPrimary) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton(
                            onPressed: action.onPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary2,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Text(action.label),
                          ),
                        );
                      } else {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: TextButton(
                            onPressed: action.onPressed,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              action.label,
                              style: TextStyle(color: AppColors.primary2),
                            ),
                          ),
                        );
                      }
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AccountSheetAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const AccountSheetAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });
}

void showAccountExistsBottomSheet(BuildContext context, String identifier) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AccountBottomSheet(
      title: 'Are you trying to log in?',
      message:
          'This ${identifier.contains('@') ? 'email' : 'number'} is associated with an existing account. You can log into it or create a new account with a new password.',
      actions: [
        AccountSheetAction(
          label: 'Log into an existing account',
          onPressed: () {
            context.pop();
            context.pop();
            context.go('/signin');
          },
          isPrimary: true,
        ),
        AccountSheetAction(
          label: 'Create new account',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}
