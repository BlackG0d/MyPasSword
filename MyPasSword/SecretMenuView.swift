import SwiftUI
import PhotosUI
import ARKit

// Time formatter for API status
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .short
    return formatter
}()

// Neumorphic стиль для SecretMenuView
struct NeumorphicModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var isCircle: Bool = false
    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if isCircle {
                        Circle()
                            .fill(Color(.systemGray6))
                            .shadow(color: Color.white.opacity(0.8), radius: 8, x: -6, y: -6)
                            .shadow(color: Color.black.opacity(0.13), radius: 8, x: 6, y: 6)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color(.systemGray6))
                            .shadow(color: Color.white.opacity(0.8), radius: 8, x: -6, y: -6)
                            .shadow(color: Color.black.opacity(0.13), radius: 8, x: 6, y: 6)
                    }
                }
            )
    }
}

// Inset Neumorphic стиль (вдавленный)
struct InsetNeumorphicModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.systemGray6))
                    .shadow(color: Color.white.opacity(0.8), radius: 4, x: 2, y: 2)
                    .shadow(color: Color.black.opacity(0.13), radius: 4, x: -2, y: -2)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Instructions Button Component
struct InstructionsButton: View {
    var body: some View {
        Button(action: {
            print("Instructions button tapped")
        }) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                Text("Instructions")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .shadow(color: Color.white.opacity(0.9), radius: 8, x: -4, y: -4)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 4, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
    }
}

// MARK: - Passcode Length Component
struct PasscodeLengthSection: View {
    @Binding var tempLength: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Passcode Length")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)

            Picker("Passcode Length", selection: $tempLength) {
                Text("4 digits").tag(4)
                Text("6 digits").tag(6)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .neumorphic()
        .padding(.horizontal, 16)
    }
}

