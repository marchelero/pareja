import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/player.dart';
import '../../core/models/question.dart';
import '../../core/storage/local_storage.dart';
import '../../data/questions_repository.dart';
import 'questions_result_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../widgets/neon_background.dart';

class QuestionsGameScreen extends StatefulWidget {
  final int maxRounds;
  final List<String> categories;
  final bool startingPlayerIsHe;

  const QuestionsGameScreen({
    super.key,
    required this.maxRounds,
    required this.categories,
    required this.startingPlayerIsHe,
  });

  @override
  State<QuestionsGameScreen> createState() => _QuestionsGameScreenState();
}

class _QuestionsGameScreenState extends State<QuestionsGameScreen> {
  final QuestionsRepository _repository = QuestionsRepository();
  List<Question> _allQuestions = [];
  List<Question> _availableQuestions = [];
  late Player _playerHe;
  late Player _playerShe;
  Player? _currentPlayer;
  Question? _currentQuestion;
  Color _backgroundColor = Colors.blue;
  bool _isLoading = true;
  int _currentRound = 0;
  bool _isSuddenDeath = false;
  int _suddenDeathRound = 0;

  Color? _lastBackgroundColor;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/clic.mp3'));
    } catch (e) {
      // Ignore
    }
  }

  final Map<String, Color> _categoryColors = {
    'General': Colors.blue.shade600,
    'Romántico': Colors.pink.shade500,
    'Picante': Colors.deepOrange.shade600,
    'Convivencia': Colors.green.shade600,
    'Futuro': Colors.indigo.shade600,
    'Viajes': Colors.teal.shade600,
    'Pasatiempos': Colors.orange.shade700,
    'Valores': Colors.brown.shade600,
    'Humor': Colors.amber.shade800,
    'Profundo': Colors.blueGrey.shade700,
    'Trivia': Colors.purple.shade600,
    'Flirteo': Colors.red.shade700,
  };

  final List<Color> _statusColors = [
    const Color(0xFF128C7E), // Teal
    const Color(0xFF075E54), // Dark Teal
    const Color(0xFF34B7F1), // Light Blue
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF009688), // Teal
    const Color(0xFFFFC107), // Amber
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF4CAF50), // Green
    const Color(0xFFCDDC39), // Lime
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    final heName = await LocalStorage.getHeName();
    final sheName = await LocalStorage.getSheName();
    _playerHe = Player(name: heName.isEmpty ? 'ÉL' : heName);
    _playerShe = Player(name: sheName.isEmpty ? 'ELLA' : sheName);
    
    _allQuestions = await _repository.loadQuestions();
    
    // Filter by categories
    _availableQuestions = _allQuestions.where((q) {
      return widget.categories.contains(q.category);
    }).toList();

    if (_availableQuestions.isEmpty) {
      _availableQuestions = List.from(_allQuestions);
    }

    // Set starting player from coin flip
    _currentPlayer = widget.startingPlayerIsHe ? _playerHe : _playerShe;
    
    _nextTurn();
    
    setState(() {
      _isLoading = false;
    });
  }

  void _nextTurn() {
    // Check if sudden death is active
    if (_isSuddenDeath) {
      if (_suddenDeathRound >= 2) {
        // Both players have played in sudden death, finish
        _finishGame();
        return;
      }
      _suddenDeathRound++;
      
      // Alternate players in sudden death
      _currentPlayer = (_suddenDeathRound == 1) 
        ? (widget.startingPlayerIsHe ? _playerHe : _playerShe)
        : (widget.startingPlayerIsHe ? _playerShe : _playerHe);
      
      // Filter only sudden death questions
      List<Question> validQuestions = _allQuestions.where((q) {
        bool matchesPlayer = (_currentPlayer == _playerHe)
            ? (q.target == Target.male || q.target == Target.any)
            : (q.target == Target.female || q.target == Target.any);
        return matchesPlayer && q.isSuddenDeath;
      }).toList();
      
      if (validQuestions.isEmpty) {
        // Fallback to all questions if no sudden death ones found
        validQuestions = _allQuestions.where((q) {
          if (_currentPlayer == _playerHe) {
            return q.target == Target.male || q.target == Target.any;
          } else {
            return q.target == Target.female || q.target == Target.any;
          }
        }).toList();
      }

      _currentQuestion = validQuestions[Random().nextInt(validQuestions.length)];
      
      setState(() {
        _backgroundColor = _categoryColors[_currentQuestion?.category] ?? Colors.indigo;
      });
      return;
    }

    // Normal game flow
    if (_currentRound >= widget.maxRounds || _availableQuestions.isEmpty) {
      // Game ended, go to results
      _finishGame();
      return;
    }

    _currentRound++;

    // Alternating turns logic
    if (_currentRound > 1) {
      _currentPlayer = (_currentPlayer == _playerHe) ? _playerShe : _playerHe;
    }

    // Filter questions for current player
    List<Question> validQuestions = _availableQuestions.where((q) {
      if (_currentPlayer == _playerHe) {
        return q.target == Target.male || q.target == Target.any;
      } else {
        return q.target == Target.female || q.target == Target.any;
      }
    }).toList();

    if (validQuestions.isEmpty) {
      // If no valid questions left for this player, finish the game
      _finishGame();
      return;
    }

    // Choose random question
    _currentQuestion = validQuestions[Random().nextInt(validQuestions.length)];
    _availableQuestions.remove(_currentQuestion);
    
    setState(() {
      _backgroundColor = _categoryColors[_currentQuestion?.category] ?? Colors.indigo;
    });
  }

  String _formatQuestionText(String text) {
    return text
        .replaceAll('ELLA', _playerShe.name)
        .replaceAll('ÉL', _playerHe.name);
  }

  void _addPoints(int points) {
    _playSound();
    setState(() {
      if (_isSuddenDeath) {
        // Sudden death scoring
        if (points == 7) {
          _currentPlayer!.score += 7;
          _currentPlayer!.suddenDeathPoints = 7;
          _currentPlayer!.suddenDeathCorrect = true;
        } else {
          _currentPlayer!.suddenDeathPoints = 0;
          _currentPlayer!.suddenDeathCorrect = false;
        }
      } else {
        // Normal scoring
        if (points == 2) {
          _currentPlayer!.score += 2;
          _currentPlayer!.perfectAnswers++;
        } else if (points == 1) {
          _currentPlayer!.score += 1;
          _currentPlayer!.partialAnswers++;
        } else {
          _currentPlayer!.failedAnswers++;
        }
      }
    });
    
    _nextTurn();
  }

  void _activateSuddenDeath() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.black,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.yellow.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.flash_on, color: Colors.yellow, size: 80),
            ),
            const SizedBox(height: 30),
            const Text(
              'MUERTE SÚBITA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Habrá una sola pregunta para cada uno.\n\nSi responden correctamente, ganarán 7 puntos.\n\n¿Están listos para el desafío final?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _playSound();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          _playSound();
                          Navigator.pop(context);
                          setState(() {
                            _isSuddenDeath = true;
                            _suddenDeathRound = 0;
                          });
                          _nextTurn();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow.shade700,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 10,
                        ),
                        child: const Text(
                          '¡EMPEZAR!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionsResultScreen(
          playerHe: _playerHe,
          playerShe: _playerShe,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final otherPlayer = (_currentPlayer == _playerHe) ? _playerShe : _playerHe;

    return Scaffold(
      body: NeonBackground(
        backgroundColor: _backgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ronda $_currentRound/${widget.maxRounds}',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () {
                        _playSound();
                        _finishGame();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              Column(
                children: [
                  const Text(
                    'Turno de',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPlayer?.name}'.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${otherPlayer.name}'.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'PREGUNTA:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _formatQuestionText(_currentQuestion?.text ?? ''),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              // Conditional buttons based on mode
              if (_isSuddenDeath)
                // Sudden Death buttons: Star and Skull
                Row(
                  children: [
                    Expanded(
                      child: _SuddenDeathButton(
                        icon: Icons.sentiment_very_dissatisfied,
                        label: 'Falló',
                        color: Colors.black.withOpacity(0.7),
                        iconColor: Colors.white,
                        onPressed: () => _addPoints(0),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _SuddenDeathButton(
                        icon: Icons.star,
                        label: '+7 puntos',
                        color: Colors.yellow.shade700,
                        iconColor: Colors.amber.shade900,
                        onPressed: () => _addPoints(7),
                      ),
                    ),
                  ],
                )
              else
                // Normal scoring buttons + sudden death button below
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ScoreButton(
                            icon: Icons.close,
                            label: 'Nada',
                            color: Colors.redAccent.withOpacity(0.3),
                            onPressed: () => _addPoints(0),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _ScoreButton(
                            icon: Icons.star_half,
                            label: 'Medio',
                            color: Colors.orangeAccent.withOpacity(0.3),
                            onPressed: () => _addPoints(1),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _ScoreButton(
                            icon: Icons.star,
                            label: '¡Bien!',
                            color: Colors.greenAccent.withOpacity(0.3),
                            onPressed: () => _addPoints(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _playSound();
                          _activateSuddenDeath();
                        },
                        icon: const Icon(Icons.flash_on, color: Colors.yellow),
                        label: const Text(
                          'MUERTE SÚBITA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ScoreButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 70,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
            child: Icon(icon, size: 35),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SuddenDeathButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onPressed;

  const _SuddenDeathButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: Colors.white.withOpacity(0.3), width: 3),
              ),
              shadowColor: color.withOpacity(0.5),
            ),
            child: Icon(icon, size: 60, color: iconColor),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
