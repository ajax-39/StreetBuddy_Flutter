class FnotificationModel {
  final String id;
  final String token;
  final String title;
  final String body;
  final String route;
  final String type;
  final String? image;

  FnotificationModel({
    required this.id,
    required this.token,
    required this.title,
    required this.body,
    required this.route,
    required this.type,
    this.image,
  });

  factory FnotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return FnotificationModel(
      id: id,
      token: map['token'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      route: map['route'] ?? '',
      type: map['type'] ?? '',
      image: map['image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'title': title,
      'body': body,
      'route': route,
      'type': type,
      'image': image,
    };
  }

  // // Update copyWith method
  // FnotificationModel copyWith({
  //   String? type,
  //   String? typeName,
  //   String? experience,
  //   String? tips,
  //   List<String>? mediaUrls,
  //   String? image,
  // }) {
  //   return FnotificationModel(
  //     id: id,
  //     token: token,
  //     title: title,
  //     body: body,
  //     route: route,
  //     type: type ?? this.type,
  //     typeName: typeName ?? this.typeName,
  //     experience: experience ?? this.experience,
  //     tips: tips ?? this.tips,
  //     mediaUrls: mediaUrls ?? this.mediaUrls,
  //     image: image ?? this.image,
  //     createdAt: createdAt,
  //   );
  // }
}
