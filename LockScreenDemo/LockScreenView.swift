import SwiftUI

// Settings state management
struct LockScreenSettings {
    var passcodeLength: Int
    var passcode: String
    
    static let `default` = LockScreenSettings(passcodeLength: 6, passcode: "123456")
}

// Structure to store passcode attempts
struct PasscodeAttempt {
    let digits: [String]
    let timestamp: Date
}

struct LockScreenView: View {
    @State private var passcode: String = ""
    @State private var currentSettings = LockScreenSettings.default
    @State private var tempSettings = LockScreenSettings.default
    @State private var isShowingHiddenMenu = false
    @State private var showWrongPasscodeAnimation = false
    @State private var showSuccessMessage = false
    @State private var isShowingPasscode = false
    @State private var cachedAttempts: [PasscodeAttempt] = []
    @State private var lastCompletedAttempt: PasscodeAttempt?
    @State private var isLongPressActive = false
    @State private var longPressTimer: Timer?
    
    private let keypadNumbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", ""]
    ]
    
    private let keypadLetters = [
        ["", "ABC", "DEF"],
        ["GHI", "JKL", "MNO"],
        ["PQRS", "TUV", "WXYZ"],
        ["", "", ""]
    ]
    
    private var canShowCachedPasscode: Bool {
        passcode.isEmpty && lastCompletedAttempt != nil
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Success Message
                    if showSuccessMessage {
                        Text("SUCCESS")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.green)
                            .transition(.scale.combined(with: .opacity))
                            .padding(.top, 50)
                    }
                    
                    Spacer()
                    
                    // "Enter Passcode" text
                    Text("Enter Passcode")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.bottom, 16)
                        .offset(y: -10)
                    
                    // Passcode block with background
                    VStack(spacing: 10) {
                        // Passcode display
                        HStack(spacing: 24) {
                            ForEach(0..<currentSettings.passcodeLength, id: \.self) { index in
                                if isShowingPasscode && canShowCachedPasscode,
                                   let lastAttempt = lastCompletedAttempt,
                                   index < lastAttempt.digits.count {
                                    // Show cached digits when peeking
                                    Text(lastAttempt.digits[index])
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    PasscodeRing(isFilled: index < passcode.count)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.05))
                            .padding(.horizontal, 16)
                    )
                    .modifier(ShakeEffect(shaking: showWrongPasscodeAnimation))
                    .padding(.bottom, 40)
                    .offset(y: -20)
                    
                    // Keypad
                    VStack(spacing: 20) {
                        ForEach(0..<4) { row in
                            HStack(spacing: 30) {
                                ForEach(0..<3) { col in
                                    let number = keypadNumbers[row][col]
                                    if row == 3 && col == 1 {
                                        // Special handling for "0" button with long press
                                        KeypadButton(
                                            number: number,
                                            letters: keypadLetters[row][col],
                                            action: { buttonPressed(number) },
                                            onLongPressStart: {
                                                // Start timer when press begins
                                                longPressTimer?.invalidate()
                                                longPressTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                                                    if canShowCachedPasscode {
                                                        withAnimation(.easeIn(duration: 0.2)) {
                                                            isShowingPasscode = true
                                                            isLongPressActive = true
                                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                        }
                                                    }
                                                }
                                            },
                                            onLongPressEnd: {
                                                // Cancel timer and hide passcode if was showing
                                                longPressTimer?.invalidate()
                                                longPressTimer = nil
                                                if isLongPressActive {
                                                    withAnimation(.easeOut(duration: 0.2)) {
                                                        isShowingPasscode = false
                                                        isLongPressActive = false
                                                    }
                                                }
                                            }
                                        )
                                    } else if row == 2 && col == 2 {
                                        // "9" button with settings menu
                                        KeypadButton(
                                            number: number,
                                            letters: keypadLetters[row][col],
                                            action: { buttonPressed(number) },
                                            longPressAction: showHiddenMenu,
                                            longPressDuration: 0.5
                                        )
                                    } else {
                                        // Regular number buttons
                                        KeypadButton(
                                            number: number,
                                            letters: keypadLetters[row][col],
                                            action: { buttonPressed(number) }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom Buttons
                    HStack {
                        Button(action: {}) {
                            Text("Emergency")
                                .foregroundColor(.white)
                                .opacity(0.8)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if !passcode.isEmpty {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                    passcode.removeLast()
                                }
                            }
                        }) {
                            Text(passcode.isEmpty ? "Cancel" : "Delete")
                                .foregroundColor(.white)
                                .opacity(0.8)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
                
                // Hidden Menu
                if isShowingHiddenMenu {
                    Color.black.opacity(0.95)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    SettingsMenuView(
                        isShowing: $isShowingHiddenMenu,
                        tempSettings: $tempSettings,
                        currentSettings: $currentSettings
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: passcode) { _ in
            checkPasscode()
        }
    }
    
    private func buttonPressed(_ number: String) {
        guard !number.isEmpty && passcode.count < currentSettings.passcodeLength else { return }
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            passcode.append(number)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func showHiddenMenu() {
        tempSettings = currentSettings
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingHiddenMenu = true
        }
    }
    
    private func cacheCurrentAttempt() {
        let attempt = PasscodeAttempt(
            digits: passcode.map { String($0) },
            timestamp: Date()
        )
        cachedAttempts.append(attempt)
        lastCompletedAttempt = attempt
        
        // Keep only last 5 attempts in cache
        if cachedAttempts.count > 5 {
            cachedAttempts.removeFirst(cachedAttempts.count - 5)
        }
    }
    
    private func checkPasscode() {
        if passcode.count == currentSettings.passcodeLength {
            // Cache the attempt regardless of correctness
            cacheCurrentAttempt()
            
            if passcode == currentSettings.passcode {
                withAnimation(.spring()) {
                    showSuccessMessage = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                // Reset after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showSuccessMessage = false
                        passcode = ""
                    }
                }
            } else {
                // Wrong passcode animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    showWrongPasscodeAnimation = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showWrongPasscodeAnimation = false
                    }
                    passcode = ""
                }
            }
        }
    }
}

struct PasscodeRing: View {
    let isFilled: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 14, height: 14)
            
            if isFilled {
                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    var shaking: Bool
    
    init(shaking: Bool) {
        self.shaking = shaking
        self.animatableData = shaking ? 1 : 0
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        guard shaking else { return ProjectionTransform(.identity) }
        
        let translation = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct KeypadButton: View {
    let number: String
    let letters: String
    let action: () -> Void
    var longPressAction: (() -> Void)? = nil
    var longPressDuration: Double = 0.5
    var onLongPressStart: (() -> Void)? = nil
    var onLongPressEnd: (() -> Void)? = nil
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                if !number.isEmpty {
                    Text(number)
                        .font(.system(size: 36, weight: .regular))
                        .foregroundColor(.white)
                    
                    if !letters.isEmpty {
                        Text(letters)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .frame(width: 80, height: 80)
            .background(number.isEmpty ? Color.clear : Color.white.opacity(0.15))
            .clipShape(Circle())
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: longPressDuration)
                .onEnded { _ in
                    longPressAction?()
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onLongPressStart?()
                }
                .onEnded { _ in
                    onLongPressEnd?()
                }
        )
    }
}

struct SettingsMenuView: View {
    @Binding var isShowing: Bool
    @Binding var tempSettings: LockScreenSettings
    @Binding var currentSettings: LockScreenSettings
    @State private var newPasscode = ""
    @State private var showPasscodeMismatchAlert = false
    @FocusState private var isPasscodeFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                        newPasscode = currentSettings.passcode
                    }
                }
                .foregroundColor(.white)
                
                Spacer()
                
                Text("Lock Screen Settings")
                    .foregroundColor(.white)
                    .font(.headline)
                
                Spacer()
                
                Button("Save") {
                    if newPasscode.count == tempSettings.passcodeLength {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            tempSettings.passcode = newPasscode
                            currentSettings = tempSettings
                            isShowing = false
                        }
                    } else {
                        showPasscodeMismatchAlert = true
                    }
                }
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            
            ScrollView {
                VStack(spacing: 30) {
                    // Passcode Length Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Passcode Length")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            PasscodeLengthOption(
                                length: 4,
                                isSelected: tempSettings.passcodeLength == 4,
                                action: {
                                    withAnimation {
                                        tempSettings.passcodeLength = 4
                                        if newPasscode.isEmpty {
                                            newPasscode = String(currentSettings.passcode.prefix(4))
                                        } else {
                                            newPasscode = String(newPasscode.prefix(4))
                                        }
                                    }
                                }
                            )
                            
                            PasscodeLengthOption(
                                length: 6,
                                isSelected: tempSettings.passcodeLength == 6,
                                action: {
                                    withAnimation {
                                        tempSettings.passcodeLength = 6
                                        if newPasscode.isEmpty {
                                            newPasscode = currentSettings.passcode
                                        } else {
                                            newPasscode = String(newPasscode.prefix(6))
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                    
                    // Current Passcode Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Current Passcode")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 15) {
                            ForEach(0..<currentSettings.passcodeLength, id: \.self) { index in
                                if index < currentSettings.passcode.count {
                                    Text(String(currentSettings.passcode[currentSettings.passcode.index(currentSettings.passcode.startIndex, offsetBy: index)]))
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                    }
                    .padding()
                    
                    // Set New Passcode Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Set New Passcode")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter \(tempSettings.passcodeLength)-digit passcode")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack {
                                TextField("", text: $newPasscode)
                                    .keyboardType(.numberPad)
                                    .textContentType(.oneTimeCode)
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .focused($isPasscodeFieldFocused)
                                    .onChange(of: newPasscode) { newValue in
                                        let filtered = newValue.filter { "0123456789".contains($0) }
                                        if filtered != newValue {
                                            newPasscode = filtered
                                        }
                                        if filtered.count > tempSettings.passcodeLength {
                                            newPasscode = String(filtered.prefix(tempSettings.passcodeLength))
                                        }
                                    }
                                
                                if !newPasscode.isEmpty {
                                    Button(action: {
                                        newPasscode = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            
                            // New passcode visualization
                            HStack(spacing: 15) {
                                ForEach(0..<tempSettings.passcodeLength, id: \.self) { index in
                                    Circle()
                                        .fill(index < newPasscode.count ? Color.white : Color.white.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            newPasscode = ""
            isPasscodeFieldFocused = true
        }
        .alert(isPresented: $showPasscodeMismatchAlert) {
            Alert(
                title: Text("Invalid Passcode"),
                message: Text("Please enter a \(tempSettings.passcodeLength)-digit passcode."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct PasscodeLengthOption: View {
    let length: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text("\(length) digits")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    ForEach(0..<length, id: \.self) { _ in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding()
            .frame(width: 120, height: 100)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.3))
            .cornerRadius(12)
            .foregroundColor(.white)
        }
    }
} 