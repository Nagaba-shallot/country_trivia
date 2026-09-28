# Country Trivia — Master Plan

## 1. Overview

A Flutter mobile game where the user is shown a country flag and must pick the correct country name from 4 options. Correct answers earn points based on how many attempts were used (10 / 8 / 6). After 3 wrong attempts the correct answer is revealed and the round ends with no points.

- **Platform:** Android & iOS (Flutter cross-platform)
- **Architecture:** MVVM (Model–View–ViewModel)
- **State management:** `provider` (ChangeNotifier)
- **Data source:** REST Countries API (Postman collection: `https://documenter.getpostman.com/view/1134062/T1LJjU52`)
- **Flag CDN:** `http://flagcdn.com/w320/{iso}.png` (ISO 3166-1 alpha-2, lowercase)

---

## 2. Architecture (MVVM + Provider)

```
┌─────────────────────────────────────────────────────┐
│                    Presentation                      │
│  Views (Widgets)  ←── listens ──→  ViewModels       │
│  - GamePage                      - GameViewModel    │
│  - ScoreBoardWidget              - ScoreViewModel   │
│  - OptionButtonWidget                               │
└──────────────┬──────────────────────┬───────────────┘
               │                      │
               ▼                      ▼
┌─────────────────────────────────────────────────────┐
│                      Domain                          │
│  - Entities: Country, Question, GameSession          │
│  - Repositories (abstract): CountryRepository        │
│  - Services: QuestionGenerator, ScoreCalculator      │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────┐
│                       Data                           │
│  - Models (DTO): CountryDto                          │
│  - API: CountryApiService (http/dio)                 │
│  - Local: CountryLocalDataSource (cache/fallback)    │
│  - Repository impl: CountryRepositoryImpl            │
└─────────────────────────────────────────────────────┘
```

### Layer responsibilities

| Layer         | Responsibility                                                                                        |
| ------------- | ----------------------------------------------------------------------------------------------------- |
| **View**      | Render UI, forward user taps to ViewModel, no business logic                                          |
| **ViewModel** | Expose observable state (score, current question, attempts left, reveal state), orchestrate game flow |
| **Domain**    | Pure Dart entities & business rules (question generation, scoring) — no Flutter imports               |
| **Data**      | Fetch/serialize JSON, cache, map DTOs → domain entities                                               |

---

## 3. Data Layer

### 3.1 API

- **Endpoint:** `GET https://restcountries.com/v3.1/all?fields=name,cca2`
  - The Postman collection documents the REST Countries API. The v3.1 endpoint returns `name.common` and `cca2` (ISO alpha-2) which we need for flags.
  - ⚠️ **Deprecation note:** As of 2026 the v3.1 endpoint returns a deprecation notice. The plan includes a **local fallback dataset** (bundled JSON asset) so the game works regardless. The API call is attempted first; on failure the local dataset is used.
- **Flag URL:** `http://flagcdn.com/w320/{cca2_lowercase}.png`

### 3.2 DTO → Entity mapping

```dart
// DTO (data layer)
class CountryDto {
  final String commonName;   // from name.common
  final String cca2;         // ISO alpha-2
  factory CountryDto.fromJson(Map<String, dynamic> json);
}

// Entity (domain layer)
class Country {
  final String name;
  final String isoCode;      // lowercase alpha-2
  String get flagUrl => 'http://flagcdn.com/w320/$isoCode.png';
}
```

### 3.3 Local fallback

- `assets/data/countries.json` — bundled list of ~50–100 countries (name + cca2) so the game is fully playable offline and in tests.
- Loaded via `rootBundle.loadString` and parsed into the same DTO shape.

### 3.4 Repository

```dart
abstract class CountryRepository {
  Future<List<Country>> getCountries();
}

class CountryRepositoryImpl implements CountryRepository {
  // 1. Try API  2. On error → load local asset
}
```

---

## 4. Domain Layer

### 4.1 Entities

