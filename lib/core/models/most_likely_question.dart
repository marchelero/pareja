class MostLikelyQuestion {
  final int id;
  final String text;
  final bool isHot;

  MostLikelyQuestion({
    required this.id,
    required this.text,
    required this.isHot,
  });

  factory MostLikelyQuestion.fromJson(Map<String, dynamic> json) {
    return MostLikelyQuestion(
      id: json['id'] as int,
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
