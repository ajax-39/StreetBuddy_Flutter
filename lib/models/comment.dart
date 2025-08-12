
class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String userProfileImage;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommentModel(
      id: id,
      postId: map['post_id'] ?? '',
      userId: map['user_id'] ?? '',
      username: map['username'] ?? '',
      userProfileImage: map['user_profile_image'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['created_at'] is DateTime
          ? map['created_at']
          : DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'post_id': postId,
      'user_id':
          userId, 
      'username': username,
      'user_profile_image':
          userProfileImage,
      'content': content,
      'created_at':
          createdAt.toIso8601String(),
    };
  }
}
