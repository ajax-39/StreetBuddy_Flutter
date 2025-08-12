import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  bool _agreedToTerms = false;

  // List of expandable sections
  final List<Map<String, dynamic>> _sections = [
    {'title': 'User Account & Responsibilities', 'isExpanded': false},
    {'title': 'Privacy & Data Usage', 'isExpanded': false},
    {'title': 'Content Rights & Ownership', 'isExpanded': false},
    {'title': 'Platform Rules & Guidelines', 'isExpanded': false},
    {'title': 'Liability & Disclaimers', 'isExpanded': false},
    {'title': 'Account Termination', 'isExpanded': false},
    {'title': 'Changes to Terms', 'isExpanded': false},
    {'title': 'Contact Information', 'isExpanded': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: const CustomLeadingButton(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: SizedBox(
                height: 44,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search terms...',
                    contentPadding: EdgeInsets.zero,
                    hintStyle: AppTypography.searchBar16,
                    prefixIconConstraints: const BoxConstraints(
                      maxHeight: 24,
                      maxWidth: 44,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Image.asset(
                        'assets/icon/search.png',
                        color: const Color(0xffD9D9D9),
                      ),
                    ),
                    border: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xffD9D9D9), width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xffD9D9D9), width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                  ),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Street Buddy Terms of Service',
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Last updated
                      Text(
                        'Last updated: February 15, 2024',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Introduction
                      Text(
                        'Welcome to Street Buddy. By using our service, you agree to these terms. Please read them carefully.',
                        style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 20),

                      // Expandable sections
                      ...List.generate(_sections.length, (index) {
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _sections[index]['isExpanded'] =
                                      !_sections[index]['isExpanded'];
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _sections[index]['title'],
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      _sections[index]['isExpanded']
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_sections[index]['isExpanded'])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  'This is sample content for the ${_sections[index]['title']} section. In a real app, this would contain the actual terms related to this section.',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                            const Divider(
                              color: Color(0xffE5E7EB),
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 20),

                      // Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the Terms of Service and Privacy Policy.',
                              style: TextStyle(fontSize: 12.0),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Agree button
                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _agreedToTerms
                              ? () async {
                                  // Get reference to the auth provider
                                  final authProvider =
                                      Provider.of<AuthenticationProvider>(
                                          context,
                                          listen: false);
                                  final supabase = Supabase.instance.client;

                                  try {
                                    // Update the terms_accepted field in Supabase
                                    if (authProvider.user != null) {
                                      await supabase.from('users').update({
                                        'terms_accepted': true,
                                      }).eq('uid', authProvider.user!.id);

                                      // Show success message
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Terms accepted successfully')),
                                        );
                                        Navigator.pop(
                                            context); // Return to previous screen
                                      }
                                    }
                                  } catch (e) {
                                    // Show error message
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Error accepting terms: $e')),
                                      );
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor:
                                Colors.deepOrange.withOpacity(0.5),
                          ),
                          child: const Text(
                            'Agree & Continue',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
