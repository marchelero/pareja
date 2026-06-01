import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/models/charades_word.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

class CharadesController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final List<String> selectedCategories;
  final bool singleCategoryMode;
  final int timerSeconds;
  final int pointsToWin;
  final int strikesForPenance;
  final bool isHotMode;

  CharadesController({
    required this.audioService,
    required this.settingsProvider,
    required this.selectedCategories,
    required this.singleCategoryMode,
    required this.timerSeconds,
    required this.pointsToWin,
    required this.strikesForPenance,
    required this.isHotMode,
  });

  List<CharadesWord> _allWords = [];
  List<CharadesWord> _availableWords = [];
  CharadesWord? _currentWord;
  bool _isLoading = true;
  bool _isPlaying = false;
  int _timeLeft = 0;
  Timer? _timer;
  int _scoreHe = 0;
  int _scoreShe = 0;
  int _strikesHe = 0;
  int _strikesShe = 0;
  bool _isHeTurn = true;
  bool _turnReady = false;
  bool _roundDone = false;
  bool _wasGuessed = false;
  String? _penanceText;
  String? _winner;
  String? _matchPointPlayer;

  void Function(String winnerName)? onGameWinner;

  bool get isLoading => _isLoading;
  CharadesWord? get currentWord => _currentWord;
  bool get isHeTurn => _isHeTurn;
  bool get isPlaying => _isPlaying;
  int get timeLeft => _timeLeft;
  bool get turnReady => _turnReady;
  bool get roundDone => _roundDone;
  bool get wasGuessed => _wasGuessed;
  int get scoreHe => _scoreHe;
  int get scoreShe => _scoreShe;
  int get strikesHe => _strikesHe;
  int get strikesShe => _strikesShe;
  String get heName => settingsProvider.heName;
  String get sheName => settingsProvider.sheName;
  String get currentPlayerName => _isHeTurn ? heName : sheName;
  String get partnerName => _isHeTurn ? sheName : heName;
  String? get penanceText => _penanceText;
  String? get winner => _winner;

  Future<void> initGame() async {
    try {
      final String jsonStr =
          await rootBundle.loadString('assets/data/charades_words.json');
      final List<dynamic> data = json.decode(jsonStr);
      _allWords = data.map((j) => CharadesWord.fromJson(j)).toList();
    } catch (e) {
      _allWords = [];
    }

    _availableWords = _allWords.where((w) {
      if (!selectedCategories.contains(w.category)) return false;
      if (w.isHot && !isHotMode) return false;
      return true;
    }).toList();

    // Si el modo es categoría única, seleccionar una al azar
    if (singleCategoryMode && selectedCategories.isNotEmpty) {
      final random = Random();
      final chosenCategory =
          selectedCategories[random.nextInt(selectedCategories.length)];
      _availableWords =
          _availableWords.where((w) => w.category == chosenCategory).toList();
    }

    _availableWords.shuffle();
    _isLoading = false;
    notifyListeners();
  }

  void showNewWord() {
    if (_availableWords.isEmpty) {
      _availableWords = _allWords.where((w) {
        if (!selectedCategories.contains(w.category)) return false;
        if (w.isHot && !isHotMode) return false;
        return true;
      }).toList();

      // Mantener la categoría única si el modo está activo
      if (singleCategoryMode && selectedCategories.isNotEmpty && _currentWord != null) {
        _availableWords = _availableWords
            .where((w) => w.category == _currentWord!.category)
            .toList();
      }

      _availableWords.shuffle();
    }

    _currentWord = _availableWords.removeAt(0);
    _turnReady = false;
    _roundDone = false;
    _wasGuessed = false;
    _isPlaying = false;
    notifyListeners();
  }

  void startTurn() {
    _isPlaying = true;
    _turnReady = true;
    _timeLeft = timerSeconds;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        _timeOut();
      }
    });
  }

  void guessCorrect() {
    _timer?.cancel();
    _isPlaying = false;
    _wasGuessed = true;
    _roundDone = true;

    if (_isHeTurn) {
      _scoreHe++;
    } else {
      _scoreShe++;
    }

    notifyListeners();

    if (_matchPointPlayer == null &&
        ((_isHeTurn && _scoreHe >= pointsToWin) ||
         (!_isHeTurn && _scoreShe >= pointsToWin))) {
      _matchPointPlayer = currentPlayerName;
    }
  }

  void _timeOut() {
    _timer?.cancel();
    _isPlaying = false;
    _roundDone = true;
    _wasGuessed = false;

    final random = Random().nextInt(4);
    switch (random) {
      case 0:
        _strikesHe++;
        break;
      case 1:
        _strikesShe++;
        break;
      case 2:
        _strikesHe++;
        _strikesShe++;
        break;
      case 3:
        break;
    }

    notifyListeners();
    _checkPenance();
  }

  void _checkPenance() {
    if (_strikesHe >= strikesForPenance) {
      _penanceText = 'Penitencia para $heName';
    } else if (_strikesShe >= strikesForPenance) {
      _penanceText = 'Penitencia para $sheName';
    }
    if (_penanceText != null) {
      notifyListeners();
    }
  }

  void clearPenance() {
    _penanceText = null;
    if (_strikesHe >= strikesForPenance) _strikesHe = 0;
    if (_strikesShe >= strikesForPenance) _strikesShe = 0;
    notifyListeners();
  }

  void nextRound() {
    _isHeTurn = !_isHeTurn;
    _turnReady = false;
    _roundDone = false;
    _wasGuessed = false;
    _isPlaying = false;
    _timer?.cancel();

    if (_matchPointPlayer != null && currentPlayerName == _matchPointPlayer) {
      _finishGameOrContinue();
      if (_winner != null) {
        notifyListeners();
        onGameWinner?.call(_winner!);
        return;
      }
    }

    showNewWord();
  }

  void _finishGameOrContinue() {
    if (_scoreHe == _scoreShe) {
      _matchPointPlayer = null;
      return;
    }

    _winner = _scoreHe > _scoreShe ? heName : sheName;
  }

  void cancelTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
