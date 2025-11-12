//
//  ImageCache.swift
//  Verkada iOS Assessment
//
//  Created by Dylan Soong on 11/9/25.
//

import UIKit

class ImageCache {
    
    private init() { // private to prevent outside initiation of an ImageCache
        cache.countLimit = 150 // set max # of images in cache
    }

    // creates one global instance for entire app
    static let shared = ImageCache()
    
    private let cache = NSCache<NSNumber, UIImage>() // pokemon id -> image
    
    // grabs image from cache based on id number
    func image(for id: Int) -> UIImage? {
        cache.object(forKey: NSNumber(value: id))
    }
    
    // stores a UIImage into cache at specific id number key
    func insert(_ image: UIImage, for id: Int) {
        cache.setObject(image, forKey: NSNumber(value: id))
    }
}
