/// Configuracion de caps diarios para free tier.
///
/// - [dailyCap] = 0: sin limite (ligeros + pesados)
/// - [dailyCap] > 0: limite diario (medianos), se puede extender +1 via rewarded ad
enum GameTier { ligero, mediano, pesado }

enum GameCap {
  // ── Pesados: contenido denso, larga duracion. Sin cap. ──
  yoNunca('Yo Nunca', GameTier.pesado, 0),
  preguntas('Preguntas', GameTier.pesado, 0),
  sinPalabras('Sin palabras', GameTier.pesado, 0),

  // ── Medianos: ritmo medio. Cap 3/dia para free, +1 via ad rewarded. ──
  ruleta('Ruleta', GameTier.mediano, 3),
  chupitos('Chupitos', GameTier.mediano, 3),
  bomba('Bomba', GameTier.mediano, 3),
  dueloNocturno('Duelo Nocturno', GameTier.mediano, 3),
  altoAlFuego('Alto al Fuego', GameTier.mediano, 3),

  // ── Ligeros: rapidos, re-jugables infinitamente. Sin cap. ──
  ruletaRusa('Ruleta Rusa', GameTier.ligero, 0),
  memoria('Memoria', GameTier.ligero, 0),
  pares('Pares', GameTier.ligero, 0),
  mentiroso('Mentiroso', GameTier.ligero, 0),
  aTiempo('A TIEMPO', GameTier.ligero, 0),
  premiado('Premiado', GameTier.ligero, 0);

  final String displayName;
  final GameTier tier;
  final int dailyCap;

  const GameCap(this.displayName, this.tier, this.dailyCap);

  /// True si este juego lleva cap diario (medianos).
  bool get isCapped => dailyCap > 0;

  /// Cap por defecto (el `dailyCap` del enum).
  int get defaultCap => dailyCap;

  /// Lookup por nombre exacto (case-sensitive). Retorna null si no existe.
  static GameCap? fromName(String name) {
    for (final cap in GameCap.values) {
      if (cap.displayName == name) return cap;
    }
    return null;
  }

  /// Todas las entradas (constante en tiempo de compilacion).
  static const List<GameCap> all = GameCap.values;
}
