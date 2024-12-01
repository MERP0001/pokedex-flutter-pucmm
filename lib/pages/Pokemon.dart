class Pokemon {
  final int id;
  final String name;
  final List<String> types;
  final String generation;
  final double height;
  final double weight;
  final List<String> abilities;
  final List<String> stats;
  final List<String> moves;

  Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.generation,
    required this.height,
    required this.weight,
    required this.abilities,
    required this.stats,
    required this.moves,
  });
}
