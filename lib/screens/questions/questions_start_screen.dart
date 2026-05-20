import 'package:flutter/material.dart';
import '../../core/storage/local_storage.dart';
import 'coin_flip_screen.dart';
import '../../widgets/neon_background.dart';
import 'dart:ui';

class QuestionsStartScreen extends StatefulWidget {
  const QuestionsStartScreen({super.key});

  @override
  State<QuestionsStartScreen> createState() => _QuestionsStartScreenState();
}

class _QuestionsStartScreenState extends State<QuestionsStartScreen> {
  final TextEditingController _heController = TextEditingController();
  final TextEditingController _sheController = TextEditingController();
  int _selectedRounds = 10;
  final List<int> _roundOptions = [10, 20, 30, 40, 50];
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'General', 'icon': Icons.all_inclusive, 'color': Colors.blue},
    {'name': 'Romántico', 'icon': Icons.favorite, 'color': Colors.pink},
    {'name': 'Picante', 'icon': Icons.whatshot, 'color': Colors.deepOrange},
    {'name': 'Convivencia', 'icon': Icons.home, 'color': Colors.green},
    {'name': 'Futuro', 'icon': Icons.rocket_launch, 'color': Colors.purple},
    {'name': 'Viajes', 'icon': Icons.flight, 'color': Colors.teal},
    {'name': 'Pasatiempos', 'icon': Icons.sports_esports, 'color': Colors.indigo},
    {'name': 'Valores', 'icon': Icons.balance, 'color': Colors.brown},
    {'name': 'Humor', 'icon': Icons.mood, 'color': Colors.yellow.shade800},
    {'name': 'Profundo', 'icon': Icons.psychology, 'color': Colors.blueGrey},
    {'name': 'Trivia', 'icon': Icons.quiz, 'color': Colors.indigo},
    {'name': 'Flirteo', 'icon': Icons.favorite_border, 'color': Colors.redAccent},
  ];
  final Set<String> _selectedCategories = {'General', 'Romántico'};

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final he = await LocalStorage.getHeName();
    final she = await LocalStorage.getSheName();
    setState(() {
      _heController.text = he;
      _sheController.text = she;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text('CONFIGURAR PARTIDA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              foregroundColor: Colors.white,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Nombres de la Pareja', Icons.people),
                      const SizedBox(height: 15),
                      _buildGlassCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('  ÉL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: _heController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Nombre...',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                      prefixIcon: const Icon(Icons.male, color: Colors.blueAccent),
                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.3))),
                                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('  ELLA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: _sheController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Nombre...',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                      prefixIcon: const Icon(Icons.female, color: Colors.pinkAccent),
                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent.withOpacity(0.3))),
                                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              const SizedBox(height: 30),
              _buildSectionTitle('Número de Preguntas', Icons.timer),
              const SizedBox(height: 15),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _roundOptions.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final rounds = _roundOptions[index];
                    final isSelected = _selectedRounds == rounds;
                    return _RoundCard(
                      rounds: rounds,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedRounds = rounds),
                    );
                  },
                ),
              ),
              const SizedBox(height: 35),
              _buildSectionTitle('Categorías', Icons.category),
              const SizedBox(height: 15),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.3,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategories.contains(cat['name']);
                  return _CategoryCard(
                    name: cat['name'],
                    icon: cat['icon'],
                    color: cat['color'],
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          if (_selectedCategories.length > 1) {
                            _selectedCategories.remove(cat['name']);
                          }
                        } else {
                          _selectedCategories.add(cat['name']);
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
              _buildStartButton(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  ],
),
),
);
}

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 24),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return _buildGlassCard(
      child: InkWell(
        onTap: () async {
          final navigator = Navigator.of(context);
          await LocalStorage.saveNames(_heController.text, _sheController.text);
          if (!mounted) return;
          navigator.push(
            MaterialPageRoute(
              builder: (context) => CoinFlipScreen(
                maxRounds: _selectedRounds,
                categories: _selectedCategories.toList(),
                heName: _heController.text,
                sheName: _sheController.text,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.withOpacity(0.6), Colors.purple.withOpacity(0.4)],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            '¡EMPEZAR PARTIDA!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  final int rounds;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoundCard({required this.rounds, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$rounds',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              'Preg.',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