| Entity        | Fields                                                            |
| ------------- | ----------------------------------------------------------------- |
| `Country`     | `name`, `isoCode`, `flagUrl` (computed)                           |
| `Question`    | `correctCountry`, `options` (List\<Country\>, shuffled, length 4) |
| `GameSession` | `score`, `currentQuestion`, `attemptsLeft`, `roundState`          |

### 4.2 Round state machine

```
RoundState:
  inProgress ──(correct pick)──→ answeredCorrectly
      │
      ├──(wrong pick, attemptsLeft > 1)──→ inProgress (attemptsLeft--)
      │
      └──(wrong pick, attemptsLeft == 1)──→ revealed
```

### 4.3 Scoring

| Attempt used     | Points |
| ---------------- | ------ |
| 1st (first try)  | 10     |
| 2nd              | 8      |
| 3rd              | 6      |
| Failed (3 wrong) | 0      |

### 4.4 Question generation (no repeats)

1. Maintain a `Set<String> _playedIsoCodes` in `GameViewModel` tracking every country already shown.
2. `QuestionGenerator` receives only **unplayed** countries as its pool.
3. Pick a random country from the remaining pool as the correct answer.
4. Pick 3 distinct random countries (different from correct) as distractors.
5. Combine + shuffle → 4 options.
6. Ensure no duplicate names in options.
7. After the round ends, add the correct answer's ISO code to `_playedIsoCodes`.
8. **Pool exhaustion:** When fewer than 4 unplayed countries remain, reset the pool (clear `_playedIsoCodes`) and start a fresh cycle — the game never gets stuck.

**Persistence (optional):** Save `_playedIsoCodes` to `shared_preferences` so repeats are avoided even across app restarts. On launch, load the saved set before generating the first question.

---

## 5. State Management (Provider)

### Providers

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => GameViewModel()),
  ],
  child: const GamePage(),
)
```

### GameViewModel (ChangeNotifier)

| Property         | Type          | Description                                                 |
| ---------------- | ------------- | ----------------------------------------------------------- |
| `score`          | `int`         | Running total                                               |
| `question`       | `Question?`   | Current question                                            |
| `attemptsLeft`   | `int`         | 3 → 0                                                       |
| `roundState`     | `RoundState`  | inProgress / answeredCorrectly / revealed                   |
| `selectedOption` | `Country?`    | Last picked option                                          |
| `isLoading`      | `bool`        | Initial load                                                |
| `playedIsoCodes` | `Set<String>` | ISO codes of all countries already shown (prevents repeats) |

| Method                  | Behavior                                   |
| ----------------------- | ------------------------------------------ |
| `startGame()`           | Load countries, generate first question    |
| `selectOption(Country)` | Evaluate pick, update score/attempts/state |
| `nextQuestion()`        | Generate new question, reset attempts      |
| `resetGame()`           | Reset score & start over                   |

### ScoreViewModel (optional, for persistence)

- Wraps `GameViewModel` or stores high score via `shared_preferences`.

---

## 6. Presentation Layer

### 6.1 Screen: GamePage

```
┌─────────────────────────────┐
│  Score: 42        Round: 5  │  ← Header bar
├─────────────────────────────┤
│                             │
│      ┌───────────────┐      │
│      │               │      │
│      │   FLAG IMAGE  │      │  ← flagcdn w320
│      │               │      │
│      └───────────────┘      │
│                             │
│   "Which country is this?"  │
│                             │
│  ┌───────────────────────┐  │
│  │  Option A             │  │  ← 4 option buttons
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Option B             │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Option C             │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Option D             │  │
│  └───────────────────────┘  │
│                             │
│  Attempts: ●●○              │  ← attempt dots
│                             │
└─────────────────────────────┘
```

### 6.2 Widgets

| Widget              | Responsibility                                     |
| ------------------- | -------------------------------------------------- |
| `GamePage`          | Scaffold, wires ViewModel                          |
| `ScoreHeader`       | Displays score & round number                      |
| `FlagImage`         | Loads flag from CDN with loading/error placeholder |
| `OptionButton`      | One answer option; color-codes on result           |
| `AttemptsIndicator` | Visual dots for remaining attempts                 |
| `ResultOverlay`     | Shows correct/wrong feedback + "Next" button       |

### 6.3 Option button states

| State                   | Visual                         |
| ----------------------- | ------------------------------ |
| Default                 | Neutral background, tappable   |
| Correct pick            | Green background, check icon   |
| Wrong pick              | Red background, X icon         |
| Revealed (failed round) | Correct = green, others dimmed |
| Disabled                | Not tappable after round ends  |

---

## 7. Project Structure

```
lib/
├── main.dart
├── app.dart                      # MaterialApp + theme
├── core/
│   ├── constants/
│   │   ├── api_constants.dart     # URLs, endpoints
│   │   └── game_constants.dart    # scoring, attempts count
│   ├── errors/
│   │   └── failures.dart         # Failure classes
│   └── utils/
│       └── shuffle.dart
├── data/
│   ├── datasources/
│   │   ├── country_api_service.dart
│   │   └── country_local_data_source.dart
│   ├── models/
│   │   └── country_dto.dart
│   └── repositories/
│       └── country_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── country.dart
│   │   ├── question.dart
│   │   └── game_session.dart
│   ├── repositories/
│   │   └── country_repository.dart    (abstract)
│   └── services/
│       ├── question_generator.dart
│       └── score_calculator.dart
├── presentation/
│   ├── viewmodels/
│   │   ├── game_view_model.dart
│   │   └── score_view_model.dart
│   ├── pages/
│   │   └── game_page.dart
│   └── widgets/
│       ├── score_header.dart
│       ├── flag_image.dart
│       ├── option_button.dart
│       ├── attempts_indicator.dart
│       └── result_overlay.dart
└── injection.dart                # Provider setup / DI

