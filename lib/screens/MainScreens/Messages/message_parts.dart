import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/message.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:street_buddy/provider/MainScreen/message_provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/custom_video_player.dart';

class MessageCard extends StatelessWidget {
  final ChatMessageModel message;
  final String thisId;
  final String? otherUserId;
  const MessageCard(
      {super.key,
      required this.message,
      required this.thisId,
      this.otherUserId});

  @override
  Widget build(BuildContext context) {
    return message.fromId == thisId
        ? rightCard(context, message)
        : leftCard(context, message);
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : hour;
      return '$displayHour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  Widget leftCard(BuildContext context, ChatMessageModel message) {
    if (message.read != null && message.read!.isEmpty) {
      MessageProvider.updateMessageReadStatus(message);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: GestureDetector(
                onLongPress: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => CupertinoActionSheet(
                      actions: [
                        CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Clipboard.setData(
                                  ClipboardData(text: message.msg.toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Text copied to clipboard!')),
                              );
                            },
                            child: const Text('Copy')),
                        if (otherUserId != null)
                          CupertinoActionSheetAction(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                try {
                                  await MessageProvider().unsendMessage(
                                    message,
                                    otherUserId!,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Message deleted')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to delete message: $e')),
                                  );
                                }
                              },
                              child: const Text('Delete')),
                      ],
                    ),
                  );
                },
                child: message.type == 'image' || message.type == 'video'
                    ? mediaPreviewCard(context, message)
                    : message.type == 'post'
                        ? postPreviewCard(context, message)
                        : message.type == 'guide'
                            ? guidePreviewCard(context, message)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      message.msg.toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      _formatTimestamp(message.sent),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget postPreviewCard(BuildContext context, ChatMessageModel message) {
    String url = message.msg!.split(' ')[1];
    String username = message.msg!.split(' ').last;
    String route = message.msg!.split(' ').first;
    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shadowColor: Theme.of(context).primaryColor,
      margin: const EdgeInsets.all(AppSpacing.sm),
      child: InkWell(
        onTap: () => context.push(route),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 2,
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: url,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black45,
                child: Center(
                    child: Text(
                  "$username's post",
                  style: const TextStyle(color: Colors.white),
                )),
              ),
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.grid_on,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget guidePreviewCard(BuildContext context, ChatMessageModel message) {
    String url = message.msg!.split(' ')[1];
    String username = message.msg!.split(' ').last;
    String route = message.msg!.split(' ').first;
    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shadowColor: Theme.of(context).primaryColor,
      margin: const EdgeInsets.all(AppSpacing.sm),
      child: InkWell(
        onTap: () => context.push(route),
        child: Stack(
          children: [
            url != 'null'
                ? AspectRatio(
                    aspectRatio: 2,
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: url,
                    ),
                  )
                : AspectRatio(
                    aspectRatio: 2,
                    child: Container(
                      color: Colors.blueGrey,
                    )),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black45,
                child: Center(
                    child: Text(
                  "$username's guide",
                  style: const TextStyle(color: Colors.white),
                )),
              ),
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget mediaPreviewCard(BuildContext context, ChatMessageModel message) {
    final messageParts = message.msg!.split(' ');
    final String mediaUrl = messageParts.first;
    final bool isVideo = message.type == 'video';
    final String thumbnailUrl =
        isVideo && messageParts.length > 1 ? messageParts.last : '';

    return InkWell(
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (context) => GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: isVideo
                ? CustomVideoPlayer(
                    videoUrl: mediaUrl, thumbnailUrl: thumbnailUrl)
                : Image.network(
                    mediaUrl,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
      child: Card(
        semanticContainer: true,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shadowColor: Theme.of(context).primaryColor,
        margin: const EdgeInsets.all(AppSpacing.sm),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: isVideo && thumbnailUrl.isNotEmpty
                    ? thumbnailUrl
                    : mediaUrl,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            if (isVideo)
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isVideo ? Icons.videocam : Icons.image,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget rightCard(BuildContext context, ChatMessageModel message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Right message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Stack(
                children: [
                  GestureDetector(
                    onLongPress: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
                          actions: [
                            CupertinoActionSheetAction(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Clipboard.setData(ClipboardData(
                                      text: message.msg.toString()));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Text copied to clipboard!')),
                                  );
                                },
                                child: const Text('Copy')),
                            CupertinoActionSheetAction(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  if (otherUserId != null) {
                                    try {
                                      await MessageProvider().unsendMessage(
                                        message,
                                        otherUserId!,
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Message deleted')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Failed to delete message: $e')),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Unsend'))
                          ],
                        ),
                      );
                    },
                    child: message.type == 'image' || message.type == 'video'
                        ? mediaPreviewCard(context, message)
                        : message.type == 'post'
                            ? postPreviewCard(context, message)
                            : message.type == 'guide'
                                ? guidePreviewCard(context, message)
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFED7014),
                                          border: Border.all(
                                            color: const Color(0xFFD65A0A),
                                            width: 1,
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                            bottomLeft: Radius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          message.msg.toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatTimestamp(message.sent),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              message.read != null &&
                                                      message.read!.isNotEmpty
                                                  ? Icons.check_circle
                                                  : Icons.check_circle_outline,
                                              size: 14,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SendMediaScreen extends StatelessWidget {
  final UserModel user;
  const SendMediaScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Provider.of<UploadProvider>(context, listen: false).reset();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title:
              const Text('Send Media', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Consumer<UploadProvider>(builder: (context, state, child) {
            if (state.selectedMedia == null || state.mediaType == null) {
              return Container(
                height: 300,
                width: double.infinity,
                color: Colors.black,
                child: const Center(
                  child: Text(
                    'No media selected',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            if (state.mediaType == PostType.image) {
              return Image.file(
                state.selectedMedia!,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            } else if (state.mediaType == PostType.video) {
              return state.thumbnail != null
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.file(
                          state.thumbnail!,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
            }
            return Container(
              height: 300,
              width: double.infinity,
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Consumer2<UploadProvider, AuthenticationProvider>(
            builder: (context, uploadState, authProvider, child) {
          return FloatingActionButton.extended(
            onPressed: uploadState.isMsgValid && !uploadState.isUploading
                ? () async {
                    try {
                      uploadState.setUploading(true);

                      await uploadState.createMediaMessage(
                          user: authProvider.userModel!, chatUser: user);

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Media sent successfully!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send media: $e')),
                      );
                    } finally {
                      if (uploadState.isUploading) {
                        uploadState.setUploading(false);
                      }
                    }
                  }
                : null,
            backgroundColor: uploadState.isMsgValid && !uploadState.isUploading
                ? Theme.of(context).primaryColor
                : Colors.grey,
            label: uploadState.isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Send'),
            icon: const Icon(Icons.send_outlined),
          );
        }),
      ),
    );
  }
}
