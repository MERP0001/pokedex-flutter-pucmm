import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importa shared_preferences

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isFavorite = false;

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

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1.0;
        _controller.forward();
      });
    });

    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFavorite = prefs.getBool('favorite_${widget.pokemonId}') ?? false;
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFavorite = !isFavorite;
      prefs.setBool('favorite_${widget.pokemonId}', isFavorite);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playCry(Pokemon pokemon) async {
    final url =
        'https://play.pokemonshowdown.com/audio/cries/${pokemon.name.toLowerCase()}.mp3';
    await _audioPlayer.play(url as Source);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/pokeball (2).png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Detalles del Pokémon',
              style: TextStyle(fontFamily: 'DiaryOfAn8BitMage'),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 7, 169, 244),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
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

          final isEeveelution = [
            'vaporeon',
            'jolteon',
            'flareon',
            'espeon',
            'umbreon',
            'leafeon',
            'glaceon',
            'sylveon'
          ].contains(pokemonData['name'].toLowerCase());

          final evolutions = evolutionsData
              .where((evolutionData) => evolutionData['id'] != widget.pokemonId)
              .where((evolutionData) {
            if (isEeveelution) {
              return evolutionData['name'].toLowerCase() == 'eevee';
            } else {
              return true;
            }
          }).map((evolutionData) {
            return {
              'id': evolutionData['id'],
              'name': evolutionData['name'],
              'types': (evolutionData['pokemon_v2_pokemons'][0]
                      ['pokemon_v2_pokemontypes'] as List)
                  .map((type) => type['pokemon_v2_type']['name'] as String)
                  .toList(),
            };
          }).toList()
            ..sort((a, b) => a['id'].compareTo(b['id']));

          final pokemon = Pokemon(
            id: pokemonData['id'] ?? 0,
            name: pokemonData['name'] ?? 'Desconocido',
            types: (pokemonData['pokemon_v2_pokemontypes'] as List?)
                    ?.map((type) => type['pokemon_v2_type']['name'] as String)
                    .toList() ??
                ['Desconocido'],
            generation: pokemonData['pokemon_v2_pokemonspecy']
                    ?['pokemon_v2_generation']?['name'] ??
                'Desconocido',
            height: pokemonData['height'] ?? 0.0,
            weight: pokemonData['weight'] ?? 0.0,
            abilities: (pokemonData['pokemon_v2_pokemonabilities'] as List?)
                    ?.map((ability) =>
                        ability['pokemon_v2_ability']['name'] as String)
                    .toList() ??
                ['Desconocido'],
            stats: (pokemonData['pokemon_v2_pokemonstats'] as List?)
                    ?.map((stat) => stat['pokemon_v2_stat']['name'] as String)
                    .toList() ??
                ['Desconocido'],
            moves: (pokemonData['pokemon_v2_pokemonmoves'] as List?)
                    ?.map((move) => move['pokemon_v2_move']['name'] as String)
                    .toList() ??
                ['Desconocido'],
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SlideTransition(
                    position: _offsetAnimation,
                    child: Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _playCry(pokemon),
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
                  AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 1500),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.blue.shade50,
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
                            Text(
                              pokemon.types.join(', '),
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
                  AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 1500),
                    child: Row(
                      children: [
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: Colors.green.shade50,
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
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: Colors.green.shade50,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                              pokemon.abilities.join(', '),
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
                              pokemon.stats.join(', '),
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
                              pokemon.moves.join(', '),
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
                                        builder: (context) => PokemonDetailPage(
                                            pokemonId: evolution['id']),
                                      ),
                                    );
                                  },
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
