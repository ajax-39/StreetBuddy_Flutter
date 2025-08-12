import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/models/vendor.dart';
import 'package:street_buddy/utils/styles.dart';

class RegistryDevScreen extends StatelessWidget {
  const RegistryDevScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Registry'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('registry').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs
              .map(
                (e) => VendorModel.fromJson(e.id, e.data()),
              )
              .toList();

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final place = data[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistryDetailsScreen(
                          place: place,
                        ),
                      ));
                },
                child: Column(
                  children: [
                    Image.network(
                      place.photoUrl?.first ?? Constant.DEFAULT_PLACE_IMAGE,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    ListTile(
                      title: Text(
                        place.name ?? '',
                        style: AppTypography.cardTitle,
                      ),
                      subtitle: Text(
                        place.city ?? '',
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RegistryDetailsScreen extends StatefulWidget {
  final VendorModel place;
  const RegistryDetailsScreen({super.key, required this.place});

  @override
  State<RegistryDetailsScreen> createState() => _RegistryDetailsScreenState();
}

class _RegistryDetailsScreenState extends State<RegistryDetailsScreen> {
  PageController pagecontroller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name ?? ''),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: PageView(
                children: [
                  ...widget.place.photoUrl?.map(
                        (e) => Image.network(
                          e,
                          fit: BoxFit.cover,
                        ),
                      ) ??
                      []
                ],
              ),
            ),
            Visibility(
              visible: widget.place.photoUrl!.length > 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SmoothPageIndicator(
                  controller: pagecontroller,
                  count: widget.place.photoUrl!.length > 1
                      ? widget.place.photoUrl!.length
                      : 1,
                  effect: WormEffect(
                    activeDotColor: AppColors.primary,
                    dotHeight: 5,
                    dotWidth: 5,
                    spacing: 5,
                  ),
                ),
              ),
            ),
            Text(
              widget.place.name ?? '',
              style: TextStyle(fontSize: 30),
            ),
            Text(widget.place.city ?? ''),
            TextButton(
                onPressed: () {
                  context.push('/profile?uid=${widget.place.userId}');
                },
                child: Text('View user info')),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                child: Column(
               
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('category: ${widget.place.category}'.toUpperCase()),
                    const SizedBox(height: AppSpacing.md),
                    Text('phone: ${widget.place.phoneNumber}'.toUpperCase()),
                         const SizedBox(height: AppSpacing.md),
                    Text('email: ${widget.place.email}'.toUpperCase()),
                    Wrap(
                      children: [
                        Text('address: '.toUpperCase()),
                        Text(
                          widget.place.address.toString(),
                          style: AppTypography.cardTitle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            ...widget.place.placedata!.map(
              (e) {
                var index = widget.place.placedata!.indexOf(e);
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Q${index + 1}. ${e.ques}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Ans. ${e.ans}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      SizedBox(
                        height: 15,
                      )
                    ],
                  ),
                );
              },
            ),
            ElevatedButton(onPressed: () {}, child: Text('Approve')),
            SizedBox(
              height: 30,
            )
          ],
        ),
      ),
    );
  }
}
