import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/models/comment.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/services/notification_sender.dart';
import 'package:street_buddy/utils/styles.dart';

class ReportDbScreen extends StatefulWidget {
  const ReportDbScreen({super.key});

  @override
  State<ReportDbScreen> createState() => _ReportDbScreenState();
}

class _ReportDbScreenState extends State<ReportDbScreen> {
  List<String> commentsSelected = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports Monitor'),
      ),
      body: SingleChildScrollView(
        child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Comments'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Posts'),
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.sizeOf(context).height,
                  width: MediaQuery.sizeOf(context).width,
                  child: TabBarView(children: [
                    _buildCommentsTab(),
                    _buildPostsTab(),
                  ]),
                )
              ],
            )),
      ),
      persistentFooterButtons: [
        Visibility(
          visible: commentsSelected.isNotEmpty,
          child: IconButton(
            onPressed: () async {
              for (var i in commentsSelected) {
                await FirebaseFirestore.instance
                    .collection('comments')
                    .doc(i)
                    .delete();
              }
              setState(() {
                commentsSelected = [];
              });
            },
            icon: Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsTab() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('comments')
          .where('reports', isNull: false)
          .orderBy('reports', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.docs
            .map(
              (e) => CommentModel.fromMap(e.id, e.data()),
            )
            .toList();

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            var comment = data[index];
            return ListTile(
              selected: commentsSelected.contains(comment.id),
              selectedTileColor: Colors.pink.shade50,
              onTap: () {
                if (commentsSelected.contains(comment.id)) {
                  setState(() {
                    commentsSelected.remove(comment.id);
                  });
                } else
                  context.push('/post?id=${comment.postId}');
              },
              onLongPress: () {
                if (!commentsSelected.contains(comment.id)) {
                  setState(() {
                    commentsSelected.add(comment.id);
                  });
                }
              },
              leading: CircleAvatar(
                backgroundImage: NetworkImage(comment.userProfileImage),
              ),
              title: Text(comment.content),
              subtitle: Text(comment.username),
              trailing:
                  Text('${snapshot.data?.docs[index].data()['reports']}R'),
            );
          },
        );
      },
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('reports', isNull: false)
          .orderBy('reports', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.docs
            .map(
              (e) => PostModel.fromMap(e.id, e.data()),
            )
            .toList();

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            var post = data[index];
            return ListTile(
              onTap: () {
                context.push('/post?id=${post.id}');
              },
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Restrict Post',
                                style: AppTypography.headline,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'The selected post will be marked as Explicit and will be set to private',
                            style: AppTypography.body,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                  onPressed: () {
                                    context.pop();
                                  },
                                  child: Text('Cancel')),
                              TextButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('posts')
                                        .doc(post.id)
                                        .update({
                                      'isPrivate': true,
                                      'explicit': true,
                                    });
                                    NotificationSender()
                                        .sendPostRestrictedAlert(post);
                                    context.pop();
                                  },
                                  child: Text('Restrict')),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
              leading: CircleAvatar(
                backgroundImage: NetworkImage(post.userProfileImage),
              ),
              title: Text(post.title),
              subtitle: Text(post.username),
              trailing:
                  Text('${snapshot.data?.docs[index].data()['reports']}R'),
            );
          },
        );
      },
    );
  }
}
