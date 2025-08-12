import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/utils/indianStatesCities.dart';
import 'package:street_buddy/utils/styles.dart';

void showMissingStateCityBottomSheet(BuildContext context, String uid) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return StateCityModal(
        uid: uid,
      );
    },
  );
}

class StateCityModal extends StatefulWidget {
  final String uid;
  const StateCityModal({super.key, required this.uid});

  @override
  State<StateCityModal> createState() => _StateCityModalState();
}

class _StateCityModalState extends State<StateCityModal> {
  final Map<String, List<String>> stateCityData = indianStatesCities;
  String? selectedState;
  String? selectedCity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'State and City are missing!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Please add a state and city to proceed.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select a State:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            isExpanded: true,
            value: selectedState,
            hint: const Text('Choose a state'),
            items: stateCityData.keys.map((state) {
              return DropdownMenuItem(
                value: state,
                child: Text(state),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedState = value;
                selectedCity = null; // Reset city when state changes
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
            value: selectedCity,
            hint: const Text('Choose a city'),
            items: selectedState == null
                ? []
                : stateCityData[selectedState]!.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCity = value;
              });
            },
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (selectedCity == null || selectedState == null)
                  ? null
                  : () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.uid)
                            .update({
                          'state': selectedState,
                          'city': selectedCity,
                        });
                        context.pop();
                      } catch (e) {
                        debugPrint(e.toString());
                      }
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
                'Add',
                style: AppTypography.button,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
