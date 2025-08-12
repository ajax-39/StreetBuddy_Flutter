class Like {
  final String postid;
  final int likes;
  final List likedby;
  final String userid;

  Like({
    required this.likes,
    required this.likedby,
    required this.userid,
    required this.postid,
  });

  factory Like.fromMap(Map<String, dynamic> map) {
    return Like(
      postid: map['postid'] as String,
      likes: map['likes'] as int,
      likedby: map['likedby'] as List,
      userid: map['userid'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postid': postid,
      'likes': likes,
      'likedby': likedby,
      'userid': userid,
    };
  }
}
