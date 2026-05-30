class CharadesWord {
  final int id;
  final String word;
  final String category;
  final bool isHot;

  CharadesWord({
    required this.id,
    required this.word,
    required this.category,
    required this.isHot,
  });

  factory CharadesWord.fromJson(Map<String, dynamic> json) {
    return CharadesWord(
      id: json['id'] as int,
      word: json['word'] as String,
      category: json['category'] as String,
      isHot: json['isHot'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'isHot': isHot,
      'category': category,
    };
  }
}
