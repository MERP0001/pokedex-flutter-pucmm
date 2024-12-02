import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'Pokemon.dart';
import 'PokemonQueries.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class PokemonDetailPage extends StatefulWidget {
  final int pokemonId;

  const PokemonDetailPage({super.key, required this.pokemonId});

  @override
  _PokemonDetailPageState createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends State<PokemonDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  double _opacity = 0.0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isFavorite = false;
  Color _backgroundColor = Color.fromARGB(255, 117, 192, 194);
  final GlobalKey _globalKey = GlobalKey();

  // Define un mapa de colores para los tipos de Pokémon
  final Map<String, Color> typeColors = {
    'fire': Colors.redAccent,
    'water': Colors.blueAccent,
    'grass': Colors.greenAccent,
    'electric': Colors.yellowAccent,
    'ice': Colors.cyanAccent,
    'fighting': Colors.orangeAccent,
    'poison': Colors.purpleAccent,
    'ground': Colors.brown,
    'flying': Colors.lightBlueAccent,
    'psychic': Colors.pinkAccent,
    'bug': Colors.lightGreen,
    'rock': Colors.grey,
    'ghost': Colors.deepPurpleAccent,
    'dragon': Colors.indigoAccent,
    'dark': Colors.black54,
    'steel': Colors.blueGrey,
    'fairy': Colors.pink,
    'normal': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1.0;
        _controller.forward();
      });
    });

    _loadFavoriteStatus();
  }

  Future<String> _getBackgroundImage(String type) async {
    return 'assets/backgrounds/$type.jpg';
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFavorite = prefs.getBool('favorite_${widget.pokemonId}') ?? false;
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFavorite = !isFavorite;
      prefs.setBool('favorite_${widget.pokemonId}', isFavorite);
    });
  }

  Future<void> _sharePokemonDetails(pokemon) async {
    if (pokemon == null) return;

    try {
      final styledImage = await _createCustomPokemonImage(pokemon);

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/styled_pokemon_details.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(styledImage);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: '¡Mira los detalles de ${pokemon.name.toUpperCase()}!',
      );
    } catch (e) {
      print(e.toString());
    }
  }

  Future<Uint8List> _createCustomPokemonImage(pokemon) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double width = 400;
    const double height = 700;

    final backgroundImage =
        await _loadAssetImage('assets/backgrounds/${pokemon!.types.first}.jpg');
    canvas.drawImageRect(
      backgroundImage,
      Rect.fromLTWH(0, 0, backgroundImage.width.toDouble(),
          backgroundImage.height.toDouble()),
      Rect.fromLTWH(0, 0, width, height),
      Paint(),
    );

    final image = await _loadNetworkImage(
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${pokemon!.id}.png');
    canvas.drawImage(image, Offset(50, 50), Paint());

    final textPainter = TextPainter(
      text: TextSpan(
        text: pokemon!.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'DiaryOfAn8BitMage',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: width);
    textPainter.paint(canvas, Offset(50, 300));

    final typesText = pokemon!.types.join(', ');
    final typesPainter = TextPainter(
      text: TextSpan(
        text: 'Tipo: $typesText',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'DiaryOfAn8BitMage',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    typesPainter.layout(minWidth: 0, maxWidth: width);
    typesPainter.paint(canvas, Offset(50, 350));

    final heightWeightText =
        'Altura: ${pokemon!.height} m, Peso: ${pokemon!.weight} kg';
    final heightWeightPainter = TextPainter(
      text: TextSpan(
        text: heightWeightText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'DiaryOfAn8BitMage',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    heightWeightPainter.layout(minWidth: 0, maxWidth: width);
    heightWeightPainter.paint(canvas, Offset(50, 400));

    final statsText = pokemon!.stats.join('\n');
    final statsPainter = TextPainter(
      text: TextSpan(
        text: 'Estadísticas:\n$statsText',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'DiaryOfAn8BitMage',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    statsPainter.layout(minWidth: 0, maxWidth: width);
    statsPainter.paint(canvas, Offset(50, 450));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<ui.Image> _loadAssetImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<ui.Image> _loadNetworkImage(String url) async {
    final completer = Completer<ui.Image>();
    final image = NetworkImage(url);
    image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
      }),
    );
    return completer.future;
  }

  void _changeBackgroundColor(Color color) {
    setState(() {
      _backgroundColor = color;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playCry(Pokemon pokemon) async {
    final url =
        'https://play.pokemonshowdown.com/audio/cries/${pokemon.name.toLowerCase()}.mp3';
    await _audioPlayer.play(UrlSource(url));
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: Query(
        options: QueryOptions(
          document: gql(PokemonQueries.getPokemonDetails),
          variables: {'id': widget.pokemonId},
        ),
        builder: (QueryResult result, {fetchMore, refetch}) {
          if (result.hasException) {
            return Center(child: Text(result.exception.toString()));
          }

          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pokemonData = result.data?['pokemon_v2_pokemon_by_pk'];
          final evolutionsData = pokemonData['pokemon_v2_pokemonspecy']
                  ['pokemon_v2_evolutionchain']['pokemon_v2_pokemonspecies']
              as List<dynamic>;

          final isEeveelution = [
            'vaporeon',
            'jolteon',
            'flareon',
            'espeon',
            'umbreon',
            'leafeon',
            'glaceon',
            'sylveon'
          ].contains(pokemonData['name'].toLowerCase());

          final evolutions = evolutionsData
              .where((evolutionData) => evolutionData['id'] != widget.pokemonId)
              .where((evolutionData) {
            if (isEeveelution) {
              return evolutionData['name'].toLowerCase() == 'eevee';
            } else {
              return true;
            }
          }).map((evolutionData) {
            return {
              'id': evolutionData['id'],
              'name': evolutionData['name'],
              'types': (evolutionData['pokemon_v2_pokemons'][0]
                      ['pokemon_v2_pokemontypes'] as List)
                  .map((type) => type['pokemon_v2_type']['name'] as String)
                  .toList(),
            };
          }).toList()
            ..sort((a, b) => a['id'].compareTo(b['id']));

          final pokemon = Pokemon(
            id: pokemonData['id'] ?? 0,
            name: pokemonData['name'] ?? 'Desconocido',
            types: (pokemonData['pokemon_v2_pokemontypes'] as List?)
                    ?.map((type) => type['pokemon_v2_type']['name'] as String)
                    .toList() ??
                ['Desconocido'],
            generation: pokemonData['pokemon_v2_pokemonspecy']
                    ?['pokemon_v2_generation']?['name'] ??
                'Desconocido',
            height: (pokemonData['height'] ?? 0).toDouble(),
            weight: (pokemonData['weight'] ?? 0).toDouble(),
            abilities: (pokemonData['pokemon_v2_pokemonabilities'] as List?)
                    ?.map((ability) =>
                        ability['pokemon_v2_ability']['name'] as String)
                    .toList() ??
                ['Desconocido'],
            stats: (pokemonData['pokemon_v2_pokemonstats'] as List?)
                    ?.map((stat) =>
                        '${stat['pokemon_v2_stat']['name']}: ${stat['base_stat']}')
                    .toList() ??
                ['Desconocido'],
            moves: (pokemonData['pokemon_v2_pokemonmoves'] as List?)
                    ?.map((move) => move['pokemon_v2_move']['name'] as String)
                    .toList() ??
                ['Desconocido'],
          );

          // Obtén el color del primer tipo de Pokémon
          final primaryType =
              pokemon.types.isNotEmpty ? pokemon.types.first : 'normal';
          final containerColor = typeColors[primaryType] ?? Colors.grey;

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/backgrounds/${primaryType}.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/pokeball (2).png',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 2),
                    const Flexible(
                      child: Text(
                        'Detalles del Pokémon',
                        style: TextStyle(
                            fontFamily: 'DiaryOfAn8BitMage', fontSize: 16),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF548C94),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _sharePokemonDetails(pokemon),
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SlideTransition(
                        position: _offsetAnimation,
                        child: Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  if (pokemon.name.isNotEmpty) {
                                    await _playCry(pokemon);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 500),
                                  transform: Matrix4.rotationZ(0.1),
                                  child: Image.network(
                                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${pokemon.id}.png',
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                pokemon.name.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontFamily: 'DiaryOfAn8BitMage',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: containerColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tipo',
                                  style: TextStyle(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  pokemon.types.join(', '),
                                  style: const TextStyle(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: const Color(0xFF779242),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Altura',
                                        style: TextStyle(
                                          fontFamily: 'DiaryOfAn8BitMage',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${pokemon.height} m',
                                        style: const TextStyle(
                                          fontFamily: 'DiaryOfAn8BitMage',
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: const Color(0xFF779242),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Peso',
                                        style: TextStyle(
                                          fontFamily: 'DiaryOfAn8BitMage',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${pokemon.weight} kg',
                                        style: const TextStyle(
                                          fontFamily: 'DiaryOfAn8BitMage',
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: containerColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Habilidades',
                                  style: TextStyle(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  pokemon.abilities.join(', '),
                                  style: const TextStyle(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: containerColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estadísticas',
                                  style: TextStyle(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ...pokemon.stats.map((stat) {
                                  final parts = stat.split(': ');
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          parts[0],
                                          style: const TextStyle(
                                            fontFamily: 'DiaryOfAn8BitMage',
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          parts[1],
                                          style: const TextStyle(
                                            fontFamily: 'DiaryOfAn8BitMage',
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: containerColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Movimientos (10 primeros)',
                                  style: TextStyle(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: min(pokemon.moves.length, 3),
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(
                                        pokemon.moves[index],
                                        style: const TextStyle(
                                          fontFamily: 'DiaryOfAn8BitMage',
                                          fontSize: 11,
                                        ),
                                      ),
                                      leading: Container(
                                        decoration: BoxDecoration(
                                          color: containerColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontFamily: 'DiaryOfAn8BitMage',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Movimientos'),
                                          content: SingleChildScrollView(
                                            child: ListBody(
                                              children:
                                                  pokemon.moves.map((move) {
                                                return ListTile(
                                                  title: Text(move),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('Cerrar'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: const Text('Mostrar más movimientos'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: const Color(0xFF779242),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Evoluciones',
                                  style: TextStyle(
                                    fontFamily: 'DiaryOfAn8BitMage',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (evolutions.isEmpty)
                                  const Text(
                                    'No evolutions available',
                                    style: TextStyle(
                                      fontFamily: 'DiaryOfAn8BitMage',
                                      fontSize: 16,
                                    ),
                                  )
                                else
                                  ...evolutions.map((evolution) {
                                    return ListTile(
                                      leading: Image.network(
                                        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${evolution['id']}.png',
                                        height: 40,
                                        width: 40,
                                      ),
                                      title: Text(
                                        evolution['name'],
                                        style: const TextStyle(
                                          fontFamily: 'DiaryOfAn8BitMage',
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        (evolution['types'] as List).join(', '),
                                        style: const TextStyle(
                                          fontFamily: 'DiaryOfAn8BitMage',
                                          fontSize: 14,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PokemonDetailPage(
                                                    pokemonId: evolution['id']),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
