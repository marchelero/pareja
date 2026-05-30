import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../widgets/neon_background.dart';

enum _DuelAction { shoot, redirect, load }

class DuelGameScreen extends StatefulWidget {
  final String heName;
  final String sheName;
  const DuelGameScreen({super.key, required this.heName, required this.sheName});
  @override
  State<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends State<DuelGameScreen> with TickerProviderStateMixin {
  late String _heName, _sheName;
  int _heLives = 3, _sheLives = 3;
  int _heStars = 0, _sheStars = 0;
  bool _isHeTurn = true;
  List<bool> _shells = [];
  bool _hasRedirect = true, _hasLoad = true;
  bool _isAnimating = false;
  bool _showResult = false;
  bool _resultIsLove = false;
  String? _starQuestion;
  String? _gameWinner;
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> _questions = [];
  bool _isLoading = true;
  late AnimationController _shotController, _flashController, _resultTextController;
  late Animation<double> _shotAnim;
  bool _wasRedirect = false;
  _DuelAction? _pendingAction;

  @override
  void initState() {
    super.initState();
    _heName = widget.heName;
    _sheName = widget.sheName;
    _shotController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shotAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shotController, curve: Curves.easeOutBack));
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _resultTextController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _initRound();
  }

  @override
  void dispose() {
    _shotController.dispose();
    _flashController.dispose();
    _resultTextController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initRound() async {
    if (_questions.isEmpty) {
      try {
        final r = await rootBundle.loadString('assets/data/duel_questions.json');
        _questions = (json.decode(r) as List).cast<String>();
      } catch (_) {}
      _questions.shuffle();
    }
    _shells = [];
    for (int i = 0; i < 3; i++) { _shells.add(true); }
    for (int i = 0; i < 3; i++) { _shells.add(false); }
    _shells.shuffle();
    setState(() => _isLoading = false);
  }

  String get _currentPlayerName => _isHeTurn ? _heName : _sheName;
  String get _partnerName => _isHeTurn ? _sheName : _heName;
  int get _currentStars => _isHeTurn ? _heStars : _sheStars;

  int get _loveCount => _shells.where((s) => s).length;
  int get _blankCount => _shells.where((s) => !s).length;
  bool get _canRedirect => _hasRedirect && _shells.length > 1 && !_isAnimating;
  bool get _canLoad => _hasLoad && !_isAnimating;

  void _fire(_DuelAction action) {
    if (_isAnimating || _shells.isEmpty || _gameWinner != null) return;
    _pendingAction = action;
    setState(() {
      _isAnimating = true;
      _showResult = false;
      _wasRedirect = false;
    });
    _shotController.reset();
    _flashController.reset();
    _shotController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _flashController.forward();
      HapticFeedback.heavyImpact();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _resolveShot();
    });
  }

  void _resolveShot() {
    final bool firstShell = _shells.removeAt(0);
    String target = _currentPlayerName;
    if (_pendingAction == _DuelAction.redirect) {
      target = _partnerName;
      _wasRedirect = true;
      _hasRedirect = false;
    }
    if (_pendingAction == _DuelAction.load) {
      _shells.insert(0, true);
      _hasLoad = false;
    }
    bool isLove = firstShell;
    if (_pendingAction == _DuelAction.load) isLove = false;
    setState(() {
      _isAnimating = false;
      _resultIsLove = isLove;
      _showResult = true;
      if (isLove) {
        if (target == _heName) { _heLives--; } else { _sheLives--; }
        if (_heLives <= 0 || _sheLives <= 0) {
          _gameWinner = _heLives <= 0 ? _sheName : _heName;
        }
      } else {
        if (!_wasRedirect) {
          if (_isHeTurn) { _heStars++; } else { _sheStars++; }
          if (_questions.isNotEmpty) { _starQuestion = _questions.removeAt(0); }
          if (_currentStars >= 3) { _gameWinner = _currentPlayerName; }
        }
      }
      _resultTextController.reset();
      _resultTextController.forward();
    });
  }

  void _nextTurn() {
    if (_shells.isEmpty && _gameWinner == null) {
      _initRound();
      setState(() {});
      return;
    }
    setState(() {
      _isHeTurn = !_isHeTurn;
      _showResult = false;
      _starQuestion = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Stack(
            children: [
              _buildMainContent(),
              if (_gameWinner != null) _buildWinnerOverlay(),
              _buildFlashOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildPlayerStatus(),
                  const SizedBox(height: 10),
                  _buildShellDisplay(),
                  const Spacer(),
                  _buildPistol(),
                  const SizedBox(height: 12),
                  _buildTurnText(),
                  const SizedBox(height: 12),
                  _buildActionButtons(),
                  if (!_showResult) _buildPowerupButtons(),
                  if (_showResult) _buildResultArea(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerStatus() {
    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, _) {
        final flash = _flashController.value;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _resultIsLove && flash > 0
                ? Colors.red.withOpacity(flash * 0.3)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(child: _playerCol(_heName, _heLives, _heStars, _isHeTurn, true)),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
              Expanded(child: _playerCol(_sheName, _sheLives, _sheStars, _isHeTurn, false)),
            ],
          ),
        );
      },
    );
  }

  Widget _playerCol(String name, int lives, int stars, bool isHeTurn, bool isHe) {
    final bool active = isHeTurn == isHe;
    return Column(
      children: [
        Text(
          name.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : Colors.white38,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i < lives ? Icons.favorite : Icons.favorite_border,
                color: i < lives ? Colors.red.shade400 : Colors.white24,
                size: 18,
              ),
            )),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(stars, (_) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: Text('⭐', style: TextStyle(fontSize: 14)),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildShellDisplay() {
    final love = _loveCount;
    final blank = _blankCount;
    return Column(
      children: [
        Text(
          'Restan: $love❤️ · $blank💨',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _shells.asMap().entries.map((e) {
            final int idx = e.key;
            final bool isLove = e.value;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: idx == 0 ? 42 : 32,
              height: idx == 0 ? 52 : 40,
              decoration: BoxDecoration(
                color: idx == 0
                    ? (isLove ? Colors.red.withOpacity(0.7) : Colors.grey.withOpacity(0.5))
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: idx == 0
                    ? Border.all(color: Colors.white.withOpacity(0.6), width: 2)
                    : Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Center(
                child: Text(
                  idx == 0 ? (isLove ? '❤️' : '💨') : '?',
                  style: TextStyle(fontSize: idx == 0 ? 20 : 16),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPistol() {
    return AnimatedBuilder(
      animation: _shotController,
      builder: (context, _) {
        final s = _shotAnim.value;
        final shake = sin(s * 2 * pi * 6) * 4 * (1 - s);
        return Transform.scale(
          scale: 1 + s * 0.2,
          child: Transform.translate(
            offset: Offset(shake, 0),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4081), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.pink.withOpacity(0.6), blurRadius: 30, spreadRadius: 4 * s),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: -pi / 4,
                    child: Icon(Icons.flight_takeoff, size: 50, color: Colors.white.withOpacity(0.3)),
                  ),
                  const Text('❤️', style: TextStyle(fontSize: 36)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTurnText() {
    return Text(
      'Turno de ${_currentPlayerName.toUpperCase()}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 3))],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: _isAnimating || _showResult || _gameWinner != null ? null : () => _fire(_DuelAction.shoot),
          icon: const Icon(Icons.gps_fixed, size: 24),
          label: const Text('DISPARARME', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            elevation: 8,
            disabledBackgroundColor: Colors.white12,
          ),
        ),
      ),
    );
  }

  Widget _buildPowerupButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _powerupBtn('🎯 Redirigir', _canRedirect, () => _fire(_DuelAction.redirect)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _powerupBtn('💥 Cargar', _canLoad, () => _fire(_DuelAction.load)),
          ),
        ],
      ),
    );
  }

  Widget _powerupBtn(String label, bool enabled, VoidCallback onTap) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: SizedBox(
        height: 42,
        child: OutlinedButton(
          onPressed: enabled ? onTap : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: enabled ? Colors.pinkAccent : Colors.white12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    return AnimatedBuilder(
      animation: _resultTextController,
      builder: (context, _) {
        final t = _resultTextController.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - t)),
            child: Column(
              children: [
                if (_starQuestion != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)],
                    ),
                    child: Column(
                      children: [
                        const Text('⭐ +1 PUNTO CITA', style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 10),
                        Text(_starQuestion!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 45,
                  child: ElevatedButton.icon(
                    onPressed: _nextTurn,
                    icon: const Icon(Icons.skip_next, size: 20),
                    label: Text(_shells.isEmpty ? 'SIGUIENTE RONDA' : 'SIGUIENTE TURNO', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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

  Widget _buildFlashOverlay() {
    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, _) {
        final f = _flashController.value;
        if (f <= 0) return const SizedBox.shrink();
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: _resultIsLove
                  ? Colors.red.withOpacity(f * 0.35)
                  : Colors.white.withOpacity(f * 0.3),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWinnerOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text(
                '${_gameWinner!.toUpperCase()} GANA',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3),
              ),
              const SizedBox(height: 12),
              Text(
                '¡Elige un gran reto final para la pareja!',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
              ),
              const SizedBox(height: 30),
              _rewardsList(),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('VOLVER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardsList() {
    final rewards = [
      '💋 Beso largo de 30 segundos',
      '💆 Masaje de 5 minutos',
      '🕯️ Cena a la luz de velas esta semana',
      '🎬 Elegir la próxima película',
      '💌 Declaración de amor escrita',
      '🍳 Desayuno en cama',
    ];
    return Column(
      children: rewards.map((r) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
        child: Text(r, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15)),
      )).toList(),
    );
  }
}
