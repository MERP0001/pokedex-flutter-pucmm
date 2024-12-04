import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'pokemon_detail_page.dart';

class MoveDetailPage extends StatelessWidget {
  final String moveName;
  final String moveType;
  final int moveLevel;
  final int moveAccuracy;

  const MoveDetailPage({
    Key? key,
    required this.moveName,
    required this.moveType,
    required this.moveLevel,
    required this.moveAccuracy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(moveName),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Query(
        options: QueryOptions(
          document: gql(getMoveDetailsQuery),
          variables: {'name': moveName},
        ),
        builder: (QueryResult result, {fetchMore, refetch}) {
          if (result.hasException) {
            return Center(child: Text(result.exception.toString()));
          }

          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final moveData = result.data?['move'][0];
          if (moveData == null) {
            return const Center(child: Text('No data available'));
          }

          final moveType = moveData['type']['name'] as String;
          final movePower = moveData['power'] ?? 'N/A';
          final moveAccuracy = moveData['accuracy'] ?? 'N/A';
          final movePP = moveData['pp'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo: $moveType',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Poder: $movePower',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Precisión: $moveAccuracy',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'PP: $movePP',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Define your GraphQL query to fetch move details
const String getMoveDetailsQuery = """
  query GetMoveDetails(\$name: String!) {
    move: pokemon_v2_move(where: {name: {_eq: \$name}}) {
      name
      type: pokemon_v2_type {
        name
      }
      power
      accuracy
      pp
    }
  }
"""; 