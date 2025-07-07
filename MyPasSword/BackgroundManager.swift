import SwiftUI
import PhotosUI
import UIKit

class BackgroundManager: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isImageSelected: Bool = false
    
    private let userDefaultsKey = "selectedBackgroundImage"
    
    init() {
        loadSavedImage()
    }
    
    func selectImage() {
        // Этот метод будет вызываться из PhotosPicker
        // Реальная логика выбора изображения будет в SecretMenuView
    }
    
    func saveImage(_ image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: userDefaultsKey)
            selectedImage = image
            isImageSelected = true
        }
    }
    
    func loadSavedImage() {
        if let imageData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let image = UIImage(data: imageData) {
            selectedImage = image
            isImageSelected = true
        } else {
            selectedImage = nil
            isImageSelected = false
        }
    }
    
    func clearImage() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        selectedImage = nil
        isImageSelected = false
    }
} 