import SwiftUI
import AudioToolbox
import MediaPlayer
import AVFoundation

// MARK: - Volume Button Listener
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Physical Button Manager
class PhysicalButtonManager: ObservableObject {
    @Published var isVolumeButtonEnabled = false
    private var volumeListener: VolumeButtonListener?
    
    func setupVolumeButtonListener(callback: @escaping () -> Void) {
        volumeListener = VolumeButtonListener(showHiddenDigitsCallback: callback)
        isVolumeButtonEnabled = true
    }
    
    func disableVolumeButtonListener() {
        volumeListener = nil
        isVolumeButtonEnabled = false
    }
    
    func handleVolumeEffect() {
        print("Activating Volume effect")
        // Логика для обработки эффекта Volume
    }
    
    func isVolumeEffectReady() -> Bool {
        return isVolumeButtonEnabled
    }
} 