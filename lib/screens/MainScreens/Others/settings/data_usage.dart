import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/services/places_sync_service.dart';
import 'package:street_buddy/services/settings_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/data_saver_widgets.dart';

class DataUsageScreen extends StatefulWidget {
  const DataUsageScreen({super.key});

  @override
  State<DataUsageScreen> createState() => _DataUsageScreenState();
}

class _DataUsageScreenState extends State<DataUsageScreen> {
  // These are not used in the current implementation but kept for future use
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'App Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: fontmedium,
            color: Colors.black,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Data usage circle
              // Center(
              //   child: SizedBox(
              //     width: 140,
              //     height: 140,
              //     child: Stack(
              //       alignment: Alignment.center,
              //       children: [
              //         SizedBox(
              //           width: 140,
              //           height: 140,
              //           child: Image.asset(
              //             'assets/ellipse.png',
              //           ),
              //         ),
              //         const Column(
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           mainAxisSize: MainAxisSize.min,
              //           children: [
              //             Text(
              //               '12.5 GB',
              //               style: TextStyle(
              //                 fontSize: 25,
              //                 fontWeight: FontWeight.w500,
              //                 color: Colors.black,
              //               ),
              //             ),
              //             // SizedBox(height: 4),
              //             Text(
              //               'Used of 15 GB',
              //               style: TextStyle(
              //                 fontSize: 14,
              //                 color: Colors.black,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

              const SizedBox(height: 12),

              // Tab buttons
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 15),
              //   child: Container(
              //     height: 36,
              //     decoration: BoxDecoration(
              //       borderRadius: BorderRadius.circular(24),
              //       color: Colors.grey.withOpacity(0.1),
              //     ),
              //     child: Row(
              //       children: List.generate(
              //         _tabs.length,
              //         (index) => Expanded(
              //           child: GestureDetector(
              //             onTap: () {
              //               setState(() {
              //                 _selectedTabIndex = index;
              //               });
              //             },
              //             child: Container(
              //               decoration: BoxDecoration(
              //                 borderRadius: BorderRadius.circular(24),
              //                 color: _selectedTabIndex == index
              //                     ? AppColors.primary
              //                     : Colors.transparent,
              //               ),
              //               alignment: Alignment.center,
              //               child: Text(
              //                 _tabs[index],
              //                 style: TextStyle(
              //                   fontSize: 14,
              //                   fontWeight: FontWeight.w500,
              //                   color: _selectedTabIndex == index
              //                       ? Colors.white
              //                       : Colors.black,
              //                 ),
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),

              const SizedBox(height: 32),

              // Mobile Data Controls section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mobile Data Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Data Saver Mode
                    Consumer<SettingsService>(
                      builder: (context, settingsService, child) {
                        return _buildToggleItem(
                          icon: Icons.speed,
                          title: 'Data Saver Mode',
                          subtitle:
                              'Reduce image quality and limit background refresh',
                          value: settingsService.dataSaverMode,
                          onChanged: (value) async {
                            await settingsService.setDataSaverMode(value);
                            setState(() {
                              // Refresh the UI
                            });

                            // Show a snackbar to confirm the setting change
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value
                                      ? 'Data Saver Mode enabled. Images will load with reduced quality.'
                                      : 'Data Saver Mode disabled. Images will load at full quality.'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Background Data Management section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Background Data Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Background Data Usage
                    Consumer<SettingsService>(
                      builder: (context, settingsService, child) {
                        return _buildToggleItem(
                          icon: Icons.refresh,
                          title: 'Background Data Usage',
                          subtitle: 'Allow app to refresh data in background',
                          value: settingsService.backgroundDataUsage,
                          onChanged: (value) async {
                            // Update the setting
                            await settingsService.setBackgroundDataUsage(value);
                            setState(() {
                              // Refresh UI
                            });

                            // Show appropriate feedback
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value
                                      ? 'Background data enabled. App will update content in the background.'
                                      : 'Background data disabled. App will only update when open.'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),

                    // Grey divider
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16.0),
                      height: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),

                    // Sync Over Wi-Fi Only
                    Consumer<SettingsService>(
                      builder: (context, settingsService, child) {
                        return _buildToggleItem(
                          icon: Icons.wifi,
                          title: 'Sync Over Wi-Fi Only',
                          subtitle: 'Prevent data sync on mobile networks',
                          value: settingsService.syncOverWifi,
                          onChanged: (value) async {
                            // Update the setting
                            await settingsService.setSyncOverWifi(value);
                            setState(() {
                              // Refresh UI
                            });

                            // Get connection status to provide better feedback
                            final isOnWifi =
                                await settingsService.isConnectedToWifi();

                            // Show confirmation with network-aware message
                            if (mounted) {
                              String message;
                              if (value) {
                                message = isOnWifi
                                    ? 'Wi-Fi sync enabled. Your data will only sync on Wi-Fi networks.'
                                    : 'Wi-Fi sync enabled. Connect to Wi-Fi to sync your data.';
                              } else {
                                message =
                                    'Wi-Fi sync disabled. Your data will sync on any network.';
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  duration: const Duration(seconds: 2),
                                ),
                              );

                              // If we just enabled Wi-Fi only mode and we're on Wi-Fi,
                              // or if we just disabled Wi-Fi only mode, attempt a sync
                              if ((value && isOnWifi) || !value) {
                                if (settingsService.syncSavedPlaces) {
                                  final syncService = PlacesSyncService(
                                      settingsService: settingsService);
                                  syncService.attemptSync();
                                }
                              }
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Places Sync section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Synchronization',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sync Saved Places
                    Consumer<SettingsService>(
                      builder: (context, settingsService, child) {
                        return _buildToggleItem(
                          icon: Icons.bookmark_border,
                          title: 'Sync Saved Places',
                          subtitle: 'Sync bookmarks on Wi-Fi only',
                          value: settingsService.syncSavedPlaces,
                          onChanged: (value) async {
                            // Update the setting
                            await settingsService.setSyncSavedPlaces(value);
                            setState(() {
                              // Refresh UI
                            });

                            // If enabling sync, attempt to sync right away if possible
                            if (value) {
                              final syncService = PlacesSyncService(
                                  settingsService: settingsService);

                              final success = await syncService.attemptSync();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Saved places syncing enabled. Sync started.'
                                        : value
                                            ? 'Saved places syncing enabled. Will sync when on Wi-Fi.'
                                            : 'Saved places syncing disabled.'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } else {
                              // If disabling sync, just show a notification
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Saved places syncing disabled.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Example section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Example',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Import the DataSaverModeExample widget here
                    // to show how image quality changes with the setting
                    const DataSaverModeExample(),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: fontmedium,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: fontregular,
                    color: Colors.black.withOpacity(0.6),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
