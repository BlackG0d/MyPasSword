import SwiftUI

struct LockScreenInterfaceView: View {
    @Binding var enteredDigits: [String]
    @Binding var showDigits: Bool
    @Binding var showLastFourDigits: Bool
    @Binding var lastFourDigitsToShow: [String]
    @Binding var animatingButton: String?
    @Binding var showEmergencyIndication: Bool
    @Binding var shake: Bool
    
    let passwordLength: Int
    let columns: [[String]]
    let onButtonTap: (String) -> Void
    let onEmergencyTap: () -> Void
    let onCancelTap: () -> Void
    let onEmergencyLongPress: () -> Void
    let onCancelLongPress: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Фиксированный отступ сверху
                Spacer(minLength: 110)
                
                // Надпись "Enter Passcode" - фиксированная позиция
                Text("Enter Passcode")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                
                // Кружки индикаторы - фиксированная позиция
                HStack(spacing: 22) {
                    ForEach(0..<passwordLength, id: \.self) { index in
                        if showDigits && index < enteredDigits.count {
                            Text(enteredDigits[index])
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 12, height: 12)
                        } else if showLastFourDigits && index < lastFourDigitsToShow.count {
                            Text(lastFourDigitsToShow[index])
                                .font(.title3)
                                .foregroundColor(.red)
                                .frame(width: 12, height: 12)
                        } else {
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                                .frame(width: 12, height: 12)
                                .background(
                                    Circle()
                                        .fill(index < enteredDigits.count ? Color.white : Color.clear)
                                        .frame(width: 16, height: 16)
                                )
                        }
                    }
                }
                .padding(.top, 24)
                .modifier(ShakeEffect(travelDistance: 30, shakesPerUnit: 2, animatableData: CGFloat(shake ? 1 : 0)))
                .animation(.easeInOut(duration: 0.2), value: shake)
                
                // Фиксированный отступ между кружками и numpad
                Spacer(minLength: 65)
                
                // Numpad - фиксированная позиция
                VStack(spacing: 18) {
                    ForEach(columns, id: \.self) { row in
                        HStack(spacing: 18) {
                            ForEach(row, id: \.self) { item in
                                if item != "" {
                                    Button(action: {
                                        onButtonTap(item)
                                    }) {
                                        VStack(spacing: 1) {
                                            Text(item)
                                                .font(.system(size: 42, weight: .medium))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                                            
                                            if let letters = getLetters(for: item) {
                                                Text(letters)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                                            }
                                        }
                                        .frame(width: 88, height: 88)
                                        .background(
                                            animatingButton == item ? 
                                                Color.white.opacity(0.9) : // Очень яркий белый при нажатии
                                                Color.white.opacity(0.15) // Полупрозрачный белый фон для круглых кнопок
                                        )
                                        .clipShape(Circle())
                                        .shadow(
                                            color: .black.opacity(0.3),
                                            radius: 3,
                                            x: 0,
                                            y: 2
                                        )
                                        .scaleEffect(animatingButton == item ? 0.98 : 1.0) // Очень легкое масштабирование
                                        .animation(.easeInOut(duration: 0.15), value: animatingButton == item)
                                    }
                                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.1).onChanged { _ in
                                        // При удержании кнопки
                                        animatingButton = item
                                    }.onEnded { _ in
                                        // При окончании удержания
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            animatingButton = nil
                                        }
                                    })
                                    .simultaneousGesture(LongPressGesture(minimumDuration: 1.5).onEnded { _ in
                                        if item == "9" {
                                            // Убрано открытие меню с цифры 9
                                        }
                                    })
                                } else {
                                    Spacer().frame(width: 80, height: 80)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 30)
                .padding(.bottom, 50)
                
                // Фиксированный отступ между numpad и кнопками
                Spacer(minLength: 5)
                
                // Кнопки Emergency и Cancel - фиксированная позиция
                HStack(spacing: 0) {
                    // Emergency кнопка - фиксированная позиция слева
                    Button(showEmergencyIndication ? "Em\u{00EA}rgency" : "Emergency", action: {
                        onEmergencyTap()
                    })
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                        onEmergencyLongPress()
                    })
                    .simultaneousGesture(LongPressGesture(minimumDuration: 2.0).onEnded { _ in
                        // Альтернативный способ для тестирования в симуляторе
                        print("Long press Emergency - showing hidden digits")
                        onEmergencyLongPress()
                    })
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 75)
                    
                    // Cancel кнопка - фиксированная позиция справа
                    Button("Cancel", action: {
                        onCancelTap()
                    })
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .simultaneousGesture(LongPressGesture(minimumDuration: 1.5).onEnded { _ in
                        onCancelLongPress()
                    })
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 75)
                }
                .padding(.bottom, 45)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 8)
        }
    }
    
    // Вспомогательная функция для получения букв
    private func getLetters(for digit: String) -> String? {
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