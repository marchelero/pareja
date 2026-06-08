import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/premiado_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/game_help_modal.dart';
import '../../services/haptics_service.dart';
import '../../widgets/game_button.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/route_transitions.dart';
import '../../screens/games_menu_screen.dart';

class PremiadoGameScreen extends StatefulWidget {
  final PremiadoController controller;

  const PremiadoGameScreen({super.key, required this.controller});

  @override
  State<PremiadoGameScreen> createState() => _PremiadoGameScreenState();
}

class _PremiadoGameScreenState extends State<PremiadoGameScreen>
    with TickerProviderStateMixin {
  final Map<int, Offset> _pointers = {};
  Offset? _p1Pos;
  Offset? _p2Pos;
  bool _isBothReady = false;
  int _countdown = 3;
  Timer? _countdownTimer;
  bool _isSelected = false;
  bool? _isP1Selected;
  Offset? _selectedPos;
  bool _gameOver = false;

  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _resultEntryCtrl;
  late Animation<double> _glowScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().incrementGamePlayed('Premiado');
    });
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _glowScale = Tween<double>(begin: 0.3, end: 1.5).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut),
    );

    _resultEntryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _resultEntryCtrl.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent e) {
    if (_isBothReady || _isSelected) return;
    setState(() {
      _pointers[e.pointer] = e.position;
      _updateTouchAssignment();
    });
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_isSelected) return;
    if (!_pointers.containsKey(e.pointer)) return;
    setState(() {
      _pointers[e.pointer] = e.position;
      final sorted = _pointers.entries.toList()
        ..sort((a, b) => a.value.dx.compareTo(b.value.dx));
      _p1Pos = sorted[0].value;
      _p2Pos = sorted.length > 1 ? sorted[1].value : null;
    });
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_isSelected) return;
    _countdownTimer?.cancel();
    setState(() {
      _pointers.remove(e.pointer);
      _p1Pos = null;
      _p2Pos = null;
      _isBothReady = false;
      _countdown = 3;
    });
  }

  void _updateTouchAssignment() {
    if (_pointers.length >= 2) {
      final sorted = _pointers.entries.toList()
        ..sort((a, b) => a.value.dx.compareTo(b.value.dx));
      _p1Pos = sorted[0].value;
      _p2Pos = sorted[1].value;
      _isBothReady = true;
      _startCountdown();
    } else {
      _p1Pos = _pointers.values.isNotEmpty ? _pointers.values.first : null;
      _p2Pos = null;
    }
  }

  void _startCountdown() {
    _countdown = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown--;
      if (mounted) setState(() {});
      if (_countdown <= 0) {
        timer.cancel();
        _performSelection();
      }
    });
    if (mounted) setState(() {});
  }

  void _performSelection() {
    final random = Random();
    final isP1 = random.nextBool();
    final pos = isP1 ? _p1Pos : _p2Pos;

    _countdownTimer?.cancel();

    setState(() {
      _isSelected = true;
      _isP1Selected = isP1;
      _selectedPos = pos;
    });

    HapticsService.heavy();
    widget.controller.audioService.playLevelUp();

    _glowCtrl.forward();
    _resultEntryCtrl.forward();

    final c = widget.controller;
    if (isP1) {
      c.incrementP2();
    } else {
      c.incrementP1();
    }
  }

  void _resetGame() {
    _countdownTimer?.cancel();

    if (widget.controller.hasWinner) {
      setState(() => _gameOver = true);
      return;
    }

    setState(() {
      _pointers.clear();
      _p1Pos = null;
      _p2Pos = null;
      _isBothReady = false;
      _isSelected = false;
      _isP1Selected = null;
      _selectedPos = null;
      _countdown = 3;
      _glowCtrl.reset();
      _resultEntryCtrl.reset();
    });
  }

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'Cada jugador coloca un dedo en la pantalla.'),
        GameHelpModal.step('2', 'Cuando ambos tocan, se selecciona aleatoriamente a uno.'),
        GameHelpModal.step('3', 'El seleccionado pierde la ronda y el otro suma un punto.'),
        GameHelpModal.bullet('Te seleccionan', 'pierdes la ronda, rival suma 1.', Colors.redAccent, ''),
        GameHelpModal.bullet('Gana la partida', 'quien llegue primero a la puntuaci\u00f3n objetivo.', Colors.greenAccent, ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isP1 = _isP1Selected == true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: NeonBackground(
        child: _gameOver
            ? _buildGameOverContent(c)
            : (_isSelected
                ? _buildResultContent(c, isP1)
                : _buildGameContent(c)),
      ),
    );
  }

  Widget _buildGameContent(PremiadoController c) {
    return SafeArea(
      child: Stack(
        children: [
          Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPlayerLabel(c.player1Name, c.player1Color, c.player1Icon),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.modePremiado.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.modePremiado.withValues(alpha: 0.3)),
                    ),
                    child: Text('VS', style: TextStyle(
                      color: AppColors.modePremiado, fontWeight: FontWeight.w900, fontSize: 12,
                    )),
                  ),
                  _buildPlayerLabel(c.player2Name, c.player2Color, c.player2Icon),
                ],
              ),
              const SizedBox(height: 16),
              _buildScoreChips(c),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, _) {
                  final p = _pulseCtrl.value;
                  return Icon(
                    Icons.touch_app,
                    size: 100 + p * 20,
                    color: AppColors.modePremiado.withValues(alpha: 0.3 + p * 0.3),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_pointers.isEmpty)
                Text(
                  'CADA UNO PONE UN DEDO\nEN LA PANTALLA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                )
              else if (!_isBothReady)
                Text(
                  '¡${c.player1Name} YA TOCÓ!\nFALTA ${c.player2Name.toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.modePremiado,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '🏆 PREMIADO 🏆',
                  style: TextStyle(
                    color: AppColors.modePremiado.withValues(alpha: 0.3),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
              ),
            ],
            ),
          ),

          if (_p1Pos != null && !_isBothReady)
            _buildTouchIndicator(_p1Pos!, c.player1Color, c.player1Name, c.player1Icon),
          if (_p2Pos != null && _isBothReady)
            _buildTouchIndicator(_p2Pos!, c.player2Color, c.player2Name, c.player2Icon),
          if (_p1Pos != null && _isBothReady)
            _buildTouchIndicator(_p1Pos!, c.player1Color, c.player1Name, c.player1Icon),

          if (_isBothReady)
            _buildCountdownOverlay(),

          Positioned(
            right: 8,
            top: 8,
            child: GameHelpModal.helpButton(_showHelpModal),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 28),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerLabel(String name, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(name.toUpperCase(), style: TextStyle(
          color: color, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2,
        )),
      ],
    );
  }

  Widget _buildTouchIndicator(Offset pos, Color color, String name, IconData icon) {
    return Positioned(
      left: pos.dx - 30,
      top: pos.dy - 30,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) {
          final p = _pulseCtrl.value;
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1 + p * 0.15),
              border: Border.all(color: color.withValues(alpha: 0.4 + p * 0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2 + p * 0.3),
                  blurRadius: 20 + p * 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          );
        },
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
            child: Text(
              '${_countdown > 0 ? _countdown : '¡YA!'}',
              key: ValueKey(_countdown),
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: AppColors.modePremiado,
                shadows: [Shadow(color: AppColors.modePremiado.withValues(alpha: 0.6), blurRadius: 30)],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('SE ELIGE AL AZAR...', style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4), fontSize: 12,
            fontWeight: FontWeight.w700, letterSpacing: 3,
          )),
        ],
      ),
    );
  }

  Widget _buildResultContent(PremiadoController c, bool isP1) {
    final victimName = isP1 ? c.player1Name : c.player2Name;
    final victimColor = isP1 ? c.player1Color : c.player2Color;
    final victimIcon = isP1 ? c.player1Icon : c.player2Icon;
    final safeName = isP1 ? c.player2Name : c.player1Name;
    final safeColor = isP1 ? c.player2Color : c.player1Color;
    final safeIcon = isP1 ? c.player2Icon : c.player1Icon;

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusCard(safeName, safeIcon, safeColor, 'SE SALVA', Colors.greenAccent, false, isP1),
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, _) {
                      final p = _pulseCtrl.value;
                      return Container(
                        width: 2,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(color: victimColor.withValues(alpha: 0.2 + p * 0.3), blurRadius: 8 + p * 8, spreadRadius: 1),
                          ],
                          gradient: LinearGradient(
                            colors: [
                              victimColor.withValues(alpha: 0.1),
                              victimColor.withValues(alpha: 0.5 + p * 0.3),
                              victimColor.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  _buildStatusCard(victimName, victimIcon, victimColor, 'LA VÍCTIMA', Colors.redAccent, true, isP1),
                ],
              ),
              const SizedBox(height: 24),
              _buildScoreChips(c),
              const Spacer(),
              AnimatedBuilder(
                animation: _resultEntryCtrl,
                builder: (_, _) {
                  final e = _resultEntryCtrl.value;
                  return Opacity(
                    opacity: e,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, _) {
                            final p = _pulseCtrl.value;
                            return Icon(victimIcon, size: 48 + p * 6, color: victimColor.withValues(alpha: 0.8 + p * 0.2));
                          },
                        ),
                        const SizedBox(height: 12),
                        Text('PIERDE', style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6), fontSize: 14,
                          fontWeight: FontWeight.w700, letterSpacing: 4,
                        )),
                        const SizedBox(height: 8),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [victimColor, Colors.white, victimColor],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(bounds),
                          child: AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, _) {
                              final p = _pulseCtrl.value;
                              return Text(victimName.toUpperCase(), style: TextStyle(
                                fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white,
                                letterSpacing: 6,
                                shadows: [
                                  Shadow(color: victimColor.withValues(alpha: 0.6 + p * 0.3), blurRadius: 20 + p * 20),
                                  Shadow(color: victimColor.withValues(alpha: 0.3 + p * 0.3), blurRadius: 40 + p * 30),
                                  Shadow(color: Colors.white.withValues(alpha: 0.15 + p * 0.15), blurRadius: 60),
                                ],
                              ));
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, _) {
                            final p = _pulseCtrl.value;
                            return Text('⚡', style: TextStyle(fontSize: 32 + p * 8, color: victimColor));
                          },
                        ),
                        const SizedBox(height: 12),
                        Text('LE TOCA PAGAR / BEBER / PERDER', style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4), fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: 3,
                        )),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GameButton(
                  text: 'VOLVER A JUGAR',
                  customColor: victimColor,
                  onPressed: _resetGame,
                  style: GameButtonStyle.primary,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    RouteTransitions.slideFromBottom(const GamesMenuScreen()),
                    (route) => false,
                  );
                },
                child: Text('MENÚ PRINCIPAL', style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700, letterSpacing: 3, fontSize: 13,
                )),
              ),
              const SizedBox(height: 40),
            ],
          ),

          if (_selectedPos != null)
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, _) {
                final t = _glowCtrl.value;
                if (t <= 0) return const SizedBox.shrink();
                final radius = _glowScale.value * 80;
                final opacity = (1.0 - t).clamp(0.0, 0.35);
                return Positioned(
                  left: _selectedPos!.dx - radius / 2,
                  top: _selectedPos!.dy - radius / 2,
                  child: Container(
                    width: radius,
                    height: radius,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: victimColor.withValues(alpha: opacity),
                          blurRadius: radius * 0.6,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('⚡', style: TextStyle(fontSize: radius * 0.4, color: victimColor.withValues(alpha: opacity * 2))),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String name, IconData icon, Color color, String label, Color labelColor, bool isVictim, bool isP1) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) {
        final p = _pulseCtrl.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isVictim ? 80 + p * 6 : 80,
              height: isVictim ? 80 + p * 6 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: isVictim ? 0.15 + p * 0.1 : 0.1),
                border: Border.all(
                  color: color.withValues(alpha: isVictim ? 0.6 + p * 0.3 : 0.5),
                  width: isVictim ? 2 + p * 0.5 : 2,
                ),
                boxShadow: isVictim
                    ? [
                        BoxShadow(color: color.withValues(alpha: 0.3 + p * 0.4), blurRadius: 15 + p * 15, spreadRadius: 0),
                        BoxShadow(color: color.withValues(alpha: 0.1 + p * 0.2), blurRadius: 30 + p * 20, spreadRadius: 0),
                      ]
                    : [
                        BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 0),
                      ],
              ),
              child: Icon(icon, color: color, size: isVictim ? 36 + p * 3 : 36),
            ),
            const SizedBox(height: 8),
            Text(name.toUpperCase(), style: TextStyle(
              color: color, fontSize: isVictim ? 13 + p * 1 : 13,
              fontWeight: FontWeight.w900, letterSpacing: 1,
              shadows: isVictim
                  ? [Shadow(color: color.withValues(alpha: 0.3 + p * 0.3), blurRadius: 8 + p * 6)]
                  : null,
            )),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: labelColor.withValues(alpha: isVictim ? 0.2 + p * 0.1 : 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: labelColor.withValues(alpha: isVictim ? 0.4 + p * 0.3 : 0.3),
                ),
                boxShadow: isVictim
                    ? [BoxShadow(color: labelColor.withValues(alpha: 0.1 + p * 0.2), blurRadius: 8 + p * 6, spreadRadius: 0)]
                    : null,
              ),
              child: Text(label, style: TextStyle(
                color: labelColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2,
              )),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoreChips(PremiadoController c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: c.player1Color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.player1Color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(c.player1Icon, size: 14, color: c.player1Color),
              const SizedBox(width: 6),
              Text(c.player1Name.toUpperCase(), style: TextStyle(color: c.player1Color, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text('${c.scoreP1}', style: TextStyle(color: c.player1Color, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('VS', style: TextStyle(
            color: AppColors.modePremiado, fontWeight: FontWeight.w900, fontSize: 14,
          )),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: c.player2Color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.player2Color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(c.player2Icon, size: 14, color: c.player2Color),
              const SizedBox(width: 6),
              Text(c.player2Name.toUpperCase(), style: TextStyle(color: c.player2Color, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text('${c.scoreP2}', style: TextStyle(color: c.player2Color, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverContent(PremiadoController c) {
    final isP1Winner = c.winnerIndex == 0;
    final winnerName = isP1Winner ? c.player1Name : c.player2Name;
    final winnerColor = isP1Winner ? c.player1Color : c.player2Color;
    final winnerIcon = isP1Winner ? c.player1Icon : c.player2Icon;

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 60),
              _buildScoreChips(c),
              const Spacer(),
              Icon(winnerIcon, size: 72, color: winnerColor.withValues(alpha: 0.8)),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [winnerColor, Colors.white, winnerColor],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: Text(winnerName.toUpperCase(), style: const TextStyle(
                  fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white,
                  letterSpacing: 6,
                )),
              ),
              const SizedBox(height: 12),
              Text('🏆 CAMPEÓN 🏆', style: TextStyle(
                color: winnerColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4,
              )),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GameButton(
                  text: 'VOLVER A JUGAR',
                  customColor: winnerColor,
                  onPressed: () {
                    c.resetScores();
                    setState(() => _gameOver = false);
                    _resetGame();
                  },
                  style: GameButtonStyle.primary,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    RouteTransitions.slideFromBottom(const GamesMenuScreen()),
                    (route) => false,
                  );
                },
                child: Text('MENÚ PRINCIPAL', style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700, letterSpacing: 3, fontSize: 13,
                )),
              ),
              const SizedBox(height: 40),
            ],
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GameHelpModal.helpButton(_showHelpModal),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 28),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }
}
