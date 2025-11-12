## Data Fetching

- At the start, `ContentView` creates a `PokemonViewModel` and calls `loadBatch()` for an initial batch of 20 pokemon.
- `loadBatch()` hits the PokeAPI (`/pokemon?limit=pageSize&offset=offset`), decodes the JSON into `Pokemon` models (id, name, imageURL), and appends them to `pokemons`.

## Pagination

- `pageSize` is 20, the app fetches new pokemon 20 at a time.
- `offset` tracks how many Pokémon have been loaded so far (incremented after every batch is fetched).
- As the user scrolls, each grid cell’s `.onAppear` calls `loadMore(currentIndex:)`.
- `loadMore(currentIndex:)` checks if the user reaches near the end of the loaded list and `loadBatch()` is called to fetch the next page.
- `hasMore` is set to `false` when a page returns fewer than `pageSize` items, stopping further loads.

## Image Loading & Caching

- Each `PokemonImage` view:
  - On appear, runs `loadImage()` in a `Task`.
  - First checks `ImageCache.shared` for an existing `UIImage` by Pokémon id.
  - If cached, uses it immediately.
  - If not, downloads the image from `imageURL`, adds it into `ImageCache`, then updates the view.
- `ImageCache` is a singleton (only one instance) that has a `NSCache<NSNumber, UIImage>` with a `countLimit`, so old images are evicted automatically while new ones are added.
