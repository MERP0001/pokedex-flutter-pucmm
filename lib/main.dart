import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pokedex/pages/pokemon_list_page.dart';

void main() async {
  await initHiveForFlutter();
  
  final HttpLink httpLink = HttpLink('https://beta.pokeapi.co/graphql/v1beta');
  
  final GraphQLClient client = GraphQLClient(
    link: httpLink,
    cache: GraphQLCache(store: HiveStore()),
  );

  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final GraphQLClient client;
  const MyApp({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: ValueNotifier(client),
      child: MaterialApp(
        title: 'Pokédex',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        home: const PokemonListPage(),
      ),
    );
  }
}
