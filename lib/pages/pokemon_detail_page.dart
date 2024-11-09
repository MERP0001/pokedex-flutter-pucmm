import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class PokemonDetailPage extends StatelessWidget {
  final int pokemonId;

  const PokemonDetailPage({super.key, required this.pokemonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Pokémon'),
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
                base_experience
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
                pokemon_v2_pokemonspecy {
                  pokemon_v2_generation {
                    name
                  }
                }
              }
            }
          '''),
          variables: {'id': pokemonId},
        ),
        builder: (QueryResult result, {fetchMore, refetch}) {
          if (result.hasException) {
            return Center(child: Text(result.exception.toString()));
          }

          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pokemon = result.data?['pokemon_v2_pokemon_by_pk'];
          final name = pokemon['name'];

          final types = (pokemon['pokemon_v2_pokemontypes'] as List?)
              ?.map((type) => type['pokemon_v2_type']['name'])
              .join(', ') ?? 'No types available';

          final height = pokemon['height'];
          final weight = pokemon['weight'];

          final abilities = (pokemon['pokemon_v2_pokemonabilities'] as List?)
              ?.map((ability) => ability['pokemon_v2_ability']['name'])
              .join(', ') ?? 'No abilities available';

          final stats = (pokemon['pokemon_v2_pokemonstats'] as List?)
              ?.map((stat) => '${stat['pokemon_v2_stat']['name']}: ${stat['base_stat']}')
              .join('\n') ?? 'No stats available';

          final moves = (pokemon['pokemon_v2_pokemonmoves'] as List?)
              ?.map((move) => move['pokemon_v2_move']['name'])
              .take(10)
              .join(', ') ?? 'No moves available';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Imagen y nombre
                  Center(
                    child: Column(
                      children: [
                        Image.network(
                          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png',
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tipos
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(types, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Altura y peso
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('Altura', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('$height m', style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('Peso', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('$weight kg', style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Habilidades
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Habilidades', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(abilities, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Estadísticas
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.purple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(stats, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Movimientos
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.yellow.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Movimientos (10 primeros)', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(moves, style: const TextStyle(fontSize: 16)),
                        ],
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
