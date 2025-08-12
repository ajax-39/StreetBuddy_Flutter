import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/Auth/auth_notifier.dart';
import 'package:street_buddy/utils/styles.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _navigateAfterDelay();
  }

  Future<void> _fetchUserData() async {
    final user = globalUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _user = UserModel.fromMap(userDoc.id, userDoc.data()!);
        });
      }
    }
  }

  Future<void> _navigateAfterDelay() async {
    Provider.of<AuthStateNotifier>(context, listen: false)
        .markWelcomeScreenComplete();
    await Future.delayed(const Duration(seconds: 5));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: _user == null
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          "Street Buddy",
                          style: AppTypography.headline.copyWith(
                            fontFamily: 'Instagram Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ), 
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.border,
                              backgroundImage: _user?.profileImageUrl != null &&
                                      _user!.profileImageUrl!.isNotEmpty
                                  ? NetworkImage(_user!.profileImageUrl!)
                                  : null,
                              child: _user?.profileImageUrl == null ||
                                      _user!.profileImageUrl!.isEmpty
                                  ? const Icon(
                                      Icons.person_outline,
                                      size: 60,
                                      color: AppColors.textSecondary,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              "Welcome to the Street Buddy,",
                              style: AppTypography.body.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _user!.username,
                              style: AppTypography.body.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              "Let's start customizing your\nexperience",
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                        child: Container(
                          width: 100,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
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
