import 'package:flutter/material.dart';

class DrinkGameOverDialog extends StatelessWidget {
  final String playerName;
  final bool isHe;
  final VoidCallback onVascoSecoSiguiente;

  const DrinkGameOverDialog({
    super.key,
    required this.playerName,
    required this.isHe,
    required this.onVascoSecoSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    final Color playerColor = isHe ? Colors.deepPurple : Colors.pink;
    final String imagePath = isHe ? 'assets/images/man_drinking.png' : 'assets/images/woman_drinking.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [playerColor.withValues(alpha: 0.5), Colors.black],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      width: 250, height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: playerColor.withValues(alpha: 0.5), blurRadius: 50, spreadRadius: 10),
                        ],
                      ),
                      child: ClipOval(child: Image.asset(imagePath, fit: BoxFit.cover)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              'SECO! SECO!',
              style: TextStyle(
                color: playerColor,
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
                width: double.infinity, height: 60,
                child: ElevatedButton(
                  onPressed: onVascoSecoSiguiente,
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
  }
}
