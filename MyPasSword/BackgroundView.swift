import SwiftUI

struct BackgroundView: View {
    @ObservedObject var backgroundManager: BackgroundManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Черный фон по умолчанию
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                // Пользовательская фотография с правильной обработкой
                if let image = backgroundManager.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill) // Заполняет весь экран
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped() // Обрезает изображение по границам экрана
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: 15) // Blur эффект
                        .opacity(0.7) // Прозрачность
                }
            }
        }
        .ignoresSafeArea()
    }
} 