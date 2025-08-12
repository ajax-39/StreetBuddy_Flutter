import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:go_router/go_router.dart';

class UserTestScreen extends StatefulWidget {
  const UserTestScreen({super.key});

  @override
  State<UserTestScreen> createState() => _UserTestScreenState();
}

class _UserTestScreenState extends State<UserTestScreen> {
  bool _isImageLoading = false;
  bool _imageLoadError = false;

  Future<void> _handleSignOut() async {
    try {
      await context.read<AuthenticationProvider>().signOut();
      context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSignIn() async {
    try {
      // await context.read<AuthenticationProvider>().signOut();
      context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing in: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _retryLoadingImage() async {
    setState(() {
      _imageLoadError = false;
      _isImageLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isImageLoading = false;
    });
  }

  Widget _buildProfileImage(String? imageUrl) {
    if (_isImageLoading) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[200],
        child: const CircularProgressIndicator(),
      );
    }

    if (imageUrl == null || imageUrl.isEmpty || _imageLoadError) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[300],
        child: const Icon(
          Icons.person,
          size: 50,
          color: Colors.grey,
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(
            imageUrl,
          ),
          onBackgroundImageError: (exception, stackTrace) {
            print(imageUrl);
            debugPrint('Error loading profile image: $exception');

            if (mounted) {
              setState(() {
                _imageLoadError = true;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Failed to load profile image'),
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: _retryLoadingImage,
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          },
        ),
        if (_imageLoadError)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _retryLoadingImage,
            color: Colors.black54,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final signInProvider = context.watch<AuthenticationProvider>();
    final userModel = signInProvider.userModel;
    final firebaseUser = signInProvider.firebaseUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Test Screen"),
        actions: [
          ElevatedButton(
            onPressed: _handleSignIn,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            child: const Text("Home"),
          ),
          ElevatedButton(
            onPressed: _handleSignOut,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            child: const Text("Sign Out"),
          ),
        ],
      ),
      body: userModel == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _retryLoadingImage();
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfileImage(userModel.profileImageUrl),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome, ${userModel.username.isNotEmpty ? userModel.username : 'User'}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        context,
                        title: "User Details",
                        items: [
                          if (userModel.username.isNotEmpty)
                            {"Username": userModel.username},
                          if (userModel.email != null)
                            {"Email": userModel.email!},
                          if (userModel.phoneNumber != null)
                            {"Phone": userModel.phoneNumber!},
                          {"VIP Status": userModel.isVIP ? "Yes" : "No"},
                          {
                            "Email Verified":
                                userModel.isEmailVerified ? "Yes" : "No"
                          },
                          {
                            "Account Created": userModel.createdAt
                                .toLocal()
                                .toString()
                                .split('.')[0]
                          },
                          if (userModel.birthdate != null)
                            {
                              "Birthday": userModel.birthdate!
                                  .toLocal()
                                  .toString()
                                  .split('.')[0]
                            },
                        ],
                      ),
                      if (firebaseUser != null) ...[
                        const SizedBox(height: 20),
                        _buildInfoCard(
                          context,
                          title: "Authentication Details",
                          items: [
                            {"User ID": firebaseUser.id},
                            if (firebaseUser.email != null)
                              {"Auth Email": firebaseUser.email!},
                            if (firebaseUser.phone != null)
                              {"Auth Phone": firebaseUser.phone!},
                            {
                              "Provider": firebaseUser.identities!
                                  .map((p) => p.provider)
                                  .join(", ")
                            },
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Map<String, String>> items,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.keys.first,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(item.values.first),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