assets/
└── data/
    └── countries.json            # fallback dataset

test/
├── unit/
│   ├── domain/
│   │   ├── question_generator_test.dart
│   │   └── score_calculator_test.dart
│   └── data/
│       └── country_repository_impl_test.dart
├── viewmodel/
│   └── game_view_model_test.dart
└── widget/
    └── game_page_test.dart
```

---

## 8. Dependencies

| Package                | Purpose                           |
| ---------------------- | --------------------------------- |
| `provider`             | State management (ChangeNotifier) |
| `http`                 | REST API calls                    |
| `cached_network_image` | Flag image loading + caching      |
| `shared_preferences`   | High score persistence            |
| `flutter_test` (dev)   | Widget & unit tests               |
| `mocktail` (dev)       | Mocking in tests                  |

---

## 9. Testing Strategy

### 9.1 Unit tests

- **QuestionGenerator:** correct answer always in options, 4 unique options, shuffled.
- **ScoreCalculator:** 10/8/6/0 points per attempt number.
- **CountryRepositoryImpl:** falls back to local data when API fails.

### 9.2 ViewModel tests

- `startGame()` loads countries and sets first question.
- Correct pick → score increases by 10, state = answeredCorrectly.
- Wrong pick → attemptsLeft decreases, score unchanged.
- 3 wrong picks → state = revealed, correct answer highlighted.
- `nextQuestion()` resets attempts and generates new question.

### 9.3 Widget tests

- Flag image renders (mock network image).
- 4 option buttons render with country names.
- Tapping correct option shows green + score update.
- Tapping wrong option shows red + attempts decrease.
- After 3 wrong taps, correct answer revealed + "Next" button appears.

---

## 10. Ticket Breakdown & Execution Order

### Execution Waves

Tickets are grouped into **waves**. Tickets within the same wave have no dependencies on each other and **can be executed in parallel**. Waves must be completed in order (Wave N+1 depends on Wave N).

```
Wave 1:  T1, T2, T3, T4          (parallel)
Wave 2:  T5, T6, T7              (parallel)
Wave 3:  T8, T9                  (parallel)
Wave 4:  T10, T11                (parallel)
Wave 5:  T12                     (single)
Wave 6:  T13, T14, T15, T16      (parallel)
Wave 7:  T17                     (single)
Wave 8:  T18, T19, T20           (parallel)
Wave 9:  T21, T22                (parallel)
```

---

### Wave 1 — Foundation (Parallel)

#### T1 — Add dependencies to `pubspec.yaml`

- **Description:** Add `provider`, `http`, `cached_network_image`, `shared_preferences` to dependencies; add `mocktail` to dev_dependencies.
- **Depends on:** None
- **Parallel with:** T2, T3, T4
- **Acceptance criteria:**
  `flutter pub get` succeeds; all packages resolve.

#### T2 — Create `assets/data/countries.json` fallback dataset

- **Description:** Bundle a JSON file with ~50–100 countries (`name` + `cca2`). Register the asset folder in `pubspec.yaml`.
- **Depends on:** None
- **Parallel with:** T1, T3, T4
- **Acceptance criteria:** File exists at `assets/data/countries.json`; `pubspec.yaml` includes the asset declaration; JSON is valid.

#### T3 — Implement core constants & failure classes

- **Description:** Create `core/constants/api_constants.dart` (API URL, flag URL template), `core/constants/game_constants.dart` (max attempts = 3, points [10, 8, 6]), and `core/errors/failures.dart` (Failure base class, ServerFailure, CacheFailure).
- **Depends on:** None
- **Parallel with:** T1, T2, T4
- **Acceptance criteria:** Constants are referenced from a single location; failure classes exist and are used by data layer.

#### T4 — Create domain entities

- **Description:** Create `domain/entities/country.dart` (name, isoCode, flagUrl getter), `domain/entities/question.dart` (correctCountry, options), `domain/entities/game_session.dart` (score, currentQuestion, attemptsLeft, roundState enum).
- **Depends on:** None
- **Parallel with:** T1, T2, T3
- **Acceptance criteria:** Entities are pure Dart (no Flutter imports); all fields are final; `RoundState` enum defined.

---

### Wave 2 — Data Layer (Parallel)

#### T5 — Implement `CountryDto` (JSON parsing)

- **Description:** Create `data/models/country_dto.dart` with `fromJson` factory mapping `name.common` → `commonName` and `cca2` → `cca2`. Include `toDomain()` method to map to `Country` entity.
- **Depends on:** T4
- **Parallel with:** T6, T7
- **Acceptance criteria:** Parses REST Countries v3.1 JSON response correctly; handles missing fields gracefully.

#### T6 — Implement `CountryApiService`

- **Description:** Create `data/datasources/country_api_service.dart` using `http` package. Calls `GET /v3.1/all?fields=name,cca2`. Returns `List<CountryDto>`. Throws `ServerFailure` on non-200 response.
- **Depends on:** T3, T5
- **Parallel with:** T5, T7
- **Acceptance criteria:** Successful response returns parsed DTO list; network error / non-200 throws `ServerFailure`.

#### T7 — Implement `CountryLocalDataSource`

- **Description:** Create `data/datasources/country_local_data_source.dart`. Loads `assets/data/countries.json` via `rootBundle`, parses JSON, returns `List<CountryDto>`. Throws `CacheFailure` on error.
- **Depends on:** T2, T5
- **Parallel with:** T5, T6
- **Acceptance criteria:** Returns parsed DTO list from bundled asset; throws `CacheFailure` if asset missing or malformed.

---

### Wave 3 — Repository (Parallel with Domain Services)

#### T8 — Implement `CountryRepositoryImpl`

- **Description:** Create `data/repositories/country_repository_impl.dart`. Implements `CountryRepository` abstract class. Tries API first; on `ServerFailure` falls back to local data source. Maps DTOs to domain entities.
- **Depends on:** T5, T6, T7
- **Parallel with:** T9
- **Acceptance criteria:** Returns countries from API when available; returns local data when API fails; never throws unhandled exceptions.

#### T9 — Implement domain services (QuestionGenerator + ScoreCalculator)

- **Description:** Create `domain/services/question_generator.dart` (picks correct + 3 distractors from unplayed pool, shuffles, ensures unique names, handles pool exhaustion) and `domain/services/score_calculator.dart` (returns 10/8/6/0 based on attempt number).
- **Depends on:** T4
- **Parallel with:** T8
- **Acceptance criteria:** QuestionGenerator always includes correct answer in 4 unique options; ScoreCalculator returns correct points for attempts 1–3 and 0 for failure.

---

### Wave 4 — ViewModel (Parallel)

#### T10 — Implement `GameViewModel`

- **Description:** Create `presentation/viewmodels/game_view_model.dart` as `ChangeNotifier`. Manages score, current question, attemptsLeft, roundState, playedIsoCodes set. Methods: `startGame()`, `selectOption(Country)`, `nextQuestion()`, `resetGame()`. Implements no-repeat logic via `playedIsoCodes`.
- **Depends on:** T8, T9
- **Parallel with:** T11
- **Acceptance criteria:** Full game flow works (start → answer → next → reset); score updates correctly; no country repeats until pool resets; state transitions match the round state machine.

#### T11 — Implement `ScoreViewModel` (optional)

- **Description:** Create `presentation/viewmodels/score_view_model.dart`. Persists high score via `shared_preferences`. Loads on init, updates when current score exceeds stored high score.
- **Depends on:** T1
- **Parallel with:** T10
- **Acceptance criteria:** High score persists across app restarts; updates only when beaten.

---

### Wave 5 — App Shell

#### T12 — Create `app.dart` + `main.dart` + `injection.dart`

- **Description:** Create `app.dart` (MaterialApp with theme), `injection.dart` (MultiProvider setup with GameViewModel + ScoreViewModel), update `main.dart` to use them.
- **Depends on:** T10, T11
- **Parallel with:** None (single ticket)
- **Acceptance criteria:** App launches with provider setup; MaterialApp renders GamePage as home.

---

### Wave 6 — UI Widgets (Parallel)

#### T13 — Build `GamePage` scaffold + `ScoreHeader`

- **Description:** Create `presentation/pages/game_page.dart` (Scaffold with AppBar, body layout) and `presentation/widgets/score_header.dart` (displays score and round number from ViewModel).
- **Depends on:** T12
- **Parallel with:** T14, T15, T16
- **Acceptance criteria:** Page renders with score header; layout matches wireframe; consumes GameViewModel via Provider.

#### T14 — Build `FlagImage` widget

- **Description:** Create `presentation/widgets/flag_image.dart` using `cached_network_image`. Shows loading spinner while loading, error icon on failure, flag image on success. Takes `flagUrl` as parameter.
- **Depends on:** T12
- **Parallel with:** T13, T15, T16
- **Acceptance criteria:** Flag loads from CDN; placeholder shown during load; error widget shown on failure.

#### T15 — Build `OptionButton` widget

- **Description:** Create `presentation/widgets/option_button.dart`. Displays country name; supports visual states (default, correct, wrong, revealed, disabled). Calls `selectOption` on tap when enabled.
- **Depends on:** T12
- **Parallel with:** T13, T14, T16
- **Acceptance criteria:** All 5 visual states render correctly; tap is disabled when round is over; correct/wrong colors match spec.

#### T16 — Build `AttemptsIndicator` + `ResultOverlay`

- **Description:** Create `presentation/widgets/attempts_indicator.dart` (dots showing remaining attempts) and `presentation/widgets/result_overlay.dart` (feedback message + "Next" button after round ends).
- **Depends on:** T12
- **Parallel with:** T13, T14, T15
- **Acceptance criteria:** Dots reflect `attemptsLeft`; overlay appears on round end; "Next" button triggers `nextQuestion()`.

---

### Wave 7 — Integration

#### T17 — Wire everything together

- **Description:** Assemble GamePage with all widgets. Connect ViewModel state to widget props. Verify full game loop works end-to-end (load → display → answer → feedback → next).
- **Depends on:** T13, T14, T15, T16
- **Parallel with:** None (single ticket)
- **Acceptance criteria:** Complete game loop works; no runtime errors; UI updates reactively to ViewModel changes.

---

### Wave 8 — Testing (Parallel)

#### T18 — Write unit tests (domain + data)

- **Description:** Create `test/unit/domain/question_generator_test.dart`, `test/unit/domain/score_calculator_test.dart`, `test/unit/data/country_repository_impl_test.dart`. Use `mocktail` to mock API service and local data source.
- **Depends on:** T8, T9
- **Parallel with:** T19, T20
- **Acceptance criteria:** All domain logic covered; repository fallback logic verified; tests pass.

#### T19 — Write ViewModel tests

- **Description:** Create `test/viewmodel/game_view_model_test.dart`. Mock repository; test `startGame()`, `selectOption()` (correct/wrong/reveal), `nextQuestion()`, `resetGame()`, no-repeat logic.
- **Depends on:** T10
- **Parallel with:** T18, T20
- **Acceptance criteria:** All state transitions verified; scoring verified; no-repeat behavior verified; tests pass.

#### T20 — Write widget tests

- **Description:** Create `test/widget/game_page_test.dart`. Mock network image; test rendering, tap interactions, visual state changes, full game loop.
- **Depends on:** T17
- **Parallel with:** T18, T19
- **Acceptance criteria:** All widget states tested; tap interactions verified; tests pass.

---

### Wave 9 — Polish (Parallel)

#### T21 — Add app icon & splash screen

- **Description:** Configure app icon in `pubspec.yaml` and platform-specific files. Add splash screen configuration.
- **Depends on:** T17
- **Parallel with:** T22
- **Acceptance criteria:** App icon displays on Android & iOS; splash screen shows on launch.

#### T22 — Run `flutter analyze` and fix all warnings

- **Description:** Run `flutter analyze`; fix all lint warnings and errors. Ensure code follows `flutter_lints` rules.
- **Depends on:** T17
- **Parallel with:** T21
- **Acceptance criteria:** `flutter analyze` reports zero issues.

---

### Dependency Graph

```
T1 ──┬── T6 ──┬── T8 ──┬── T10 ──┬── T12 ──┬── T13 ──┬── T17 ──┬── T18
     │        │        │         │         │        │        │
