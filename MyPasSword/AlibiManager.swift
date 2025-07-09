import SwiftUI
import UIKit

class AlibiManager: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isImageSelected: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let alibiImageKey = "alibiImage"
    
    init() {
        loadImage()
    }
    
    func saveImage(_ image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            userDefaults.set(imageData, forKey: alibiImageKey)
            selectedImage = image
            isImageSelected = true
        }
    }
    
    func loadImage() {
        if let imageData = userDefaults.data(forKey: alibiImageKey),
           let image = UIImage(data: imageData) {
            selectedImage = image
            isImageSelected = true
        } else {
            selectedImage = nil
            isImageSelected = false
        }
    }
    
    func clearImage() {
        userDefaults.removeObject(forKey: alibiImageKey)
        selectedImage = nil
        isImageSelected = false
    }
} 