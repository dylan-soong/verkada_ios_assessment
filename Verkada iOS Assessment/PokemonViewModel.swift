//
//  PokemonViewModel.swift
//  Verkada iOS Assessment
//
//  Created by Dylan Soong on 11/7/25.
//

import SwiftUI

@MainActor
class PokemonViewModel: ObservableObject {
    // keeps track of all fetched pokemon (id, name, imageURL) directly in memory
    @Published var pokemons: [Pokemon] = []
    @Published var selectedPokemon: Pokemon?
    
    @Published var isLoading = false
    @Published var hasMore = true
    
    private var offset = 0
    private let pageSize = 20
    
    // check if the pokemon is the LAST loaded pokemon before loading more
    func loadMore(currentIndex: Int) {
        if currentIndex == pokemons.count - 6 {
            Task { await loadBatch() }
        }
    }
    
    // fetches info of the next "pageSize" pokemons and appends to pokemons array
    func loadBatch() async {
        
        // check if main thread is already fetching, if so just cancel the call
        guard !isLoading, hasMore else { return }
        
        // lock loadBatch() while fetching so no extra calls get queued and no extra pokemon get fetched
        isLoading = true
        let newPage = await loadPokemonPage(limit: pageSize, offset: offset)
        offset += newPage.count  // increment offset for next batch
        if newPage.count < pageSize { hasMore = false }
        pokemons.append(contentsOf: newPage)
        isLoading = false
    }
    
    // returns ID, NAME, IMAGE URL of each new pokemon
    func loadPokemonPage(limit: Int, offset: Int) async -> [Pokemon] {
        var result: [Pokemon] = []
        
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=\(limit)&offset=\(offset)") else {
            return []
        }
        
        do {
            // hit api, decode JSON -> names, urls
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(PokemonListResponse.self, from: data)
            
            for item in decoded.results {
                
                // parts looks like ["https:", "pokeapi.co", "api", "v2", "pokemon", "1"]  <- last item is pokemon id
                let parts = item.url.split(separator: "/")
                
                guard let idString = parts.last, let id = Int(idString) else { continue }
                guard let imageURL = URL(
                    // front_default always points to same link type so i just inserted the each id into a string
                    string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
                ) else { continue }
                
                result.append(Pokemon(id: id,
                                      name: item.name.capitalized,
                                      imageURL: imageURL))
            }
        } catch {
            print("Failed to load page:", error)
        }
        
        return result
    }
}
