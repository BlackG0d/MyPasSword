import SwiftUI
import PhotosUI

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

extension View {
    func neumorphic(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(NeumorphicModifier(cornerRadius: cornerRadius, isCircle: false))
    }
    func neumorphicCircle() -> some View {
        self.modifier(NeumorphicModifier(isCircle: true))
    }
    func insetNeumorphic(cornerRadius: CGFloat = 12) -> some View {
        self.modifier(InsetNeumorphicModifier(cornerRadius: cornerRadius))
    }
}

struct SecretMenuView: View {
    @Binding var showSecretMenu: Bool
    @Binding var passwordLength: Int
    let onSettingsChanged: () -> Void

    @ObservedObject var apiService: PasswordAPIService
    @State private var showingImagePicker = false
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
                        // Instructions button - Neumorphic style
                        Button(action: {
                            // Здесь можно добавить логику для показа инструкций
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

                        // Passcode length - Neumorphic style
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

                        // Password setup - Neumorphic style
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
                                            confirmPassword = ""
                                            passwordError = ""
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

                        // Matching mode - Neumorphic style
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
                                
                                // Ghost Effect кнопки
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
                        .padding(.vertical, 12)
                        .neumorphic()
                        .padding(.horizontal, 16)

                        // Inject API - Neumorphic style
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Inject API")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            VStack(spacing: 16) {
                                // User ID input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("User ID")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    TextField("Inject ID", text: $apiService.userID)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .insetNeumorphic(cornerRadius: 12)
                                }
                                // Auto Monitor - только value
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Auto Monitor")
                                            .font(.body)
                                        Text("Value")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { apiService.isMonitoring },
                                        set: { isOn in
                                            if isOn {
                                                apiService.startMonitoring()
                                            } else {
                                                apiService.stopMonitoring()
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .scaleEffect(1.2)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .neumorphic(cornerRadius: 16)
                                // Instant Catch button
                                Button(action: {
                                    apiService.instantCatch { password in
                                        if let password = password {
                                            tempPassword = password
                                            passcodeSetSuccess = true
                                        }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("Instant Catch")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.orange)
                                            .shadow(color: Color.white.opacity(0.9), radius: 4, x: -2, y: -2)
                                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 2, y: 2)
                                    )
                                }
                                .neumorphicCircle()
                            }
                        }
                        .padding(.vertical, 8)
                        .neumorphic()
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 20)
                    .padding(.top, 8)
                }
                .background(Color(.systemGray5).ignoresSafeArea())
                Spacer()
            }
            .navigationTitle("Secret Menu")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        tempLength = originalLength
                        tempPassword = ""
                        confirmPassword = ""
                        passwordError = ""
                        showSecretMenu = false
                    }
                    .foregroundColor(.blue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        passwordLength = tempLength
                        UserDefaults.standard.set(passwordLength, forKey: "passLength")
                        if !tempPassword.isEmpty {
                            UserDefaults.standard.set(tempPassword, forKey: "userPassword")
                        }
                        UserDefaults.standard.set(matchingModeEnabled, forKey: "matchingModeEnabled")
                        UserDefaults.standard.set(autoEmergencyModeEnabled, forKey: "autoEmergencyModeEnabled")
                        UserDefaults.standard.set(autoEmergencyDelay, forKey: "autoEmergencyDelay")
                        
                        // Save API settings
                        UserDefaults.standard.set(apiService.userID, forKey: "apiUserID")
                        UserDefaults.standard.set(apiService.isMonitoring, forKey: "autoMonitorEnabled")
                        
                        onSettingsChanged()
                        showSecretMenu = false
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .id("menu-\(tempLength)")
        .onAppear {
            originalLength = passwordLength
            originalLength = passwordLength
            tempLength = passwordLength
            
            // Загружаем сохранённые значения или используем значения по умолчанию
            if let savedPassword = UserDefaults.standard.string(forKey: "userPassword"), !savedPassword.isEmpty {
                tempPassword = savedPassword
            } else {
                tempPassword = ""
            }
            
            matchingModeEnabled = UserDefaults.standard.bool(forKey: "matchingModeEnabled")
            autoEmergencyModeEnabled = UserDefaults.standard.bool(forKey: "autoEmergencyModeEnabled")
            autoEmergencyDelay = UserDefaults.standard.double(forKey: "autoEmergencyDelay") == 0 ? 0.5 : UserDefaults.standard.double(forKey: "autoEmergencyDelay")
            
            // Load API settings
            apiService.userID = UserDefaults.standard.string(forKey: "apiUserID") ?? ""
            
            // Сброс индикации Emergency при открытии меню
            NotificationCenter.default.post(name: .resetEmergencyIndication, object: nil)
        }


        .sheet(isPresented: $showingPasswordInput) {
            PasswordInputView(
                tempLength: tempLength,
                tempPassword: $tempPassword,
                confirmPassword: $confirmPassword,
                passwordError: $passwordError,
                showingPasswordInput: $showingPasswordInput,
                passcodeSetSuccess: $passcodeSetSuccess
            )
        }
        .onDisappear {
            passcodeSetSuccess = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .passwordUpdatedFromAPI)) { notification in
            if let password = notification.object as? String {
                tempPassword = password
                passcodeSetSuccess = true
            }
        }
    }
    
    
}



