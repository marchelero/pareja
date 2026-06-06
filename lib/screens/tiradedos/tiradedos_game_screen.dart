import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../controllers/tiradedos_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../services/haptics_service.dart';
import '../../widgets/game_button.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/route_transitions.dart';
import '../../screens/games_menu_screen.dart';

class TiradedosGameScreen extends StatefulWidget {
  final TiradedosController controller;

  const TiradedosGameScreen({super.key, required this.controller});

  @override
  State<TiradedosGameScreen> createState() => _TiradedosGameScreenState();
}

class _TiradedosGameScreenState extends State<TiradedosGameScreen>
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

  late AnimationController _pulseCtrl;
  late AnimationController _flashCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _resultEntryCtrl;
  late Animation<double> _glowScale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _glowScale = Tween<double>(begin: 0.5, end: 4.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut),
    );

    _resultEntryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseCtrl.dispose();
    _flashCtrl.dispose();
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

    _flashCtrl.forward();
    _glowCtrl.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _resultEntryCtrl.forward();
    });
  }

  void _resetGame() {
    _countdownTimer?.cancel();
    setState(() {
      _pointers.clear();
      _p1Pos = null;
      _p2Pos = null;
      _isBothReady = false;
      _isSelected = false;
      _isP1Selected = null;
      _selectedPos = null;
      _countdown = 3;
      _flashCtrl.reset();
      _glowCtrl.reset();
      _resultEntryCtrl.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isP1 = _isP1Selected == true;
    final victimName = isP1 ? c.player1Name : c.player2Name;
    final victimColor = isP1 ? c.player1Color : c.player2Color;
    final safeName = isP1 ? c.player2Name : c.player1Name;
    final safeColor = isP1 ? c.player2Color : c.player1Color;
    final victimIcon = isP1 ? c.player1Icon : c.player2Icon;
    final safeIcon = isP1 ? c.player2Icon : c.player1Icon;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          NeonBackground(
            child: _isSelected
                ? _buildResultContent(victimName, victimColor, victimIcon, safeName, safeColor, safeIcon)
                : _buildGameContent(c),
          ),

          if (!_isSelected)
            Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),

          if (_p1Pos != null && !_isSelected)
            _buildTouchIndicator(_p1Pos!, c.player1Color, c.player1Name, c.player1Icon),
          if (_p2Pos != null && !_isSelected)
            _buildTouchIndicator(_p2Pos!, c.player2Color, c.player2Name, c.player2Icon),

          if (_isBothReady && !_isSelected)
            _buildCountdownOverlay(),

          if (_isSelected)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _flashCtrl,
                builder: (_, _) {
                  final flashValue = _flashCtrl.value;
                  if (flashValue <= 0) return const SizedBox.shrink();
                  final opacity = flashValue < 0.3
                      ? flashValue / 0.3
                      : (1.0 - (flashValue - 0.3) / 0.7);
                  return Opacity(
                    opacity: opacity.clamp(0.0, 0.9),
                    child: Container(color: Colors.white),
                  );
                },
              ),
            ),

          if (_isSelected && _selectedPos != null)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, _) {
                  final radius = _glowScale.value * 30;
                  final glowOpacity = (1.0 - _glowCtrl.value).clamp(0.0, 0.8);
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
                            color: victimColor.withValues(alpha: glowOpacity),
                            blurRadius: radius * 0.8,
                            spreadRadius: radius * 0.3,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameContent(TiradedosController c) {
    return SafeArea(
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
                  color: AppColors.modeTiradedos.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.modeTiradedos.withValues(alpha: 0.3)),
                ),
                child: Text('VS', style: TextStyle(
                  color: AppColors.modeTiradedos, fontWeight: FontWeight.w900, fontSize: 12,
                )),
              ),
              _buildPlayerLabel(c.player2Name, c.player2Color, c.player2Icon),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) {
              final p = _pulseCtrl.value;
              return Icon(
                Icons.touch_app,
                size: 100 + p * 20,
                color: AppColors.modeTiradedos.withValues(alpha: 0.3 + p * 0.3),
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
                color: AppColors.modeTiradedos,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '⚡ TIRADEDOS ⚡',
              style: TextStyle(
                color: AppColors.modeTiradedos.withValues(alpha: 0.3),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
              ),
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
                color: AppColors.modeTiradedos,
                shadows: [Shadow(color: AppColors.modeTiradedos.withValues(alpha: 0.6), blurRadius: 30)],
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

  Widget _buildResultContent(
    String victimName, Color victimColor, IconData victimIcon,
    String safeName, Color safeColor, IconData safeIcon,
  ) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusCard(
                safeName, safeIcon, safeColor,
                'SE SALVA', Colors.greenAccent,
              ),
              _buildStatusCard(
                victimName, victimIcon, victimColor,
                'LA VÍCTIMA', Colors.redAccent,
              ),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _resultEntryCtrl,
            builder: (_, _) {
              final e = _resultEntryCtrl.value;
              return Opacity(
                opacity: e,
                child: Column(
                  children: [
                    Icon(victimIcon, size: 48, color: victimColor),
                    const SizedBox(height: 12),
                    Text('PIERDE', style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 14,
                      fontWeight: FontWeight.w700, letterSpacing: 4,
                    )),
                    const SizedBox(height: 4),
                    Text(victimName.toUpperCase(), style: TextStyle(
                      fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white,
                      letterSpacing: 6,
                      shadows: [Shadow(color: victimColor.withValues(alpha: 0.8), blurRadius: 30)],
                    )),
                    const SizedBox(height: 24),
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
    );
  }

  Widget _buildStatusCard(String name, IconData icon, Color color, String label, Color labelColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: Icon(icon, color: color, size: 36),
        ),
        const SizedBox(height: 8),
        Text(name.toUpperCase(), style: TextStyle(
          color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1,
        )),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: labelColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: labelColor.withValues(alpha: 0.3)),
          ),
          child: Text(label, style: TextStyle(
            color: labelColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2,
          )),
        ),
      ],
    );
  }
}
