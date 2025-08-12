import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/message.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/services/notification_sender.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageProvider extends ChangeNotifier {
  // Delete all messages and chat document for a conversation
  Future<void> deleteConversation(String otherUserId) async {
    try { 
      final convId = getConversationID(otherUserId);
      final messagesRef = firestore.collection('chats/$convId/messages/');
      final messagesSnapshot = await messagesRef.get();
      // Delete all messages
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }
      // Optionally delete the chat document itself (if you have metadata)
      // await firestore.collection('chats').doc(convId).delete();
      // Remove from both users' myusers list
      await firestore
          .collection('users/${user.uid}/myusers/')
          .doc(otherUserId)
          .delete();
      await firestore
          .collection('users/$otherUserId/myusers/')
          .doc(user.uid)
          .delete();
      debugPrint('✅ Conversation and messages deleted for $convId');
    } catch (e) {
      debugPrint('❌ Error deleting conversation: $e');
    }
  }

  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;
  final supabaseClient = Supabase.instance.client;

  // Get user from global variable that's populated from Supabase
  static UserModel get user => globalUser!;

  List<UserModel> myUserslist = [];
  List<String> myUsersIdlist = [];

  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool isSearching = false;
  List<UserModel> following = [];

  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      UserModel user) {
    return firestore
        .collection('chats/${getConversationID(user.uid)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersStream() {
    return firestore.collection('users/${user.uid}/myusers/').snapshots();
  }

  //? send individual message
  static Future<void> sendMessage(
      UserModel chatUser, String msg, String type) async {
    //message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    //message to send
    final ChatMessageModel message = ChatMessageModel(
        toId: chatUser.uid,
        msg: msg,
        read: '',
        type: type,
        fromId: user.uid,
        sent: time);

    try {
      debugPrint('✉️ Sending message to ${chatUser.uid}: "$msg"');
      final ref = firestore
          .collection('chats/${getConversationID(chatUser.uid)}/messages/');
      await ref.doc(time).set(message.toJson());
      await firestore
          .collection('users/${user.uid}/myusers/')
          .doc(chatUser.uid)
          .set({'convId': getConversationID(chatUser.uid)});
      await firestore
          .collection('users/${chatUser.uid}/myusers/')
          .doc(user.uid)
          .set({'convId': getConversationID(chatUser.uid)});

      //? send notification
      NotificationSender().sendMessage(chatUser, msg);
      debugPrint('✅ Message sent to ${chatUser.uid}');
    } catch (e) {
      debugPrint('❌ Error sending msg: $e');
      rethrow;
    }
  }

  //? message read status updating
  static Future<void> updateMessageReadStatus(ChatMessageModel message) async {
    debugPrint(
        '👀 Marking message as read: ${message.sent} from ${message.fromId}');
    await firestore
        .collection(
            'chats/${getConversationID(message.fromId.toString())}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
    debugPrint('✅ Message marked as read: ${message.sent}');
  }

  static bool isNewMessage(QuerySnapshot<Map<String, dynamic>> snap) {
    final data = snap.docs.first.data();

    return data['read'].toString().isEmpty &&
        data['fromId'].toString() != user.uid;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      UserModel user) {
    return firestore
        .collection('chats/${getConversationID(user.uid)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //? fetch users model from list of user ids using Supabase
  Future<void> getMyUsers(List<String> myUsersIdList) async {
    try {
      debugPrint('🔄 Fetching user models for IDs: $myUsersIdList');
      if (myUsersIdList.isEmpty) {
        myUserslist = [];
        debugPrint('⚠️ No user IDs provided, user list cleared.');
      } else {
        List<UserModel> finalList = [];
        for (var uid in myUsersIdList) {
          try {
            debugPrint('🔍 Fetching user from Supabase: $uid');
            final response = await supabaseClient
                .from('users')
                .select()
                .eq('uid', uid)
                .single();

            final userData = response;
            finalList.add(UserModel.fromMap(userData['uid'], userData));
            debugPrint('✅ User fetched: ${userData['uid']}');
          } catch (e) {
            debugPrint('❌ Error fetching user $uid: $e');
          }
        }
        myUserslist = finalList;
        debugPrint('✅ User list updated, total: ${myUserslist.length}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
      rethrow;
    }
  }

  Future<UserModel> getMyUsersReturn(String myUsersId) async {
    try {
      debugPrint('🔍 Fetching single user from Supabase: $myUsersId');
      final response = await supabaseClient
          .from('users')
          .select()
          .eq('uid', myUsersId)
          .single();

      final userData = response;
      debugPrint('✅ User fetched: ${userData['uid']}');
      return UserModel.fromMap(userData['uid'], userData);
    } catch (e) {
      debugPrint('❌ Error searching user $myUsersId: $e');
      rethrow;
    }
  }

  //? search in users following list using Supabase
  Future<List<UserModel>> searchFollowing(String searchQuery) async {
    if (searchQuery.isEmpty) {
      debugPrint('🔎 Search query is empty, returning empty list.');
      return [];
    }

    try {
      debugPrint('🔎 Searching following for query: "$searchQuery"');
      final currentUser = globalUser;
      if (currentUser == null) {
        debugPrint('⚠️ No current user found.');
        return [];
      }

      // Get following from the current user's following array
      final followingList = currentUser.following ?? [];

      if (followingList.isEmpty) {
        debugPrint('⚠️ No following users found.');
        return [];
      }

      // Get user data for all following users with username match
      final response = await supabaseClient
          .from('users')
          .select()
          .inFilter('uid', followingList)
          .ilike('username', '%$searchQuery%');

      if (response.isEmpty) {
        debugPrint('🔎 No users found matching "$searchQuery".');
        return [];
      }

      debugPrint(
          '✅ Found ${(response as List).length} users matching "$searchQuery".');
      return (response as List)
          .map((userData) => UserModel.fromMap(
              userData['uid'], userData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching following: $e');
      rethrow;
    }
  }

  Future<void> performSearch(String query, BuildContext context) async {
    if (query.isEmpty) {
      debugPrint('🔎 Search query is empty, clearing search.');
      clearSearch();
      return;
    }

    isSearching = true;
    notifyListeners();

    try {
      debugPrint('🔎 Performing search for "$query"');
      List<UserModel> users = await searchFollowing(query);
      following = users;
      debugPrint('✅ Search complete, found ${users.length} users.');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error performing search: ${e.toString()}')),
      );
      clearSearch();
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    searchController.clear();
    following = [];
    isSearching = false;
    notifyListeners();
  }

  //? delete a user in message list
  Future<void> deleteMyUser(String id) async {
    try {
      debugPrint('🗑️ Deleting user from message list: $id');
      await firestore.collection('users/${user.uid}/myusers/').doc(id).delete();
      debugPrint('✅ User $id deleted from message list');
    } catch (e) {
      debugPrint('❌ Error deleting user $id: $e');
    }
  }

  //? delete or unsend a message
  Future<void> unsendMessage(ChatMessageModel message, String id) async {
    try {
      debugPrint(
          '🚫 Unsend message: ${message.sent} for conversation with $id');
      await firestore
          .collection('chats/${getConversationID(id)}/messages/')
          .doc(message.sent)
          .delete();
      debugPrint('✅ Message ${message.sent} unsent for conversation with $id');
    } catch (e) {
      debugPrint('❌ Error unsending message ${message.sent}: $e');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }
}
