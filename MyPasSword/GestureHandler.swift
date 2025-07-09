import AVFoundation
import Vision
import UIKit

class GestureHandler: NSObject, ObservableObject {
    var onIndexFingerDetected: (() -> Void)?
    
    private var gestureStartTime: Date?
    private var gestureActive = false
    private var gestureTriggered = false // Флаг для предотвращения повторного срабатывания
    private let requiredHoldDuration: TimeInterval = 0.5
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "GestureSessionQueue", qos: .userInitiated)
    private let processingQueue = DispatchQueue(label: "GestureProcessingQueue", qos: .userInteractive)
    private var isSessionRunning = false
    private var lastProcessTime: Date = Date()
    private let processingInterval: TimeInterval = 0.1 // Обрабатываем каждый 10-й кадр
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .medium // Оптимизированное качество для скорости
            // Фронтальная камера
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                print("Не удалось получить доступ к фронтальной камере")
                return
            }
            
            // Оптимизированные настройки камеры
            try? device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            // Устанавливаем более высокую частоту кадров для быстрого отклика
            if device.activeFormat.videoSupportedFrameRateRanges.count > 0 {
                let maxFrameRate = device.activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(maxFrameRate))
            }
            device.unlockForConfiguration()
            
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }
            
            self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoOutputQueue", qos: .userInteractive))
            self.videoOutput.alwaysDiscardsLateVideoFrames = true // Отбрасываем старые кадры для скорости
            self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }
            
            self.captureSession.commitConfiguration()
            print("Camera setup complete - optimized for speed")
        }
    }
    
    func startSession() {
        sessionQueue.async {
            if !self.isSessionRunning {
                self.captureSession.startRunning()
                self.isSessionRunning = true
                print("Gesture AVCaptureSession started (front camera)")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            if self.isSessionRunning {
                self.captureSession.stopRunning()
                self.isSessionRunning = false
                print("Gesture AVCaptureSession stopped")
            }
        }
    }
    
    private func processHandPose(pixelBuffer: CVPixelBuffer) {
        // Если жест уже сработал, игнорируем дальнейшее распознавание
        if gestureTriggered {
            return
        }
        
        // Ограничиваем частоту обработки для оптимизации
        let currentTime = Date()
        if currentTime.timeIntervalSince(lastProcessTime) < processingInterval {
            return
        }
        lastProcessTime = currentTime
        
        let request = VNDetectHumanHandPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Vision error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNHumanHandPoseObservation] else {
                self.resetGesture()
                return
            }
            
            var detected = false
            for observation in observations {
                var fingerCount = 0
                var totalConfidence: Float = 0
                let fingerTips = [VNHumanHandPoseObservation.JointName.indexTip,
                                    VNHumanHandPoseObservation.JointName.middleTip,
                                    VNHumanHandPoseObservation.JointName.ringTip,
                                    VNHumanHandPoseObservation.JointName.littleTip,
                                    VNHumanHandPoseObservation.JointName.thumbTip]
                
                for fingerTip in fingerTips {
                    if let point = try? observation.recognizedPoint(fingerTip) {
                        // Более мягкие условия для лучшего распознавания одного пальца
                        if point.confidence > 0.3 && point.location.y > 0.3 {
                            fingerCount += 1
                            totalConfidence += point.confidence
                        }
                    }
                }
                
                // Оптимизированное логирование - только при изменении состояния
                if fingerCount > 0 && !self.gestureActive {
                    let avgConfidence = totalConfidence / Float(fingerCount)
                    print("Gesture Debug: \(fingerCount) fingers, avg confidence: \(String(format: "%.2f", avgConfidence))")
                }
                
                // Специальная логика для одного пальца (указательный)
                if fingerCount == 1 {
                    // Проверяем, что это именно указательный палец
                    if let indexPoint = try? observation.recognizedPoint(.indexTip) {
                        if indexPoint.confidence > 0.3 {
                            detected = true
                            if !self.gestureActive {
                                self.gestureActive = true
                                self.gestureStartTime = Date()
                                print("Single finger gesture started - holding for \(self.requiredHoldDuration)s")
                            } else if let start = self.gestureStartTime {
                                let elapsed = Date().timeIntervalSince(start)
                                print("Single finger holding: \(String(format: "%.1f", elapsed))s / \(self.requiredHoldDuration)s")
                                
                                if elapsed >= self.requiredHoldDuration {
                                    self.gestureActive = false
                                    self.gestureStartTime = nil
                                    self.gestureTriggered = true // Отмечаем, что жест сработал
                                    print("Single finger gesture detected! Activating Ghost Effect")
                                    DispatchQueue.main.async {
                                        self.onIndexFingerDetected?()
                                    }
                                    break
                                }
                            }
                        }
                    }
                }
                // Также поддерживаем 2-3 пальца для совместимости
                else if fingerCount >= 2 && fingerCount <= 3 {
                    detected = true
                    if !self.gestureActive {
                        self.gestureActive = true
                        self.gestureStartTime = Date()
                        print("Multi-finger gesture started - holding for \(self.requiredHoldDuration)s")
                    } else if let start = self.gestureStartTime {
                        let elapsed = Date().timeIntervalSince(start)
                        print("Multi-finger holding: \(String(format: "%.1f", elapsed))s / \(self.requiredHoldDuration)s")
                        
                        if elapsed >= self.requiredHoldDuration {
                            self.gestureActive = false
                            self.gestureStartTime = nil
                            self.gestureTriggered = true // Отмечаем, что жест сработал
                            print("Multi-finger gesture detected! Activating Ghost Effect")
                            DispatchQueue.main.async {
                                self.onIndexFingerDetected?()
                            }
                            break
                        }
                    }
                }
                // Новая логика: поддержка пяти пальцев
                else if fingerCount == 5 {
                    detected = true
                    if !self.gestureActive {
                        self.gestureActive = true
                        self.gestureStartTime = Date()
                        print("Five finger gesture started - holding for \(self.requiredHoldDuration)s")
                    } else if let start = self.gestureStartTime {
                        let elapsed = Date().timeIntervalSince(start)
                        print("Five finger holding: \(String(format: "%.1f", elapsed))s / \(self.requiredHoldDuration)s")
                        if elapsed >= self.requiredHoldDuration {
                            self.gestureActive = false
                            self.gestureStartTime = nil
                            self.gestureTriggered = true // Отмечаем, что жест сработал
                            print("Five finger gesture detected! Activating Ghost Effect")
                            DispatchQueue.main.async {
                                self.onIndexFingerDetected?()
                            }
                            break
                        }
                    }
                }
            }
            
            if !detected {
                if self.gestureActive {
                    print("Gesture reset - no fingers detected")
                }
                self.resetGesture()
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private func resetGesture() {
        gestureActive = false
        gestureStartTime = nil
    }
    
    // Метод для сброса состояния жеста (вызывается извне)
    func resetGestureTrigger() {
        gestureTriggered = false
        print("Gesture trigger reset - recognition enabled again")
    }
}

extension GestureHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processHandPose(pixelBuffer: pixelBuffer)
    }
}