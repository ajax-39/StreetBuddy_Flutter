import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/vendor.dart';
import 'package:street_buddy/services/upload_service.dart';
import 'package:street_buddy/utils/indianStatesCities.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/file_video_player.dart';

class RegisterPlaceScreen extends StatefulWidget {
  const RegisterPlaceScreen({super.key});

  @override
  State<RegisterPlaceScreen> createState() => _RegisterPlaceScreenState();
}

class _RegisterPlaceScreenState extends State<RegisterPlaceScreen> {
  TextEditingController namecon = TextEditingController();
  TextEditingController phonecon = TextEditingController();
  TextEditingController addresscon = TextEditingController();
  TextEditingController emailcon = TextEditingController();

  PageController pagecontroller = PageController();

  List<File> resultimagefile = [];
  var selectedCategory = -1;
  final categories = [
    'Food and Drink',
    'Regular Shop',
    'Hotels or Stay',
    'Others'
  ];
  final weekdays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  List<String> days = [];
  TimeOfDay? opensat;
  TimeOfDay? closesat;

  List ques = [
    [
      'Can you provide a brief description of your store (e.g., type of cuisine, specialty drinks, etc.)?',
      'Do you have any signature dishes or drinks that you’re known for?',
      'Do you operate at a fixed location, or do you move around (e.g., food truck)?',
      'Do you have any specific requirements or preferences for how your store is displayed on the app?',
      'What is your store rating in Google or any other platform?',
    ],
    [
      'Can you provide a brief description of your shop (e.g., what products or services you offer)?',
      'Do you offer any unique or specialty items that set your shop apart?',
      'Do you have a social media presence or website for your shop?',
      'Do you have any specific requirements or preferences for how your shop is displayed on the app?',
      'What is your shop rating in Google or any other platform?',
    ],
    [
      'Can you provide a brief description of your property (e.g., type of accommodation, unique features, target audience)?',
      'What amenities do you offer (e.g., Wi-Fi, swimming pool, gym, spa, restaurant)?',
      'Do you have all the necessary licenses and permits to operate your hotel or guest stay (e.g., hospitality license, fire safety clearance)?',
      'Do you have any specific requirements or preferences for how your property is displayed on the app?',
      'What is your hotel/stay rating in Google or any other platform?',
    ],
    [
      'Can you provide a brief description of your shop (e.g., what products or services you offer)?',
      'Do you have a social media presence or website for your shop?',
      'Do you have all the necessary licenses and permits to operate your shop (e.g., business license, tax registration)?',
      'Do you have any specific requirements or preferences for how your shop is displayed on the app?',
      'What is your shop rating in Google or any other platform?',
    ],
  ];

  final Map<String, List<String>> stateCityData = indianStatesCities;
  String? selectedState;
  String? selectedCity;
  List<String> ans = ['', '', '', '', ''];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool isUploading = false;

