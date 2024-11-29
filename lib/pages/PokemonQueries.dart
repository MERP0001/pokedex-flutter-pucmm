// lib/queries/pokemon_queries.dart

class PokemonQueries {
  static String getPokemons(List<String>? types, List<String>? generations) {
    final typeFilter = types != null && types.isNotEmpty
        ? 'pokemon_v2_pokemontypes: { pokemon_v2_type: { name: { _in: \$types } } }'
        : '';
    final generationFilter = generations != null && generations.isNotEmpty
        ? 'pokemon_v2_pokemonspecy: { pokemon_v2_generation: { name: { _in: \$generations } } }'
        : '';

    final query = '''
      query GetPokemons(\$types: [String!], \$generations: [String!]) {
        pokemon_v2_pokemon(where: {
          $typeFilter
          $generationFilter
        }) {
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
    print('Generated Query: $query');
    return query;
  }

  static String getAllPokemons() {
    return '''
      query GetAllPokemons {
        pokemon_v2_pokemon {
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
  }

  static const String getPokemonDetails = '''
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
        pokemon_v2_pokemonspecy {
          pokemon_v2_evolutionchain {
            pokemon_v2_pokemonspecies {
              id
              name
              evolves_from_species_id
              pokemon_v2_pokemons {
                pokemon_v2_pokemontypes {
                  pokemon_v2_type {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  ''';
}
