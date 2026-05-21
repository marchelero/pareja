import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/models/most_likely_question.dart';
import '../../widgets/neon_background.dart';

class MostLikelyGameScreen extends StatefulWidget {
  final int bestOf;
  final bool isHotMode;
  final String heName;
  final String sheName;

  const MostLikelyGameScreen({
    super.key,
    required this.bestOf,
    required this.isHotMode,
    required this.heName,
    required this.sheName,
  });

  @override
  State<MostLikelyGameScreen> createState() => _MostLikelyGameScreenState();
}

class _MostLikelyGameScreenState extends State<MostLikelyGameScreen> {
  List<MostLikelyQuestion> _allQuestions = [];
  List<MostLikelyQuestion> _availableQuestions = [];
  MostLikelyQuestion? _currentQuestion;

  bool _isLoading = true;
  int _roundNumber = 1;

  int _scoreHe = 0;
  int _scoreShe = 0;
  late int _pointsToWin;

  bool _hasVotedHe = false;
  bool _hasVotedShe = false;
  bool? _heVotedFor; // true = él, false = ella
  bool? _sheVotedFor; // true = él, false = ella
  bool _isRevealed = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pointsToWin = (widget.bestOf / 2).floor() + 1;
    _initGame();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String fileName) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _initGame() async {
    final String jsonStr = await rootBundle.loadString('assets/data/most_likely_questions.json');
    final List<dynamic> data = json.decode(jsonStr);
    _allQuestions = data.map((json) => MostLikelyQuestion.fromJson(json)).toList();
    _availableQuestions = _allQuestions.where((q) => q.isHot == widget.isHotMode).toList();
    _shuffleQuestions();
    _nextQuestion();
    setState(() => _isLoading = false);
  }

  void _shuffleQuestions() {
    _availableQuestions.shuffle(Random());
  }

  void _nextQuestion() {
    if (_availableQuestions.isEmpty) {
      _availableQuestions = _allQuestions.where((q) => q.isHot == widget.isHotMode).toList();
      _shuffleQuestions();
    }
    setState(() {
      _currentQuestion = _availableQuestions.removeAt(0);
      _hasVotedHe = false;
      _hasVotedShe = false;
      _heVotedFor = null;
      _sheVotedFor = null;
      _isRevealed = false;
    });
  }

  void _voteHe() {
    if (_hasVotedHe || _isRevealed) return;
    _playSound('clic.mp3');
    setState(() {
      _hasVotedHe = true;
      _heVotedFor = true; // voted for himself (ÉL)
    });
    _checkBothVoted();
  }

  void _voteShe() {
    if (_hasVotedShe || _isRevealed) return;
    _playSound('clic.mp3');
    setState(() {
      _hasVotedShe = true;
      _sheVotedFor = false; // voted for herself (ELLA)
    });
    _checkBothVoted();
  }

  void _voteHeForHer() {
    if (_hasVotedHe || _isRevealed) return;
    _playSound('clic.mp3');
    setState(() {
      _hasVotedHe = true;
      _heVotedFor = false; // voted for her (ELLA)
    });
    _checkBothVoted();
  }

  void _voteSheForHim() {
    if (_hasVotedShe || _isRevealed) return;
    _playSound('clic.mp3');
    setState(() {
      _hasVotedShe = true;
      _sheVotedFor = true; // voted for him (ÉL)
    });
    _checkBothVoted();
  }

  void _checkBothVoted() {
    if (_hasVotedHe && _hasVotedShe) {
      _revealResult();
    }
  }

  void _revealResult() {
    final bool match = _heVotedFor == _sheVotedFor;
    if (match) {
      _playSound('level_up.mp3');
      setState(() {
        _scoreHe++;
        _scoreShe++;
        _isRevealed = true;
      });
    } else {
      _playSound('clic.mp3');
      setState(() => _isRevealed = true);
    }
  }

  void _nextRound() {
    if (_scoreHe >= _pointsToWin || _scoreShe >= _pointsToWin) {
      _showWinnerDialog();
    } else {
      _playSound('clic.mp3');
      setState(() {
        _roundNumber++;
        _currentQuestion = null;
      });
      _nextQuestion();
    }
  }

  void _showWinnerDialog() {
    final bool heWon = _scoreHe >= _pointsToWin;
    final String winnerName = heWon ? widget.heName : widget.sheName;
    final Color winnerColor = heWon ? Colors.blueAccent : Colors.pinkAccent;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [winnerColor.withOpacity(0.4), Colors.transparent],
                radius: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 120, color: Colors.amber),
                const SizedBox(height: 30),
                const Text(
                  '¡TENEMOS GANADOR!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 20),
                Text(
                  winnerName.toUpperCase(),
                  style: TextStyle(
                    color: winnerColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: winnerColor, blurRadius: 20)],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ha llegado a $_pointsToWin puntos.',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      const Text('MARCADOR FINAL', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(widget.heName, style: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('$_scoreHe', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const Text('VS', style: TextStyle(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold)),
                          Column(
                            children: [
                              Text(widget.sheName, style: const TextStyle(color: Colors.pinkAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('$_scoreShe', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      _playSound('clic.mp3');
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: winnerColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('VOLVER AL MENÚ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: NeonBackground(
        showIcons: false,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Text('$_scoreHe', style: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('-', style: TextStyle(color: Colors.white54, fontSize: 20)),
                          ),
                          Text('$_scoreShe', style: const TextStyle(color: Colors.pinkAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Round indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'RONDA $_roundNumber de ${widget.bestOf}',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                ),
              ),

              const Spacer(flex: 1),

              // Question
              if (_currentQuestion != null) ...[
                const Text(
                  '¿Quién es más probable que...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    _currentQuestion!.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                ),
                const Text(
                  '?',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ],

              const Spacer(flex: 1),

              // Voting area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  children: [
                    // ÉL button
                    Expanded(
                      child: _buildVoteButton(
                        label: widget.heName,
                        genderColor: Colors.blueAccent,
                        genderIcon: Icons.male,
                        isVoted: _hasVotedHe,
                        votedFor: _heVotedFor,
                        canVote: !_hasVotedHe && !_isRevealed,
                        onVote: _voteHe,
                        onVoteOther: _voteHeForHer,
                        isRevealedOther: _isRevealed && _sheVotedFor == true,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // ELLA button
                    Expanded(
                      child: _buildVoteButton(
                        label: widget.sheName,
                        genderColor: Colors.pinkAccent,
                        genderIcon: Icons.female,
                        isVoted: _hasVotedShe,
                        votedFor: _sheVotedFor,
                        canVote: !_hasVotedShe && !_isRevealed,
                        onVote: _voteSheForHim,
                        onVoteOther: _voteShe,
                        isRevealedOther: _isRevealed && _heVotedFor == false,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Result / Instruction area
              if (_isRevealed)
                _buildResultPanel()
              else if (_hasVotedHe && _hasVotedShe)
                const SizedBox.shrink()
              else
                _buildInstruction(),

              const Spacer(flex: 1),

              // Next round button
              if (_isRevealed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: SizedBox(
                    width: 260,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextRound,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                      ),
                      child: const Text('SIGUIENTE RONDA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                    ),
                  ),
                )
              else
                const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteButton({
    required String label,
    required Color genderColor,
    required IconData genderIcon,
    required bool isVoted,
    required bool? votedFor,
    required bool canVote,
    required VoidCallback onVote,
    required VoidCallback onVoteOther,
    required bool isRevealedOther,
  }) {
    final bool tappedSelf = isVoted && votedFor == true;
    final bool tappedOther = isVoted && votedFor == false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Vote for SELF
        GestureDetector(
          onTap: canVote ? onVote : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: tappedSelf
                  ? genderColor.withOpacity(0.3)
                  : (isVoted ? Colors.white.withOpacity(0.05) : genderColor.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: tappedSelf
                    ? genderColor
                    : (isVoted ? Colors.white12 : genderColor.withOpacity(0.3)),
                width: tappedSelf ? 3 : 1.5,
              ),
              boxShadow: tappedSelf
                  ? [BoxShadow(color: genderColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(genderIcon, color: tappedSelf ? genderColor : Colors.white54, size: 32),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: tappedSelf ? Colors.white : Colors.white54,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (tappedSelf)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Vote for OTHER
        GestureDetector(
          onTap: canVote ? onVoteOther : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            height: 70,
            decoration: BoxDecoration(
              color: tappedOther
                  ? Colors.amber.withOpacity(0.2)
                  : (isVoted ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: tappedOther
                    ? Colors.amber
                    : (isVoted ? Colors.white12 : Colors.white24),
                width: tappedOther ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tappedOther ? 'VOTADO' : 'LA OTRA',
                  style: TextStyle(
                    color: tappedOther ? Colors.amber : Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (tappedOther)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                  ),
              ],
            ),
          ),
        ),

        // Revealed: other player voted for this person
        if (isRevealedOther)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'VOTARON POR ESTE',
                    style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultPanel() {
    final bool match = _heVotedFor == _sheVotedFor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: match ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: match ? Colors.greenAccent.withOpacity(0.5) : Colors.orange.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            match ? Icons.check_circle : Icons.cancel,
            color: match ? Colors.greenAccent : Colors.orange,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            match ? '¡COINCIDIERON!' : 'NO COINCIDIERON',
            style: TextStyle(
              color: match ? Colors.greenAccent : Colors.orange,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            match
                ? '+1 punto para cada uno'
                : '${widget.heName} votó por ${_heVotedFor! ? widget.heName : widget.sheName} · ${widget.sheName} votó por ${_sheVotedFor! ? widget.heName : widget.sheName}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: match ? Colors.greenAccent.withOpacity(0.8) : Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                Text(
                  _getInstructionText(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getInstructionText() {
    if (!_hasVotedHe && !_hasVotedShe) {
      return 'CADA UNO TOCA QUIÉN CREE';
    } else if (!_hasVotedHe) {
      return '${widget.heName} TIENE QUE VOTAR';
    } else {
      return '${widget.sheName} TIENE QUE VOTAR';
    }
  }
}
