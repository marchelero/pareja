class Player {
  String name;
  int score;
  int perfectAnswers; // 2 points / 2 stars
  int partialAnswers; // 1 point / 1 star
  int failedAnswers;  // 0 points / X
  int suddenDeathPoints; // 7 points if correct in sudden death
  bool suddenDeathCorrect; // true if answered correctly in sudden death

  Player({
    required this.name,
    this.score = 0,
    this.perfectAnswers = 0,
    this.partialAnswers = 0,
    this.failedAnswers = 0,
    this.suddenDeathPoints = 0,
    this.suddenDeathCorrect = false,
  });

  void reset() {
    score = 0;
    perfectAnswers = 0;
    partialAnswers = 0;
    failedAnswers = 0;
    suddenDeathPoints = 0;
    suddenDeathCorrect = false;
  }
}
