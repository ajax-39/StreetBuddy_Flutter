import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/Auth/sign_up_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class BirthdayScreen extends StatelessWidget {
  const BirthdayScreen({super.key});

  bool _isAtLeast14(DateTime birthday) {
    final today = DateTime.now();
    int age = today.year - birthday.year;

    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }

    return age >= 14;
  }

  void _showDatePicker(BuildContext context, SignUpProvider provider) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: provider.selectedBirthday ??
          DateTime.now().subtract(
              const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFED7014), // Orange color for selection
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && context.mounted) {
      if (!_isAtLeast14(selectedDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be at least 14 years old to proceed.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      provider.setBirthday(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpProvider>(
      builder: (context, provider, child) {
        bool isAgeValid = provider.selectedBirthday != null &&
            _isAtLeast14(provider.selectedBirthday!);

        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                const Text(
                  'Create your Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your account. Ensure it unique from all the users',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Username section
                const Text(
                  'Create a Username',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: provider.usernameController,
                  decoration: InputDecoration(
                    hintText: 'Create User Name',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFED7014)),
                    ),
                    suffixIcon: _buildSuffixIcon(provider),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    provider.debounceUsernameCheck(value);
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[a-z0-9_.]')),
                  ],
                ),
                const SizedBox(height: 24),

                // Birthday section
                const Text(
                  'What\'s Your birthday ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showDatePicker(context, provider),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.selectedBirthday != null
                              ? provider.birthdayText
                              : 'Select Your birthday',
                          style: TextStyle(
                            fontSize: 16,
                            color: provider.selectedBirthday != null
                                ? Colors.black
                                : AppColors.textSecondary,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                if (provider.selectedBirthday != null && !isAgeValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'You must be at least 14 years old to proceed',
                      style: AppTypography.body.copyWith(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),

                // Confirm button
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: !isAgeValid ||
                              provider.usernameController.text.isEmpty ||
                              provider.isUsernameExists ||
                              provider.isCheckingUsername
                          ? null
                          : () {
                              context.push('/signup/addstatecity');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED7014),
                        disabledBackgroundColor: const Color(0xFFED7014),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
