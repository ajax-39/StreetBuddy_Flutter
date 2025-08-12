import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:street_buddy/models/message.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/message_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/screens/MainScreens/Messages/message_parts.dart';
import 'package:street_buddy/widgets/crop_image_screen.dart';
import 'package:street_buddy/screens/MainScreens/Profile/view_profile_screen.dart';
import 'package:street_buddy/utils/styles.dart';

class PersonalMessageScreen extends StatefulWidget {
  final String currentUserid;
  const PersonalMessageScreen({super.key, required this.currentUserid});

  @override
  State<PersonalMessageScreen> createState() => _PersonalMessageScreenState();
}
 
class _PersonalMessageScreenState extends State<PersonalMessageScreen> {
  TextEditingController textEditingController = TextEditingController();
  FocusNode textFieldFocusNode = FocusNode();
  bool isSend = false;
  bool isEmojiPickerVisible = false;
  List<ChatMessageModel> list = [];
  UserModel? currentUser;
  late Stream<QuerySnapshot<Map<String, dynamic>>> messagesData;
  late Stream<bool> isOnlineData;
  final MessageProvider _messageProvider = MessageProvider();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onEmojiSelected(Emoji emoji) {
    textEditingController.text += emoji.emoji;
    setState(() {
      isSend = textEditingController.text.isNotEmpty;
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      isEmojiPickerVisible = !isEmojiPickerVisible;
    });

    if (isEmojiPickerVisible) {
      // Hide keyboard when emoji picker is shown
      textFieldFocusNode.unfocus();
    } else {
      // Show keyboard when emoji picker is hidden
      textFieldFocusNode.requestFocus();
    }
  }

