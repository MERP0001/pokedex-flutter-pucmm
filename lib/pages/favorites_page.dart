import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pokemon_detail_page.dart';
import 'Pokemon.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<int> favoritePokemonIds = [];
  final Map<String, Color> typeColors = {
    'fire': Colors.red,
    'water': Colors.blue,
    'grass': Colors.green,
    'electric': Colors.yellow,
    'normal': Colors.grey,
    'fighting': Colors.brown,
    'flying': Colors.lightBlueAccent,
    'poison': Colors.purple,
    'ground': Colors.orange,
    'rock': Colors.brown[700]!,
    'bug': Colors.lightGreen,
    'ghost': Colors.deepPurple,
    'steel': Colors.blueGrey,
    'psychic': Colors.pink,
    'ice': Colors.cyan,
    'dragon': Colors.indigo,
    'dark': Colors.black,
    'fairy': Colors.pinkAccent,
  };

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
      body: Container(
        decoration: BoxDecoration(
          color: Colors.lightBlueAccent,
          image: DecorationImage(
            image: const AssetImage('assets/icons/pokeball.png'),
            fit: BoxFit.none,
            alignment: Alignment.center,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.1),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: Query(
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
                final color = typeColors[primaryType] ?? Colors.grey;
                final imageUrl =
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PokemonDetailPage(pokemonId: pokemon.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        image: DecorationImage(
                          image: const AssetImage('assets/icons/pokeball.png'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.white.withOpacity(0.2),
                            BlendMode.dstATop,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${pokemon.id} ${pokemon.name}',
                                  style: const TextStyle(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: pokemon.types.map((type) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Image.asset(
                                        'assets/icons/$type.png',
                                        width: 32,
                                        height: 32,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pokemon.generation,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
