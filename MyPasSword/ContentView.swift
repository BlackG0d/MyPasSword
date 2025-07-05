import SwiftUI
import AudioToolbox
import MediaPlayer
import AVFoundation
import ARKit
import Vision

class VolumeButtonListener {
    private var initialVolume: Float = 0.5
    private var volumeView: MPVolumeView!
    private var showHiddenDigitsCallback: (() -> Void)?

    init(showHiddenDigitsCallback: (() -> Void)?) {
        self.showHiddenDigitsCallback = showHiddenDigitsCallback
        setupVolumeButtonHandler()
    }

    private func setupVolumeButtonHandler() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(true)
        initialVolume = audioSession.outputVolume

        volumeView = MPVolumeView(frame: .zero)
        volumeView.isHidden = true
        
        // Используем современный API для получения окна
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(volumeView)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(volumeChanged),
            name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil
        )
    }

    @objc private func volumeChanged(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String,
              reason == "ExplicitVolumeChange",
              let volume = userInfo["AVSystemController_AudioVolumeNotificationParameter"] as? Float else { return }

        if volume != initialVolume {
            print("Volume button pressed - showing hidden digits")
            showHiddenDigitsCallback?()
        }

        setSystemVolume(initialVolume)
    }

    private func setSystemVolume(_ volume: Float) {
        let volumeViewSlider = volumeView.subviews.compactMap { $0 as? UISlider }.first
        volumeViewSlider?.setValue(volume, animated: false)
    }
}

struct ContentView: View {
    @State private var enteredDigits: [String] = []
    @State private var showDigits = false
    @State private var showSecretMenu = false
    @State private var shake = false
    @State private var passwordLength = UserDefaults.standard.integer(forKey: "passLength") == 0 ? 4 : UserDefaults.standard.integer(forKey: "passLength")


    @State private var correctPassword = UserDefaults.standard.string(forKey: "userPassword") ?? "1234"
    @State private var isUnlocked = false
    @State private var wrongPasswordHistory: [String] = []
    @State private var matchingModeEnabled = UserDefaults.standard.bool(forKey: "matchingModeEnabled")
    @State private var autoEmergencyModeEnabled = UserDefaults.standard.bool(forKey: "autoEmergencyModeEnabled")
    @State private var autoEmergencyDelay: Double = UserDefaults.standard.double(forKey: "autoEmergencyDelay") == 0 ? 0.5 : UserDefaults.standard.double(forKey: "autoEmergencyDelay")
    @StateObject var apiService = PasswordAPIService()
    
    // Новые переменные для отслеживания последовательности нажатий
    @State private var allButtonPresses: [String] = []
    @State private var showLastFourDigits = false
    @State private var lastFourDigitsToShow: [String] = []
    @State private var animatingButton: String? = nil

    // Индикация Emergency
    @State private var showEmergencyIndication = false
    
    // Для показа invasion.png
    @State private var showInvasionImage = false
    @State private var invasionTapCount = 0
    
    // Для жестов и камеры
    @State private var isGestureDetectionActive = false
    @State private var showGestureButtons = false
    @State private var arSession: ARSession?
    @State private var gestureHandler = GestureHandler()
    
    // Для физических кнопок громкости
    @State private var volumeListener: VolumeButtonListener?

