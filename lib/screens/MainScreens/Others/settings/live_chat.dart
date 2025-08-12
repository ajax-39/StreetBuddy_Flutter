import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/message.dart';
import 'package:street_buddy/utils/styles.dart';

class LiveSupportScreen extends StatefulWidget {
  const LiveSupportScreen({super.key});

  @override
  State<LiveSupportScreen> createState() => _LiveSupportScreenState();
}

class _LiveSupportScreenState extends State<LiveSupportScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;

    final newMessage = ChatMessageModel(
        toId: 'support',
        msg: message,
        read: null,
        type: 'text',
        sent: DateTime.now().toString(),
        fromId: globalUser?.uid);

    try {
      await supabase.from('support').insert({
        ...newMessage.toJson(),
        'userId': globalUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Live Support",
            style: TextStyle(
              fontSize: 18,
              fontWeight: fontregular,
            )),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSupportHeader(),
            Expanded(child: _buildChatMessages()),
            _buildMessageInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportHeader() {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
        color: Colors.black.withOpacity(0.1),
      )),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(
                'assets/icon/newlogo.png',
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Street Buddy Support",
                    style: TextStyle(fontSize: 16, fontWeight: fontmedium)),
                Text("Usually responds in 2-3 mins",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: fontregular)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessages() {
    return FutureBuilder<List<ChatMessageModel>>(
        future: supabase
            .from('support')
            .select('*')
            .eq('userId', globalUser?.uid ?? '')
            .order('created_at', ascending: true)
            .then(
              (value) => value
                  .map(
                    (e) => ChatMessageModel.fromJson(e),
                  )
                  .toList(),
            ),
        builder: (context, snapshot) {
          // Handle error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load messages',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  TextButton(
                    onPressed: () => setState(() {}), // Refresh
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }

          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check if there's data and it's not empty
          final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;

          List<ChatMessageModel> messages = [
            ChatMessageModel(
                toId: globalUser?.uid ?? '',
                msg: 'Hi, how can I help you?',
                read: null,
                type: 'text',
                sent: hasData
                    ? snapshot.data!.first.sent
                    : DateTime.now().toString(),
                fromId: 'support'),
            ...(snapshot.data ?? []),
          ];

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            reverse: false, // Keep messages in chronological order
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return message.fromId == globalUser?.uid
                  ? _buildMyChatBubble(message)
                  : _buildSupportChatBubble(message);
            },
          );
        });
  }

  Widget _buildMessageInputField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 41,
              child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: "Type your message...",
                    hintStyle: TextStyle(
                      color: const Color(0xff1E1E1E).withOpacity(0.3),
                      fontSize: 14,
                      fontWeight: fontregular,
                    ),
                    contentPadding: const EdgeInsets.only(left: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Color(0xff777777),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Color(0xff777777),
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Image.asset(
                            'assets/icon/attach.png',
                            width: 23,
                          ),
                          onPressed: () {
                            // Implement attachment functionality
                          },
                        ),
                        IconButton(
                          icon: Image.asset(
                            'assets/icon/image-plus.png',
                            width: 23,
                          ),
                          onPressed: () {
                            // Implement image upload functionality
                          },
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.send, color: AppColors.primary),
                          onPressed: () async {
                            if (_messageController.text.trim().isNotEmpty) {
                              await sendMessage(_messageController.text);
                              _messageController.clear();
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (value) async {
                    if (value.trim().isNotEmpty) {
                      await sendMessage(value);
                      _messageController.clear();
                      setState(() {});
                    }
                  }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyChatBubble(ChatMessageModel message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  // width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 11)
                          .copyWith(left: 31),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16)
                        .copyWith(topRight: Radius.zero),
                  ),
                  child: Text(
                    message.msg ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: fontregular,
                    ),
                  ),
                ),
                Text(
                  DateFormat('hh:mm a    ').format(
                    DateTime.parse(message.sent ?? ''),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: fontregular,
                    color: Colors.black.withOpacity(0.6),
                  ),
                )
              ],
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(
              globalUser?.profileImageUrl ?? '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportChatBubble(ChatMessageModel message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundImage: AssetImage(
            'assets/icon/newnewlogo.png',
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                // width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 14,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 11)
                    .copyWith(right: 31),
                decoration: BoxDecoration(
                  color: const Color(0xffF3F4F6),
                  borderRadius:
                      BorderRadius.circular(16).copyWith(topLeft: Radius.zero),
                ),
                child: Text(
                  message.msg ?? "",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: fontregular,
                  ),
                ),
              ),
              Text(
                DateFormat('    hh:mm a').format(
                  DateTime.parse(message.sent ?? ''),
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: fontregular,
                  color: Colors.black.withOpacity(0.6),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
