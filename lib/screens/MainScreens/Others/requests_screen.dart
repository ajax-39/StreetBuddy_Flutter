import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:street_buddy/provider/MainScreen/message_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        centerTitle: true,
      ),
      body: Consumer2<AuthenticationProvider, ProfileProvider>(
          builder: (context, authProvider, provider, child) {
        final userModel = authProvider.userModel;

        if (userModel == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('users')
                .stream(primaryKey: ['id'])
                .eq('uid', userModel.uid)
                .limit(1),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('User data not found'),
                );
              }

              List<dynamic> requests = snapshot.data![0]['requests'] ?? [];
              
              if (requests.isNotEmpty) {
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) => FutureBuilder<UserModel?>(
                      future: _getUserData(requests[index]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        
                        if (snapshot.hasData && snapshot.data != null) {
                          UserModel listuser = snapshot.data!;
                          return ListTile(
                            onTap: () {
                              context.push('/profile?uid=${listuser.uid}');
                            },
                            leading: CircleAvatar(
                              backgroundImage: listuser.profileImageUrl != null
                                  ? NetworkImage(listuser.profileImageUrl!)
                                  : null,
                              child: listuser.profileImageUrl == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(listuser.name),
                            subtitle: Text(listuser.username),
                            trailing: CupertinoButton(
                              child: const Text('Accept'),
                              onPressed: () async {
                                await provider.unrequestFollow(
                                    listuser.uid, userModel.uid);

                                await provider.followUser(
                                    listuser.uid, userModel.uid);
                              },
                            ),
                          );
                        } else {
                          return const ListTile();
                        }
                      }),
                );
              } else {
                return const AspectRatio(
                  aspectRatio: 3 / 2,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notification_important_outlined,
                          size: 30,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'No Requests!',
                          style: AppTypography.headline,
                        ),
                        Text(
                          'No pending follow requests!',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                );
              }
            });
      }),
    );
  }
  
  Future<UserModel?> _getUserData(String uid) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('uid', uid)
          .single();
      
      if (response != null) {
        return UserModel.fromMap(uid, response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }
}