T2 ──┤        └── T7 ──┘         │         ├── T14 ──┤        ├── T19
     │                          │         │        │        │
T3 ──┘                          │         ├── T15 ──┤        └── T20
                                │         │        │
T4 ──┬── T5 ────────────────────┘         └── T16 ──┘
     │
     └── T9 ──────────────────────────────┘

T11 ──────────────────────────────────────┘

T17 ──┬── T21
      └── T22
```

---

### Summary

| Wave | Tickets            | Parallelizable | Est. Effort |
| ---- | ------------------ | -------------- | ----------- |
| 1    | T1, T2, T3, T4     | Yes (4)        | Small       |
| 2    | T5, T6, T7         | Yes (3)        | Medium      |
| 3    | T8, T9             | Yes (2)        | Medium      |
| 4    | T10, T11           | Yes (2)        | Large       |
| 5    | T12                | No             | Small       |
| 6    | T13, T14, T15, T16 | Yes (4)        | Medium      |
| 7    | T17                | No             | Medium      |
| 8    | T18, T19, T20      | Yes (3)        | Large       |
| 9    | T21, T22           | Yes (2)        | Small       |

**Total: 22 tickets across 9 waves.**

---

## 11. Risk Mitigation

| Risk                               | Mitigation                                                      |
| ---------------------------------- | --------------------------------------------------------------- |
| API deprecated / unreachable       | Local JSON fallback ensures game always works                   |
| Flag CDN slow/unreachable          | `cached_network_image` with placeholder + error widget          |
| Duplicate country names in options | Filter by name uniqueness in `QuestionGenerator`                |
| Rapid double-taps                  | Disable buttons immediately on tap, re-enable on `nextQuestion` |
| Memory leaks                       | Cancel HTTP requests on dispose; use `ChangeNotifier` properly  |

---

## 12. Future Enhancements

- Difficulty levels (more options, fewer attempts).
- Timer per question for bonus points.
- Categories (continents, capitals).
- Leaderboard (online via Firebase).
- Sound effects & animations.
- Dark mode support.
