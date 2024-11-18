import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'Pokemon.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          document: gql('''
            query GetPokemonDetails(\$id: Int!) {
              pokemon_v2_pokemon_by_pk(id: \$id) {
                id
                name
                height
                weight
                pokemon_v2_pokemontypes {
                  pokemon_v2_type {
                    name
                  }
                }
                pokemon_v2_pokemonabilities {
                  pokemon_v2_ability {
                    name
                  }
                }
                pokemon_v2_pokemonstats {
                  pokemon_v2_stat {
                    name
                  }
                  base_stat
                }
                pokemon_v2_pokemonmoves {
                  pokemon_v2_move {
                    name
                  }
                }
              }
            }
          '''),
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

          return Padding(
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
                          Image.network(
                            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${pokemon.id}.png',
                            height: 200,
                            fit: BoxFit.cover,
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
                              pokemon.types,
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
                  // Altura y peso con animación de opacidad
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
