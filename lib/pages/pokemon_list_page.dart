import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'pokemon_detail_page.dart';
import 'favorites_page.dart'; // Importa la nueva página de favoritos
import 'PokemonQueries.dart';

class Pokemon {
  final int id;
  final String name;
  final List<String> types;
  final String generation;

  Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.generation,
  });
}

class PokemonListPage extends StatefulWidget {
  const PokemonListPage({super.key});

  @override
  _PokemonListPageState createState() => _PokemonListPageState();
}

class _PokemonListPageState extends State<PokemonListPage>
    with TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Pokemon> allPokemons = [];
  List<Pokemon> filteredPokemons = [];
  List<String> selectedTypes = [];
  List<String> selectedGenerations = [];
  String? selectedOrder = null;
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;

  final List<String> types = [
    'fire',
    'water',
    'grass',
    'electric',
    'normal',
    'fighting',
    'flying',
    'poison',
    'ground',
    'rock',
    'bug',
    'ghost',
    'steel',
    'psychic',
    'Ice',
    'dragon',
    'dark',
    'fairy'
  ];

  final Map<String, String> generations = {
    'generation-i': 'Primera',
    'generation-ii': 'Segunda',
    'generation-iii': 'Tercera',
    'generation-iv': 'Cuarta',
    'generation-v': 'Quinta',
    'generation-vi': 'Sexta',
    'generation-vii': 'Séptima',
    'generation-viii': 'Octava',
    'generation-ix': 'Novena',
  };

  String getGenerationName(String key) {
    return generations[key] ?? 'Unknown Generation';
  }

  final List<String> orderByFields = [
    'Ninguno',
    'name',
    'hp',
    'attack',
    'defense',
    'special-attack',
    'special-defense',
    'speed',
    'total'
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

  // Function to draw text with a border
  Widget _textWithBorder(String text, TextStyle style, {double borderWidth = 2.0}) {
    return Stack(
      children: [
        // Border text
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = borderWidth
              ..color = Colors.black,
          ),
        ),
        // Main text
        Text(
          text,
          style: style,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterPokemons);
    _scrollController.addListener(() {
      // Add any specific scroll behavior if needed
    });
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      filteredPokemons.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _animations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterPokemons() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredPokemons = allPokemons.where((pokemon) {
        final matchesType = selectedTypes.isEmpty ||
            selectedTypes.any((type) => pokemon.types.contains(type));
        final matchesGeneration = selectedGenerations.isEmpty ||
            selectedGenerations.contains(pokemon.generation);
        final matchesSearch = pokemon.name.toLowerCase().contains(query) ||
            pokemon.id.toString() == query;
        return matchesType && matchesGeneration && matchesSearch;
      }).toList();
      _initializeAnimations();
    });
  }

  void _clearSearch() {
    searchController.clear();
    setState(() {
      selectedTypes.clear();
      selectedGenerations.clear();
      selectedOrder = 'Ninguno';
      filteredPokemons = allPokemons; // Reset filteredPokemons to allPokemons
      _initializeAnimations(); // Reinitialize animations for all elements
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Remove the old list view
        setState(() {
          filteredPokemons = [];
        });
        // Load a new list view
        setState(() {
          filteredPokemons = allPokemons;
        });
      });
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeOut,
      );
    });
  }

  void _showFilterOptions(BuildContext context, String filterType) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final options =
            filterType == 'type' ? types : generations.keys.toList();
        final selectedOptions =
            filterType == 'type' ? selectedTypes : selectedGenerations;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                      'Selecciona ${filterType == 'type' ? 'Tipos' : 'Generaciones'}'),
                ),
                SizedBox(
                  height: 300,
                  child: ListView(
                    children: options.map((option) {
                      return CheckboxListTile(
                        title: Text(filterType == 'type'
                            ? option
                            : generations[option]!),
                        value: selectedOptions.contains(option),
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              selectedOptions.add(option);
                            } else {
                              selectedOptions.remove(option);
                            }
                          });
                          setState(() {
                            _filterPokemons();
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOrderOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final orderOptions = orderByFields;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text('Selecciona un orden'),
                ),
                SizedBox(
                  height: 300,
                  child: ListView(
                    children: orderOptions.map((option) {
                      return RadioListTile<String>(
                        title: Text(option),
                        value: option,
                        groupValue: selectedOrder,
                        onChanged: (String? value) {
                          setModalState(() {
                            selectedOrder = value == 'Ninguno' ? null : value;
                          });
                          setState(() {
                            _filterPokemons();
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    selectedOrder ??= 'Ninguno';
    final List<String> stats = [
      'hp',
      'attack',
      'defense',
      'special-attack',
      'special-defense',
      'speed',
    ];

    final bool useFilters = selectedTypes.isNotEmpty ||
        selectedGenerations.isNotEmpty ||
        selectedOrder != null;

    final bool useStat = selectedOrder != null && stats.contains(selectedOrder);

    final String query = useStat
        ? PokemonQueries.getPokemonsOrderedByStatWithFilters(
            selectedOrder!, selectedTypes, selectedGenerations)
        : PokemonQueries.getPokemons(
            selectedTypes, selectedGenerations, selectedOrder!);

    final Map<String, dynamic> variables = {};
    if (selectedTypes.isNotEmpty) {
      variables['types'] = selectedTypes;
    }
    if (selectedGenerations.isNotEmpty) {
      variables['generations'] = selectedGenerations;
    }
    if (useStat) {
      variables['stat'] = selectedOrder;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icons/pokeball (2).png',
              width: 24, // Ajusta el tamaño según sea necesario
              height: 24,
            ),
            const SizedBox(width: 8), // Espacio entre el icono y el texto
            const Text(
              'Pokédex',
              style: TextStyle(fontFamily: 'DiaryOfAn8BitMage'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF59CEDE),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: 'Buscar Pokémon',
                            prefixIcon: Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                          ),
                          onChanged: (value) {
                            _filterPokemons();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.update),
                        onPressed: _clearSearch,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showFilterOptions(context, 'type'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF59CEDE),
                          ),
                          icon:
                              Icon(Icons.filter_list_alt, color: Colors.white),
                          label: const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _showFilterOptions(context, 'generation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF59CEDE),
                          ),
                          child: Icon(
                            Icons.filter_list,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showOrderOptions(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF59CEDE),
                          ),
                          child: const Text(
                            'Ordenar',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 45.0),
                child: Query(
                  options: QueryOptions(
                    document: gql(query),
                    variables: variables,
                  ),
                  builder: (QueryResult result, {fetchMore, refetch}) {
                    if (result.hasException) {
                      print(
                          'GraphQL Exception: ${result.exception.toString()}');
                      return Center(child: Text(result.exception.toString()));
                    }

                    if (result.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final pokemonsData = result.data;

                    if (pokemonsData?['pokemon_v2_pokemonstat'] != null) {
                      // Caso para el query de stats
                      final statData = pokemonsData?['pokemon_v2_pokemonstat']
                              as List<dynamic>? ??
                          [];
                      print('Pokemons Data (Stats Query): $statData');
                      allPokemons = statData.map((statEntry) {
                        final pokemon = statEntry['pokemon_v2_pokemon'];
                        return Pokemon(
                          id: pokemon['id'],
                          name: pokemon['name'],
                          types: (pokemon['pokemon_v2_pokemontypes'] as List)
                              .map((type) =>
                                  type['pokemon_v2_type']['name'] as String)
                              .toList(),
                          generation: pokemon['pokemon_v2_pokemonspecy']
                              ['pokemon_v2_generation']['name'],
                        );
                      }).toList();
                    } else if (pokemonsData?['pokemon_v2_pokemon'] != null) {
                      // Caso para el query sin stats
                      final pokemonList = pokemonsData?['pokemon_v2_pokemon']
                              as List<dynamic>? ??
                          [];
                      print('Pokemons Data (Standard Query): $pokemonList');
                      allPokemons = pokemonList.map((pokemonData) {
                        return Pokemon(
                          id: pokemonData['id'],
                          name: pokemonData['name'],
                          types:
                              (pokemonData['pokemon_v2_pokemontypes'] as List)
                                  .map((type) =>
                                      type['pokemon_v2_type']['name'] as String)
                                  .toList(),
                          generation: pokemonData['pokemon_v2_pokemonspecy']
                              ['pokemon_v2_generation']['name'],
                        );
                      }).toList();
                    } else {
                      print('No Pokémon data found.');
                      allPokemons = [];
                    }

                    if (filteredPokemons.isEmpty) {
                      filteredPokemons = List.from(allPokemons);
                      _initializeAnimations();
                    }

                    if (filteredPokemons.isEmpty) {
                      return const Center(
                          child: Text('No se encontraron Pokémon.'));
                    }

                    return ListView.builder(
                      itemCount: filteredPokemons.length,
                      itemBuilder: (context, index) {
                        final pokemon = filteredPokemons[index];
                        final primaryType = pokemon.types.isNotEmpty
                            ? pokemon.types[0]
                            : 'normal';
                        final color = typeColors[primaryType] ?? Colors.grey;
                        final imageUrl =
                            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png';

                        _controllers[index].forward();

                        return SlideTransition(
                          position: _animations[index],
                          child: InkWell(
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
                                    image: const AssetImage(
                                        'assets/icons/pokeball.png'),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _textWithBorder(
                                            '#${pokemon.id} ${pokemon.name}',
                                            const TextStyle(
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
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: Image.asset(
                                                  'assets/icons/$type.png',
                                                  width: 32,
                                                  height: 32,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 4),
                                          _textWithBorder(
                                            getGenerationName(pokemon.generation) +
                                                ' Generación',
                                            const TextStyle(
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
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
