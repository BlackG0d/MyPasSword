import SwiftUI

struct ContentView: View {
    @State private var passcode: String = ""
    @State private var showingSettings = false
    @State private var passcodeLength: Int = 6
    @State private var unlockPasscode: String = ""
    @State private var selectedBackground = BackgroundOption.solid
    @State private var showingPasscodeAlert = false
    
    // Store previous settings
    @State private var previousPasscodeLength: Int = 6
    @State private var previousUnlockPasscode: String = ""
    @State private var previousBackground = BackgroundOption.solid
    
    enum BackgroundOption: String, CaseIterable {
        case solid = "Solid Color"
        case gradient = "Gradient"
        case image = "Image"
    }
    
    var backgroundView: some View {
        Group {
            switch selectedBackground {
            case .solid:
                Color.black
            case .gradient:
                LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom)
            case .image:
                Image(systemName: "photo.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(Color.black.opacity(0.3))
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    let numbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", ""]
    ]
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack(spacing: 20) {
                Spacer()
                
                Text("Enter Passcode")
                    .foregroundColor(.white)
                    .font(.title)
                
                HStack(spacing: 20) {
                    ForEach(0..<passcodeLength, id: \.self) { index in
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .fill(passcode.count > index ? Color.white : Color.clear)
                                    .frame(width: 15, height: 15)
                            )
                    }
                }
                .padding(.bottom, 30)
                .animation(.easeInOut, value: passcodeLength)
                
                Spacer()
                
                VStack(spacing: 15) {
                    ForEach(numbers, id: \.self) { row in
                        HStack(spacing: 30) {
                            ForEach(row, id: \.self) { number in
                                if !number.isEmpty {
                                    Button(action: {
                                        if passcode.count < passcodeLength {
                                            passcode += number
                                            
                                            if passcode.count == passcodeLength {
                                                if !unlockPasscode.isEmpty && passcode == unlockPasscode {
                                                    showingPasscodeAlert = true
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    passcode = ""
                                                }
                                            }
                                        }
                                    }) {
                                        if number == "9" {
                                            Text(number)
                                                .font(.title)
                                                .frame(width: 80, height: 80)
                                                .foregroundColor(.white)
                                                .background(
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.3))
                                                )
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 1)
                                                )
                                                .onLongPressGesture(minimumDuration: 3) {
                                                    // Store current settings before showing settings view
                                                    previousPasscodeLength = passcodeLength
                                                    previousUnlockPasscode = unlockPasscode
                                                    previousBackground = selectedBackground
                                                    showingSettings = true
                                                }
                                        } else {
                                            Text(number)
                                                .font(.title)
                                                .frame(width: 80, height: 80)
                                                .foregroundColor(.white)
                                                .background(
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.3))
                                                )
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 1)
                                                )
                                        }
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 80, height: 80)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    passcodeLength: $passcodeLength,
                    unlockPasscode: $unlockPasscode,
                    selectedBackground: $selectedBackground,
                    previousPasscodeLength: previousPasscodeLength,
                    previousUnlockPasscode: previousUnlockPasscode,
                    previousBackground: previousBackground
                )
            }
            .alert(isPresented: $showingPasscodeAlert) {
                Alert(
                    title: Text("Success!"),
                    message: Text("Correct passcode entered"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct SettingsView: View {
    @Binding var passcodeLength: Int
    @Binding var unlockPasscode: String
    @Binding var selectedBackground: ContentView.BackgroundOption
    @Environment(\.dismiss) var dismiss
    
    let previousPasscodeLength: Int
    let previousUnlockPasscode: String
    let previousBackground: ContentView.BackgroundOption
    
    @State private var tempPasscode: String = ""
    @State private var isSettingPasscode = false
    @State private var tempPasscodeLength: Int
    @State private var tempSelectedBackground: ContentView.BackgroundOption
    @State private var tempUnlockPasscode: String
    
    init(passcodeLength: Binding<Int>,
         unlockPasscode: Binding<String>,
         selectedBackground: Binding<ContentView.BackgroundOption>,
         previousPasscodeLength: Int,
         previousUnlockPasscode: String,
         previousBackground: ContentView.BackgroundOption) {
        _passcodeLength = passcodeLength
        _unlockPasscode = unlockPasscode
        _selectedBackground = selectedBackground
        self.previousPasscodeLength = previousPasscodeLength
        self.previousUnlockPasscode = previousUnlockPasscode
        self.previousBackground = previousBackground
        
        // Initialize temporary values
        _tempPasscodeLength = State(initialValue: passcodeLength.wrappedValue)
        _tempSelectedBackground = State(initialValue: selectedBackground.wrappedValue)
        _tempUnlockPasscode = State(initialValue: unlockPasscode.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Background")) {
                    Picker("Background Style", selection: $tempSelectedBackground) {
                        ForEach(ContentView.BackgroundOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
                
                Section(header: Text("Lock Screen Settings")) {
                    Picker("Number of Digits", selection: $tempPasscodeLength) {
                        Text("4 digits").tag(4)
                        Text("6 digits").tag(6)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: tempPasscodeLength) { newValue in
                        // Update the main passcode length immediately for preview
                        passcodeLength = newValue
                        // Clear existing passcode when length changes
                        tempPasscode = ""
                        tempUnlockPasscode = ""
                    }
                    
                    if !isSettingPasscode {
                        Button("Set Lock Screen Passcode") {
                            tempPasscode = ""
                            isSettingPasscode = true
                        }
                    }
                }
                
                if isSettingPasscode {
                    Section(header: Text("Enter New Passcode (\(tempPasscodeLength) digits)")) {
                        SecureField("Enter \(tempPasscodeLength) digits", text: $tempPasscode)
                            .keyboardType(.numberPad)
                            .onChange(of: tempPasscode) { newValue in
                                if newValue.count > tempPasscodeLength {
                                    tempPasscode = String(newValue.prefix(tempPasscodeLength))
                                }
                                
                                if newValue.count == tempPasscodeLength {
                                    tempUnlockPasscode = tempPasscode
                                    isSettingPasscode = false
                                }
                            }
                    }
                }
                
                if !tempUnlockPasscode.isEmpty {
                    Section {
                        Text("Current passcode: \(tempUnlockPasscode)")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(
                leading: Button("Cancel") {
                    // Restore previous settings
                    passcodeLength = previousPasscodeLength
                    unlockPasscode = previousUnlockPasscode
                    selectedBackground = previousBackground
                    dismiss()
                },
                trailing: Button("Save") {
                    // Apply temporary settings
                    unlockPasscode = tempUnlockPasscode
                    selectedBackground = tempSelectedBackground
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    ContentView()
} 