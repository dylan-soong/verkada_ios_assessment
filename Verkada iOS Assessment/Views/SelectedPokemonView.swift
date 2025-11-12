//
//  SelectedPokemonView.swift
//  Verkada iOS Assessment
//
//  Created by Dylan Soong on 11/6/25.
//

import SwiftUI

struct SelectedPokemonView: View {
    let pokemon: Pokemon? // ? because no pokemon is selected at the start
    @State private var backgroundColor: Color = Color.white.opacity(0.3)
    @State private var jiggle = false
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea(edges: .top)
                
            if let pokemon {
                VStack(spacing: 0) {
                    
                    // display pokemon image
                    PokemonImage(pokemon: pokemon)
                        .id(pokemon.id) // reloads PokemonImage when pokemon.id changes
                    
                    // display pokemon name
                    Text(pokemon.name)
                        .font(.custom("Avenir-Heavy", size: 30, relativeTo: .title2))
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 2)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .padding(.top, 24) // mainly to avoid pokemon getting cut off by notch on certain phones
                
                /*  JIGGLE ANIMATION */
                .scaleEffect(jiggle ? 1.1 : 1.0)
                .animation(
                    .spring(response: 0.1, dampingFraction: 0.8),
                    value: jiggle
                )
                .task(id: pokemon.id) {
                    // update background color when pokemon.id changes (SEE averageColorCI() below)
                    if let uiImage = ImageCache.shared.image(for: pokemon.id),
                       let avg = uiImage.averageColorCI() {
                        backgroundColor = Color(avg)
                    }
                    
                    // init jiggle when pokemon.id changes
                    jiggle = true
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    jiggle = false
                }
                
                
            } else {
                // at beggining when no pokemon is selected
                Text("Tap a Pokémon")
                    .font(.custom("Avenir-Heavy", size: 16, relativeTo: .title2))
                    .foregroundColor(.secondary)
            }
        }
        // limit frame of displayed pokemon to 1/3 of the screen so that you can always see the scrollview
        .frame(height: UIScreen.main.bounds.height / 3)
        
    }
}


/*
Additional UI feature (used LLM for this)
 
Calculates the "average color" of a UIImage.
Ignores transparent pixels and pixels close to black to make resulting color more vibrant
*/

extension UIImage {
    func averageColorCI() -> UIColor? {
        guard let cgImage = self.cgImage else { return nil }
                
        // Downscale for performance
        let width = 40
        let height = 40
        
        let bitmapBytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapData = [UInt8](repeating: 0, count: width * height * 4)
        
        guard let context = CGContext(
            data: &bitmapData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bitmapBytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        // Draw the image scaled into our small context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        var count: Int = 0
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = CGFloat(bitmapData[offset]) / 255.0
                let g = CGFloat(bitmapData[offset + 1]) / 255.0
                let b = CGFloat(bitmapData[offset + 2]) / 255.0
                let a = CGFloat(bitmapData[offset + 3]) / 255.0
                
                // Ignore fully transparent
                guard a > 0.01 else { continue }
                
                // Ignore "almost black" pixels
                let brightness = (r + g + b) / 3.0
                guard brightness > 0.1 else { continue }
                
                totalR += r
                totalG += g
                totalB += b
                count += 1
            }
        }
        
        guard count > 0 else { return nil }
        
        let avgR = totalR / CGFloat(count)
        let avgG = totalG / CGFloat(count)
        let avgB = totalB / CGFloat(count)
        
        return UIColor(red: avgR, green: avgG, blue: avgB, alpha: 1.0)
    }
}
