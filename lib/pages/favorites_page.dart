import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pokemon_detail_page.dart'; // Asegúrate de importar la página de detalles

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<int> favoritePokemonIds = [];

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokémon Favoritos'),
      ),
      body: favoritePokemonIds.isEmpty
          ? Center(child: Text('No hay Pokémon favoritos.'))
          : ListView.builder(
              itemCount: favoritePokemonIds.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Pokémon ID: ${favoritePokemonIds[index]}'),
                  // Aquí podrías mostrar más detalles del Pokémon si los tienes
                  onTap: () {
                    // Navegar a la página de detalles del Pokémon favorito
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PokemonDetailPage(
                            pokemonId: favoritePokemonIds[index]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
