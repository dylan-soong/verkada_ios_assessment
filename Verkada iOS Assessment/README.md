# Verkada iOS Assessment – Pokémon Browser

A small SwiftUI app that:

- Fetches Pokémon from the public [PokeAPI](https://pokeapi.co/)
- Displays them in an infinite-scrolling grid
- Shows a selected Pokémon in a large header view with a dynamic background color
- Caches sprites in memory for smoother scrolling

---

## High-Level Data Flow

### 1. Pokémon List Fetching & Pagination

1. **App start**
   - `ContentView` creates a single `PokemonViewModel` with `@StateObject`.
   - In `.task {}`, it calls `await viewModel.loadBatch()` to fetch the first page (20 Pokémon).

2. **Fetching a page**
   - `PokemonViewModel.loadBatch()`:
     - Uses `guard !isLoading, hasMore else { return }` so only one batch is fetched at a time.
     - Calls `loadPokemonPage(limit: pageSize, offset: offset)`.
     - Appends the new `Pokemon` objects to the `pokemons` array.
     - Updates `offset` and flips `hasMore` to `false` when fewer than `pageSize` items are returned (last page).

3. **Infinite scrolling**
   - `PokemonGridView` shows the grid of Pokémon.
   - Each cell’s `.onAppear` calls `viewModel.loadMore(currentIndex: index)`.
   - When `currentIndex` reaches `pokemons.count - 6`, `loadMore` triggers `loadBatch()` → next page is fetched just before reaching the bottom.

---

### 2. Image Loading & Caching

1. **Image cache**
   - `ImageCache` is a global in-memory cache:
     - `static let shared = ImageCache()`
     - Uses `NSCache<NSNumber, UIImage>` keyed by Pokémon `id`.
     - `countLimit` caps how many images are stored.

2. **Loading an image**
   - `PokemonImage` is responsible for showing one Pokémon’s sprite.
   - It keeps `@State private var image: UIImage?`.
   - In `.onAppear`, it starts a `Task { await loadImage() }`.
   - `loadImage()`:
     - First checks `ImageCache.shared.image(for: pokemon.id)`.
       - If found → sets `image` on the main actor immediately.
     - If not found → downloads from `pokemon.imageURL`.
       - On success: inserts into `ImageCache`, then updates `image` on the main actor.

3. **Smooth scrolling**
   - `Task {}` instead of `.task {}` lets downloads continue even if a cell briefly goes off-screen, so images often finish loading even during fast scrolling.

---

### 3. UI Behavior & Animations

1. **Top selected Pokémon view**
   - `SelectedPokemonView` shows:
     - A large `PokemonImage`
     - The Pokémon’s name with a custom font and drop shadow.
   - It takes `pokemon: Pokemon?`:
     - `nil` → shows “Tap a Pokémon”.
     - Non-nil → shows image + name.

2. **Dynamic background color**
   - When the selected Pokémon changes:
     - `.task(id: pokemon.id)` in `SelectedPokemonView` runs.
     - It tries to grab the cached sprite from `ImageCache`.
     - Calls `averageColorCI()` on that `UIImage`.
     - Sets `backgroundColor` to that average color.
   - The resulting `backgroundColor` fills the top area and ignores the safe area at the top.

3. **Jiggle animation**
   - In `SelectedPokemonView`, the whole stack scales:

     ```swift
     .scaleEffect(jiggle ? 1.1 : 1.0)
     ```

   - `.task(id: pokemon.id)` toggles `jiggle`:
     - `jiggle = true`
     - Sleep 0.1s
     - `jiggle = false`
   - A spring animation is attached to `jiggle`, so the selected Pokémon pops slightly whenever the selection changes.

4. **Grid cell selection effect**
   - In `PokemonGridView`, the selected Pokémon cell:
     - Gets a green background with rounded corners.
     - Gets a black stroke border.
     - Slightly scales up with a spring animation.

---

## File-by-File Overview

### `ContentView.swift`

- Owns the single `PokemonViewModel` instance using `@StateObject`.
- Layout:
  - `SelectedPokemonView(pokemon: viewModel.selectedPokemon)` at the top.
  - A thin `Rectangle` divider.
  - `PokemonGridView(viewModel: viewModel)` filling the rest.
- In `.task`:
  - Calls `await viewModel.loadBatch()` to fetch the initial Pokémon batch.
- Background is yellow and ignores the top safe area so the header color bleeds under the notch/status bar.

---

### `PokemonViewModel.swift`

- Annotated with `@MainActor` (all UI-related state is on the main actor).
- `@Published` properties:
  - `pokemons: [Pokemon]` – all currently fetched Pokémon.
  - `selectedPokemon: Pokemon?` – currently selected Pokémon.
  - `isLoading: Bool` – whether a batch is currently being fetched.
  - `hasMore: Bool` – whether there are more Pokémon to load from the API.
- Pagination state:
  - `offset` – how many Pokémon have been fetched so far.
  - `pageSize` – number of Pokémon per page (20).
- Methods:
  - `loadMore(currentIndex:)`
    - When `currentIndex == pokemons.count - 6`, triggers `loadBatch()`.
  - `loadBatch()`
    - Uses `guard !isLoading, hasMore` to avoid duplicate loads and stop when done.
    - Calls `loadPokemonPage(limit:offset:)`.
    - Updates `offset`, `hasMore`, and appends new Pokémon to `pokemons`.
  - `loadPokemonPage(limit:offset:)`
    - Builds the PokeAPI URL.
    - Fetches data with `URLSession.shared.data(from:)`.
    - Decodes `PokemonListResponse`.
    - For each result:
      - Parses the Pokémon `id` from the URL.
      - Constructs the sprite URL using that `id`.
      - Builds a `Pokemon` struct.
    - Returns an array of `Pokemon`.

---

### `PokemonGridView.swift`

- Takes `@ObservedObject var viewModel: PokemonViewModel`.
- Displays a 3-column `LazyVGrid` inside a `ScrollView`.
- Uses `ForEach(Array(viewModel.pokemons.enumerated()), id: \.element.id)` to get both `index` and `pokemon`.
- For each Pokémon:
  - Renders `PokemonImage(pokemon: pokemon)`.
  - Applies:
    - Green background and black stroke if it’s the selected Pokémon.
    - Tap gesture that sets `viewModel.selectedPokemon = pokemon`.
    - `.onAppear` that calls `viewModel.loadMore(currentIndex: index)` to drive infinite scrolling.
    - A scale animation when selected.

---

### `SelectedPokemonView.swift`

- Takes `pokemon: Pokemon?`.
- Local state:
  - `backgroundColor: Color` – the header’s background.
  - `jiggle: Bool` – controls the scale animation.
- Layout:
  - `ZStack` with `backgroundColor` filling and ignoring the top safe area.
  - If a Pokémon is selected:
    - `VStack` with `PokemonImage` and the name text.
  - If none is selected:
    - Shows “Tap a Pokémon”.
- Behavior:
  - `.task(id: pokemon.id)`:
    - Looks up the cached image.
    - Uses `averageColorCI()` to compute a color and sets `backgroundColor`.
    - Triggers the jiggle (scale from 1.0 → 1.1 → 1.0) with a short delay.

---

### `PokemonImage.swift`

- Stateless from the outside: takes `pokemon: Pokemon`.
- Local `@State private var image: UIImage?`.
- In `body`:
  - If `image` exists → shows it using `Image(uiImage:)` with `.resizable()` and `.scaledToFit()`.
  - Else → shows a `ProgressView`.
- Uses `.onAppear` with:

  ```swift
  Task { await loadImage() }
