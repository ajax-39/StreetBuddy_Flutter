import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class ChooseCity extends StatefulWidget {
  final void Function(LocationModel) onCitySelected;
  const ChooseCity({super.key, required this.onCitySelected});

  @override
  State<ChooseCity> createState() => _ChooseCityState();
}

class _ChooseCityState extends State<ChooseCity> {
  List<LocationModel> cities = [];
  LocationModel? selectedCity; 
  Future<void> getAllCities() async {
    final data = await supabase.from('locations').select('*');

    cities = data.map((e) => LocationModel.fromJson(e)).toList();

    if (cities
        .map((e) => e.nameLowercase)
        .contains(globalUser?.city?.toLowerCase())) {
      selectedCity = cities.firstWhere((element) =>
          element.nameLowercase == globalUser?.city?.toLowerCase());
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getAllCities();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: Colors.white,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose City'),
              DropdownButtonHideUnderline(
                child: DropdownButton(
                  value: selectedCity,
                  menuWidth: 200,
                  dropdownColor: Colors.white,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Select City'),
                    ),
                    ...cities.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ))
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCity = value;
                    });
                    // Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedCity == null
                      ? null
                      : () {
                          Provider.of<ExploreProvider>(context, listen: false)
                              .setLocation(selectedCity!);
                          Navigator.pop(context);
                          widget.onCitySelected(selectedCity!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: AppTypography.button.copyWith(
                      color: AppColors.buttonText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
