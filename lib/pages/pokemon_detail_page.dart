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

  // Define el color del texto basado en el tipo de Pokémon
  Color getTextColor(String type) {
    return type == 'dark' ? Colors.white : Colors.black;
  }

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

    // Function to draw text with border
    void drawTextWithBorder(Canvas canvas, String text, double x, double y, TextStyle style, {double borderWidth = 2.0}) {
      final borderStyle = style.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..color = Colors.black,
      );

      final textPainterBorder = TextPainter(
        text: TextSpan(text: text, style: borderStyle),
        textDirection: TextDirection.ltr,
      );
      textPainterBorder.layout(minWidth: 0, maxWidth: width);
      textPainterBorder.paint(canvas, Offset(x, y));

      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: width);
      textPainter.paint(canvas, Offset(x, y));
    }

    // Draw the name with border
    drawTextWithBorder(
      canvas,
      pokemon!.name.toUpperCase(),
      50,
      300,
      const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'DiaryOfAn8BitMage',
      ),
    );

    // Draw the types as chips with border
    double chipOffsetY = 350;
    for (var type in pokemon.types) {
      drawTextWithBorder(
        canvas,
        type,
        50,
        chipOffsetY,
        const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'DiaryOfAn8BitMage',
        ),
      );
      chipOffsetY += 24; // Adjust spacing between chips
    }

    final heightWeightText =
        'Altura: ${pokemon!.height} m, Peso: ${pokemon!.weight} kg';
    drawTextWithBorder(
      canvas,
      heightWeightText,
      50,
      chipOffsetY + 16,
      const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontFamily: 'DiaryOfAn8BitMage',
      ),
    );

    final statsText = pokemon!.stats.join('\n');
    drawTextWithBorder(
      canvas,
      'Estadísticas:\n$statsText',
      50,
      chipOffsetY + 56,
      const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontFamily: 'DiaryOfAn8BitMage',
      ),
    );

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
          final textColor = getTextColor(primaryType);

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
                backgroundColor: containerColor,
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
                                      color: getTextColor(primaryType),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8.0,
                                children: pokemon.types.map((type) {
                                  return Chip(
                                    label: Text(
                                      type,
                                      style: const TextStyle(
                                        fontFamily: 'DiaryOfAn8BitMage',
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor:
                                        typeColors[type] ?? Colors.grey,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: SingleChildScrollView(
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: containerColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Altura',
                                    style: TextStyle(
                                      fontFamily: 'DiaryOfAn8BitMage',
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    '${pokemon.height} m',
                                    style: TextStyle(
                                      fontFamily: 'DiaryOfAn8BitMage',
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: SingleChildScrollView(
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: containerColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Peso',
                                    style: TextStyle(
                                      fontFamily: 'DiaryOfAn8BitMage',
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    '${pokemon.weight} kg',
                                    style: TextStyle(
                                      fontFamily: 'DiaryOfAn8BitMage',
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: SingleChildScrollView(
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: containerColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Habilidades',
                                    style: TextStyle(
                                      fontFamily: 'DiaryOfAn8BitMage',
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    pokemon.abilities.join(', '),
                                    style: TextStyle(
                                      fontFamily: 'DiaryOfAn8BitMage',
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: SingleChildScrollView(
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: Colors.white,
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
                                    final statName = parts[0];
                                    final statValue = int.tryParse(parts[1]) ?? 0;
                                    final progress = statValue / 250;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                statName,
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
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.grey[300],
                                            color: Colors.greenAccent,
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
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: SingleChildScrollView(
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: containerColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Movimientos',
                                    style: TextStyle(
                                      fontFamily: 'DiaryOfAn8BitMage',
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
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
                                          style: TextStyle(
                                            fontFamily: 'DiaryOfAn8BitMage',
                                            fontSize: 16,
                                            color: textColor,
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
                                            style: TextStyle(
                                              fontFamily: 'DiaryOfAn8BitMage',
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
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
                                                    title: Text(
                                                      move,
                                                      style: TextStyle(
                                                        color: textColor,
                                                      ),
                                                    ),
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
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 1500),
                        child: SingleChildScrollView(
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: containerColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Evoluciones',
                                    style: TextStyle(
                                      fontFamily: 'DiaryOfAn8BitMage',
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  if (evolutions.isEmpty)
                                    Text(
                                      'No evolutions available',
                                      style: TextStyle(
                                        fontFamily: 'DiaryOfAn8BitMage',
                                        fontSize: 16,
                                        color: textColor,
                                      ),
                                    )
                                  else
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: 120,
                                      ),
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: evolutions.length,
                                        itemBuilder: (context, index) {
                                          final evolution = evolutions[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: Column(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            PokemonDetailPage(
                                                                pokemonId:
                                                                    evolution[
                                                                        'id']),
                                                      ),
                                                    );
                                                  },
                                                  child: Image.network(
                                                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${evolution['id']}.png',
                                                    height: 60,
                                                    width: 60,
                                                  ),
                                                ),
                                                Text(
                                                  evolution['name'],
                                                  style: TextStyle(
                                                    fontFamily: 'DiaryOfAn8BitMage',
                                                    fontSize: 16,
                                                    color: textColor,
                                                  ),
                                                ),
                                                Text(
                                                  (evolution['types'] as List)
                                                      .join(', '),
                                                  style: TextStyle(
                                                    fontFamily: 'DiaryOfAn8BitMage',
                                                    fontSize: 14,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
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
