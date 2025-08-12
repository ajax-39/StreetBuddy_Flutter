import 'package:flutter/material.dart';

class OTPOptionsBottomSheet extends StatelessWidget {
  final String identifier;
  final VoidCallback onResendCode;
  final VoidCallback onChangeEmail;
  final VoidCallback onConfirmByMobile;

  const OTPOptionsBottomSheet({
    super.key,
    required this.identifier,
    required this.onResendCode,
    required this.onChangeEmail,
    required this.onConfirmByMobile,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
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
                  _buildOptionButton(
                    context,
                    'Resend confirmation code',
                    onResendCode,
                  ),
                  _buildOptionButton(
                    context,
                    identifier.contains('@')
                        ? 'Change email'
                        : 'Change phone number',
                    onChangeEmail,
                  ),
                  _buildOptionButton(
                    context,
                    identifier.contains('@')
                        ? 'Confirm by mobile number'
                        : 'Confirm by email',
                    onConfirmByMobile,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onPressed();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black87,
              ),
        ),
      ),
    );
  }
}

// Helper function to show the bottom sheet
void showOTPOptionsBottomSheet({
  required BuildContext context,
  required String identifier,
  required VoidCallback onResendCode,
  required VoidCallback onChangeEmail,
  required VoidCallback onConfirmByMobile,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => OTPOptionsBottomSheet(
      identifier: identifier,
      onResendCode: onResendCode,
      onChangeEmail: onChangeEmail,
      onConfirmByMobile: onConfirmByMobile,
    ),
  );
}