  Future<void> _pickMedia(
      BuildContext context, ImageSource source, bool isVideo) async {
    final ImagePicker imagePicker = ImagePicker();

    try {
      final List<XFile> si =
          await imagePicker.pickMultiImage(imageQuality: 60, limit: 5);
      if (si.isNotEmpty) {
        si.forEach(
          (element) => resultimagefile.add(File(element.path)),
        );
        if (resultimagefile.length > 5) {
          resultimagefile.removeRange(5, resultimagefile.length);
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  Future<String> uploadFile(File file) async {
    final String postId = DateTime.now().millisecondsSinceEpoch.toString();
    String mediaUrl;
    final String imagePath = 'registry/images/$postId.jpg';
    final ref = _storage.ref().child(imagePath);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    mediaUrl = await snapshot.ref.getDownloadURL();

    return mediaUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Register',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              const SizedBox(
                height: 15,
              ),
              resultimagefile.isEmpty
                  ? InkWell(
                      onTap: () {
                        _pickMedia(context, ImageSource.gallery, false);
                      },
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(15)),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 50,
                              ),
                              Text(
                                'Add a photo',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: PageView(
                          controller: pagecontroller,
                          children: [
                            ...resultimagefile.map(
                              (e) => Image.file(
                                e,
                                fit: BoxFit.cover,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
              Visibility(
                visible: resultimagefile.length > 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SmoothPageIndicator(
                    controller: pagecontroller,
                    count:
                        resultimagefile.length > 1 ? resultimagefile.length : 1,
                    effect: const WormEffect(
                      activeDotColor: AppColors.primary,
                      dotHeight: 5,
                      dotWidth: 5,
                      spacing: 5,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              Row(
                children: [
                  Text(
                    'Name of Buisness',
                    style: GoogleFonts.poppins(
                        color: Colors.orange.shade800, fontSize: 23),
                  ),
                ],
              ),
              TextField(
                controller: namecon,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    hintText: 'Your shop/store/merchandise name',
                    focusedBorder:
                        UnderlineInputBorder(borderSide: BorderSide(width: 2)),
                    enabledBorder:
                        UnderlineInputBorder(borderSide: BorderSide(width: 1))),
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              const SizedBox(
                height: 50,
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(50)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Choose category',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    DropdownButton(
                      items: [
                        const DropdownMenuItem(
                          child: Text('Select'),
                          value: 'Select',
                        ),
                        ...categories.map(
                          (e) => DropdownMenuItem(
                            child: Text(e),
                            value: e,
                          ),
                        )
                      ],
                      onChanged: (value) {
                        if (value == 'Select') {
                          selectedCategory = -1;
                        } else {
                          selectedCategory =
                              categories.indexOf(value.toString());
                        }
                        setState(() {});
                      },
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontWeight: FontWeight.bold),
                      value: selectedCategory == -1
                          ? 'Select'
                          : categories[selectedCategory],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              Row(
                children: [
                  Text(
                    'Describe your place',
                    style: GoogleFonts.poppins(
                        color: Colors.orange.shade800, fontSize: 23),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              ...ques[selectedCategory == -1
                      ? ques.length - 1
                      : selectedCategory]
                  .map(
                (e) {
                  var index = ques[selectedCategory == -1
                          ? ques.length - 1
                          : selectedCategory]
                      .indexOf(e);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Q${index + 1}. $e',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) => ans[index] = value,
                        decoration: const InputDecoration(
                            focusedBorder: UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder()),
                      ),
                      const SizedBox(
                        height: 15,
                      )
                    ],
                  );
                },
              ),
              const SizedBox(
                height: 30,
              ),
              const SizedBox(
                height: 10,
              ),
              const Row(
                children: [
                  SizedBox(
                    width: 30,
                  ),
                  Text(
                    'Place Info',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: phonecon,
                maxLength: 10,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: 'Add place contact',
                    prefixIcon: Icon(Icons.phone),
                    prefixText: '+91',
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                      width: 1,
                    )),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                      width: 1,
                    ))),
                style: const TextStyle(),
              ),
              TextField(
                controller: addresscon,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Add location address',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                    labelStyle: TextStyle(),
                    prefixIcon: Icon(Icons.location_on),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                      width: 1,
                    )),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                      width: 1,
                    ))),
                style: const TextStyle(),
                maxLines: 3,
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: emailcon,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    hintText: 'Add place email',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                    labelStyle: TextStyle(),
                    prefixIcon: Icon(Icons.email),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                      width: 1,
                    )),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                      width: 1,
                    ))),
                style: const TextStyle(),
              ),
              const SizedBox(
                height: 30,
              ),
              const Row(
                children: [
                  SizedBox(
                    width: 30,
                  ),
                  Text(
                    'Open Hours',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        "Select days and time",
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          ...weekdays.map(
                            (e) => InputChip(
                              shape: const CircleBorder(),
                              showCheckmark: false,
                              labelPadding: EdgeInsets.zero,
                              label: Text(e[0].toUpperCase()),
                              selected: days.contains(e),
                              onSelected: (value) => setState(
                                () {
                                  if (value)
                                    days.add(e);
                                  else
                                    days.remove(e);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Opens at:'),
                        trailing: Text(opensat?.format(context) ?? "SELECT"),
                        onTap: () async {
                          opensat = await showTimePicker(
                              context: context, initialTime: TimeOfDay.now());
                          setState(() {});
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.access_time_filled),
                        title: const Text('Closes at:'),
                        trailing: Text(closesat?.format(context) ?? "SELECT"),
                        onTap: () async {
                          closesat = await showTimePicker(
                              context: context, initialTime: TimeOfDay.now());
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Select a State:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                            selectedCity =
                                null; // Reset city when state changes
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select a City:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: resultimagefile.isEmpty ||
                          namecon.text.isEmpty ||
                          addresscon.text.isEmpty ||
                          selectedCity == null ||
                          isUploading == true ||
                          selectedCategory == -1
                      ? null
                      : () async {
                          var user = globalUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Cannot get user!")));
                            return;
                          }
                          if (ans.any(
                            (element) => element.isEmpty,
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Answer all above questions!")));
                            return;
                          }

                          if (phonecon.text.length != 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Enter 10 digit phone number!")));
                            return;
                          }
                          try {
                            setState(() {
                              isUploading = true;
                            });
                            List<OpeningHours> openingHours = [];
                            for (var i in days) {
                              openingHours.add(
                                OpeningHours(
                                    day: i,
                                    opensat: opensat?.format(context),
                                    closesat: closesat?.format(context)),
                              );
                            }
                            List<Placedata> data = [];
                            for (var i = 0; i < 5; i++) {
                              data.add(Placedata(
                                  ques: ques[selectedCategory == -1
                                      ? ques.length - 1
                                      : selectedCategory][i],
                                  ans: ans[i]));
                            }

                            List<String> imgurl = [];

                            for (var i in resultimagefile) {
                              imgurl.add(await uploadFile(i));
                            }

                            final place = VendorModel(
                                name: namecon.text,
                                phoneNumber: phonecon.text,
                                address: addresscon.text,
                                email: emailcon.text,
                                photoUrl: imgurl,
                                openingHours: openingHours,
                                placedata: data,
                                city: selectedCity,
                                userId: user.uid,
                                category: categories[selectedCategory]);

                            await _firestore
                                .collection('registry')
                                .add(place.toJson());

                            showBusinessProfileModal(context);
                            setState(() {
                              isUploading = false;
                            });
                          } catch (e) {
                            setState(() {
                              isUploading = false;
                            });
                            UploadService.error();
                          }
                        },
                  child: Text(isUploading ? 'Sending' : 'Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showBusinessProfileModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 50),
            const SizedBox(height: 16),
            const Text(
              "Profile Sent for Approval!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your business place profile has been sent to Street Buddy and is under process! Wait till your profile is approved!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () {
                context.pop();
                context.pop();
              },
              child: const Text("Okay",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      );
    },
  );
}