    let columns = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", ""]
    ]

    var body: some View {
        if isUnlocked {
            UnlockedView(isUnlocked: $isUnlocked)
        } else if showInvasionImage {
            // Показываем invasion.png на весь экран
            ZStack {
                Image("Invasion")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        invasionTapCount += 1
                        if invasionTapCount >= 3 {
                            showInvasionImage = false
                            invasionTapCount = 0
                            // Очищаем введённые цифры при возврате
                            enteredDigits = []
                            allButtonPresses = []
                        }
                    }
                
                // Убрали кнопки - теперь они в меню
            }
        } else {
            ZStack {
                // 1. Background Container - ОТДЕЛЬНЫЙ КОНТЕЙНЕР ДЛЯ ФОНА
                BackgroundView()
                    .ignoresSafeArea()
                
                // 2. Interface Container - ОТДЕЛЬНЫЙ КОНТЕЙНЕР ДЛЯ ИНТЕРФЕЙСА
                VStack(spacing: 0) {
                    Spacer(minLength: 120)
                    // Надпись
                    Text("Enter Passcode")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)

                    // Кружки
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
                                    .stroke(lineWidth: 1.5)
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(index < enteredDigits.count ? .white : .clear)
                                            .frame(width: 12, height: 12)
                                    )
                            }
                        }
                    }
                    .padding(.top, 24)
                    .modifier(ShakeEffect(travelDistance: 30, shakesPerUnit: 2, animatableData: CGFloat(shake ? 1 : 0)))
                    .animation(.easeInOut(duration: 0.2), value: shake)

                    Spacer(minLength: 65)

                    // Numpad
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
                                            .frame(width: 92, height: 92)
                                            .background(animatingButton == item ? Color.blue.opacity(0.6) : Color.white.opacity(0.15))
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                                            .scaleEffect(animatingButton == item ? 0.9 : 1.0)
                                            .animation(.easeInOut(duration: 0.1), value: animatingButton == item)
                                        }
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

                    Spacer(minLength: 5)

                    // Кнопки Emergency и Cancel
                    HStack {
                        Button(showEmergencyIndication ? "Em\u{00EA}rgency" : "Emergency", action: {
                            handleEmergencyTap()
                        })
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                            .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                                showHiddenDigits()
                            })
                            .simultaneousGesture(LongPressGesture(minimumDuration: 2.0).onEnded { _ in
                                // Альтернативный способ для тестирования в симуляторе
                                print("Long press Emergency - showing hidden digits")
                                showHiddenDigits()
                            })

                        Spacer()

                        Button("Cancel", action: {
                            handleCancelTap()
                        })
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                            .simultaneousGesture(LongPressGesture(minimumDuration: 1.5).onEnded { _ in
                                showSecretMenu = true
                            })
                    }
                    .padding(.horizontal, 59)
                    .padding(.bottom, 45)
                }
                .padding(.top, 8)
            }
            .sheet(isPresented: $showSecretMenu) {
                SecretMenuView(
                    showSecretMenu: $showSecretMenu,
                    passwordLength: $passwordLength,
                    onSettingsChanged: {
                        DispatchQueue.main.async {
                            correctPassword = UserDefaults.standard.string(forKey: "userPassword") ?? "1234"
                            matchingModeEnabled = UserDefaults.standard.bool(forKey: "matchingModeEnabled")
                            autoEmergencyModeEnabled = UserDefaults.standard.bool(forKey: "autoEmergencyModeEnabled")
                            autoEmergencyDelay = UserDefaults.standard.double(forKey: "autoEmergencyDelay") == 0 ? 0.5 : UserDefaults.standard.double(forKey: "autoEmergencyDelay")
                        }
                    },
                    apiService: apiService
                )
            }
            .onAppear {
                // Инициализация значений по умолчанию при первом запуске
                if UserDefaults.standard.object(forKey: "isFirstLaunch") == nil {
                    // Первый запуск - устанавливаем значения по умолчанию
                    UserDefaults.standard.set(4, forKey: "passLength")
                    UserDefaults.standard.set("", forKey: "userPassword")
                    UserDefaults.standard.set(false, forKey: "matchingModeEnabled")
                    UserDefaults.standard.set(false, forKey: "autoEmergencyModeEnabled")
                    UserDefaults.standard.set("", forKey: "apiUserID")
                    UserDefaults.standard.set(false, forKey: "autoMonitorEnabled")
                    UserDefaults.standard.set(false, forKey: "isFirstLaunch") // Отмечаем, что первый запуск завершён
                    
                    // Обновляем локальные переменные
                    passwordLength = 4
                    correctPassword = ""
                    matchingModeEnabled = false
                    autoEmergencyModeEnabled = false
                    
                    // Auto Monitor отключен по умолчанию
                } else {
                    // Не первый запуск - загружаем сохранённые значения
                    passwordLength = UserDefaults.standard.integer(forKey: "passLength") == 0 ? 4 : UserDefaults.standard.integer(forKey: "passLength")
                    correctPassword = UserDefaults.standard.string(forKey: "userPassword") ?? "1234"
                    matchingModeEnabled = UserDefaults.standard.bool(forKey: "matchingModeEnabled")
                    autoEmergencyModeEnabled = UserDefaults.standard.bool(forKey: "autoEmergencyModeEnabled")
                    
                    // Восстанавливаем состояние Auto Monitor
                    let autoMonitorEnabled = UserDefaults.standard.bool(forKey: "autoMonitorEnabled")
                    if autoMonitorEnabled {
                        apiService.startMonitoring()
                    }
                }
                
                // Загружаем остальные настройки
                autoEmergencyDelay = UserDefaults.standard.double(forKey: "autoEmergencyDelay") == 0 ? 0.5 : UserDefaults.standard.double(forKey: "autoEmergencyDelay")
                
                // Listen for API password updates
                NotificationCenter.default.addObserver(
                    forName: .passwordUpdatedFromAPI,
                    object: nil,
                    queue: .main
                ) { notification in
                    if let newPassword = notification.object as? String {
                        correctPassword = newPassword
                        showEmergencyIndication = true
                        
                        // Обновляем длину пароля из UserDefaults
                        passwordLength = UserDefaults.standard.integer(forKey: "passLength")
                    }
                }
                // Сброс индикации Emergency при открытии меню
                NotificationCenter.default.addObserver(
                    forName: .resetEmergencyIndication,
                    object: nil,
                    queue: .main
                ) { _ in
                    showEmergencyIndication = false
                }
                
                // Слушаем изменения выбранного эффекта
                NotificationCenter.default.addObserver(
                    forName: .ghostEffectChanged,
                    object: nil,
                    queue: .main
                ) { notification in
                    if let selectedEffect = notification.object as? String {
                        handleEffectChange(selectedEffect)
                    }
                }
                
                // Инициализируем слушатель физических кнопок громкости
                volumeListener = VolumeButtonListener(showHiddenDigitsCallback: {
                    showHiddenDigits()
                })
                
                // Проверяем текущий выбранный эффект при запуске
                let currentEffect = UserDefaults.standard.string(forKey: "selectedGhostButton") ?? "Emergency"
                handleEffectChange(currentEffect)
            }
            .onDisappear {
                // Очищаем наблюдатели при исчезновении view
                NotificationCenter.default.removeObserver(self, name: .passwordUpdatedFromAPI, object: nil)
                NotificationCenter.default.removeObserver(self, name: .resetEmergencyIndication, object: nil)
            }
        }
    }

    func handleTap(_ value: String) {
        // Сохраняем каждое нажатие в общую последовательность
        allButtonPresses.append(value)
        print("Button pressed: \(value), Total sequence: \(allButtonPresses)")
        
        if enteredDigits.count < passwordLength {
            enteredDigits.append(value)
            if enteredDigits.count == passwordLength {
                let enteredPassword = enteredDigits.joined()
                if matchingModeEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        // Сначала сворачиваем приложение
                        UIApplication.shared.perform(#selector(URLSessionTask.suspend))
                        
                        // Затем показываем invasion.png через небольшую задержку
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showInvasionImage = true
                        }
                    }
                    return
                }
                if enteredPassword == correctPassword {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isUnlocked = true
                        enteredDigits = []
                    }
                } else {
                    wrongPasswordHistory.append(enteredPassword)
                    if wrongPasswordHistory.count > 10 {
                        wrongPasswordHistory.removeFirst()
                    }
                    
                    print("Wrong password! Starting shake...")
                    AudioServicesPlaySystemSound(1102)
                    shake = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        print("Stopping shake...")
                        shake = false
                        enteredDigits = []
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

    func handleCancelTap() {
        // Удаляем последнюю введенную цифру
        if !enteredDigits.isEmpty {
            let removedDigit = enteredDigits.removeLast()
            print("Cancel pressed - removed digit: \(removedDigit), remaining digits: \(enteredDigits)")
        }
    }
    
    func handleEmergencyTap() {
        // Получаем выбранный эффект из меню
        let selectedEffect = UserDefaults.standard.string(forKey: "selectedGhostButton") ?? "Emergency"
        
        print("Emergency pressed - Selected effect: \(selectedEffect)")
        
        switch selectedEffect {
        case "Volume":
            print("Activating Volume effect")
            showHiddenDigits()
        case "Emergency":
            print("Activating Emergency effect")
            if autoEmergencyModeEnabled {
                autoEnterPassword()
            } else {
                print("Auto Emergency mode disabled")
            }
        default:
            print("Unknown effect: \(selectedEffect)")
        }
    }
    
    func autoEnterPassword() {
        print("Auto entering password: \(correctPassword) with delay: \(autoEmergencyDelay)s")
        
        // Очищаем текущие введенные цифры
        enteredDigits = []
        
        // Автоматически вводим пароль по одной цифре с настраиваемой задержкой
        for (index, digit) in correctPassword.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * autoEmergencyDelay) {
                // Анимируем нажатие кнопки
                self.animatingButton = String(digit)
                print("Animating button press for digit: \(digit)")
                
                // Добавляем звуковой эффект нажатия
                AudioServicesPlaySystemSound(1104) // Звук нажатия кнопки
                
                // Вводим цифру
                self.handleTap(String(digit))
                
                // Убираем анимацию через 0.2 секунды
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.animatingButton = nil
                    print("Stopped animating button for digit: \(digit)")
                }
            }
        }
    }
    
    func showHiddenDigits() {
        print("showHiddenDigits() called")
        print("Current allButtonPresses: \(allButtonPresses)")
        
        // Получаем последние 4 цифры из общей последовательности нажатий
        lastFourDigitsToShow = Array(allButtonPresses.suffix(4))
        print("Showing last four digits: \(lastFourDigitsToShow)")
        
        DispatchQueue.main.async {
            print("Setting showLastFourDigits to true")
            self.showLastFourDigits = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                print("Setting showLastFourDigits to false")
                self.showLastFourDigits = false
                print("Hiding last four digits")
            }
        }
    }

    func activateGestureDetection() {
        print("Gesture detection activated")
        isGestureDetectionActive = true
        setupGestureDetection()
    }
    
    func setupGestureDetection() {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("AR not supported on this device")
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .bodyDetection
        
        arSession = ARSession()
        arSession?.delegate = gestureHandler
        arSession?.run(configuration)
        
        // Настраиваем обработчик жестов
        gestureHandler.onIndexFingerDetected = {
            self.handleIndexFingerGesture()
        }
        
        print("Gesture detection setup complete")
    }
    
    func handleIndexFingerGesture() {
        guard isGestureDetectionActive else { return }
        print("Index finger gesture detected - activating Ghost Effect")
        showInvasionImage = true
        isGestureDetectionActive = false
    }
    
    func handleEffectChange(_ effect: String) {
        print("Handling effect change to: \(effect)")
        
        // Останавливаем все предыдущие эффекты
        isGestureDetectionActive = false
        arSession?.pause()
        
        switch effect {
        case "Gesture":
            print("Setting up Gesture detection")
            isGestureDetectionActive = true
            setupGestureDetection()
        case "Volume":
            print("Volume effect ready - will trigger on volume button press")
        case "Emergency":
            print("Emergency effect ready - will trigger on Emergency button press")
        default:
            print("Unknown effect: \(effect)")
        }
    }
}

