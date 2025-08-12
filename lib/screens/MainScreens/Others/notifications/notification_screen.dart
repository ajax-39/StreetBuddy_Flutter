import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/fnotification.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  Future<List<FnotificationModel>> getNotifications(String userId) async {
    try {
      SharedPreferences.getInstance().then(
        (pref) => pref.setString('last_notification_epoch',
            DateTime.now().millisecondsSinceEpoch.toString()),
      );

      final data = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((e) => FnotificationModel.fromMap(e['id'], e)).toList();
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: const CustomLeadingButton(),
      ),
      body: FutureBuilder<List<FnotificationModel>>(
          future: getNotifications(globalUser?.uid ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return noNewNotifications();
            }

            var data = snapshot.data!;

            if (data.isEmpty) {
              return noNewNotifications();
            }
            return ListView.builder(
                // reverse: true,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final boxData = data[index];
                  return GestureDetector(
                    onTap: () {
                      context.push(boxData.route);
                    },
                    onLongPress: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
                          actions: [
                            CupertinoActionSheetAction(
                                onPressed: () async {
                                  await supabase
                                      .from('notifications')
                                      .delete()
                                      .eq('id', boxData.id);

                                  context.pop();
                                },
                                child: const Text('Delete'))
                          ],
                        ),
                      );
                    },
                    child: SizedBox(
                      // height: 90,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        clipBehavior: Clip.antiAlias,
                        child: Center(
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(
                                boxData.image ?? Constant.DEFAULT_PLACE_IMAGE,
                              ),
                            ),
                            title: Text(
                              boxData.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            isThreeLine: true,
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  boxData.body,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timeago.format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(boxData.id),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                });
          }),
    );
  }

  Widget noNewNotifications() {
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
              'No Notifications!',
              style: AppTypography.headline,
            ),
            Text(
              'Come later!',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
