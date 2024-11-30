import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:audioplayers/audioplayers.dart'; // Importa el paquete audioplayers

import 'Pokemon.dart';
import 'PokemonQueries.dart';

class PokemonDetailPage extends StatefulWidget {
  final int pokemonId;

  const PokemonDetailPage({super.key, required this.pokemonId});

  @override
  _PokemonDetailPageState createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends State<PokemonDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  double _opacity = 0.0;
  final AudioPlayer _audioPlayer =
      AudioPlayer(); // Crea una instancia de AudioPlayer

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Iniciar la animación de opacidad
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1.0;
        _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose(); // Asegúrate de liberar los recursos del AudioPlayer
    super.dispose();
  }

  Future<void> _playCry(Pokemon pokemon) async {
    final url =
        'https://play.pokemonshowdown.com/audio/cries/${pokemon.name.toLowerCase()}.mp3'; // URL del cry del Pokémon
    await _audioPlayer.play(url); // Reproduce el sonido desde la URL
  }

  @override
  Widget build(BuildContext context) {
    final typeColors = {
      'Normal': Colors.grey,
      'Fire': Colors.red,
      'Water': Colors.blue,
      'Electric': Colors.yellow,
      'Grass': Colors.green,
      'Ice': Colors.cyan,
      'Fighting': Colors.red,
      'Poison': Colors.purple,
      'Ground': Colors.brown,
      'Flying': Colors.blue,
      'Psychic': Colors.pink,
      'Bug': Colors.green,
      'Rock': Colors.brown,
      'Ghost': Colors.purple,
      'Dragon': Colors.purple,
      'Dark': Colors.black,
      'Steel': Colors.grey,
      'Fairy': Colors.pink,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalles del Pokémon',
          style: TextStyle(fontFamily: 'DiaryOfAn8BitMage'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Query(
        options: QueryOptions(
          document: gql(PokemonQueries.getPokemonDetails),
          variables: {'id': widget.pokemonId},
        ),
        builder: (QueryResult result, {fetchMore, refetch}) {
          if (result.hasException) {
            return Center(child: Text(result.exception.toString()));
          }

          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pokemonData = result.data?['pokemon_v2_pokemon_by_pk'];
          final evolutionsData = pokemonData['pokemon_v2_pokemonspecy']
                  ['pokemon_v2_evolutionchain']['pokemon_v2_pokemonspecies']
              as List<dynamic>;

          // Exclude the current Pokémon and sort evolutions by ID
          final evolutions = evolutionsData
              .where((evolutionData) => evolutionData['id'] != widget.pokemonId)
              .map((evolutionData) {
            return {
              'id': evolutionData['id'],
              'name': evolutionData['name'],
              'types': (evolutionData['pokemon_v2_pokemons'][0]
                      ['pokemon_v2_pokemontypes'] as List)
                  .map((type) => type['pokemon_v2_type']['name'] as String)
                  .toList(),
            };
          }).toList()
            ..sort((a, b) => a['id'].compareTo(b['id'])); // Sort by ID

          final pokemon = Pokemon(
            id: pokemonData['id'],
            name: pokemonData['name'],
            types: (pokemonData['pokemon_v2_pokemontypes'] as List?)
                    ?.map((type) => type['pokemon_v2_type']['name'])
                    .join(', ') ??
                'No types available',
            height: pokemonData['height'].toDouble(),
            weight: pokemonData['weight'].toDouble(),
            abilities: (pokemonData['pokemon_v2_pokemonabilities'] as List?)
                    ?.map((ability) => ability['pokemon_v2_ability']['name'])
                    .join(', ') ??
                'No abilities available',
            stats: (pokemonData['pokemon_v2_pokemonstats'] as List?)
                    ?.map((stat) =>
                        '${stat['pokemon_v2_stat']['name']}: ${stat['base_stat']}')
                    .join('\n') ??
                'No stats available',
            moves: (pokemonData['pokemon_v2_pokemonmoves'] as List?)
                    ?.map((move) => move['pokemon_v2_move']['name'])
                    .take(10)
                    .join(', ') ??
                'No moves available',
          );

          final backgroundColor =
              typeColors[pokemon.types.split(', ').first] ?? Colors.grey;

          return Container(
            color: backgroundColor
                .withOpacity(0.1), // Background color based on type
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagen y nombre animados
                    SlideTransition(
                      position: _offsetAnimation,
                      child: Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _playCry(
                                  pokemon), // Reproduce el cry al hacer clic
                              child: Image.network(
                                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${pokemon.id}.png',
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              pokemon.name.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sección de Tipo con animación de opacidad
                    AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 1500),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.blue.shade100, // Stronger color
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tipo',
                                style: TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Wrap(
                                spacing: 8.0,
                                children: pokemon.types.split(', ').map((type) {
                                  final typeColor =
                                      typeColors[type] ?? Colors.grey;
                                  return Chip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/icons/${type}.png',
                                          width: 24,
                                          height: 24,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          type,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'DiaryOfAn8BitMage',
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: typeColor,
                                    shape: StadiumBorder(
                                      side: BorderSide(color: typeColor),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Altura y peso con animación de opacidad
                    AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 1500),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.green.shade200, // Stronger color
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Altura',
                                style: TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${pokemon.height} m',
                                style: const TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 1500),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.green.shade200, // Stronger color
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Peso',
                                style: TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${pokemon.weight} kg',
                                style: const TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sección de Habilidades con animación de opacidad
                    AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 1500),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Habilidades',
                                style: TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                pokemon.abilities,
                                style: const TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sección de Estadísticas con animación de opacidad
                    AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 1500),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.purple.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estadísticas',
                                style: TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                pokemon.stats,
                                style: const TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sección de Movimientos con animación de opacidad
                    AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 1500),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.yellow.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Movimientos (10 primeros)',
                                style: TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                pokemon.moves,
                                style: const TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sección de Evoluciones
                    AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 1500),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.teal.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Evoluciones',
                                style: TextStyle(
                                  fontFamily: 'DiaryOfAn8BitMage',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (evolutions.isEmpty)
                                const Text(
                                  'No evolutions available',
                                  style: TextStyle(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontSize: 16,
                                  ),
                                )
                              else
                                ...evolutions.map((evolution) {
                                  return ListTile(
                                    leading: Image.network(
                                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${evolution['id']}.png',
                                      height: 40,
                                      width: 40,
                                    ),
                                    title: Text(
                                      evolution['name'],
                                      style: const TextStyle(
                                        fontFamily: 'DiaryOfAn8BitMage',
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      (evolution['types'] as List).join(', '),
                                      style: const TextStyle(
                                        fontFamily: 'DiaryOfAn8BitMage',
                                        fontSize: 14,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PokemonDetailPage(
                                                  pokemonId: evolution['id']),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