struct PasswordInputView: View {
    let tempLength: Int
    @Binding var tempPassword: String
    @Binding var confirmPassword: String
    @Binding var passwordError: String
    @Binding var showingPasswordInput: Bool
    @Binding var passcodeSetSuccess: Bool
    
    @State private var isConfirming = false
    @State private var currentInput = ""
    
    let columns = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", ""]
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text(isConfirming ? "Confirm Passcode" : "Enter Passcode")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack(spacing: 22) {
                        ForEach(0..<tempLength, id: \.self) { index in
                            Circle()
                                .stroke(lineWidth: 1.5)
                                .frame(width: 12, height: 12)
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(index < currentInput.count ? .white : .clear)
                                        .frame(width: 12, height: 12)
                                )
                        }
                    }
                    .padding(.top, 16)
                    
                    if !passwordError.isEmpty {
                        Text(passwordError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
                
                Spacer(minLength: 52)
                
                VStack(spacing: 18) {
                    ForEach(columns, id: \.self) { row in
                        HStack(spacing: 18) {
                            ForEach(row, id: \.self) { item in
                                if item != "" {
                                    Button(action: {
                                        handleTap(item)
                                    }) {
                                        VStack(spacing: 1) {
                                            Text(item)
                                                .font(.system(size: 36, weight: .semibold))
                                                .foregroundColor(.white)
                                            if let letters = getLetters(for: item) {
                                                Text(letters)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                        .frame(width: 92, height: 92)
                                        .background(Color.white.opacity(0.15))
                                        .clipShape(Circle())
                                    }
                                } else {
                                    Spacer().frame(width: 80, height: 80)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 30)
                .padding(.bottom, 55)
                
                Spacer(minLength: 18)
                
                HStack {
                    Button("Cancel", action: {
                        showingPasswordInput = false
                    })
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Delete", action: {
                        if !currentInput.isEmpty {
                            currentInput.removeLast()
                        }
                    })
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 59)
                .padding(.bottom, 35)
            }
            .padding(.top, 100)
            .background(Color.black)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    func handleTap(_ value: String) {
        if currentInput.count < tempLength {
            currentInput.append(value)
            
            if currentInput.count == tempLength {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if isConfirming {
                        // Confirming password
                        if currentInput == tempPassword {
                            confirmPassword = currentInput
                            showingPasswordInput = false
                            passcodeSetSuccess = true
                        } else {
                            passwordError = "Passcodes don't match"
                            currentInput = ""
                        }
                    } else {
                        // First password entry
                        tempPassword = currentInput
                        isConfirming = true
                        currentInput = ""
                        passwordError = ""
                    }
                }
            }
        }
    }
    
    func getLetters(for digit: String) -> String? {
        switch digit {
        case "2": return "ABC"
        case "3": return "DEF"
        case "4": return "GHI"
        case "5": return "JKL"
        case "6": return "MNO"
        case "7": return "PQRS"
        case "8": return "TUV"
        case "9": return "WXYZ"
        default: return nil
        }
    }
}


