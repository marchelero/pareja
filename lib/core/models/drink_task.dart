enum DrinkTarget {
  he,
  she,
  both,
  none,
  winner,
  loser,
  random,
}

enum DrinkType {
  rule,
  challenge,
  game,
}

enum DrinkCategory {
  question, // A - Pregunta
  challenge, // B - Reto
  punishment, // C - Castigo
  decision, // D - Decisión
}

enum DrinkGender {
  male,
  female,
  any,
}

class DrinkTask {
  final String id;
  final String text;
  final DrinkTarget target;
  final DrinkType type; // Deprecated conceptually, replaced by category for UI, but kept for compatibility or mapped
  final DrinkCategory category;
  final int intensity; // 1-7
  final bool isHot;
  final int sips; // Sorbos base si se pierde o aplica
  final DrinkGender gender;

  DrinkTask({
    required this.id,
    required this.text,
    required this.target,
    required this.type,
    required this.category,
    required this.intensity,
    required this.isHot,
    this.sips = 1,
    this.gender = DrinkGender.any,
  });

  factory DrinkTask.fromJson(Map<String, dynamic> json) {
    // Map old types or use existing logic if needed, but we will update JSON
    DrinkCategory cat = DrinkCategory.question;
    if (json['category'] != null) {
      cat = DrinkCategory.values.firstWhere((e) => e.toString().split('.').last == json['category']);
    } else {
      // Fallback mapping
      String t = json['type'] ?? 'rule';
      if (t == 'rule') cat = DrinkCategory.punishment;
      if (t == 'game') cat = DrinkCategory.challenge;
      if (t == 'challenge') cat = DrinkCategory.challenge;
    }

    DrinkGender gen = DrinkGender.any;
    if (json['gender'] != null) {
      gen = DrinkGender.values.firstWhere((e) => e.toString().split('.').last == json['gender']);
    }

    return DrinkTask(
      id: json['id'],
      text: json['text'],
      target: DrinkTarget.values.firstWhere((e) => e.toString().split('.').last == json['target']),
      type: DrinkType.values.firstWhere((e) => e.toString().split('.').last == json['type']),
      category: cat,
      intensity: json['intensity'],
      isHot: json['isHot'] ?? false,
      sips: json['sips'] ?? 1,
      gender: gen,
    );
  }
}
