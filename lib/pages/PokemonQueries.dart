// lib/queries/pokemon_queries.dart

class PokemonQueries {
  static String getPokemons(String? type, String? generation) {
    return '''
      query GetPokemons {
        pokemon_v2_pokemon(where: {
          ${type != null ? 'pokemon_v2_pokemontypes: { pokemon_v2_type: { name: { _eq: "$type" } } }' : ''}
          ${generation != null ? 'pokemon_v2_pokemonspecy: { pokemon_v2_generation: { name: { _eq: "$generation" } } }' : ''}
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
