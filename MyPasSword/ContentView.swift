import SwiftUI
import AudioToolbox
import MediaPlayer
import AVFoundation
import ARKit
import Vision

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
    @StateObject var backgroundManager = BackgroundManager()
    @StateObject var alibiManager = AlibiManager()
    
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
    @State private var gestureHandler = GestureHandler()
    
    // Для физических кнопок громкости
    @StateObject private var physicalButtonManager = PhysicalButtonManager()

    @State private var skipUnlockScreen = false
    
    // Переменные для тройного нажатия Cancel
    @State private var cancelTapCount = 0
    @State private var lastCancelTapTime: Date?
    @State private var volumeObserver: NSKeyValueObservation?
    @State private var volumeView: MPVolumeView? = nil
    @State private var isSettingVolume = false

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
            // Показываем Alibi-фотографию или дефолтную картинку
            ZStack {
                if let alibiImage = alibiManager.selectedImage {
                    Image(uiImage: alibiImage)
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
                } else {
                    Image("Alibi")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            invasionTapCount += 1
                            if invasionTapCount >= 3 {
                                showInvasionImage = false
                                invasionTapCount = 0
                                enteredDigits = []
                                allButtonPresses = []
                            }
                        }
                }
                // Убрали кнопки - теперь они в меню
            }
        } else {
            ZStack {
                // 1. Background Container - ОТДЕЛЬНЫЙ КОНТЕЙНЕР ДЛЯ ФОНА
                BackgroundView(backgroundManager: backgroundManager)
                    .ignoresSafeArea()
                
                // 2. Interface Container - ОТДЕЛЬНЫЙ КОНТЕЙНЕР ДЛЯ ИНТЕРФЕЙСА
                LockScreenInterfaceView(
                    enteredDigits: $enteredDigits,
                    showDigits: $showDigits,
                    showLastFourDigits: $showLastFourDigits,
                    lastFourDigitsToShow: $lastFourDigitsToShow,
                    animatingButton: $animatingButton,
                    showEmergencyIndication: $showEmergencyIndication,
                    shake: $shake,
                    passwordLength: passwordLength,
                    columns: columns,
                    onButtonTap: { item in
                        handleTap(item)
                    },
                    onEmergencyTap: {
                        handleEmergencyTap()
                    },
                    onCancelTap: {
                        handleCancelTap()
                    },
                    onEmergencyLongPress: {
                        showHiddenDigits()
                    },
                    onCancelLongPress: {
                        showSecretMenu = true
                    }
                )
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
                    apiService: apiService,
                    backgroundManager: backgroundManager,
                    alibiManager: alibiManager
                )
            }
            .onAppear {
                // Предотвращаем засыпание экрана
                UIApplication.shared.isIdleTimerDisabled = true
                
                // Восстанавливаем состояние при возвращении из фона
                NotificationCenter.default.addObserver(
                    forName: UIApplication.willEnterForegroundNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    print("App returning from background - restoring state")
                    self.restoreAppState()
                }
                
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
                physicalButtonManager.setupVolumeButtonListener(callback: {
                    UIApplication.shared.perform(#selector(URLSessionTask.suspend))
                })
                
                // Проверяем текущий выбранный эффект при запуске
                let currentEffect = UserDefaults.standard.string(forKey: "selectedGhostButton") ?? "Emergency"
                handleEffectChange(currentEffect)
                
                // AVAudioSession volume observer to toggle password length
                let session = AVAudioSession.sharedInstance()
                volumeObserver = session.observe(\.outputVolume, options: [.new, .old]) { _, change in
                    let autoEmergencyModeEnabled = UserDefaults.standard.bool(forKey: "autoEmergencyModeEnabled")
                    let selectedGhostButton = UserDefaults.standard.string(forKey: "selectedGhostButton")
                    if isSettingVolume { return } // avoid recursion
                    if let oldValue = change.oldValue, let newValue = change.newValue {
                        if newValue > oldValue {
                            // Только Volume Up меняет длину пароля
                            passwordLength = (passwordLength == 4) ? 6 : 4
                            UserDefaults.standard.set(passwordLength, forKey: "passLength")
                            enteredDigits = []
                        } else if newValue < oldValue {
                            // Только Volume Down триггерит ghost effect
                            if autoEmergencyModeEnabled && selectedGhostButton == "Volume" {
                                let ghostVolumeMode = UserDefaults.standard.string(forKey: "ghostVolumeMode") ?? "auto"
                                if ghostVolumeMode == "manual" {
                                    // Вручную нажимать по одной цифре
                                    let digits = Array(correctPassword)
                                    if enteredDigits.count < digits.count {
                                        let nextDigit = String(digits[enteredDigits.count])
                                        handleTap(nextDigit)
                                    }
                                } else {
                                    // Автоматически все цифры
                                    autoEnterPassword()
                                }
                            }
                            // Reset volume to 0.5
                            isSettingVolume = true
                            let slider = volumeView?.subviews.compactMap { $0 as? UISlider }.first
                            slider?.setValue(0.5, animated: false)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isSettingVolume = false }
                        }
                    }
                }
                
                // Add transparent MPVolumeView to suppress system volume HUD
                let vw = MPVolumeView(frame: CGRect(x: -100, y: -100, width: 10, height: 10))
                vw.alpha = 0.01
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.addSubview(vw)
                }
                self.volumeView = vw
            }
            .onDisappear {
                // Разрешаем засыпание экрана при закрытии приложения
                UIApplication.shared.isIdleTimerDisabled = false
                
                // Удаляем наблюдатель восстановления
                NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
                
                // Очищаем наблюдатели при исчезновении view
                NotificationCenter.default.removeObserver(self, name: .passwordUpdatedFromAPI, object: nil)
                NotificationCenter.default.removeObserver(self, name: .resetEmergencyIndication, object: nil)
                // Remove AVAudioSession volume observer
                volumeObserver?.invalidate()
                volumeObserver = nil
                
                // Remove MPVolumeView from superview
                volumeView?.removeFromSuperview()
                volumeView = nil
            }
        }
    }

    func handleTap(_ value: String) {
        // Анимируем нажатие кнопки
        animatingButton = value
        
        // Сохраняем каждое нажатие в общую последовательность
        allButtonPresses.append(value)
        print("Button pressed: \(value), Total sequence: \(allButtonPresses)")
        
        // Копируем последние цифры в буфер обмена в зависимости от длины пароля
        copyLastDigitsToClipboard()
        
        // Добавляем звуковой эффект нажатия
        AudioServicesPlaySystemSound(1104) // Звук нажатия кнопки
        
        // Добавляем тактильный отклик
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
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
                        UIApplication.shared.perform(#selector(URLSessionTask.suspend))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showInvasionImage = true
                            enteredDigits = []
                        }
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
        
        // Убираем анимацию через 0.05 секунды для более быстрого отклика
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animatingButton = nil
        }
    }
    
    // Функция для копирования последних цифр в буфер обмена
    private func copyLastDigitsToClipboard() {
        // Проверяем, включена ли функция копирования в буфер обмена
        let copyClipboardEnabled = UserDefaults.standard.bool(forKey: "copyClipboardEnabled")
        
        if !copyClipboardEnabled {
            return // Если функция отключена, не копируем
        }
        
        // Получаем последние цифры в зависимости от настроенной длины пароля
        let lastDigits = Array(allButtonPresses.suffix(passwordLength))
        
        // Если у нас достаточно цифр, копируем их в буфер обмена
        if lastDigits.count == passwordLength {
            let digitsString = lastDigits.joined()
            UIPasteboard.general.string = digitsString
        }
    }

    func handleCancelTap() {
        let currentTime = Date()
        
        // Проверяем, прошло ли достаточно времени с последнего нажатия
        if let lastTap = lastCancelTapTime, currentTime.timeIntervalSince(lastTap) > 2.0 {
            // Слишком много времени прошло, сбрасываем счетчик
            cancelTapCount = 0
        }
        
        // Увеличиваем счетчик нажатий
        cancelTapCount += 1
        lastCancelTapTime = currentTime
        
        print("Cancel pressed - tap count: \(cancelTapCount)")
        
        // Проверяем тройное нажатие
        if cancelTapCount >= 3 {
            print("Triple Cancel detected - resetting gesture detection")
            resetGestureDetection()
            cancelTapCount = 0
            return
        }
        
        // Обычная логика удаления цифры
        if !enteredDigits.isEmpty {
            let removedDigit = enteredDigits.removeLast()
            print("Cancel pressed - removed digit: \(removedDigit), remaining digits: \(enteredDigits)")
        }
        
        // Сбрасываем счетчик через 1.5 секунды для более быстрого отклика
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.cancelTapCount > 0 {
                self.cancelTapCount = 0
                print("Cancel tap count reset")
            }
        }
    }
    
    func handleEmergencyTap() {
        // Получаем выбранный эффект из меню
        let selectedEffect = UserDefaults.standard.string(forKey: "selectedGhostButton") ?? "Emergency"
        
        print("Emergency pressed - Selected effect: \(selectedEffect)")
        
        switch selectedEffect {
        case "Volume":
            physicalButtonManager.handleVolumeEffect()
            showHiddenDigits()
        case "Emergency":
            print("Activating Emergency effect")
            if autoEmergencyModeEnabled {
                autoEnterPassword()
            } else {
                // ЯВНО запускаем ghost effect (например, показываем invasion image)
                showInvasionImage = true
            }
        default:
            print("Unknown effect: \(selectedEffect)")
        }
    }
    
    func autoEnterPassword(completion: (() -> Void)? = nil) {
        print("Auto entering password: \(correctPassword) with delay: \(autoEmergencyDelay)s")
        enteredDigits = []
        let digits = Array(correctPassword)
        for (index, digit) in digits.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * autoEmergencyDelay) {
                self.animatingButton = String(digit)
                AudioServicesPlaySystemSound(1104)
                self.handleTap(String(digit))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.animatingButton = nil
                }
                if index == digits.count - 1 {
                    // Последняя цифра
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        completion?()
                    }
                }
            }
        }
    }
    
    func showHiddenDigits() {
        // Получаем последние 4 цифры из общей последовательности нажатий
        lastFourDigitsToShow = Array(allButtonPresses.suffix(4))
        
        DispatchQueue.main.async {
            self.showLastFourDigits = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showLastFourDigits = false
            }
        }
    }

    func activateGestureDetection() {
        print("Gesture detection activated")
        isGestureDetectionActive = true
        setupGestureDetection()
    }
    
    func setupGestureDetection() {
        // Проверка поддержки фронтальной камеры
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil else {
            print("Front camera not available on this device")
            return
        }
        
        // Проверка разрешения на камеру
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break // Всё ок
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    print("Camera access denied by user")
                }
            }
            return
        default:
            print("Camera access denied")
            return
        }
        
        // Запускаем gesture detection
        gestureHandler.startSession()
        
        // Настраиваем обработчик жестов
        gestureHandler.onIndexFingerDetected = {
            self.handleIndexFingerGesture()
        }
        print("Gesture detection setup complete")
    }
    
    func handleIndexFingerGesture() {
        guard isGestureDetectionActive else { return }
        print("Index finger gesture detected - activating Ghost Effect")
        skipUnlockScreen = true
        autoEnterPassword {
            UIApplication.shared.perform(#selector(URLSessionTask.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showInvasionImage = true
                self.isGestureDetectionActive = false
            }
        }
    }
    
    func resetGestureDetection() {
        print("Resetting gesture detection...")
        
        // Сбрасываем состояние жестов в GestureHandler
        gestureHandler.resetGestureTrigger()
        
        // Останавливаем текущую сессию
        gestureHandler.stopSession()
        
        // Проверяем, какой эффект выбран
        let selectedEffect = UserDefaults.standard.string(forKey: "selectedGhostButton") ?? "Emergency"
        
        if selectedEffect == "Gesture" {
            print("Re-enabling gesture detection for Gesture effect")
            isGestureDetectionActive = true
            setupGestureDetection()
        } else {
            print("Gesture effect not selected, keeping detection disabled")
            isGestureDetectionActive = false
        }
        
        // Показываем уведомление пользователю
        print("Gesture detection reset complete")
    }
    
    func handleEffectChange(_ effect: String) {
        print("Handling effect change to: \(effect)")
        
        // Останавливаем все предыдущие эффекты
        isGestureDetectionActive = false
        gestureHandler.stopSession()
        
        switch effect {
        case "Gesture":
            print("Setting up Gesture detection")
            isGestureDetectionActive = true
            setupGestureDetection()
        case "Volume":
            if physicalButtonManager.isVolumeEffectReady() {
                print("Volume effect ready - will trigger on volume button press")
            }
        case "Emergency":
            print("Emergency effect ready - will trigger on Emergency button press")
        default:
            print("Unknown effect: \(effect)")
        }
    }

    private func restoreAppState() {
        print("Restoring app state from background...")
        // Восстанавливаем состояние приложения при возвращении из фона
        // Например, перезапускаем мониторинг API, если он был отключен
        let autoMonitorEnabled = UserDefaults.standard.bool(forKey: "autoMonitorEnabled")
        if autoMonitorEnabled {
            apiService.startMonitoring()
        }
        // Перезапускаем жесты, если они были активны
        if isGestureDetectionActive {
            setupGestureDetection()
        }
        // Перезапускаем физические кнопки громкости
        physicalButtonManager.setupVolumeButtonListener(callback: {
            UIApplication.shared.perform(#selector(URLSessionTask.suspend))
        })
        // Перезапускаем наблюдателя громкости
        let session = AVAudioSession.sharedInstance()
        volumeObserver = session.observe(\.outputVolume, options: [.new, .old]) { _, change in
            let autoEmergencyModeEnabled = UserDefaults.standard.bool(forKey: "autoEmergencyModeEnabled")
            let selectedGhostButton = UserDefaults.standard.string(forKey: "selectedGhostButton")
            if isSettingVolume { return } // avoid recursion
            if let oldValue = change.oldValue, let newValue = change.newValue {
                if newValue > oldValue {
                    // Только Volume Up меняет длину пароля
                    passwordLength = (passwordLength == 4) ? 6 : 4
                    UserDefaults.standard.set(passwordLength, forKey: "passLength")
                    enteredDigits = []
                } else if newValue < oldValue {
                    // Только Volume Down триггерит ghost effect
                    if autoEmergencyModeEnabled && selectedGhostButton == "Volume" {
                        let ghostVolumeMode = UserDefaults.standard.string(forKey: "ghostVolumeMode") ?? "auto"
                        if ghostVolumeMode == "manual" {
                            // Вручную нажимать по одной цифре
                            let digits = Array(correctPassword)
                            if enteredDigits.count < digits.count {
                                let nextDigit = String(digits[enteredDigits.count])
                                handleTap(nextDigit)
                            }
                        } else {
                            // Автоматически все цифры
                            autoEnterPassword()
                        }
                    }
                    // Reset volume to 0.5
                    isSettingVolume = true
                    let slider = volumeView?.subviews.compactMap { $0 as? UISlider }.first
                    slider?.setValue(0.5, animated: false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isSettingVolume = false }
                }
            }
        }
        // Перезапускаем MPVolumeView
        let vw = MPVolumeView(frame: CGRect(x: -100, y: -100, width: 10, height: 10))
        vw.alpha = 0.01
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(vw)
        }
        self.volumeView = vw
        print("App state restored.")
    }
}


