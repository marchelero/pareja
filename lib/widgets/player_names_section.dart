import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/storage/local_storage.dart';
import 'game_button.dart';

class PlayerNamesSection extends StatefulWidget {
  final void Function(String p1, String p2)? onChanged;
  final IconData player1Icon;
  final IconData player2Icon;
  final Color player1Color;
  final Color player2Color;

  const PlayerNamesSection({
    super.key,
    this.onChanged,
    required this.player1Icon,
    required this.player2Icon,
    required this.player1Color,
    required this.player2Color,
  });

  @override
  State<PlayerNamesSection> createState() => PlayerNamesSectionState();
}

class PlayerNamesSectionState extends State<PlayerNamesSection> with SingleTickerProviderStateMixin {
  String _player1Name = 'ÉL';
  String _player2Name = 'ELLA';
  late TextEditingController _p1Controller;
  late TextEditingController _p2Controller;
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _p1Controller = TextEditingController(text: _player1Name);
    _p2Controller = TextEditingController(text: _player2Name);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _loadNames();
  }

  Future<void> _loadNames() async {
    final p1 = await LocalStorage.getPlayer1Name();
    final p2 = await LocalStorage.getPlayer2Name();
    if (!mounted) return;
    setState(() {
      _player1Name = p1.isNotEmpty ? p1 : 'ÉL';
      _player2Name = p2.isNotEmpty ? p2 : 'ELLA';
      _p1Controller.text = _player1Name;
      _p2Controller.text = _player2Name;
    });
    widget.onChanged?.call(_player1Name, _player2Name);
  }

  String get player1Name => _player1Name;
  String get player2Name => _player2Name;

  void _toggleExpanded() {
    if (_isExpanded) {
      _animController.reverse();
      setState(() => _isExpanded = false);
    } else {
      setState(() {
        _isExpanded = true;
        _p1Controller.text = _player1Name;
        _p2Controller.text = _player2Name;
      });
      _animController.forward();
    }
  }

  Future<void> _save() async {
    final p1 = _p1Controller.text.trim();
    final p2 = _p2Controller.text.trim();
    final finalP1 = p1.isNotEmpty ? p1 : 'ÉL';
    final finalP2 = p2.isNotEmpty ? p2 : 'ELLA';
    await LocalStorage.savePlayer1Name(finalP1);
    await LocalStorage.savePlayer2Name(finalP2);
    setState(() {
      _player1Name = finalP1;
      _player2Name = finalP2;
    });
    widget.onChanged?.call(finalP1, finalP2);
    _animController.reverse();
    setState(() => _isExpanded = false);
  }

  void _cancel() {
    _p1Controller.text = _player1Name;
    _p2Controller.text = _player2Name;
    _animController.reverse();
    setState(() => _isExpanded = false);
  }

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isExpanded ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _isExpanded ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Player 1 side
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.player1Color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(widget.player1Icon, color: widget.player1Color, size: 22),
                        ),
                        const SizedBox(width: 10),
                        _isExpanded
                            ? Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: _p1Controller,
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: 'Nombre...',
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.player1Color.withValues(alpha: 0.3))),
                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.player1Color)),
                                    ),
                                  ),
                                ),
                              )
                            : Flexible(
                                child: Text(
                                  _player1Name,
                                  style: TextStyle(color: widget.player1Color, fontSize: 18, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      ],
                    ),
                  ),
                  // Separator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('&', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 18, fontWeight: FontWeight.w300)),
                  ),
                  // Player 2 side
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isExpanded
                            ? Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: _p2Controller,
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: 'Nombre...',
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.player2Color.withValues(alpha: 0.3))),
                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.player2Color)),
                                    ),
                                  ),
                                ),
                              )
                            : Flexible(
                                child: Text(
                                  _player2Name,
                                  style: TextStyle(color: widget.player2Color, fontSize: 18, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.player2Color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(widget.player2Icon, color: widget.player2Color, size: 22),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit button - only when collapsed
                  if (!_isExpanded)
                    GestureDetector(
                      onTap: _toggleExpanded,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white54, size: 18),
                      ),
                    ),
                ],
              ),
              // GUARDAR / CANCELAR buttons - only when editing
              SizeTransition(
                sizeFactor: _expandAnimation,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: GameButton(
                            text: 'GUARDAR',
                            onPressed: _save,
                            style: GameButtonStyle.primary,
                            height: 40,
                            customColor: Colors.greenAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: GameButton(
                            text: 'CANCELAR',
                            onPressed: _cancel,
                            style: GameButtonStyle.secondary,
                            height: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
