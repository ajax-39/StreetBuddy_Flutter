import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/utils/location_permission_handler.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  bool publicMessage = true;
  bool allowRequest = true;
  bool locationAccess = true;
  bool locationHistory = true;
  final box = Hive.box('prefs');

  Future<void> _getPrivacySettings() async {
    final data = await supabase
        .from('users')
        .select('allow_requests, public_message')
        .eq('uid', globalUser?.uid ?? '')
        .single();
    setState(() {
      allowRequest = data['allow_requests'] ?? true;
      publicMessage = data['public_message'] ?? true;
    });
  }

  @override
  void initState() {
    super.initState();
    _initPermissions();
    _getPrivacySettings();
  }

  Future<void> _initPermissions() async {
    // Get location permission status from device and update the UI
    final bool hasPermission =
        await LocationPermissionHandler.checkLocationPermission();
    if (mounted) {
      setState(() {
        locationAccess = hasPermission;
        // Save the value to Hive to keep UI and permissions in sync
        box.put('location', hasPermission);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    locationHistory = box.get('history') ?? true;
    locationAccess = LocationPermissionHandler.isLocationEnabledInPrefs();
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Privacy Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: fontmedium,
            ),
          ),
          centerTitle: true,
        ),
        body: Builder(builder: (context) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Who can message me',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await supabase.from('users').update({
                            'public_message': true,
                          }).eq('uid', globalUser?.uid ?? '');
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: publicMessage
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              'Everyone',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color:
                                    publicMessage ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      GestureDetector(
                        onTap: () async {
                          await supabase.from('users').update({
                            'public_message': false,
                          }).eq('uid', globalUser?.uid ?? '');
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: !publicMessage
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              'Friends Only',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: !publicMessage
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow friend requests'),
                    titleTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: fontmedium,
                      color: Colors.black,
                    ),
                    subtitle: const Text('Receive requests from other users'),
                    subtitleTextStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: fontregular,
                      color: Colors.black.withOpacity(0.7),
                    ),
                    trailing: Switch(
                      value: allowRequest,
                      onChanged: (value) async {
                        await supabase.from('users').update({
                          'allow_requests': value,
                        }).eq('uid', globalUser?.uid ?? '');
                      },
                    ),
                  ),
                  const Divider(
                    color: Color(0xFFF1F1F1),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      )),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Image.asset(
                      'assets/icon/pin.png',
                      height: 25,
                      width: 25,
                    ),
                    title: const Text('Location Access'),
                    titleTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: fontmedium,
                      color: Colors.black,
                    ),
                    subtitle: const Text('Allow while using app'),
                    subtitleTextStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: fontregular,
                      color: Colors.black.withOpacity(0.7),
                    ),
                    trailing: Switch(
                      value: locationAccess,
                      onChanged: (value) async {
                        // Handle location permission toggle
                        final permissionResult = await LocationPermissionHandler
                            .setLocationPermissionPreference(value);

                        if (mounted) {
                          setState(() {
                            // When turning off, we always succeed
                            // When turning on, we only succeed if permission was granted
                            locationAccess = value ? permissionResult : false;
                          });
                        }

                        // Show appropriate message based on the result
                        if (value && !permissionResult && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Location permission is required. Please enable it in your device settings.'),
                              duration: const Duration(seconds: 4),
                              action: SnackBarAction(
                                label: 'Settings',
                                onPressed: () => openAppSettings(),
                              ),
                            ),
                          );
                        } else if (value && permissionResult && mounted) {
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location access enabled'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Image.asset(
                      'assets/icon/save.png',
                      height: 30,
                      width: 25,
                      fit: BoxFit.cover,
                    ),
                    title: const Text('Location History'),
                    titleTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: fontmedium,
                      color: Colors.black,
                    ),
                    subtitle: const Text('Save visited places'),
                    subtitleTextStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: fontregular,
                      color: Colors.black.withOpacity(0.7),
                    ),
                    trailing: Switch(
                      value: locationHistory,
                      onChanged: (value) async {
                        await box.put('history', value);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Data & Permissions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      )),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      CupertinoIcons.shield,
                      size: 25,
                      color: Colors.black,
                    ),
                    title: const Text('Manage Third-party Data'),
                    titleTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: fontmedium,
                      color: Colors.black,
                    ),
                    subtitle: const Text('View & revoke permissions'),
                    subtitleTextStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: fontregular,
                      color: Colors.black.withOpacity(0.7),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20,
                      color: Colors.black,
                    ),
                    onTap: () => showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                                title: const Text('Manage Third-party Data'),
                                content: const Text(
                                    'You can manage third-party data in your settings.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Manage'),
                                  ),
                                ])),
                  ),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Image.asset(
                        'assets/icon/delete-alt.png',
                        height: 25,
                        width: 25,
                      ),
                      title: const Text('Clear History'),
                      titleTextStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: fontmedium,
                        color: Colors.black,
                      ),
                      subtitle: const Text('Delete past searches & visits'),
                      subtitleTextStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: fontregular,
                        color: Colors.black.withOpacity(0.7),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 20,
                        color: Colors.black,
                      ),
                      onTap: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear History'),
                              content: const Text(
                                  'Are you sure you want to clear your history?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await Hive.box('search_history').clear();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('History cleared'),
                                      ),
                                    );
                                  },
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
          );
        }));
  }
}
