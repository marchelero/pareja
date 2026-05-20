enum Target { male, female, any }

class Question {
  final int id;
  final String text;
  final String category;
  final Target target;
  final bool isSuddenDeath;

  Question({
    required this.id,
    required this.text,
    required this.category,
    required this.target,
    this.isSuddenDeath = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      category: json['category'],
      target: _parseTarget(json['target']),
      isSuddenDeath: json['isSuddenDeath'] ?? false,
    );
  }

  static Target _parseTarget(String target) {
    switch (target.toLowerCase()) {
      case 'male':
        return Target.male;
      case 'female':
        return Target.female;
      default:
        return Target.any;
    }
  }
}
