// lib/queries/pokemon_queries.dart

class PokemonQueries {
  static final List<String> stats = [
    'hp',
    'attack',
    'defense',
    'special-attack',
    'special-defense',
    'speed',
  ];
  static String getPokemons(
      List<String>? types, List<String>? generations, String? orderByField) {
    // Verificar si orderByField es válido
    final isOrderByFieldValid = orderByField != null && orderByField.isNotEmpty;

    // Filtros para tipos y generaciones
    final typeFilter = types != null && types.isNotEmpty
        ? 'pokemon_v2_pokemontypes: { pokemon_v2_type: { name: { _in: \$types } } }'
        : '';
    final generationFilter = generations != null && generations.isNotEmpty
        ? 'pokemon_v2_pokemonspecy: { pokemon_v2_generation: { name: { _in: \$generations } } }'
        : '';

    // Combinar los filtros
    final whereClause = [typeFilter, generationFilter]
        .where((filter) => filter.isNotEmpty)
        .join(', ');

    // Lógica para el ordenamiento
    String orderBy = '';

    if (isOrderByFieldValid && orderByField == 'total') {
      // Ordenar por el total de stats
      orderBy = '''
      order_by: {
        pokemon_v2_pokemonstats_aggregate: {
          sum: {
            base_stat: desc
          }
        }
      }
    ''';
    } else if (isOrderByFieldValid && orderByField == 'name') {
      // Ordenar por nombre
      orderBy = '''
      order_by: {
        name: asc
      }
    ''';
    }

    // Construir la consulta
    final query = '''
    query GetPokemons(\$types: [String!], \$generations: [String!]) {
      pokemon_v2_pokemon(
        ${whereClause.isNotEmpty ? 'where: { $whereClause },' : ''}
        ${orderBy.isNotEmpty ? orderBy : ''}
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
  ''';

    print('Generated Query: $query');
    return query;
  }

  static String getPokemonsOrderedByStatWithFilters(
      String stat, List<String>? types, List<String>? generations) {
    // Generar filtros condicionales para tipos y generaciones
    final typeFilter = types != null && types.isNotEmpty
        ? 'pokemon_v2_pokemon: { pokemon_v2_pokemontypes: { pokemon_v2_type: { name: { _in: \$types } } } }'
        : '';

    final generationFilter = generations != null && generations.isNotEmpty
        ? 'pokemon_v2_pokemon: { pokemon_v2_pokemonspecy: { pokemon_v2_generation: { name: { _in: \$generations } } } }'
        : '';

    // Combinar filtros
    final combinedFilters = [typeFilter, generationFilter]
        .where((filter) => filter.isNotEmpty)
        .join(', ');

    return '''
    query GetPokemonsOrderedByStatWithFilters(\$stat: String!, \$types: [String!], \$generations: [String!]) {
      pokemon_v2_pokemonstat(
        where: {
          pokemon_v2_stat: { name: { _eq: \$stat } }
          ${combinedFilters.isNotEmpty ? '$combinedFilters' : ''}
        },
        order_by: { base_stat: desc }
      ) {
        base_stat
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

  static String getAllPokemonsOrderedById() {
    return '''
      query GetAllPokemonsOrderedById {
        pokemon_v2_pokemon(order_by: { id: asc }) {
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
          level
          pokemon_v2_move {
            name
            pokemon_v2_type {
              name
            }
            accuracy
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
