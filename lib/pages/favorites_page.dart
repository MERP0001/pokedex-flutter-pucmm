import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pokemon_detail_page.dart';
import 'Pokemon.dart'; // Asegúrate de importar el modelo Pokemon

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<int> favoritePokemonIds = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    setState(() {
      favoritePokemonIds = keys
          .where((key) =>
              key.startsWith('favorite_') && prefs.getBool(key) == true)
          .map((key) => int.parse(key.split('_')[1]))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (favoritePokemonIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pokémon Favoritos'),
        ),
        body: const Center(child: Text('No hay Pokémon favoritos.')),
      );
    }

    const String query = '''
      query GetFavoritePokemons(\$ids: [Int!]) {
        pokemon_v2_pokemon(where: {id: {_in: \$ids}}) {
          id
          name
          pokemon_v2_pokemontypes {
            pokemon_v2_type {
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
    ''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Favoritos'),
      ),
      body: Query(
        options: QueryOptions(
          document: gql(query),
          variables: {'ids': favoritePokemonIds},
        ),
        builder: (QueryResult result, {fetchMore, refetch}) {
          if (result.hasException) {
            return Center(child: Text(result.exception.toString()));
          }

          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pokemonsData =
              result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];
          final favoritePokemons = pokemonsData.map((pokemonData) {
            return Pokemon(
              id: pokemonData['id'],
              name: pokemonData['name'],
              types: (pokemonData['pokemon_v2_pokemontypes'] as List)
                  .map((type) => type['pokemon_v2_type']['name'] as String)
                  .toList(),
              generation: pokemonData['pokemon_v2_pokemonspecy']
                  ['pokemon_v2_generation']['name'],
              height: 0.0,
              weight: 0.0,
              abilities: [],
              stats: [],
              moves: [],
            );
          }).toList();

          return ListView.builder(
            itemCount: favoritePokemons.length,
            itemBuilder: (context, index) {
              final pokemon = favoritePokemons[index];
              final primaryType =
                  pokemon.types.isNotEmpty ? pokemon.types[0] : 'normal';
              const color =
                  Colors.grey; // Puedes usar un mapa de colores similar
              final imageUrl =
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png';

              return ListTile(
                leading: Image.network(imageUrl),
                title: Text('#${pokemon.id} ${pokemon.name}'),
                subtitle: Text(pokemon.generation),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PokemonDetailPage(pokemonId: pokemon.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