// MARK: - Password Setup Component
struct PasswordSetupSection: View {
    @Binding var tempPassword: String
    @Binding var showingPasswordInput: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set Passcode")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            Button(action: {
                showingPasswordInput = true
            }) {
                HStack {
                    if tempPassword.isEmpty {
                        Text("Set Passcode")
                            .font(.body)
                            .foregroundColor(.blue)
                    } else {
                        Text(tempPassword)
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    Spacer()
                    if !tempPassword.isEmpty {
                        Button(action: {
                            tempPassword = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(16)
                .insetNeumorphic(cornerRadius: 16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 12)
        .neumorphic()
        .padding(.horizontal, 16)
    }
}

// MARK: - Ghost Effect Controls Component
struct GhostEffectControls: View {
    @Binding var selectedGhostButton: String?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Ghost Effect Controls")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 8)
            
            HStack(spacing: 12) {
                Button("Gesture") {
                    selectedGhostButton = "Gesture"
                    UserDefaults.standard.set("Gesture", forKey: "selectedGhostButton")
                    NotificationCenter.default.post(name: .ghostEffectChanged, object: "Gesture")
                    print("Gesture button tapped - Gesture effect selected")
                }
                .font(.system(size: selectedGhostButton == "Gesture" ? 15 : 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, selectedGhostButton == "Gesture" ? 18 : 14)
                .padding(.vertical, selectedGhostButton == "Gesture" ? 9 : 7)
                .background(selectedGhostButton == "Gesture" ? Color.blue : Color.blue.opacity(0.6))
                .cornerRadius(12)
                .scaleEffect(selectedGhostButton == "Gesture" ? 1.08 : 0.95)
                .animation(.easeInOut(duration: 0.3), value: selectedGhostButton)
                .disabled(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) == nil)
                
                Button("Volume") {
                    selectedGhostButton = "Volume"
                    UserDefaults.standard.set("Volume", forKey: "selectedGhostButton")
                    NotificationCenter.default.post(name: .ghostEffectChanged, object: "Volume")
                    print("Volume button tapped - Volume effect selected")
                }
                .font(.system(size: selectedGhostButton == "Volume" ? 15 : 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, selectedGhostButton == "Volume" ? 18 : 14)
                .padding(.vertical, selectedGhostButton == "Volume" ? 9 : 7)
                .background(selectedGhostButton == "Volume" ? Color.green : Color.green.opacity(0.6))
                .cornerRadius(12)
                .scaleEffect(selectedGhostButton == "Volume" ? 1.08 : 0.95)
                .animation(.easeInOut(duration: 0.3), value: selectedGhostButton)
                
                Button("Emergency") {
                    selectedGhostButton = "Emergency"
                    UserDefaults.standard.set("Emergency", forKey: "selectedGhostButton")
                    NotificationCenter.default.post(name: .ghostEffectChanged, object: "Emergency")
                    print("Emergency button tapped - Emergency effect selected")
                }
                .font(.system(size: selectedGhostButton == "Emergency" ? 15 : 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, selectedGhostButton == "Emergency" ? 18 : 14)
                .padding(.vertical, selectedGhostButton == "Emergency" ? 9 : 7)
                .background(selectedGhostButton == "Emergency" ? Color.red : Color.red.opacity(0.6))
                .cornerRadius(12)
                .scaleEffect(selectedGhostButton == "Emergency" ? 1.08 : 0.95)
                .animation(.easeInOut(duration: 0.3), value: selectedGhostButton)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: Color.white.opacity(0.9), radius: 4, x: -2, y: -2)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 2, y: 2)
        )
    }
}

// MARK: - Mods Section Component
struct ModsSection: View {
    @Binding var matchingModeEnabled: Bool
    @Binding var autoEmergencyModeEnabled: Bool
    @Binding var autoEmergencyDelay: Double
    @Binding var passcodeSetSuccess: Bool
    @Binding var selectedGhostButton: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mods")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password Matching")
                            .font(.body)
                        Text("App will crash when any password is entered")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Toggle("", isOn: $matchingModeEnabled)
                        .labelsHidden()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color.white.opacity(0.9), radius: 6, x: -3, y: -3)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 3, y: 3)
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ghost Effect")
                            .font(.body)
                        Text(passcodeSetSuccess ? "Em\u{00EA}rgency" : "Emergency")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Toggle("", isOn: $autoEmergencyModeEnabled)
                        .labelsHidden()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color.white.opacity(0.9), radius: 6, x: -3, y: -3)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 3, y: 3)
                )
                
                if autoEmergencyModeEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Delay between digits")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(String(format: "%.1fs", autoEmergencyDelay))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        Slider(value: $autoEmergencyDelay, in: 0.5...10.0, step: 0.1)
                            .accentColor(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .shadow(color: Color.white.opacity(0.9), radius: 4, x: -2, y: -2)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 2, y: 2)
                    )
                }
                
                // Ghost Effect controls
                GhostEffectControls(selectedGhostButton: $selectedGhostButton)
            }
        }
        .padding(.vertical, 12)
        .neumorphic()
        .padding(.horizontal, 16)
    }
}

// MARK: - API Status Section Component
struct APISection: View {
    @ObservedObject var apiService: PasswordAPIService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("API Status")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto Monitor")
                            .font(.body)
                        Text("Automatically sync password with server")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Toggle("", isOn: $apiService.isMonitoring)
                        .labelsHidden()
                        .onChange(of: apiService.isMonitoring) { oldValue, newValue in
                            if newValue {
                                apiService.startMonitoring()
                            } else {
                                apiService.stopMonitoring()
                            }
                            UserDefaults.standard.set(newValue, forKey: "autoMonitorEnabled")
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color.white.opacity(0.9), radius: 6, x: -3, y: -3)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 3, y: 3)
                )
                
                if apiService.isMonitoring {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("User ID")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            TextField("Enter User ID", text: $apiService.userID)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 120)
                        }
                        HStack {
                            Text("Last Update")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(apiService.lastFetchTime != nil ? timeFormatter.string(from: apiService.lastFetchTime!) : "Never")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        HStack {
                            Text("Status")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(apiService.isLoading ? "Loading..." : "Ready")
                                .font(.caption)
                                .foregroundColor(apiService.isLoading ? .orange : .green)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .shadow(color: Color.white.opacity(0.9), radius: 4, x: -2, y: -2)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 2, y: 2)
                    )
                }
            }
        }
        .padding(.vertical, 12)
        .neumorphic()
        .padding(.horizontal, 16)
    }
}

