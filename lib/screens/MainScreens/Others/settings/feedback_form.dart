import 'package:flutter/material.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/utils/styles.dart';

class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  int? _rating;
  final Set<String> _selectedCategories = {};
  final TextEditingController _feedbackController = TextEditingController();
  final List<String> _categories = [
    "App Performance",
    "Design",
    "Navigation",
    "Functionality"
  ];
  bool isLoading = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'How was your experience?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: fontsemibold,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Tap to rate',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: fontregular,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Star Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(
                          _rating != null && _rating! > index
                              ? Icons.star
                              : Icons.star_border,
                          size: 25,
                          color: _rating != null && _rating! > index
                              ? Colors.amber
                              : Colors.grey,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'What\'s your feedback about?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: fontmedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    const SizedBox(width: 20),
                    ..._categories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCategories.remove(category);
                            } else {
                              _selectedCategories.add(category);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12, bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.black87 : Colors.grey[200],
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: fontregular,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 20),
                  ]),
                ),

                const SizedBox(height: 16),

                // Feedback Text Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 122,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _feedbackController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts',
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.3),
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Submit Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              // Handle submission
                              if (_rating == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a rating'),
                                  ),
                                );
                                return;
                              }

                              try {
                                setState(() {
                                  isLoading = true;
                                });
                                await supabase.from('feedbacks').insert({
                                  'rating': _rating,
                                  'feedback': _feedbackController.text,
                                  'categories': _selectedCategories.toList(),
                                  'user_id': globalUser?.uid ?? '',
                                  'username': globalUser?.username ?? '',
                                });

                                setState(() {
                                  isLoading = false;
                                });

                                Navigator.pop(context);
                                // Show success message

                                showModalBottomSheet(
                                  isScrollControlled: true,
                                  context: context,
                                  builder: (context) => const ThankYouScreen(),
                                );
                              } catch (e) {
                                print(e);
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: fontmedium,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 29.0, vertical: 30)
              .copyWith(top: 35),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green check mark circle
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CD964), // Green color for the circle
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),

              // Thank You! text
              const Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle text
              const Text(
                'Your feedback helps us improve\nStreet Buddy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: fontregular,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // Done button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle button press
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7F27), // Orange color
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: fontmedium,
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
