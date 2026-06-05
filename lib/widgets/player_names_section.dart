import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/storage/local_storage.dart';

class PlayerNamesSection extends StatefulWidget {
  final void Function(String he, String she)? onChanged;

  const PlayerNamesSection({super.key, this.onChanged});

  @override
  State<PlayerNamesSection> createState() => PlayerNamesSectionState();
}

class PlayerNamesSectionState extends State<PlayerNamesSection> with SingleTickerProviderStateMixin {
  String _heName = 'ÉL';
  String _sheName = 'ELLA';
  late TextEditingController _heController;
  late TextEditingController _sheController;
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _heController = TextEditingController(text: _heName);
    _sheController = TextEditingController(text: _sheName);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _loadNames();
  }

  Future<void> _loadNames() async {
    final he = await LocalStorage.getHeName();
    final she = await LocalStorage.getSheName();
    if (!mounted) return;
    setState(() {
      _heName = he.isNotEmpty ? he : 'ÉL';
      _sheName = she.isNotEmpty ? she : 'ELLA';
      _heController.text = _heName;
      _sheController.text = _sheName;
    });
    widget.onChanged?.call(_heName, _sheName);
  }

  String get heName => _heName;
  String get sheName => _sheName;

  void _toggleExpanded() {
    if (_isExpanded) {
      _animController.reverse();
      setState(() => _isExpanded = false);
    } else {
      setState(() {
        _isExpanded = true;
        _heController.text = _heName;
        _sheController.text = _sheName;
      });
      _animController.forward();
    }
  }

  Future<void> _save() async {
    final he = _heController.text.trim();
    final she = _sheController.text.trim();
    final finalHe = he.isNotEmpty ? he : 'ÉL';
    final finalShe = she.isNotEmpty ? she : 'ELLA';
    await LocalStorage.saveNames(finalHe, finalShe);
    setState(() {
      _heName = finalHe;
      _sheName = finalShe;
    });
    widget.onChanged?.call(finalHe, finalShe);
    _animController.reverse();
    setState(() => _isExpanded = false);
  }

  void _cancel() {
    _heController.text = _heName;
    _sheController.text = _sheName;
    _animController.reverse();
    setState(() => _isExpanded = false);
  }

  @override
  void dispose() {
    _heController.dispose();
    _sheController.dispose();
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
                  // He side
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.male, color: Colors.blueAccent, size: 22),
                        ),
                        const SizedBox(width: 10),
                        _isExpanded
                            ? Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: _heController,
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: 'Nombre...',
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3))),
                                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                    ),
                                  ),
                                ),
                              )
                            : Flexible(
                                child: Text(
                                  _heName,
                                  style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
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
                  // She side
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isExpanded
                            ? Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: _sheController,
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: 'Nombre...',
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.3))),
                                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent)),
                                    ),
                                  ),
                                ),
                              )
                            : Flexible(
                                child: Text(
                                  _sheName,
                                  style: const TextStyle(color: Colors.pinkAccent, fontSize: 18, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.female, color: Colors.pinkAccent, size: 22),
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
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
                              foregroundColor: Colors.greenAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('GUARDAR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _cancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              foregroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('CANCELAR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