  Future<void> pickMedia(BuildContext context, ImageSource source, bool isVideo,
      UserModel currentUser) async {
    final picker = ImagePicker();
    try {
      final XFile? media = isVideo
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(source: source);

      print('📸 [DEBUG] Media picked: '
          'type=${isVideo ? '🎥 video' : '🖼️ image'}, path=${media?.path}');

      if (media != null && mounted) {
        File resultimagefile;

        if (!isVideo) {
          File? img = File(media.path);
          print('🖼️ [DEBUG] Image file created, path=${img.path}');
          // img = await _cropImage(imageFile: img);
          resultimagefile = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CropImageScreen(image: img),
              ));
          print(
              '✂️ [DEBUG] Image cropped, result path=${resultimagefile.path}');
        } else {
          resultimagefile = File(media.path);
          print('🎥 [DEBUG] Video file created, path=${resultimagefile.path}');
        }

        Provider.of<UploadProvider>(context, listen: false).setMedia(
            resultimagefile, isVideo ? PostType.video : PostType.image);
        print(
            '📤 [DEBUG] Media set in UploadProvider, type=${isVideo ? '🎥 video' : '🖼️ image'}');

        // context.push('/upload/info');
        if (mounted) {
          print('🚀 [DEBUG] Navigating to SendMediaScreen');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SendMediaScreen(
                user: currentUser,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [DEBUG] Error picking media: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking media: $e')),
        );
      }
    }
  }

  void getUser() async {
    try {
      final user =
          await _messageProvider.getMyUsersReturn(widget.currentUserid);
      if (mounted) {
        setState(() {
          currentUser = user;
          messagesData = MessageProvider.getAllMessages(user);
          isOnlineData = ProfileProvider()
              .checkOnlineStatus(widget.currentUserid)
              .asStream();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return currentUser == null
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewProfileScreen(
                          userId: currentUser!.uid,
                          isOwnProfile: false,
                        ),
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundImage: currentUser!.profileImageUrl != null
                          ? NetworkImage(currentUser!.profileImageUrl!)
                          : null,
                      child: currentUser!.profileImageUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ),
                  const SizedBox(
                    width: AppSpacing.sm,
                  ),
                  // Show username beside profile picture
                  Text(
                    currentUser!.username,
                    style: AppTypography.body,
                  ),
                  // StreamBuilder for online/offline status commented out
                  // StreamBuilder(
                  //     stream: isOnlineData,
                  //     builder: (context, snapshot) {
                  //       if (snapshot.connectionState ==
                  //           ConnectionState.waiting) {
                  //         return const Text(
                  //           '',
                  //           style: AppTypography.caption,
                  //         );
                  //       }
                  //
                  //       return Wrap(
                  //         direction: Axis.vertical,
                  //         children: [
                  //           Text(currentUser!.username),
                  //           snapshot.data != null && snapshot.data == true
                  //               ? const Text(
                  //                   'Online',
                  //                   style: AppTypography.link,
                  //                 )
                  //               : const Text(
                  //                   'Recently active',
                  //                   style: AppTypography.caption,
                  //                 ),
                  //         ],
                  //       );
                  //     }),
                ],
              ),
              actions: [
                PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20),
                                SizedBox(width: 8),
                                Text('Delete conversation'),
                              ],
                            ),
                            onTap: () async {
                              if (currentUser != null) {
                                await _messageProvider
                                    .deleteConversation(currentUser!.uid);
                                if (mounted) Navigator.pop(context);
                              }
                            },
                          ),
                        ]),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                      stream: messagesData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final data = snapshot.data?.docs;
                        list = data
                                ?.map(
                                    (e) => ChatMessageModel.fromJson(e.data()))
                                .toList() ??
                            [];

                        // Mark incoming messages as read
                        // Fixed code to safely handle null or empty read field
                        for (var message in list) {
                          if (message.fromId != MessageProvider.user.uid &&
                              (message.read == null || message.read!.isEmpty)) {
                            MessageProvider.updateMessageReadStatus(message);
                          }
                        }

                        if (list.isNotEmpty) {
                          return ListView.builder(
                              itemCount: list.length,
                              reverse: true,
                              itemBuilder: (context, index) {
                                final message = list[index];
                                return MessageCard(
                                  message: message,
                                  thisId: MessageProvider.user.uid,
                                  otherUserId: currentUser?.uid,
                                );
                              });
                        } else {
                          return const Center(
                            child: Text('Say Hii! 👋',
                                style: TextStyle(fontSize: 20)),
                          );
                        }
                      }),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.xs,
                    bottom: isEmojiPickerVisible
                        ? 8
                        : MediaQuery.of(context).viewPadding.bottom + 16,
                  ),
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: textEditingController,
                      focusNode: textFieldFocusNode,
                      onChanged: (value) => setState(() {
                        isSend = value.isNotEmpty;
                      }),
                      onTap: () {
                        if (isEmojiPickerVisible) {
                          setState(() {
                            isEmojiPickerVisible = false;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        prefixIcon: IconButton(
                          icon: Icon(
                            isEmojiPickerVisible
                                ? Icons.keyboard
                                : Icons.emoji_emotions_outlined,
                          ),
                          onPressed: _toggleEmojiPicker,
                        ),
                        suffixIcon: !isSend
                            ? IconButton(
                                icon: const Icon(Icons.attach_file),
                                onPressed: () {
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (context) => CupertinoActionSheet(
                                      actions: [
                                        CupertinoActionSheetAction(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              pickMedia(
                                                  _scaffoldKey.currentContext!,
                                                  ImageSource.camera,
                                                  false,
                                                  currentUser!);
                                            },
                                            child: const Text('Camera')),
                                        CupertinoActionSheetAction(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              pickMedia(
                                                  _scaffoldKey.currentContext!,
                                                  ImageSource.gallery,
                                                  false,
                                                  currentUser!);
                                            },
                                            child: const Text('Gallery')),
                                        CupertinoActionSheetAction(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              pickMedia(
                                                  _scaffoldKey.currentContext!,
                                                  ImageSource.gallery,
                                                  true,
                                                  currentUser!);
                                            },
                                            child: const Text('Video'))
                                      ],
                                    ),
                                  );
                                },
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Color(0xFFED7014),
                                ),
                                onPressed: () {
                                  if (textEditingController.text.isNotEmpty &&
                                      currentUser != null) {
                                    final message =
                                        textEditingController.text.trim();
                                    MessageProvider.sendMessage(
                                        currentUser!, message, 'text');
                                    textEditingController.clear();
                                    setState(() {
                                      isSend = false;
                                    });
                                  }
                                },
                              ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                if (isEmojiPickerVisible)
                  SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) =>
                          _onEmojiSelected(emoji),
                      config: const Config(
                        height: 256,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: EmojiViewConfig(
                          columns: 7,
                          emojiSizeMax: 32,
                          verticalSpacing: 0,
                          horizontalSpacing: 0,
                          gridPadding: EdgeInsets.zero,
                          backgroundColor: Color(0xFFF2F2F2),
                          recentsLimit: 28,
                          replaceEmojiOnLimitExceed: false,
                        ),
                        skinToneConfig: SkinToneConfig(),
                        categoryViewConfig: CategoryViewConfig(
                          backgroundColor: Color(0xFFF2F2F2),
                          indicatorColor: Colors.orange,
                          iconColorSelected: Colors.orange,
                          iconColor: Colors.grey,
                          categoryIcons: CategoryIcons(),
                        ),
                        bottomActionBarConfig: BottomActionBarConfig(
                          backgroundColor: Color(0xFFF2F2F2),
                          buttonColor: Colors.orange,
                        ),
                        searchViewConfig: SearchViewConfig(
                          backgroundColor: Color(0xFFF2F2F2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
  }
}
