import SwiftUI

struct ContentView: View {
    @State private var passcode: String = ""
    @State private var showingContextMenu = false
    @State private var passcodeLength: Int = 6
    @State private var showingSettings = false
    
    let numbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", ""]
    ]
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                Text("Enter Passcode")
                    .foregroundColor(.white)
                    .font(.title)
                
                HStack(spacing: 20) {
                    ForEach(0..<passcodeLength) { index in
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
                
                Spacer()
                
                VStack(spacing: 15) {
                    ForEach(numbers, id: \.self) { row in
                        HStack(spacing: 30) {
                            ForEach(row, id: \.self) { number in
                                if !number.isEmpty {
                                    Button(action: {
                                        if passcode.count < passcodeLength {
                                            passcode += number
                                        }
                                    }) {
                                        if number == "9" {
                                            Text(number)
                                                .font(.title)
                                                .frame(width: 80, height: 80)
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.gray.opacity(0.3)))
                                                .onLongPressGesture(minimumDuration: 3) {
                                                    showingSettings = true
                                                }
                                        } else {
                                            Text(number)
                                                .font(.title)
                                                .frame(width: 80, height: 80)
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.gray.opacity(0.3)))
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
                SettingsView(passcodeLength: $passcodeLength)
            }
        }
    }
}

struct SettingsView: View {
    @Binding var passcodeLength: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Passcode Settings")) {
                    Picker("Passcode Length", selection: $passcodeLength) {
                        Text("4 digits").tag(4)
                        Text("6 digits").tag(6)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
} 