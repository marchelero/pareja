class NeverHaveIEverQuestion {
  final int id;
  final String text;
  final bool isHot;

  NeverHaveIEverQuestion({
    required this.id,
    required this.text,
    required this.isHot,
  });

  factory NeverHaveIEverQuestion.fromJson(Map<String, dynamic> json) {
    return NeverHaveIEverQuestion(
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
