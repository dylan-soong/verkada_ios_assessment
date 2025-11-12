//
//  PokemonGridView.swift
//  Verkada iOS Assessment
//
//  Created by Dylan Soong on 11/6/25.
//

import SwiftUI

struct PokemonGridView: View {
    @ObservedObject var viewModel: PokemonViewModel   // viewModel sent in through ContentView
    
    // 3 flexible columns that will share the available screen width equally
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(Array(viewModel.pokemons.enumerated()), id: \.element.id) { index, pokemon in
                    let isSelected = viewModel.selectedPokemon?.id == pokemon.id
                    
                    PokemonImage(pokemon: pokemon)
                    
                        // green filled box for selected pokemon
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.green.opacity(0.6) : Color.clear)
                        )
                    
                        // black outline around selected pokemon
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isSelected ? Color.primary : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .onTapGesture {
                            viewModel.selectedPokemon = pokemon
                            //print(pokemon.id)
                        }
                        .onAppear {
                            // will fetch more pokemon only if pokemon is the last fetched pokemon
                            viewModel.loadMore(currentIndex: index)
                        }
                        
                        // slight visual for selection indication
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(
                            .spring(response: 0.25, dampingFraction: 0.6),
                            value: isSelected
                        )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
