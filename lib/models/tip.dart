class TipModel {
  final String id;
  final String guideId;
  final String tipText;
  final int likes;
  final int dislikes;

  TipModel({
    required this.id,
    required this.guideId,
    required this.tipText,
    this.likes = 0,
    this.dislikes = 0,
  });

  factory TipModel.fromMap(String id, Map<String, dynamic> map) {
    return TipModel(
      id: id,
      guideId: map['guide_id'] ?? '',
      tipText: map['tip_text'] ?? '',
      likes: (map['likes'] ?? 0).toInt(),
      dislikes: (map['dislikes'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guide_id': guideId,
      'tip_text': tipText,
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  TipModel copyWith({
    String? id,
    String? guideId,
    String? tipText,
    int? likes,
    int? dislikes,
  }) {
    return TipModel(
      id: id ?? this.id,
      guideId: guideId ?? this.guideId,
      tipText: tipText ?? this.tipText,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
    );
  }
}
