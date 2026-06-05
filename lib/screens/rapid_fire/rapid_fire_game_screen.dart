import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/rapid_fire_controller.dart';
import '../../widgets/game_result_screen.dart';
import '../../widgets/neon_background.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import 'rapid_fire_start_screen.dart';
import '../games_menu_screen.dart';

class RapidFireGameScreen extends StatefulWidget {
  final RapidFireController controller;
  const RapidFireGameScreen({super.key, required this.controller});

  @override
  State<RapidFireGameScreen> createState() => _RapidFireGameScreenState();
}

class _RapidFireGameScreenState extends State<RapidFireGameScreen> with TickerProviderStateMixin {
  late AnimationController _resultAnimController;
  late Animation<double> _resultAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _resultAnim = CurvedAnimation(parent: _resultAnimController, curve: Curves.easeOutBack);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulseAnim = Tween<double>(begin: 0.3, end: 0.8).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
    widget.controller.addListener(_onChange);
    widget.controller.onGameFinished = ({required String winnerName, required String loserName}) {
      _showResult(winnerName, loserName);
    };
  }

  void _onChange() {
    if (!mounted) return;
    if (widget.controller.state == RapidFireState.showingResult && !_resultAnimController.isAnimating) {
      _resultAnimController.forward(from: 0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _resultAnimController.dispose();
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _showResult(String winnerName, String loserName) {
    final c = widget.controller;
    final bool isHe = winnerName == c.player1Name;
    final Color winnerColor = isHe ? c.player1Color : c.player2Color;
    final audioService = context.read<AudioService>();
    final settingsProvider = context.read<SettingsProvider>();

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => GameResultScreen(
        gameName: 'Alto al Fuego',
        gameColor: AppColors.modeRapidFire,
        winnerName: winnerName,
        winnerColor: winnerColor,
        player1Name: c.player1Name, player2Name: c.player2Name,
        player1Icon: settingsProvider.player1Icon,
        player2Icon: settingsProvider.player2Icon,
        player1Color: c.player1Color,
        player2Color: c.player2Color,
        scoreP1: c.player1Score, scoreP2: c.player2Score,
        maxScore: c.targetScoreValue,
        isTie: winnerName == 'EMPATE',
        onReplay: () {
          final nc = RapidFireController(audioService: audioService, settingsProvider: settingsProvider, targetScore: c.targetScoreValue);
          nc.setSelectedCategories(c.selectedCategories);
          nc.initGame().then((_) {
            if (!context.mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RapidFireGameScreen(controller: nc)));
          });
        },
        onGameMenu: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RapidFireStartScreen())),
        onMainMenu: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const GamesMenuScreen()), (route) => false),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(c),
                  _buildQuestionArea(c),
                  _buildTimerBar(c),
                  Expanded(child: _buildPlayerRow(c)),
                  _buildProgress(c),
                ],
              ),
              if (c.state == RapidFireState.showingResult)
                _buildResultOverlay(c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(RapidFireController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white70, size: 26), onPressed: () => Navigator.pop(context)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.player1Color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.player1Color.withValues(alpha: 0.4)),
            ),
            child: Text(c.player1Name.toUpperCase(), style: TextStyle(color: c.player1Color, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 6),
          Text('${c.player1Score}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('-', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16)),
          ),
          Text('${c.player2Score}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.player2Color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.player2Color.withValues(alpha: 0.4)),
            ),
            child: Text(c.player2Name.toUpperCase(), style: TextStyle(color: c.player2Color, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar(RapidFireController c) {
    final bool show = c.state == RapidFireState.idle || c.state == RapidFireState.buzzed;
    if (!show) return const SizedBox();

    final maxTime = c.state == RapidFireState.idle ? 10.0 : 5.0;
    final current = c.state == RapidFireState.idle ? c.buzzTimeLeft : c.timeLeft;
    final fraction = (current / maxTime).clamp(0.0, 1.0);
    final color = fraction > 0.5 ? Colors.greenAccent : (fraction > 0.25 ? Colors.amberAccent : Colors.redAccent);
    final label = c.state == RapidFireState.idle ? 'Toca para responder' : 'Elige una opción';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text('${current.toStringAsFixed(1)}s', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(RapidFireController c) {
    final q = c.currentQuestion;
    if (q == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _categoryBadge(c.currentCategory),
              const SizedBox(width: 8),
              Text('Pregunta ${c.questionIndex}', style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: Text(
              q['q'] as String? ?? '',
              key: ValueKey('q${c.questionIndex}'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _categoryBadge(String cat) {
    const icons = {
      'Geografía': Icons.public,
      'Historia': Icons.auto_stories,
      'Ciencia': Icons.science,
      'Cultura General': Icons.lightbulb,
      'Películas': Icons.movie,
      'Música': Icons.music_note,
      'Deportes': Icons.sports_soccer,
      'Naturaleza': Icons.park,
      'Entretenimiento': Icons.videogame_asset,
      'Hot': Icons.favorite,
    };
    const colors = {
      'Geografía': Color(0xFF4CAF50),
      'Historia': Color(0xFFFF9800),
      'Ciencia': Color(0xFF2196F3),
      'Cultura General': Color(0xFF9C27B0),
      'Películas': Color(0xFFE91E63),
      'Música': Color(0xFF00BCD4),
      'Deportes': Color(0xFFFF5722),
      'Naturaleza': Color(0xFF8BC34A),
      'Entretenimiento': Color(0xFF3F51B5),
      'Hot': Color(0xFFF44336),
    };
    final Color catColor = colors[cat] ?? AppColors.modeRapidFire;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: catColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[cat] ?? Icons.category, size: 14, color: catColor),
          const SizedBox(width: 4),
          Text(cat, style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(RapidFireController c) {
    return Row(
      children: [
        Expanded(child: _buildSide(c, isHe: true)),
        Container(width: 2, color: Colors.white.withValues(alpha: 0.08)),
        Expanded(child: _buildSide(c, isHe: false)),
      ],
    );
  }

  Widget _buildSide(RapidFireController c, {required bool isHe}) {
    final name = isHe ? c.player1Name : c.player2Name;
    final Color color = isHe ? c.player1Color : c.player2Color;

    if (c.state == RapidFireState.showingResult) {
      return _buildSideResult(c, isHe: isHe, color: color);
    }

    final isBuzzer = c.buzzerPlayer == (isHe ? 'he' : 'she');
    final bool canBuzz = c.state == RapidFireState.idle;
    final bool showingOptions = c.state == RapidFireState.buzzed && isBuzzer;
    final bool waiting = c.state == RapidFireState.buzzed && !isBuzzer;

    return Padding(
      padding: const EdgeInsets.all(5),
      child: canBuzz
          ? _buildBuzzButton(c, isHe: isHe, name: name, color: color)
          : showingOptions
              ? _buildOptions(c, color: color)
              : waiting
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty, color: Colors.white.withValues(alpha: 0.2), size: 28),
                          const SizedBox(height: 6),
                          Text('Esperando...', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                    )
                  : const SizedBox(),
    );
  }

  Widget _buildBuzzButton(RapidFireController c, {required bool isHe, required String name, required Color color}) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return GestureDetector(
          onTap: () => c.buzz(isHe ? 'he' : 'she'),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0.15)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: _pulseAnim.value), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: _pulseAnim.value * 0.3), blurRadius: 15 + _pulseAnim.value * 10, spreadRadius: 2),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w300, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  const Icon(Icons.bolt, color: Colors.white, size: 32),
                  const SizedBox(height: 4),
                  Text('¡TOCA!', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptions(RapidFireController c, {required Color color}) {
    final q = c.currentQuestion;
    if (q == null) return const SizedBox();
    final options = q['o'] as List<dynamic>? ?? [];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final label = 'ABCD'[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: GestureDetector(
              onTap: () => c.selectAnswer(i),
              child: Container(
                constraints: const BoxConstraints(minWidth: 120),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(child: Text(label, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900))),
                    ),
                    const SizedBox(width: 8),
                    Text(options[i] as String? ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSideResult(RapidFireController c, {required bool isHe, required Color color}) {
    final bool playerScored;
    if (c.selectedAnswer == null) {
      playerScored = isHe != (c.buzzerPlayer == 'he');
    } else {
      final correct = c.selectedAnswer == c.correctAnswerIndex;
      if (correct) {
        playerScored = isHe == (c.buzzerPlayer == 'he');
      } else {
        playerScored = isHe != (c.buzzerPlayer == 'he');
      }
    }

    return Container(
      color: playerScored ? color.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          playerScored ? Icons.check_circle : Icons.do_not_disturb,
          color: playerScored ? Colors.greenAccent : Colors.white24,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildResultOverlay(RapidFireController c) {
    final isCorrect = c.selectedAnswer != null && c.selectedAnswer == c.correctAnswerIndex;
    final whoScored = (c.selectedAnswer == null)
        ? _otherPlayerName(c)
        : (isCorrect ? _buzzerName(c) : _otherPlayerName(c));
    final Color resultColor = isCorrect || c.selectedAnswer == null
        ? Colors.greenAccent
        : Colors.redAccent;
    final icon = isCorrect
        ? Icons.check_circle
        : (c.selectedAnswer == null ? Icons.timer_off : Icons.cancel);
    final title = isCorrect
        ? '¡CORRECTO!'
        : (c.selectedAnswer == null ? 'SE ACABÓ EL TIEMPO' : 'INCORRECTO');

    return AnimatedBuilder(
      animation: _resultAnim,
      builder: (context, _) {
        return IgnorePointer(
          child: Container(
            color: Colors.black.withValues(alpha: 0.5 * _resultAnim.value),
            child: Center(
              child: Transform.scale(
                scale: _resultAnim.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: resultColor.withValues(alpha: 0.5)),
                    boxShadow: [BoxShadow(color: resultColor.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: resultColor, size: 48),
                      const SizedBox(height: 8),
                      Text(title, style: TextStyle(color: resultColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: resultColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$whoScored +1', style: TextStyle(color: resultColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                      const SizedBox(height: 12),
                      Text('Respuesta: ${c.lastCorrectAnswer ?? ''}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _buzzerName(RapidFireController c) => c.buzzerPlayer == 'he' ? c.player1Name : c.player2Name;
  String _otherPlayerName(RapidFireController c) => c.buzzerPlayer == 'he' ? c.player2Name : c.player1Name;

  Widget _buildProgress(RapidFireController c) {
    final total = c.player1Score + c.player2Score;
    final maxPossible = c.targetScoreValue * 2;
    final progress = maxPossible > 0 ? total / maxPossible : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 3,
          backgroundColor: Colors.white10,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.modeRapidFire),
        ),
      ),
    );
  }
}
