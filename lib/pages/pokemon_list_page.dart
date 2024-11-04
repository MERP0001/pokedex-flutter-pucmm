import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class PokemonListPage extends StatelessWidget {
  const PokemonListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Query(
        options: QueryOptions(
          document: gql('''
            query GetPokemons {
              pokemon_v2_pokemon(limit: 20) {
                id
                name
                pokemon_v2_pokemontypes {
                  pokemon_v2_type {
                    name
                  }
                }
              }
            }
          '''),
        ),
        builder: (QueryResult result, {fetchMore, refetch}) {
          if (result.hasException) {
            return Center(child: Text(result.exception.toString()));
          }

          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>;

          return ListView.builder(
            itemCount: pokemons.length,
            itemBuilder: (context, index) {
              final pokemon = pokemons[index];
              return ListTile(
                title: Text(pokemon['name']),
                // Aquí agregaremos más detalles después
              );
            },
          );
        },
      ),
    );
  }
} 