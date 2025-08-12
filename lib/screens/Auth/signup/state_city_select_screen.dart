import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/Auth/sign_up_provider.dart';
import 'package:street_buddy/utils/indianStatesCities.dart';
import 'package:street_buddy/utils/styles.dart';

class StateCitySelectorScreen extends StatefulWidget {
  const StateCitySelectorScreen({super.key});

  @override
  _StateCitySelectorScreenState createState() =>
      _StateCitySelectorScreenState();
}

class _StateCitySelectorScreenState extends State<StateCitySelectorScreen> {
  final Map<String, List<String>> stateCityData = indianStatesCities;

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpProvider>(
      builder: (context, provider, _) {
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
                Text(
                  'Select Your Location',
                  style: AppTypography.headline.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your location. Make sure it will be your Real Location',
                  style: AppTypography.body2.copyWith(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // State selection section
                Text(
                  'Select State',
                  style: AppTypography.subtitle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    underline: const SizedBox(),
                    isExpanded: true,
                    value: provider.selectedState,
                    hint: Text(
                      'Select Your State',
                      style: AppTypography.body.copyWith(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey),
                    items: stateCityData.keys.map((state) {
                      return DropdownMenuItem(
                        value: state,
                        child: Text(
                          state,
                          style: AppTypography.body.copyWith(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        provider.selectedState = value;
                        provider.selectedCity =
                            null; // Reset city when state changes
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // City selection section
                const Text(
                  'Select City',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    underline: const SizedBox(),
                    isExpanded: true,
                    value: provider.selectedCity,
                    hint: const Text(
                      'Select Your City',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey),
                    items: provider.selectedState == null
                        ? []
                        : stateCityData[provider.selectedState]!.map((city) {
                            return DropdownMenuItem(
                              value: city,
                              child: Text(
                                city,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                    onChanged: (value) {
                      setState(() {
                        provider.selectedCity = value;
                      });
                    },
                  ),
                ),

                // Confirm button
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (provider.selectedCity == null ||
                              provider.selectedState == null)
                          ? null
                          : () {
                              context.push('/signup/profile');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED7014),
                        disabledBackgroundColor:
                            const Color(0xFFED7014).withAlpha(100),
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

  Widget buildO(BuildContext context) {
    return Consumer<SignUpProvider>(builder: (context, provider, _) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('State and City Selector'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a State:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: provider.selectedState,
                hint: const Text('Choose a state'),
                items: stateCityData.keys.map((state) {
                  return DropdownMenuItem(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    provider.selectedState = value;
                    provider.selectedCity =
                        null; // Reset city when state changes
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Select a City:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: provider.selectedCity,
                hint: const Text('Choose a city'),
                items: provider.selectedState == null
                    ? []
                    : stateCityData[provider.selectedState]!.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                onChanged: (value) {
                  setState(() {
                    provider.selectedCity = value;
                  });
                },
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (provider.selectedCity == null ||
                          provider.selectedState == null)
                      ? null
                      : () {
                          context.push('/signup/terms');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.buttonDisabled,
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
            ],
          ),
        ),
      );
    });
  }
}
