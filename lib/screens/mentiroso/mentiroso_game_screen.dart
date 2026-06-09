import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mentiroso_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/dice_widget.dart';
import '../../widgets/game_button.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/game_result_screen.dart';
import '../../services/haptics_service.dart';

class MentirosoGameScreen extends StatefulWidget {
  final MentirosoController controller;

  const MentirosoGameScreen({super.key, required this.controller});

  @override
  State<MentirosoGameScreen> createState() => _MentirosoGameScreenState();
}

class _MentirosoGameScreenState extends State<MentirosoGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinCtrl;
  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim;

  bool _isRolling = false;
  bool _isRevealingResult = false;
  int _displayDice1 = 3;
  int _displayDice2 = 3;
  Timer? _faceCycler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().incrementGamePlayed('Mentiroso');
    });
    widget.controller.addListener(_onChange);

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _revealAnim = CurvedAnimation(
      parent: _revealCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    widget.controller.dispose();
    _spinCtrl.dispose();
    _revealCtrl.dispose();
    _faceCycler?.cancel();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  // ── ROLL ANIMATION ──

  void _startRoll() {
    widget.controller.audioService.playDice();
    widget.controller.rollDice();
    setState(() => _isRolling = true);

    _spinCtrl.reset();
    _spinCtrl.repeat();

    final rng = Random();
    _faceCycler = Timer.periodic(const Duration(milliseconds: 70), (_) {
      setState(() {
        _displayDice1 = rng.nextInt(6) + 1;
        _displayDice2 = rng.nextInt(6) + 1;
      });
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      _faceCycler?.cancel();
      _spinCtrl.stop();
      _spinCtrl.reset();
      setState(() {
        _isRolling = false;
        _displayDice1 = widget.controller.dice1;
        _displayDice2 = widget.controller.dice2;
      });
      widget.controller.revealDice();
    });
  }

  void _revealResultDice() {
    setState(() => _isRevealingResult = true);
    _displayDice1 = widget.controller.dice1;
    _displayDice2 = widget.controller.dice2;
    _revealCtrl.forward();
  }

  // ── FINISH GAME ──

  void _finishGame() {
    final settings = context.read<SettingsProvider>();
    final isTie = widget.controller.scoreP1 == widget.controller.scoreP2;
    final p1Wins = widget.controller.scoreP1 > widget.controller.scoreP2;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameResultScreen(
        gameName: 'Mentiroso',
        gameColor: AppColors.modeMentiroso,
        winnerName: isTie
            ? 'Empate'
            : p1Wins
                ? settings.displayName1
                : settings.displayName2,
        winnerColor: isTie
            ? AppColors.modeMentiroso
            : p1Wins
                ? settings.player1Color
                : settings.player2Color,
        player1Name: settings.displayName1,
        player2Name: settings.displayName2,
        player1Icon: settings.player1Icon,
        player2Icon: settings.player2Icon,
        player1Color: settings.player1Color,
        player2Color: settings.player2Color,
        scoreP1: widget.controller.scoreP1,
        scoreP2: widget.controller.scoreP2,
        isTie: isTie,
        onReplay: () {
          Navigator.pop(ctx);
          widget.controller.resetGame();
        },
        onGameMenu: () => Navigator.of(ctx)
          ..pop()
          ..pop(),
        onMainMenu: () =>
            Navigator.of(ctx).popUntil((route) => route.isFirst),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Stack(
            children: [
              _buildBody(),
              if (widget.controller.step == MentirosoStep.handoff)
                _buildHandoffOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.controller.step) {
      case MentirosoStep.roll:
        return _buildRollStep();
      case MentirosoStep.select:
        return _buildSelectStep();
      case MentirosoStep.handoff:
        return _buildBlankUnderlay();
      case MentirosoStep.guess:
        return _buildGuessStep();
      case MentirosoStep.result:
        return _buildResultStep();
    }
  }

  // ── ROLL STEP ──

  Widget _buildRollStep() {
    return Column(
      children: [
        _buildHeader(),
        const Spacer(flex: 2),
        _buildDiceRow(),
        const SizedBox(height: 40),
        if (!_isRolling)
          GameButton(
            text: 'TIRAR DADOS',
            icon: Icons.casino,
            onPressed: _startRoll,
          )
        else
          const Text(
            'Girando...',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        const Spacer(flex: 3),
      ],
    );
  }

  // ── SELECT STEP ──

  Widget _buildSelectStep() {
    final ctrl = widget.controller;

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 6),
        Text(
          'Tus dados: ${ctrl.dice1} y ${ctrl.dice2}',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 4),
        _buildDiceRow(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Elige una afirmaci\u00f3n:',
            style: TextStyle(
              color: AppColors.modeMentiroso,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 4,
            children: List.generate(MentirosoController.statements.length, (i) {
              return _StatementChip(
                index: i,
                text: MentirosoController.statements[i],
                isTrue: ctrl.isStatementTrue(i),
                isSelected: ctrl.selectedIndex == i,
                onTap: () => ctrl.selectStatement(i),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ctrl.selectedIndex != null
              ? GameButton(
                  text: 'LISTO, PASA EL CELULAR',
                  icon: Icons.phone_iphone,
                  onPressed: () {
                    widget.controller.audioService.playClick();
                    ctrl.confirmBluff();
                  },
                )
              : GameButton(
                  text: 'LISTO, PASA EL CELULAR',
                  icon: Icons.phone_iphone,
                  onPressed: () {},
                  customColor: Colors.grey,
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── HANDOFF OVERLAY ──

  Widget _buildHandoffOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            Icons.phone_iphone,
            color: AppColors.modeMentiroso,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            'Pasa el celular al\n${widget.controller.inquisitorName(context.read<SettingsProvider>())}...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '\u00a1No mires!',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          GameButton(
            text: 'YA LO TENGO',
            icon: Icons.visibility,
            onPressed: () {
              widget.controller.audioService.playClick();
              widget.controller.startInvestigation();
            },
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildBlankUnderlay() {
    return const SizedBox.shrink();
  }

  // ── GUESS STEP ──

  Widget _buildGuessStep() {
    final ctrl = widget.controller;

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Icon(
          Icons.help_outline,
          color: AppColors.modeMentiroso,
          size: 48,
        ),
        const SizedBox(height: 20),
        Text(
          '${ctrl.liarName(context.read<SettingsProvider>())} afirma:',
          style: const TextStyle(color: Colors.white54, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.modeMentiroso.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '"${ctrl.selectedStatementText}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          '\u00bfVerdad o mentira?',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              Expanded(
                child: _VerdadButton(
                  onTap: () {
                    widget.controller.audioService.playClick();
                    ctrl.guess(true);
                    _revealResultDice();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MentiraButton(
                  onTap: () {
                    widget.controller.audioService.playClick();
                    ctrl.guess(false);
                    _revealResultDice();
                  },
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // ── RESULT STEP ──

  Widget _buildResultStep() {
    final ctrl = widget.controller;
    final settings = context.read<SettingsProvider>();

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        if (_isRevealingResult)
          ScaleTransition(
            scale: _revealAnim,
            child: _buildDiceRow(),
          )
        else
          _buildDiceRow(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.modeMentiroso.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '"${ctrl.selectedStatementText}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ctrl.selectedWasTrue
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ctrl.selectedWasTrue ? 'ERA VERDAD' : 'ERA MENTIRA',
                    style: TextStyle(
                      color: ctrl.selectedWasTrue ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            ctrl.getRoundResultText(settings),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ScoreChip(
              label: settings.displayName1,
              score: ctrl.scoreP1,
              color: settings.player1Color,
            ),
            const SizedBox(width: 20),
            _ScoreChip(
              label: settings.displayName2,
              score: ctrl.scoreP2,
              color: settings.player2Color,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!ctrl.isGameOver)
          GameButton(
            text: 'SIGUIENTE RONDA',
            icon: Icons.skip_next,
            onPressed: () {
              widget.controller.audioService.playClick();
              ctrl.nextRound();
              setState(() {
                _isRevealingResult = false;
                _displayDice1 = 3;
                _displayDice2 = 3;
              });
            },
          )
        else
          GameButton(
            text: 'VER RESULTADO FINAL',
            icon: Icons.flag,
            onPressed: () {
              widget.controller.audioService.playClick();
              _finishGame();
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── SHARED WIDGETS ──

  Widget _buildHeader() {
    final ctrl = widget.controller;
    final settings = context.read<SettingsProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 30),
            onPressed: () { HapticsService.light(); Navigator.pop(context); },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreChip(
                label: settings.displayName1,
                score: ctrl.scoreP1,
                color: settings.player1Color,
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Text(
                    'RONDA',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '${ctrl.round}/${ctrl.totalRounds}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              _ScoreChip(
                label: settings.displayName2,
                score: ctrl.scoreP2,
                color: settings.player2Color,
              ),
            ],
          ),
          GameHelpModal.helpButton(_showHelpModal),
        ],
      ),
    );
  }

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'El jugador activo lanza los dados y ve su resultado.'),
        GameHelpModal.step('2', 'Elige una afirmaci\u00f3n (puede ser verdad o mentira).'),
        GameHelpModal.step('3', 'Pasa el celular al otro jugador.'),
        GameHelpModal.step('4', 'El segundo jugador debe decidir si la afirmaci\u00f3n es verdad o mentira.'),
        GameHelpModal.bullet(null, 'Acierta', Colors.greenAccent, 'punto para el que adivina'),
        GameHelpModal.bullet(null, 'Falla', Colors.redAccent, 'punto para el mentiroso'),
        GameHelpModal.bullet(null, 'Gana', AppColors.modeMentiroso, 'quien m\u00e1s puntos acumule al final'),
      ],
    );
  }

  Widget _buildDiceRow() {
    final rotation = _spinCtrl.value * 2 * pi;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DiceWidget(
          value: _displayDice1,
          size: 90,
          rotation: _isRolling ? rotation : 0,
        ),
        const SizedBox(width: 24),
        DiceWidget(
          value: _displayDice2,
          size: 90,
          rotation: _isRolling ? rotation : 0,
        ),
      ],
    );
  }

}

// ── STATEMENT CHIP ──

class _StatementChip extends StatefulWidget {
  final int index;
  final String text;
  final bool isTrue;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatementChip({
    required this.index,
    required this.text,
    required this.isTrue,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StatementChip> createState() => _StatementChipState();
}

class _StatementChipState extends State<_StatementChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
    if (widget.isSelected) _glowCtrl.forward();
  }

  @override
  void didUpdateWidget(_StatementChip old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _glowCtrl.forward();
    } else if (!widget.isSelected && old.isSelected) {
      _glowCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neonColor = AppColors.modeMentiroso;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        final glow = _glowAnim.value;
        return GestureDetector(
          onTap: () { HapticsService.light(); widget.onTap(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? neonColor.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? neonColor
                    : Colors.white.withValues(alpha: 0.15),
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: neonColor.withValues(alpha: 0.4 * glow),
                        blurRadius: 8 + glow * 4,
                        spreadRadius: glow * 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isSelected)
                  Icon(Icons.auto_awesome,
                      color: neonColor, size: 10),
                if (widget.isSelected) const SizedBox(width: 4),
                Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.isSelected
                        ? Colors.white
                        : Colors.white54,
                    fontSize: 11,
                    fontWeight:
                        widget.isSelected ? FontWeight.bold : FontWeight.normal,
                    shadows: widget.isSelected
                        ? [
                            Shadow(
                              color: neonColor.withValues(alpha: 0.6),
                              blurRadius: 4,
                            )
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── VERDAD / MENTIRA BUTTONS ──

class _VerdadButton extends StatelessWidget {
  final VoidCallback onTap;
  const _VerdadButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticsService.light(); onTap(); },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withValues(alpha: 0.3),
              Colors.green.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check, color: Colors.greenAccent, size: 36),
            const SizedBox(height: 4),
            const Text(
              'VERDAD',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MentiraButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MentiraButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticsService.light(); onTap(); },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withValues(alpha: 0.3),
              Colors.red.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close, color: Colors.redAccent, size: 36),
            const SizedBox(height: 4),
            const Text(
              'MENTIRA',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SCORE CHIP ──

class _ScoreChip extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _ScoreChip({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
