import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/services/biometrics_service.dart';
import 'package:street_buddy/services/settings_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool twoFactorEnabled = true;
  bool suspiciousLoginAlertsEnabled = true;
  bool biometricLockEnabled = true;

  final BiometricsService _biometricsService = BiometricsService();
  List deviceList = [];
  String deviceModel = '';

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password';
    }
    if (value != password) {
      return 'Confirm password must be same as password';
    }
    return null;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDeviceList();
    getDeviceModel();
    _checkBiometricAvailability();
    _loadBiometricSettings();
  }

  void _checkBiometricAvailability() async {
    // Check once at startup, but we'll check again when needed
    await _biometricsService.isBiometricsAvailable();
  }

  void _loadBiometricSettings() async {
    bool enabled = await _biometricsService.isBiometricLockEnabled();
    setState(() {
      biometricLockEnabled = enabled;
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void getDeviceList() async {
    final data = await supabase
        .from('users')
        .select('devices')
        .eq('uid', globalUser!.uid)
        .single();
    deviceList = data['devices'] ?? [];
    setState(() {});
  }

  void getDeviceModel() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceModel = androidInfo.model; // Example: "Pixel 6"
      setState(() {});
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceModel =
          iosInfo.utsname.machine; // Example: "iPhone13,4" (iPhone 12 Pro Max)
      setState(() {});
    } else {
      deviceModel = "Unknown Device";
      setState(() {});
    }
  }

  Future<String> _getBiometricTypeText() async {
    List<BiometricType> availableBiometrics =
        await _biometricsService.getAvailableBiometrics();

    if (availableBiometrics.isEmpty) {
      return 'No biometrics available';
    }

    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (availableBiometrics.contains(BiometricType.strong)) {
      return 'Strong biometrics';
    } else if (availableBiometrics.contains(BiometricType.weak)) {
      return 'Basic biometrics';
    }

    return 'Biometrics';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security',
          style: TextStyle(
            fontSize: 20,
            fontWeight: fontmedium,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Login & Authentication',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: fontsemibold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xffF7F7F7),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: fontmedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_showNewPassword,
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            hintText: 'New Password',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: fontregular,
                              color: Colors.black.withOpacity(0.3),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(
                                    0xFFBDBDBD), // More visible border color
                                width: 1.5, // Increased border width
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5, // Increased border width
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            suffixIcon: IconButton(
                              iconSize: 20, // Reduced size of eye icon
                              icon: Icon(_showNewPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _showNewPassword = !_showNewPassword;
                                });
                              },
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      PasswordStrengthIndicator(
                        password: _newPasswordController.text,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          validator: (value) => _validateConfirmPassword(
                              value, _newPasswordController.text),
                          decoration: InputDecoration(
                            hintText: 'Confirm Password',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: fontregular,
                              color: Colors.black.withOpacity(0.3),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(
                                    0xFFBDBDBD), // More visible border color
                                width: 1.5, // Increased border width
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5, // Increased border width
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _showConfirmPassword = !_showConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final passwordError =
                                _validatePassword(_newPasswordController.text);
                            final confPasswordError = _validateConfirmPassword(
                                _confirmPasswordController.text,
                                _newPasswordController.text);
                            if (passwordError != null ||
                                confPasswordError != null) {
                              String errorMsg = '';
                              if (passwordError != null)
                                errorMsg += passwordError;
                              if (confPasswordError != null) {
                                if (errorMsg.isNotEmpty) errorMsg += '\n';
                                errorMsg += confPasswordError;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: AppColors.error,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                              setState(() {
                                _autoValidate = true;
                              });
                              return;
                            }
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Change Password'),
                                    content: const Text(
                                        'Are you sure you want to change your password?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          try {
                                            await supabase.auth
                                                .updateUser(UserAttributes(
                                              password:
                                                  _confirmPasswordController
                                                      .text
                                                      .trim(),
                                            ));
                                            _confirmPasswordController.clear();
                                            _newPasswordController.clear();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Password changed successfully')));
                                          } catch (e) {
                                            debugPrint(e.toString());
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content:
                                                  Text('Something went wrong'),
                                            ));
                                          }
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: fontsemibold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                  height: 32), // Increased space between text and box
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xffF7F7F7),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Two-Factor Authentication',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: fontmedium,
                          ),
                        ),
                        Tooltip(
                          message: 'Feature not implemented yet',
                          child: Switch(
                            value: twoFactorEnabled,
                            onChanged: (value) {
                              setState(() {
                                twoFactorEnabled = value;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'This feature is not implemented yet'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              });
                            },
                            activeColor: Colors.white,
                            activeTrackColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This feature is not implemented yet',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('This feature is not implemented yet'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Set Up 2FA (Coming Soon)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: fontsemibold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: fontsemibold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xffF7F7F7),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildActivityItem(
                      deviceName: deviceModel,
                      location: globalUser?.state ?? 'India',
                      timeAgo: 'Currently Active',
                      status: ActivityStatus.success,
                    ),
                    const SizedBox(height: 12),
                    ...deviceList.map(
                      (e) => _buildActivityItem(
                        deviceName: 'iPhone 13',
                        location: 'Andhra pradesh, CA',
                        timeAgo: '2 minutes ago',
                        status: ActivityStatus.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data Protection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal, // Reduced boldness
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xffF7F7F7),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SecurityOption(
                      icon: Icons.warning_amber_rounded,
                      title: 'Suspicious Login Alerts',
                      description: 'Get notified of unusual login attempts',
                      isEnabled: suspiciousLoginAlertsEnabled,
                      onChanged: (value) {
                        setState(() {
                          suspiciousLoginAlertsEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<String>(
                      future: _getBiometricTypeText(),
                      builder: (context, snapshot) {
                        String biometricType = snapshot.data ?? 'Biometrics';
                        return SecurityOption(
                          icon: biometricType == 'Face ID'
                              ? Icons.face_retouching_natural
                              : Icons.fingerprint,
                          title: '$biometricType Lock',
                          description: 'Use $biometricType to unlock app',
                          isEnabled: biometricLockEnabled,
                          onChanged: (value) async {
                            // Check if biometrics are available on this device
                            bool isAvailable = await _biometricsService
                                .isBiometricsAvailable();

                            if (value && !isAvailable) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Biometric authentication is not available on this device',
                                  ),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            }

                            // If enabling, test authentication first
                            if (value && isAvailable) {
                              bool authenticated = await _biometricsService
                                  .authenticateWithBiometrics();
                              if (!authenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Biometric authentication failed'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                            }

                            // Save the setting
                            await _biometricsService
                                .setBiometricLockEnabled(value);
                            setState(() {
                              biometricLockEnabled = value;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value
                                    ? 'Biometric lock enabled'
                                    : 'Biometric lock disabled'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    // Add Screenshot Protection toggle
                    const SizedBox(height: 16),
                    Consumer<SettingsService>(
                      builder: (context, settingsService, child) {
                        return SecurityOption(
                          icon: Icons.screenshot,
                          title: 'Screenshot Protection',
                          description: 'Prevent screenshots in sensitive areas',
                          isEnabled: settingsService.screenshotProtection,
                          onChanged: (value) async {
                            // Save the setting
                            await settingsService
                                .setScreenshotProtection(value);
                            // UI will update via Consumer

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value
                                    ? 'Screenshot protection enabled'
                                    : 'Screenshot protection disabled'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      {required String deviceName,
      required String location,
      required String timeAgo,
      required ActivityStatus status}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Image.asset(
        'assets/icon/mobile.png',
        width: 25,
        height: 25,
      ),
      const SizedBox(width: 5),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deviceName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: fontmedium,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Image.asset(
                  'assets/icon/pin.png',
                  width: 15,
                  color: Colors.black.withOpacity(0.6),
                ),
                const SizedBox(width: 3),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: fontregular,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: fontregular,
                color: Colors.green, // Changed text color to green
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      Icon(
        status == ActivityStatus.success ? Icons.check : Icons.close,
        color: status == ActivityStatus.success ? Colors.green : Colors.red,
      ),
    ]);
  }
}

enum ActivityStatus { success, failed }

class SecurityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isEnabled;
  final Function(bool) onChanged;

  const SecurityOption({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 28,
          color: Colors.black87,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: fontmedium,
                  fontSize: 16,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: fontregular,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: isEnabled,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Colors.deepOrange,
        ),
      ],
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  int _calculatePasswordStrength() {
    if (password.isEmpty) return 0;
    if (password.length < 4) return 1;
    if (password.length < 6) return 2;
    if (password.length < 8) return 3;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculatePasswordStrength();

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: strength >= 1 ? Colors.red : Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                bottomLeft: Radius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 1,
          child: Container(
            height: 4,
            color: strength >= 2 ? Colors.orange : Colors.grey[300],
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 1,
          child: Container(
            height: 4,
            color: strength >= 3 ? Colors.yellow : Colors.grey[300],
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 1,
          child: Container(
            height: 4,
            color: strength >= 4 ? Colors.lightGreen : Colors.grey[300],
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 1,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: strength >= 5 ? Colors.green : Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