// MARK: - Background Settings Section Component
struct BackgroundSettingsSection: View {
    @ObservedObject var backgroundManager: BackgroundManager
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Background Settings")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Background")
                            .font(.body)
                        Text("Set your own background image")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .onChange(of: selectedItem) { oldValue, newItem in
                        Task {
                            if let newItem = newItem,
                               let data = try? await newItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                backgroundManager.saveImage(image)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color.white.opacity(0.9), radius: 6, x: -3, y: -3)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 3, y: 3)
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reset to Default")
                            .font(.body)
                        Text("Remove custom background")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        backgroundManager.clearImage()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color.white.opacity(0.9), radius: 6, x: -3, y: -3)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 3, y: 3)
                )
            }
        }
        .padding(.vertical, 12)
        .neumorphic()
        .padding(.horizontal, 16)
    }
}

// MARK: - Alibi Image Section Component
struct AlibiImageSection: View {
    @ObservedObject var alibiManager: AlibiManager
    @State private var selectedAlibiItem: PhotosPickerItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Alibi Image")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Image preview
                if let image = alibiManager.selectedImage {
                    VStack(spacing: 8) {
                        Text("Current Alibi")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                // Photo picker button
                PhotosPicker(selection: $selectedAlibiItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                        Text(alibiManager.isImageSelected ? "Change Alibi" : "Select Alibi")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .insetNeumorphic(cornerRadius: 12)
                }
                .buttonStyle(PlainButtonStyle())
                .onChange(of: selectedAlibiItem) { oldValue, newItem in
                    Task {
                        if let newItem = newItem,
                           let data = try? await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            alibiManager.saveImage(image)
                        }
                    }
                }
                
                // Clear alibi button
                if alibiManager.isImageSelected {
                    Button(action: {
                        alibiManager.clearImage()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.red)
                            Text("Remove Alibi")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .insetNeumorphic(cornerRadius: 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 8)
        .neumorphic()
        .padding(.horizontal, 16)
    }
}

// MARK: - Password Settings Section Component
struct PasswordSettingsSection: View {
    @Binding var passwordLength: Int
    @Binding var tempLength: Int
    @Binding var originalLength: Int
    @Binding var tempPassword: String
    @Binding var confirmPassword: String
    @Binding var showingPasswordInput: Bool
    @Binding var passwordError: String
    @Binding var passcodeSetSuccess: Bool
    let onSettingsChanged: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Password Settings")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password Length")
                            .font(.body)
                        Text("Number of digits in passcode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: {
                            if tempLength > 4 {
                                tempLength -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(tempLength <= 4)
                        
                        Text("\(tempLength)")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(minWidth: 30)
                        
                        Button(action: {
                            if tempLength < 8 {
                                tempLength += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(tempLength >= 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set New Password")
                            .font(.body)
                        Text("Change the current passcode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        tempPassword = ""
                        confirmPassword = ""
                        passwordError = ""
                        showingPasswordInput = true
                    }) {
                        Image(systemName: "key.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingPasswordInput) {
            PasswordInputSheet(
                tempPassword: $tempPassword,
                confirmPassword: $confirmPassword,
                passwordError: $passwordError,
                passcodeSetSuccess: $passcodeSetSuccess,
                showingPasswordInput: $showingPasswordInput,
                onSettingsChanged: onSettingsChanged
            )
        }
    }
}

// MARK: - Password Input Sheet
struct PasswordInputSheet: View {
    @Binding var tempPassword: String
    @Binding var confirmPassword: String
    @Binding var passwordError: String
    @Binding var passcodeSetSuccess: Bool
    @Binding var showingPasswordInput: Bool
    let onSettingsChanged: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set New Password")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Password")
                        .font(.headline)
                    SecureField("Enter new password", text: $tempPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.headline)
                    SecureField("Confirm new password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                if !passwordError.isEmpty {
                    Text(passwordError)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingPasswordInput = false
                },
                trailing: Button("Save") {
                    if tempPassword == confirmPassword && tempPassword.count >= 4 {
                        UserDefaults.standard.set(tempPassword, forKey: "passcode")
                        passcodeSetSuccess = true
                        showingPasswordInput = false
                        onSettingsChanged()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            passcodeSetSuccess = false
                        }
                    } else {
                        passwordError = "Passwords don't match or are too short"
                    }
                }
                .disabled(tempPassword.isEmpty || confirmPassword.isEmpty)
            )
        }
    }
}

struct SecretMenuView: View {
    @Binding var showSecretMenu: Bool
    @Binding var passwordLength: Int
    let onSettingsChanged: () -> Void

