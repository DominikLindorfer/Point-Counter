import AVFoundation
import Photos
import UIKit

/// Manages AVCaptureSession for camera preview and video recording.
///
/// All AVCaptureSession mutation runs on a dedicated serial queue so configuration
/// and start/stop never block the main thread. `@Published` properties are hopped
/// back to main for SwiftUI observation.
final class CameraService: NSObject, ObservableObject {
    let captureSession = AVCaptureSession()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var audioInput: AVCaptureDeviceInput?
    private var videoInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "com.padelpulse.camera.session")

    @Published var isRecording = false
    @Published var recordingStartTime: Date?

    var onRecordingFinished: ((Bool) -> Void)?

    override init() {
        super.init()
        sessionQueue.async { [weak self] in self?.configureSession() }
    }

    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720

        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
           let input = try? AVCaptureDeviceInput(device: camera) {
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                videoInput = input
            }
        }

        if let mic = AVCaptureDevice.default(for: .audio),
           let input = try? AVCaptureDeviceInput(device: mic) {
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                audioInput = input
            }
        }

        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }

        captureSession.commitConfiguration()
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.movieOutput.isRecording { return }

            self.currentCameraPosition = self.currentCameraPosition == .back ? .front : .back

            self.captureSession.beginConfiguration()
            if let videoInput = self.videoInput {
                self.captureSession.removeInput(videoInput)
            }
            if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentCameraPosition),
               let input = try? AVCaptureDeviceInput(device: camera) {
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    self.videoInput = input
                }
            }
            self.captureSession.commitConfiguration()
        }
    }

    func startRecording() {
        sessionQueue.async { [weak self] in
            guard let self, !self.movieOutput.isRecording else { return }
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Padel_\(Int(Date().timeIntervalSince1970 * 1000))")
                .appendingPathExtension("mp4")
            self.movieOutput.startRecording(to: tempURL, recordingDelegate: self)
            DispatchQueue.main.async {
                self.isRecording = true
                self.recordingStartTime = Date()
            }
        }
    }

    func stopRecording() {
        sessionQueue.async { [weak self] in
            guard let self, self.movieOutput.isRecording else { return }
            self.movieOutput.stopRecording()
            DispatchQueue.main.async {
                self.isRecording = false
                self.recordingStartTime = nil
            }
        }
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        // Every branch below must decide what to do with the temp .mp4: either
        // hand it off to Photos (which copies it, so we delete after) or drop
        // it ourselves. Previously the auth-denied branch leaked the file.
        if let error {
            print("Recording error: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: outputFileURL)
            DispatchQueue.main.async { self.onRecordingFinished?(false) }
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else {
                // User denied photo-library access — nothing will save the clip,
                // so remove the temp file ourselves instead of letting it pile up.
                try? FileManager.default.removeItem(at: outputFileURL)
                DispatchQueue.main.async { self.onRecordingFinished?(false) }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
            }) { success, _ in
                try? FileManager.default.removeItem(at: outputFileURL)
                DispatchQueue.main.async { self.onRecordingFinished?(success) }
            }
        }
    }
}
