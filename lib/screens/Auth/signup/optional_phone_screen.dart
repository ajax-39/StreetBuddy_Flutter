import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/Auth/sign_up_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/custom_overlay_container.dart';
//
import 'package:street_buddy/widgets/transparent_appbar.dart';

class OptionalPhoneScreen extends StatefulWidget {
  const OptionalPhoneScreen({super.key});

  @override
  State<OptionalPhoneScreen> createState() => _OptionalPhoneScreenState();
}

class _OptionalPhoneScreenState extends State<OptionalPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  Future<void> _handleContinue(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final provider = context.read<SignUpProvider>();
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    debugPrint('[OptionalPhoneScreen] User entered phone: $phone');
    await provider.saveOptionalPhoneNumberLocally('+91$phone');
    debugPrint(
        '[OptionalPhoneScreen] Called saveOptionalPhoneNumberLocally with: +91$phone');
    setState(() => _isLoading = false);
    if (mounted) context.push('/signup/profile');
  }

  void _handleSkip(BuildContext context) {
    context.push('/signup/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: TransparentAppbar(context: context),
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add your phone number (optional)',
                          style: AppTypography.body2.copyWith(
                              fontSize: 24, color: AppColors.surfaceBackground),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'You can add your phone number for account recovery and notifications. You can skip this step if you want.',
                          style: AppTypography.body2
                              .copyWith(color: AppColors.surfaceBackground),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixText: '+91 ',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50)),
                            filled: true,
                            fillColor: AppColors.surfaceBackground,
                          ),
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _handleContinue(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary2,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text('Continue',
                                    style: AppTypography.button2
                                        .copyWith(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: TextButton(
                            onPressed:
                                _isLoading ? null : () => _handleSkip(context),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
