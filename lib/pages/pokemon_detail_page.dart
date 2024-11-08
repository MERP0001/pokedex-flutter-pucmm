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

          // Comprobación de nulidad para las listas
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

          /*final flavorTextEntries = pokemon['pokemon_v2_pokemonspecy']['pokemon_v2_flavortextentries'] as List?;
          final flavorText = flavorTextEntries != null && flavorTextEntries.isNotEmpty
              ? flavorTextEntries[0]['flavor_text']
              : 'No description available';*/

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: $name', style: Theme.of(context).textTheme.titleLarge),
                  Text('Types: $types'),
                  Text('Height: $height'),
                  Text('Weight: $weight'),
                  Text('Abilities: $abilities'),
                  const SizedBox(height: 16.0),
                  const SizedBox(height: 16.0),
                  Text('Stats:\n$stats'),
                  const SizedBox(height: 16.0),
                  Text('Moves: $moves'),
                  //const SizedBox(height: 16.0),
                  //Text('Description: $flavorText'),
                  const SizedBox(height: 16.0),
                  Image.network('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
