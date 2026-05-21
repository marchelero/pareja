import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/models/drink_task.dart';
import '../../core/storage/local_storage.dart';
import '../../widgets/neon_background.dart';

class DrinksGameScreen extends StatefulWidget {
  final int sipsPerGlass;
  final int initialLevel;
  final int levelingSpeed;
  final bool isHotMode;

  const DrinksGameScreen({
    super.key,
    required this.sipsPerGlass,
    required this.initialLevel,
    required this.levelingSpeed,
    required this.isHotMode,
  });

  @override
  State<DrinksGameScreen> createState() => _DrinksGameScreenState();
}

class _DrinksGameScreenState extends State<DrinksGameScreen> {
  List<DrinkTask> _allTasks = [];
  List<DrinkTask> _availableTasks = [];
  Set<String> _usedTaskIds = {};
  DrinkTask? _currentTask;
  String? _activePlayerName; // Track who the card is for (if generic)
  bool _isLoading = true;

  late String _heName;
  late String _sheName;
  int _heSipsLeft = 0;
  int _sheSipsLeft = 0;
  int _currentLevel = 1;
  int _turnCount = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _heSipsLeft = widget.sipsPerGlass;
    _sheSipsLeft = widget.sipsPerGlass;
    _currentLevel = widget.initialLevel;
    _initGame();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }



  Future<void> _playSound(String fileName) async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      // debugPrint('Error playing sound ($fileName): $e');
      // Don't disable all sounds just because one is missing (e.g. sip.mp3 might be missing but clic.mp3 exists)
    }
  }

  Future<void> _initGame() async {
    _heName = await LocalStorage.getHeName();
    _sheName = await LocalStorage.getSheName();
    if (_heName.isEmpty) _heName = 'ÉL';
    if (_sheName.isEmpty) _sheName = 'ELLA';

    _usedTaskIds = (await LocalStorage.getUsedDrinkTasks()).toSet();

    final String response = await rootBundle.loadString('assets/data/drinks_tasks.json');
    final List<dynamic> data = json.decode(response);
    _allTasks = data.map((json) => DrinkTask.fromJson(json)).toList();

    _filterTasks();
    _nextTurn();

    setState(() {
      _isLoading = false;
    });
  }

  void _filterTasks() {
    _availableTasks = _allTasks.where((task) {
      if (_usedTaskIds.contains(task.id)) return false;
      if (!widget.isHotMode && task.isHot) return false;
      
      // Gender Filter: If tasks are gender-specific, only allow if they make sense generally or if we have logic to handle them.
      // Current simplified logic: allow all gendered tasks, but they will be assigned targets based on their nature in logic or text.
      // However, if the user wants strict segregation (e.g. only show 'female' tasks if we can target female), 
      // we can filter here. For now, we assume the text is descriptive enough or targets will be handled.
      // Refined Logic based on user request: "Increase difficulty/hotness as level goes up"
      
      bool levelMatch = task.intensity <= _currentLevel;
      // Filter out too easy tasks at high levels to keep intensity up
      if (_currentLevel > 3 && task.intensity < _currentLevel - 2) levelMatch = false;
      
      return levelMatch;
    }).toList();
  }

  void _nextTurn() {
    _turnCount++;
    int turnsToLevelUp = widget.levelingSpeed;
    
    // Check for Level Up (Cap increased to 8)
    if (_turnCount % turnsToLevelUp == 0 && _currentLevel < 8) {
      _currentLevel++;
      _filterTasks();
      _playSound('level_up.mp3');
      
      // Level Up Logic
      setState(() {
        if (widget.isHotMode && _currentLevel >= 5) {
          // Intense Levels: Clothing Removal
          _currentTask = DrinkTask(
            id: 'levelup_clothing_$_currentLevel',
            text: '¡NIVEL ${_currentLevel}! 🔥\nLa temperatura sube... AMBOS SE QUITAN UNA PRENDA O TOMAN TODO EL VASO.',
            target: DrinkTarget.both,
            type: DrinkType.challenge,
            category: DrinkCategory.challenge,
            intensity: 8,
            isHot: true,
            sips: 99, // Full glass penalty
            gender: DrinkGender.any,
          );
        } else {
          // Mid Levels: Celebratory Sip
          _currentTask = DrinkTask(
            id: 'levelup_info_$_currentLevel',
            text: '¡NIVEL ${_currentLevel} ALCANZADO! 🚀\nSubimos la intensidad. Celebren con un trago.',
            target: DrinkTarget.both,
            type: DrinkType.game,
            category: DrinkCategory.decision,
            intensity: 0,
            isHot: false,
            sips: 1, // At least 1 sip
            gender: DrinkGender.any,
          );
        }
        _activePlayerName = null;
      });
      return; 
    }

    setState(() {
      if (_availableTasks.isNotEmpty) {
        _currentTask = _availableTasks[Random().nextInt(_availableTasks.length)];
        // Add to used list immediately to prevent repeat in session
        _usedTaskIds.add(_currentTask!.id);
        LocalStorage.addUsedDrinkTask(_currentTask!.id);

        // Remove from available tasks for this session to guarantee no repeats
        _availableTasks.remove(_currentTask);
        
        // Determine active player for this card (mostly for display purposes on Questions/Challenges)
        // If target is specific (he/she), that's the active player.
        // If random/both/loser based on game state, we pick one randomly for display or logic if needed.
        if (_currentTask!.target == DrinkTarget.he) _activePlayerName = _heName;
        else if (_currentTask!.target == DrinkTarget.she) _activePlayerName = _sheName;
        else if (_currentTask!.target == DrinkTarget.both) _activePlayerName = null; // Both
        else {
           // Random or Loser -> Assign to one, respecting gender
           if (_currentTask!.gender == DrinkGender.male) {
             _activePlayerName = _heName;
           } else if (_currentTask!.gender == DrinkGender.female) {
             _activePlayerName = _sheName;
           } else {
             _activePlayerName = Random().nextBool() ? _heName : _sheName;
           }
        }
      } else {
        // If we ran out of tasks (rare given the bank size vs session length), maybe clear used or just pick random?
        // For now, let's just pick from all matching intensity without used filter if available is empty
        _usedTaskIds.clear();
        LocalStorage.clearUsedDrinkTasks(); // Soft reset if exhausted
        _filterTasks();
        if (_availableTasks.isNotEmpty) {
           _currentTask = _availableTasks[Random().nextInt(_availableTasks.length)];
           _usedTaskIds.add(_currentTask!.id);
           LocalStorage.addUsedDrinkTask(_currentTask!.id);
           _availableTasks.remove(_currentTask);
           
            if (_currentTask!.target == DrinkTarget.he) _activePlayerName = _heName;
            else if (_currentTask!.target == DrinkTarget.she) _activePlayerName = _sheName;
            else if (_currentTask!.target == DrinkTarget.both) _activePlayerName = null; // Both
            else {
               // Random or Loser -> Assign to one, respecting gender
               if (_currentTask!.gender == DrinkGender.male) {
                 _activePlayerName = _heName;
               } else if (_currentTask!.gender == DrinkGender.female) {
                 _activePlayerName = _sheName;
               } else {
                 _activePlayerName = Random().nextBool() ? _heName : _sheName;
               }
            }
        }
      }
    });
  }

  void _injectForcedRemoveItemTask() {
    setState(() {
       _currentTask = DrinkTask(
        id: 'forced_remove_item_$_currentLevel', 
        text: '¡SUBIMOS DE NIVEL! 🔥\nAMBOS SE QUITAN UNA PRENDA O TOMAN EL VASO ENTERO.', 
        target: DrinkTarget.both, 
        type: DrinkType.challenge, 
        category: DrinkCategory.challenge, 
        intensity: 8, 
        isHot: true, 
        sips: 99, // Special value for full glass
        gender: DrinkGender.any
      );
      _activePlayerName = null; // Target is both
    });
  }

  void _applySips(DrinkTarget target, int sips) async {
    setState(() {
      int sipsToApply = sips;
      
      if (target == DrinkTarget.he || target == DrinkTarget.both) {
        if (sips == 99) {
          _heSipsLeft = 0;
        } else {
          _heSipsLeft = max(0, _heSipsLeft - sipsToApply);
        }
      }
      if (target == DrinkTarget.she || target == DrinkTarget.both) {
        if (sips == 99) {
          _sheSipsLeft = 0;
        } else {
          _sheSipsLeft = max(0, _sheSipsLeft - sipsToApply);
        }
      }
      if (target == DrinkTarget.random) {
        bool targetHe = Random().nextBool();
        if (targetHe) {
          _heSipsLeft = max(0, _heSipsLeft - sipsToApply);
        } else {
          _sheSipsLeft = max(0, _sheSipsLeft - sipsToApply);
        }
      }
    });

    // Wait for the liquid animation to finish before showing Game Over dialog
    if (_heSipsLeft <= 0 || _sheSipsLeft <= 0) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _checkGameOver();
    }
  }

  void _checkGameOver() {
    if (_heSipsLeft <= 0) {
      _showGameOverDialog(_heName);
    } else if (_sheSipsLeft <= 0) {
      _showGameOverDialog(_sheName);
    }
  }

  void _showGameOverDialog(String playerName) {
    _playSound('drink.mp3');
    bool isHe = playerName == _heName;
    String imagePath = isHe ? 'assets/images/man_drinking.png' : 'assets/images/woman_drinking.png';

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  (isHe ? Colors.deepPurple : Colors.pink).withOpacity(0.5),
                  Colors.black,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isHe ? Colors.deepPurple : Colors.pink).withOpacity(0.5),
                                blurRadius: 50,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  'SECO! SECO!',
                  style: TextStyle(
                    color: isHe ? Colors.deepPurpleAccent : Colors.pinkAccent,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    '${playerName.toUpperCase()} DEBE TOMAR EL VASO AHORA MISMO',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        _playSound('clic.mp3');
                        Navigator.pop(context);
                        setState(() {
                          if (isHe) {
                            _heSipsLeft = widget.sipsPerGlass;
                          } else {
                            _sheSipsLeft = widget.sipsPerGlass;
                          }

                        });
                        // Advance to next card so they don't see the same one
                        _nextTurn();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('¡VASO SECO, SIGUIENTE!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildGlassesArea(),
                    const Spacer(),
                    if (_currentTask != null) _buildTaskCard(),
                    const Spacer(),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    double progress = (_turnCount % widget.levelingSpeed) / widget.levelingSpeed;
    if (_turnCount > 0 && _turnCount % widget.levelingSpeed == 0) progress = 1.0;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('NIVEL $_currentLevel', style: TextStyle(color: _currentLevel >= 5 ? Colors.orangeAccent : Colors.amberAccent, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          if (widget.isHotMode) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.whatshot, color: Colors.orangeAccent, size: 16),
                          ],
                        ],
                      ),
                      Text('Turno $_turnCount', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      _playSound('clic.mp3');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _currentLevel >= 5 ? Colors.deepOrangeAccent : Colors.orangeAccent,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassesArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildGlass(_heName, _heSipsLeft, Colors.blue),
        _buildGlass(_sheName, _sheSipsLeft, Colors.pink),
      ],
    );
  }

  Widget _buildGlass(String name, int sipsLeft, Color color) {
    double fillPercent = sipsLeft / widget.sipsPerGlass;
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 220,
          child: CustomPaint(
            painter: GlassPainter(fillPercent: fillPercent, color: color),
          ),
        ),
        const SizedBox(height: 15),
        Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
        Text('$sipsLeft sorbos', style: TextStyle(color: color.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _getTargetText() {
    if (_currentTask == null) return '';
    if (_currentTask!.target == DrinkTarget.both) return 'PARA: AMBOS';
    
    // For specific targets (he/she) or assigned random/loser
    if (_activePlayerName != null) {
      if (_currentTask!.category == DrinkCategory.question) return 'PREGUNTA PARA: ${_activePlayerName!.toUpperCase()}';
      if (_currentTask!.category == DrinkCategory.challenge) return 'RETO PARA: ${_activePlayerName!.toUpperCase()}';
      if (_currentTask!.category == DrinkCategory.punishment) return 'CASTIGO PARA: ${_activePlayerName!.toUpperCase()}';
      if (_currentTask!.category == DrinkCategory.decision) return 'DECISIÓN DE: ${_activePlayerName!.toUpperCase()}';
      return 'PARA: ${_activePlayerName!.toUpperCase()}';
    }
    
    return '';
  }

  Widget _buildTaskCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: (_currentTask!.isHot ? Colors.pink : Colors.deepPurple).withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          if (_currentTask!.isHot)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.whatshot, color: Colors.pink, size: 20),
                SizedBox(width: 5),
                Text('MODO HOT', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
              ],
            ),

          
          // Target Indicator for ALL tasks
          if (_getTargetText().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _currentTask!.target == DrinkTarget.both 
                      ? Colors.amber.withOpacity(0.8) 
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                  border: _currentTask!.target == DrinkTarget.both 
                      ? Border.all(color: Colors.amber, width: 2) 
                      : null,
                ),
                child: Text(
                  _getTargetText(),
                  style: TextStyle(
                    color: _currentTask!.target == DrinkTarget.both ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 15),
          Text(
            _currentTask!.text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            _getCategoryLabel(_currentTask!.category),
            style: TextStyle(color: Colors.amber.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          
          if (_currentTask!.sips > 0 && _currentTask!.sips != 99)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_bar, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentTask!.sips} ${_currentTask!.sips == 1 ? 'SORBO' : 'SORBOS'}',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentTask == null) return const SizedBox();

    final target = _currentTask!.target;
    final type = _currentTask!.type;

    // 1. Both must drink
    if (target == DrinkTarget.both) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildDrinkButton(
              _currentTask!.sips == 99 ? '¡TOMAR TODO EL VASO!' : '¡TOMAMOS AMBOS!', 
              () {
                _applySips(DrinkTarget.both, _currentTask!.sips);
                _nextTurn();
              }, 
              Colors.amber, 
              isLarge: true
            ),
            const SizedBox(height: 10),
            _buildDrinkButton('NADIE / NO APLICA', () {
              _playSound('clic.mp3');
              _nextTurn();
            }, Colors.white10),
          ],
        ),
      );
    }

    // 2. Competitive Game (Ask who lost)
    if (type == DrinkType.game) {
      String sipsText = _currentTask!.sips > 0 ? ' (${_currentTask!.sips})' : '';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildDrinkButton('TOMA $_heName$sipsText', () {
                _applySips(DrinkTarget.he, _currentTask!.sips);
                _nextTurn();
              }, Colors.blue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDrinkButton('TOMA $_sheName$sipsText', () {
                _applySips(DrinkTarget.she, _currentTask!.sips);
                _nextTurn();
              }, Colors.pink),
            ),
          ],
        ),
      );
    }

    // 3. Specific target (He/She), Random, or Loser (non-game) assigned to someone
    if (target == DrinkTarget.he || target == DrinkTarget.she || 
       ((target == DrinkTarget.random || target == DrinkTarget.loser) && _activePlayerName != null)) {
      bool isHe = target == DrinkTarget.he || (_activePlayerName == _heName);
      String name = isHe ? _heName : _sheName;
      Color color = isHe ? Colors.blue : Colors.pink;
      DrinkTarget applyTarget = isHe ? DrinkTarget.he : DrinkTarget.she;
      String sipsText = _currentTask!.sips > 0 ? ' (${_currentTask!.sips})' : '';
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildDrinkButton('TOMA $name$sipsText', () {
                _applySips(applyTarget, _currentTask!.sips);
                _nextTurn();
              }, color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDrinkButton('NO APLICA', () {
                _playSound('clic.mp3');
                _nextTurn();
              }, Colors.white10),
            ),
          ],
        ),
      );
    }

    // 4. Default / Random / Choice
    String sipsText = _currentTask!.sips > 0 ? ' (${_currentTask!.sips})' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDrinkButton('TOMA $_heName$sipsText', () {
                  _applySips(DrinkTarget.he, _currentTask!.sips);
                  _nextTurn();
                }, Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDrinkButton('TOMA $_sheName$sipsText', () {
                  _applySips(DrinkTarget.she, _currentTask!.sips);
                  _nextTurn();
                }, Colors.pink),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDrinkButton('TOMAN AMBOS$sipsText', () {
                  _applySips(DrinkTarget.both, _currentTask!.sips);
                  _nextTurn();
                }, Colors.amber),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDrinkButton('NADIE', () {
                  _playSound('clic.mp3');
                  _nextTurn();
                }, Colors.white10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkButton(String text, VoidCallback onPressed, Color color, {bool isLarge = false}) {
    return SizedBox(
      height: isLarge ? 70 : 60,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
  String _getCategoryLabel(DrinkCategory category) {
    switch (category) {
      case DrinkCategory.question:
        return '🟦 PREGUNTA';
      case DrinkCategory.challenge:
        return '🟥 RETO';
      case DrinkCategory.punishment:
        return '🟩 CASTIGO';
      case DrinkCategory.decision:
        return '🟨 DECISIÓN';
      default:
        return 'TASK';
    }
  }
}

class GlassPainter extends CustomPainter {
  final double fillPercent;
  final Color color;

  GlassPainter({required this.fillPercent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Glass Body Path (slightly tapered)
    final path = Path()
      ..moveTo(size.width * 0.15, 0)
      ..lineTo(size.width * 0.85, 0)
      ..lineTo(size.width * 0.75, size.height)
      ..lineTo(size.width * 0.25, size.height)
      ..close();

    // 1. Draw Glass Background (Empty part)
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.1),
        ],
      ).createShader(rect);
    canvas.drawPath(path, bgPaint);

    // 1b. Glass Rim (Moved before fluid so fluid covers back of rim if full)
    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Top Rim Oval
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, 0),
        width: size.width * 0.7,
        height: 10,
      ),
      rimPaint,
    );

    // 2. Draw Liquid
    if (fillPercent > 0) {
      final liquidHeight = size.height * fillPercent;
      final liquidTop = size.height - liquidHeight;
      
      final liquidPath = Path()
        ..moveTo(size.width * 0.15 + (size.width * 0.1 * (1 - fillPercent)), liquidTop)
        ..lineTo(size.width * 0.85 - (size.width * 0.1 * (1 - fillPercent)), liquidTop)
        ..lineTo(size.width * 0.75, size.height)
        ..lineTo(size.width * 0.25, size.height)
        ..close();

      final liquidPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
            color.withOpacity(0.9),
          ],
        ).createShader(liquidPath.getBounds());
      
      canvas.drawPath(liquidPath, liquidPaint);

      // 3. Liquid Surface (Oval for 3D effect)
      final surfacePaint = Paint()
        ..color = color.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      
      // Surface width should match the glass width at that height
      // Top width is 0.7 (from 0.15 to 0.85). Bottom width is 0.5 (from 0.25 to 0.75).
      // Interpolation: width = bottom + (top - bottom) * percent
      // width = 0.5 + (0.7 - 0.5) * percent = 0.5 + 0.2 * percent
      final surfaceWidth = size.width * (0.5 + (0.2 * fillPercent));
      
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, liquidTop),
          width: surfaceWidth,
          height: 10,
        ),
        surfacePaint,
      );

      // 4. Bubbles
      final random = Random(42);
      for (int i = 0; i < 8; i++) {
        final bubbleX = size.width * (0.3 + random.nextDouble() * 0.4);
        final bubbleY = liquidTop + random.nextDouble() * liquidHeight;
        final bubbleSize = 1.0 + random.nextDouble() * 2.5;
        canvas.drawCircle(
          Offset(bubbleX, bubbleY), 
          bubbleSize, 
          Paint()..color = Colors.white.withOpacity(0.3)
        );
      }
    }



    // 6. Side Reflections and Body Outline
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, outlinePaint);

    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.2),
          Colors.transparent,
          Colors.white.withOpacity(0.1),
        ],
      ).createShader(rect);
    canvas.drawPath(path, reflectionPaint);
  }

  @override
  bool shouldRepaint(covariant GlassPainter oldDelegate) => 
      oldDelegate.fillPercent != fillPercent || oldDelegate.color != color;
}
