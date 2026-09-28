# AGENTS.md

## Project

Flutter country trivia game. MVVM + Provider. See `docs/master_plan.md` for architecture, ticket breakdown, and execution order.

## Commands

- Install deps: `flutter pub get`
- Analyze: `flutter analyze`
- Run all tests: `flutter test`
- Run single test: `flutter test test/path/to_test.dart`
- Run widget tests only: `flutter test test/widget/`
- Run unit tests only: `flutter test test/unit/`

## Architecture

- Layers: `data/` (DTOs, API, local assets, repo impl) -> `domain/` (entities, services, abstract repos) -> `presentation/` (ViewModels, pages, widgets)
- Domain layer must have zero Flutter imports (pure Dart)
- ViewModels are `ChangeNotifier` via `provider`
- Entry point: `lib/main.dart` -> `lib/app.dart` (MaterialApp) -> `lib/injection.dart` (MultiProvider)

## Testing

- Use `mocktail` for mocking (no `mockito` / no code generation)
- Widget tests: mock network images to avoid real HTTP calls
- Test structure mirrors `lib/`: `test/unit/`, `test/viewmodel/`, `test/widget/`

## Conventions

- Linting: `flutter_lints` (see `analysis_options.yaml`)
- JSON parsing: DTOs in `data/models/` with `fromJson` factories; map to domain entities via `toDomain()`
- API calls go through repository pattern: `data/` implements abstract repo from `domain/repositories/`
