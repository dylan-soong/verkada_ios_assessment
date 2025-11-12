//
//  PokemonImage.swift
//  Verkada iOS Assessment
//
//  Created by Dylan Soong on 11/9/25.
//

import SwiftUI

struct PokemonImage: View {
    let pokemon: Pokemon
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let uiImage = image {
                // display loaded UIImage
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                // spinny symbol while image is loading
                ProgressView()
            }
        }
        .onAppear {
            // Task {} instead of .task {} to allow off screen loading (more smooth scrolling experience)
            Task {
                await loadImage()
            }
        }
    }
    
    private func loadImage() async {
        // check if the image is in the cache first
        if let cached = ImageCache.shared.image(for: pokemon.id) {
            await MainActor.run {
                image = cached
            }
            return
        }
        
        // if not in cache, download from url and store in cache
        do {
            let (data, _) = try await URLSession.shared.data(from: pokemon.imageURL)
            guard let uiImage = UIImage(data: data) else { return }
            
            ImageCache.shared.insert(uiImage, for: pokemon.id)
            
            await MainActor.run { // run on main thread because image is UI state
                image = uiImage
            }
        } catch {
            print("Failed to load image for pokemon id:", pokemon.id)
        }
    }
}
