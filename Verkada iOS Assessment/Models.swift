//
//  Models.swift
//  Verkada iOS Assessment
//
//  Created by Dylan Soong on 11/6/25.
//

import Foundation

// structs for decoding JSON data from API
// array of pokemons
struct PokemonListResponse: Codable {
    let results: [PokemonListItem]
}
// info stored for EACH pokemon
struct PokemonListItem: Codable {
    let name: String
    let url: String
}


// self made struct
// will be stored in memory in "pokemons" array
struct Pokemon: Identifiable {
    let id: Int
    let name: String
    let imageURL: URL
}
