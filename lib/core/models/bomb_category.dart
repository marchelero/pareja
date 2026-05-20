class BombCategory {
  final String id;
  final String text;
  final bool isHot;

  BombCategory({
    required this.id,
    required this.text,
    required this.isHot,
  });

  factory BombCategory.fromJson(Map<String, dynamic> json) {
    return BombCategory(
      id: json['id'] as String,
      text: json['text'] as String,
      isHot: json['isHot'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isHot': isHot,
    };
  }
}