    @ObservedObject var apiService: PasswordAPIService
    @ObservedObject var backgroundManager: BackgroundManager
    @ObservedObject var alibiManager: AlibiManager
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedAlibiItem: PhotosPickerItem?
    @State private var tempLength: Int = 4
    @State private var originalLength: Int = 4
    @State private var tempPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showingPasswordInput = false
    @State private var passwordError: String = ""
    @State private var matchingModeEnabled = UserDefaults.standard.bool(forKey: "matchingModeEnabled")
    @State private var autoEmergencyModeEnabled = UserDefaults.standard.bool(forKey: "autoEmergencyModeEnabled")
    @State private var autoEmergencyDelay: Double = UserDefaults.standard.double(forKey: "autoEmergencyDelay") == 0 ? 0.5 : UserDefaults.standard.double(forKey: "autoEmergencyDelay")
    @State private var passcodeSetSuccess = false
    @State private var selectedGhostButton: String? = UserDefaults.standard.string(forKey: "selectedGhostButton")

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Neumorphic background
                        Color(.systemGray6)
                            .ignoresSafeArea()
                        
                        // Instructions button
                        InstructionsButton()
                        
                        // Passcode length section
                        PasscodeLengthSection(tempLength: $tempLength)
                        
                        // Password setup section
                        PasswordSetupSection(tempPassword: $tempPassword, showingPasswordInput: $showingPasswordInput)
                        
                        // Mods section
                        ModsSection(matchingModeEnabled: $matchingModeEnabled, autoEmergencyModeEnabled: $autoEmergencyModeEnabled, autoEmergencyDelay: $autoEmergencyDelay, passcodeSetSuccess: $passcodeSetSuccess, selectedGhostButton: $selectedGhostButton)
                        
                        // Background Settings Section
                        BackgroundSettingsSection(backgroundManager: backgroundManager)
                        
                        // Alibi Image Section
                        AlibiImageSection(alibiManager: alibiManager)

                        // API Status Section
                        APISection(apiService: apiService)

                        // Password Settings Section
                        PasswordSettingsSection(passwordLength: $passwordLength, tempLength: $tempLength, originalLength: $originalLength, tempPassword: $tempPassword, confirmPassword: $confirmPassword, showingPasswordInput: $showingPasswordInput, passwordError: $passwordError, passcodeSetSuccess: $passcodeSetSuccess, onSettingsChanged: onSettingsChanged)

                        // Save Button
                        Button(action: {
                            saveSettings()
                        }) {
                            Text("Save Settings")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(16)
                                .neumorphic()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showSecretMenu = false
            })
        }
        .onAppear {
            tempLength = passwordLength
            originalLength = passwordLength
            tempPassword = UserDefaults.standard.string(forKey: "userPassword") ?? ""
            matchingModeEnabled = UserDefaults.standard.bool(forKey: "matchingModeEnabled")
            autoEmergencyModeEnabled = UserDefaults.standard.bool(forKey: "autoEmergencyModeEnabled")
            autoEmergencyDelay = UserDefaults.standard.double(forKey: "autoEmergencyDelay") == 0 ? 0.5 : UserDefaults.standard.double(forKey: "autoEmergencyDelay")
            selectedGhostButton = UserDefaults.standard.string(forKey: "selectedGhostButton")
        }
        .onChange(of: selectedItem) { oldValue, newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    backgroundManager.saveImage(image)
                }
            }
        }
        .onChange(of: selectedAlibiItem) { oldValue, newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    alibiManager.saveImage(image)
                }
            }
        }
    }
    
    private func saveSettings() {
        // Save password length
        if tempLength != originalLength {
            passwordLength = tempLength
            UserDefaults.standard.set(tempLength, forKey: "passLength")
        }
        
        // Save password
        if !tempPassword.isEmpty {
            UserDefaults.standard.set(tempPassword, forKey: "userPassword")
        }
        
        // Save other settings
        UserDefaults.standard.set(matchingModeEnabled, forKey: "matchingModeEnabled")
        UserDefaults.standard.set(autoEmergencyModeEnabled, forKey: "autoEmergencyModeEnabled")
        UserDefaults.standard.set(autoEmergencyDelay, forKey: "autoEmergencyDelay")
        
        // Call the callback to update the main view
        onSettingsChanged()
        
        // Show success feedback
        passcodeSetSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            passcodeSetSuccess = false
        }
    }
}






