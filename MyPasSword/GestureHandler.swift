import AVFoundation
import Vision
import UIKit

class GestureHandler: NSObject, ObservableObject {
    var onIndexFingerDetected: (() -> Void)?
    
    private var gestureStartTime: Date?
    private var gestureActive = false
    private let requiredHoldDuration: TimeInterval = 1.5
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "GestureSessionQueue")
    private var isSessionRunning = false
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .medium
            // Фронтальная камера
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                print("Не удалось получить доступ к фронтальной камере")
                return
            }
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }
            self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoOutputQueue"))
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }
            self.captureSession.commitConfiguration()
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
        let request = VNDetectHumanHandPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            guard let observations = request.results as? [VNHumanHandPoseObservation] else {
                self.resetGesture()
                return
            }
            var detected = false
            for observation in observations {
                var fingerCount = 0
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
                if fingerCount == 1 || fingerCount == 5 {
                    detected = true
                    if !self.gestureActive {
                        self.gestureActive = true
                        self.gestureStartTime = Date()
                    } else if let start = self.gestureStartTime, Date().timeIntervalSince(start) >= self.requiredHoldDuration {
                        self.gestureActive = false
                        self.gestureStartTime = nil
                        DispatchQueue.main.async {
                            self.onIndexFingerDetected?()
                        }
                        break
                    }
                }
            }
            if !detected {
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
}

extension GestureHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processHandPose(pixelBuffer: pixelBuffer)
    }
} 