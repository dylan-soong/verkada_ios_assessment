//
//  ContentView.swift
//  Verkada iOS Assessment
//
//  Created by Dylan Soong on 11/6/25.
//

import SwiftUI

struct ContentView: View {
    
    // single viewModel init for entire app
    @StateObject private var viewModel = PokemonViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            SelectedPokemonView(pokemon: viewModel.selectedPokemon)
            
            Rectangle()
                .frame(height: 4)
                .foregroundColor(.primary)
            
            PokemonGridView(viewModel: viewModel)
        }
        .padding(.top)
        .background(Color.yellow)
        .ignoresSafeArea(edges: .top)
        .task {
            await viewModel.loadBatch()  // calls for initial batch of pokemon
        }
    }
}
