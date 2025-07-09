import SwiftUI

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