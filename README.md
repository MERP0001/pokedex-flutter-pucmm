# Pokédex — Flutter

Aplicación móvil de Pokédex hecha con **Flutter** que consume la **API GraphQL de PokeAPI**. Proyecto académico de la PUCMM.

## ✨ Funcionalidades

- **Listado de Pokémon** con búsqueda por nombre.
- **Filtros** por tipo y por generación.
- **Ordenamiento** por número, nombre, total de estadísticas o una estadística específica (HP, ataque, defensa, etc.).
- **Detalle de cada Pokémon:** tipos, habilidades, altura, peso, estadísticas base, movimientos y cadena evolutiva.
- **Detalle de movimientos.**
- **Sonido (cry)** de cada Pokémon.
- **Favoritos** guardados en el dispositivo.
- **Compartir** la ficha de un Pokémon como imagen.
- Fondos y colores según el tipo del Pokémon.

## 🛠️ Stack

| Área | Tecnología |
|---|---|
| Framework | Flutter (Dart SDK ^3.5) · Material 3 |
| Datos | [PokeAPI GraphQL](https://beta.pokeapi.co/graphql/v1beta) con `graphql_flutter` + caché en Hive |
| Persistencia local | `shared_preferences` (favoritos) |
| Multimedia | `audioplayers` (cries) · `share_plus` + `path_provider` (compartir imagen) |
| Otros | `http` · `connectivity_plus` |

## 📁 Estructura

```
lib/
├── main.dart                     # Cliente GraphQL y arranque de la app
└── pages/
    ├── PokemonQueries.dart       # Consultas GraphQL (filtros, orden, detalle)
    ├── Pokemon.dart              # Modelo
    ├── pokemon_list_page.dart    # Lista, búsqueda, filtros y orden
    ├── pokemon_detail_page.dart  # Detalle, evolución, cry, favoritos, compartir
    ├── move_detail_page.dart     # Detalle de movimientos
    └── favorites_page.dart       # Favoritos
assets/                           # Fuentes, íconos de tipos y fondos
```

## 🚀 Cómo ejecutarlo

Requisitos: [Flutter](https://docs.flutter.dev/get-started/install) con Dart SDK 3.5 o superior.

```bash
git clone https://github.com/MERP0001/pokedex-flutter-pucmm.git
cd pokedex-flutter-pucmm
flutter pub get
flutter run
```

No necesita claves ni variables de entorno: la API de PokeAPI es pública.

## 👥 Autores

- Moisés Rodríguez — [@MERP0001](https://github.com/MERP0001)
- [@Armandogl14](https://github.com/Armandogl14)
