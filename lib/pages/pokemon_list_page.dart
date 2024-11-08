import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class PokemonListPage extends StatefulWidget {
  const PokemonListPage({super.key});

  @override
  _PokemonListPageState createState() => _PokemonListPageState();
}

class _PokemonListPageState extends State<PokemonListPage> {
  String? selectedType;
  String? selectedGeneration;

  // Lista de tipos y generaciones para el dropdown
  final List<String?> types = [null, 'fire', 'water', 'grass', 'electric', 'normal', 'fighting', 'flying', 'poison', 'ground', 'rock', 'bug', 'ghost', 'steel', 'psychic', 'ice', 'dragon', 'dark', 'fairy'];
  final List<String?> generations = [null, 'generation-i', 'generation-ii', 'generation-iii', 'generation-iv', 'generation-v', 'generation-vi', 'generation-vii', 'generation-viii', 'generation-ix'];

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
                  child: DropdownButton<String?>(
                    hint: const Text("Selecciona Tipo"),
                    value: selectedType,
                    items: types.map((String? type) {
                      return DropdownMenuItem<String?>(
                        value: type,
                        child: Text(type ?? 'Todos'),
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
                  child: DropdownButton<String?>(
                    hint: const Text("Selecciona Generación"),
                    value: selectedGeneration,
                    items: generations.map((String? generation) {
                      return DropdownMenuItem<String?>(
                        value: generation,
                        child: Text(generation ?? 'Todas'),
                      );
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

                return ListView.builder(
                  itemCount: pokemons.length,
                  itemBuilder: (context, index) {
                    final pokemon = pokemons[index];
                    final pokemonId = pokemon['id'];
                    final pokemonName = pokemon['name'];
                    final pokemonTypes = pokemon['pokemon_v2_pokemontypes'] as List;
                    final pokemonGeneration = pokemon['pokemon_v2_pokemonspecy']['pokemon_v2_generation']['name'];

                    // Construir la URL de la imagen usando el ID del Pokémon
                    final imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$pokemonId.png';

                    return ListTile(
                      leading: Image.network(imageUrl),
                      title: Text('#$pokemonId $pokemonName'),
                      subtitle: Text(
                        'Types: ${pokemonTypes.map((type) => type['pokemon_v2_type']['name']).join(', ')}\nGeneration: $pokemonGeneration',
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