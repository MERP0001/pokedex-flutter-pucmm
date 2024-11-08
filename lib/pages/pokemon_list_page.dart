import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class PokemonListPage extends StatefulWidget {
  const PokemonListPage({super.key});

  @override
  _PokemonListPageState createState() => _PokemonListPageState();
}

class _PokemonListPageState extends State<PokemonListPage> {
  String? selectedType;
  int? selectedGeneration;

  // Lista de tipos y generaciones para el dropdown
  final List<String> types = ['fire', 'water', 'grass', 'electric', 'normal', 'fighting', 'flying', 'poison', 'ground', 'rock', 'bug', 'ghost', 'steel', 'psychic', 'ice', 'dragon', 'dark', 'fairy'];
  final List<int> generations = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Dropdowns de filtro para tipo y generación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    hint: const Text("Selecciona Tipo"),
                    value: selectedType,
                    items: types.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedType = newValue;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: DropdownButton<int>(
                    hint: const Text("Selecciona Generación"),
                    value: selectedGeneration,
                    items: generations.map((int generation) {
                      return DropdownMenuItem<int>(
                        value: generation,
                        child: Text("Generación $generation"),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
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
                  query GetPokemons(\$type: String, \$generation: Int) {
                    pokemon_v2_pokemon(
                      where: {
                        ${selectedType != null ? 'pokemon_v2_pokemontypes: { pokemon_v2_type: { name: { _eq: \$type } } }' : ''}
                        ${selectedGeneration != null ? 'pokemon_v2_pokemonspecies: { generation_id: { _eq: \$generation } }' : ''}
                      }
                    ) {
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
                variables: {
                  'type': selectedType,
                  'generation': selectedGeneration,
                },
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
                    final pokemonId = pokemon['id'];
                    final pokemonName = pokemon['name'];
                    final pokemonTypes = pokemon['pokemon_v2_pokemontypes'] as List;

                    // Construir la URL de la imagen usando el ID del Pokémon
                    final imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$pokemonId.png';

                    return ListTile(
                      leading: Image.network(imageUrl),
                      title: Text('#$pokemonId $pokemonName'),
                      subtitle: Text(
                        pokemonTypes.map((type) => type['pokemon_v2_type']['name']).join(', '),
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
