import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/message_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';

class MessagesScreen extends StatelessWidget {
  /// Formats a timestamp (milliseconds since epoch) into WhatsApp-style time string
  String formatLastMessageTime(String? sent) {
    if (sent == null || sent.isEmpty) return '';
    final int sentMillis = int.tryParse(sent) ?? 0;
    if (sentMillis == 0) return '';
    final now = DateTime.now();
    final sentTime = DateTime.fromMillisecondsSinceEpoch(sentMillis);
    final diff = now.difference(sentTime);
    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && now.day == sentTime.day) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1 ||
        (now.day - sentTime.day == 1 && diff.inHours < 48)) {
      return 'Yesterday';
    } else if (now.year == sentTime.year) {
      // Show as 'dd MMM' (e.g., 22 Jul)
      return '${sentTime.day.toString().padLeft(2, '0')} '
          '${_monthAbbr(sentTime.month)}';
    } else {
      // Show as 'dd/MM/yy'
      return '${sentTime.day.toString().padLeft(2, '0')}/'
          '${sentTime.month.toString().padLeft(2, '0')}/'
          '${sentTime.year.toString().substring(2)}';
    }
  }

  String _monthAbbr(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  Widget _buildPopupAction(
      {required IconData icon,
      required String text,
      required VoidCallback onTap,
      double fontSize = 16}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 18),
            Text(
              text,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Messages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                )),
            centerTitle: true,
            leading: const CustomLeadingButton(),
          ),
          floatingActionButton: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFED7014),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                // Focus on search field when FAB is pressed
                FocusScope.of(context).requestFocus(FocusNode());
                messageProvider.searchController.clear();
                messageProvider.searchController.selection =
                    TextSelection.fromPosition(TextPosition(
                        offset: messageProvider.searchController.text.length));
                // Scroll to the search bar
                Future.delayed(const Duration(milliseconds: 100), () {
                  FocusScope.of(context)
                      .requestFocus(FocusNode()..requestFocus());
                  // Set focus to search field
                  FocusScope.of(context).requestFocus(FocusNode()..unfocus());
                  FocusScope.of(context)
                      .requestFocus(messageProvider.searchFocusNode);
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.edit, color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // No tabs, no message request section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: messageProvider.searchController,
                      focusNode: messageProvider.searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        contentPadding: EdgeInsets.zero,
                        hintStyle: AppTypography.searchBar,
                        prefixIconConstraints: const BoxConstraints(
                          maxHeight: 24,
                          maxWidth: 44,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Image.asset(
                            'assets/icon/search.png',
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    AppColors.textSecondary.withOpacity(0.5)),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(50))),
                        border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: AppColors.textSecondary),
                            borderRadius:
                                BorderRadius.all(Radius.circular(50))),
                      ),
                      onChanged: (value) => messageProvider.performSearch(
                          value.toLowerCase(), context),
                    ),
                  ),
                ),
                // Only show single list
                StreamBuilder(
                  stream: MessageProvider.getMyUsersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final userIdList =
                          snapshot.data!.docs.map((e) => e.id).toList();

                      if (messageProvider.myUsersIdlist.isEmpty ||
                          !listsEqual(
                              messageProvider.myUsersIdlist, userIdList)) {
                        messageProvider.myUsersIdlist = userIdList;
                        messageProvider.getMyUsers(userIdList);
                      }

                      if (messageProvider.searchController.text.isEmpty) {
                        return buildMyUsersView(userIdList, context);
                      } else {
                        return buildSearchView(
                            messageProvider.following, context);
                      }
                    }

                    // Only show the "No Messages" widget if we're not searching
                    if (messageProvider.searchController.text.isNotEmpty) {
                      return buildSearchView(
                          messageProvider.following, context);
                    }

                    return SizedBox(
                      height: 400, // Ensures vertical centering in most screens
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icon/no_messeges.png',
                              width: 100,
                              height: 100,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No Messages Yet!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Start a conversation with a friend or\nexplore people nearby.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: AppSpacing.md,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!b.contains(a[i])) return false;
    }
    return true;
  }

  Widget buildMyUsersView(List<String> myUserslist, BuildContext context) {
    if (myUserslist.isNotEmpty) {
      return chatListView(myUserslist, context);
    } else {
      return const Center(
        child: Text('No chats to show!', style: TextStyle(fontSize: 20)),
      );
    }
  }

  Widget buildSearchView(List<UserModel> following, BuildContext context) {
    if (following.isNotEmpty) {
      return chatSearchView(following, context);
    } else {
      return const Center(
        child: Text('No Following Matching!', style: TextStyle(fontSize: 20)),
      );
    }
  }

  Widget chatListView(List<String> list, BuildContext context) {
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: list.length,
      itemBuilder: (context, index) => FutureBuilder<UserModel>(
        future: messageProvider.getMyUsersReturn(list[index]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasError) {
            return const ListTile(
              title: Text('Error'),
            );
          }
          if (snapshot.hasData) {
            UserModel listuser = snapshot.data!;
            return StreamBuilder(
              stream: MessageProvider.getLastMessage(listuser),
              builder: (context, msgSnapshot) {
                if (msgSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                final hasMessages = msgSnapshot.hasData &&
                    msgSnapshot.data != null &&
                    msgSnapshot.data!.docs.isNotEmpty;
                final messageType = hasMessages
                    ? msgSnapshot.data!.docs.first.data()['type'].toString()
                    : '';
                final messageText = hasMessages
                    ? msgSnapshot.data!.docs.first.data()['msg'].toString()
                    : 'No messages yet';
                final sentTime = hasMessages
                    ? msgSnapshot.data!.docs.first.data()['sent'].toString()
                    : null;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 8),
                                  child: Text(
                                    listuser.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                _buildPopupAction(
                                  icon: Icons.push_pin_outlined,
                                  text: 'Pin Conversation',
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  fontSize: 12,
                                ),
                                const Divider(height: 1),
                                _buildPopupAction(
                                  icon: Icons.delete_outline,
                                  text: 'Delete Chat',
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  fontSize: 12,
                                ),
                                const Divider(height: 1),
                                _buildPopupAction(
                                  icon: Icons.notifications_off_outlined,
                                  text: 'Mute Messages',
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  fontSize: 12,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  leading: SizedBox(
                    width: 44,
                    height: 44,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: listuser.profileImageUrl != null
                          ? NetworkImage(listuser.profileImageUrl!)
                          : null,
                      child: listuser.profileImageUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ),
                  title: Text(
                    listuser.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    hasMessages
                        ? (messageType == 'text' ? messageText : 'Media')
                        : 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: hasMessages
                      ? Text(
                          formatLastMessageTime(sentTime),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                  onTap: () => context.push('/messages?uid=${listuser.uid}'),
                );
              },
            );
          }
          return const ListTile(
            title: Text('User not found'),
          );
        },
      ),
    );
  }

  Widget chatSearchView(List<UserModel> list, BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: list.length,
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(
          backgroundImage: list[index].profileImageUrl != null
              ? NetworkImage(list[index].profileImageUrl!)
              : null,
          child: list[index].profileImageUrl == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(list[index].username),
        subtitle: const Text('Tap to chat'),
        onTap: () {
          Provider.of<MessageProvider>(context, listen: false).clearSearch();
          context.push('/messages?uid=${list[index].uid}');
        },
        trailing: IconButton(
            onPressed: () {
              Provider.of<MessageProvider>(context, listen: false)
                  .clearSearch();
              context.push('/messages?uid=${list[index].uid}');
            },
            icon: const Icon(Icons.message)),
      ),
    );
  }
}
