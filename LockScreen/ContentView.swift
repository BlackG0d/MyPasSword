import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var passcode: String = ""
    @State private var passcodeLength: Int = 6
    @State private var showingSettings = false
    @State private var isUnlocked = false
    @State private var backgroundImage: UIImage?
    @State private var showingImagePicker = false
    
    let numbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "delete.left"]
    ]
    
    let letters = [
        ["", "ABC", "DEF"],
        ["GHI", "JKL", "MNO"],
        ["PQRS", "TUV", "WXYZ"],
        ["", "", ""]
    ]
    
    var body: some View {
        ZStack {
            // Background
            if let backgroundImage = backgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(Color.black.opacity(0.3))
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                Spacer()
                
                Text("Enter Passcode")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                // Passcode dots
                HStack(spacing: 20) {
                    ForEach(0..<passcodeLength, id: \.self) { index in
                        Circle()
                            .fill(passcode.count > index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.bottom, 50)
                
                // Number pad
                VStack(spacing: 20) {
                    ForEach(0..<4) { row in
                        HStack(spacing: 20) {
                            ForEach(0..<3) { col in
                                let number = numbers[row][col]
                                let letter = letters[row][col]
                                
                                Button(action: {
                                    if number == "delete.left" {
                                        if !passcode.isEmpty {
                                            passcode.removeLast()
                                        }
                                    } else if !number.isEmpty {
                                        if passcode.count < passcodeLength {
                                            passcode += number
                                        }
                                    }
                                }) {
                                    if number == "delete.left" {
                                        Image(systemName: number)
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    } else if !number.isEmpty {
                                        VStack(spacing: 2) {
                                            Text(number)
                                                .font(.system(size: 32, weight: .light))
                                            if !letter.isEmpty {
                                                Text(letter)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                        }
                                        .foregroundColor(.white)
                                    } else {
                                        Color.clear
                                    }
                                }
                                .frame(width: 75, height: 75)
                                .background(number.isEmpty ? Color.clear : Color.white.opacity(0.1))
                                .clipShape(Circle())
                                .simultaneousGesture(
                                    LongPressGesture(minimumDuration: 3)
                                        .onEnded { _ in
                                            if number == "9" {
                                                showingSettings = true
                                            }
                                        }
                                )
                            }
                        }
                    }
                }
                
                // Bottom buttons
                HStack {
                    Button(action: {
                        // Handle Emergency action
                    }) {
                        Text("Emergency")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Handle Cancel action
                    }) {
                        Text("Cancel")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
                
                Spacer()
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    Form {
                        Section(header: Text("Passcode Settings")) {
                            Picker("Passcode Length", selection: $passcodeLength) {
                                Text("4 digits").tag(4)
                                Text("6 digits").tag(6)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: passcodeLength) { newValue in
                                // Clear existing passcode when length changes
                                passcode = ""
                            }
                        }
                        
                        Section(header: Text("Background")) {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Text("Choose Background Image")
                                    Spacer()
                                    Image(systemName: "photo")
                                }
                            }
                            
                            if backgroundImage != nil {
                                Button(action: {
                                    backgroundImage = nil
                                }) {
                                    HStack {
                                        Text("Remove Background Image")
                                            .foregroundColor(.red)
                                        Spacer()
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Settings")
                    .navigationBarItems(trailing: Button("Done") {
                        showingSettings = false
                    })
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $backgroundImage)
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 