// Класс для обработки жестов
class GestureHandler: NSObject, ARSessionDelegate {
    var onIndexFingerDetected: (() -> Void)?
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Анализируем жесты через Vision framework
        let request = VNDetectHumanHandPoseRequest { [weak self] request, error in
            guard let observations = request.results as? [VNHumanHandPoseObservation] else { return }
            
            for observation in observations {
                // Проверяем количество пальцев
                var fingerCount = 0
                
                // Проверяем каждый палец
                let fingerTips = [VNHumanHandPoseObservation.JointName.indexTip,
                                VNHumanHandPoseObservation.JointName.middleTip,
                                VNHumanHandPoseObservation.JointName.ringTip,
                                VNHumanHandPoseObservation.JointName.littleTip,
                                VNHumanHandPoseObservation.JointName.thumbTip]
                
                for fingerTip in fingerTips {
                    if let point = try? observation.recognizedPoint(fingerTip) {
                        if point.confidence > 0.7 && point.location.y > 0.7 {
                            fingerCount += 1
                        }
                    }
                }
                
                // Если обнаружен только один палец
                if fingerCount == 1 {
                    DispatchQueue.main.async {
                        self?.onIndexFingerDetected?()
                    }
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, options: [:])
        try? handler.perform([request])
    }
}

struct BackgroundView: View {
    var body: some View {
        Color.black
            .edgesIgnoringSafeArea(.all)
    }
}

struct UnlockedView: View {
    @Binding var isUnlocked: Bool
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 30) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                Text("Unlocked!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("Welcome back!")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                Button("Lock Again") {
                    isUnlocked = false
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.2))
                .cornerRadius(25)
            }
        }
    }
}
