import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'pokemon_detail_page.dart';

class PokemonListPage extends StatefulWidget {
  const PokemonListPage({super.key});

  @override
  _PokemonListPageState createState() => _PokemonListPageState();
}

class _PokemonListPageState extends State<PokemonListPage> with TickerProviderStateMixin {
  String? selectedType;
  String? selectedGeneration;

  final List<String?> types = [
    null, 'fire', 'water', 'grass', 'electric', 'normal', 'fighting', 'flying', 'poison', 'ground', 'rock', 'bug', 'ghost', 'steel', 'psychic', 'ice', 'dragon', 'dark', 'fairy'
  ];

  final List<String?> generations = [
    null, 'generation-i', 'generation-ii', 'generation-iii', 'generation-iv', 'generation-v', 'generation-vi', 'generation-vii', 'generation-viii', 'generation-ix'
  ];

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pokédex',
          style: TextStyle(fontFamily: 'DiaryOfAn8BitMage'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String?>(
                    hint: const Text("Selecciona Tipo"),
                    value: selectedType,
                    items: types.map((String? type) {
                      return DropdownMenuItem<String?>(value: type, child: Text(type ?? 'Todos'));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedType = newValue;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: DropdownButton<String?>(
                    hint: const Text("Selecciona Generación"),
                    value: selectedGeneration,
                    items: generations.map((String? generation) {
                      return DropdownMenuItem<String?>(value: generation, child: Text(generation ?? 'Todas'));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedGeneration = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Query(
              options: QueryOptions(
                document: gql('''
                  query GetPokemons(\$type: String, \$generation: String) {
                    pokemon_v2_pokemon(
                      where: {
                        ${selectedType != null ? 'pokemon_v2_pokemontypes: { pokemon_v2_type: { name: { _eq: \$type } } }' : ''}
                        ${selectedGeneration != null ? 'pokemon_v2_pokemonspecy: { pokemon_v2_generation: { name: { _eq: \$generation } } }' : ''}
                      }
                    ) {
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
                '''),
                variables: {
                  if (selectedType != null) 'type': selectedType,
                  if (selectedGeneration != null) 'generation': selectedGeneration,
                },
              ),
              builder: (QueryResult result, {fetchMore, refetch}) {
                if (result.hasException) {
                  return Center(child: Text(result.exception.toString()));
                }

                if (result.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];

                if (pokemons.isEmpty) {
                  return const Center(child: Text('No se encontraron Pokémon.'));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2 / 3,
                  ),
                  itemCount: pokemons.length,
                  itemBuilder: (context, index) {
                    final pokemon = pokemons[index];
                    final pokemonId = pokemon['id'];
                    final pokemonName = pokemon['name'];
                    final pokemonTypes = pokemon['pokemon_v2_pokemontypes'] as List;
                    final primaryType = pokemonTypes.isNotEmpty ? pokemonTypes[0]['pokemon_v2_type']['name'] : 'normal';
                    final color = typeColors[primaryType] ?? Colors.grey;
                    final imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$pokemonId.png';

                    final animationController = AnimationController(
                      vsync: this,
                      duration: const Duration(milliseconds: 400),
                    );
                    final animation = Tween<Offset>(
                      begin: const Offset(0, 0.7),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animationController,
                      curve: Curves.easeOut,
                    ));

                    animationController.forward();

                    return SlideTransition(
                      position: animation,
                      child: FadeTransition(
                        opacity: animationController,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PokemonDetailPage(pokemonId: pokemonId),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(10.0),
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(imageUrl, height: 60, width: 60),
                                const SizedBox(height: 6),
                                Text(
                                  '#$pokemonId $pokemonName',
                                  style: TextStyle(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  pokemonTypes.map((type) => type['pokemon_v2_type']['name']).join(', '),
                                  style: TextStyle(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
