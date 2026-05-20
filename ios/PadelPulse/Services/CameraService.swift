import AVFoundation
import Photos
import UIKit

/// Manages AVCaptureSession for camera preview and video recording.
final class CameraService: NSObject, ObservableObject {
    let captureSession = AVCaptureSession()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var audioInput: AVCaptureDeviceInput?
    private var videoInput: AVCaptureDeviceInput?

    @Published var isRecording = false
    @Published var recordingStartTime: Date?

    var onRecordingFinished: ((Bool) -> Void)?

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720

        // Video input
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
           let input = try? AVCaptureDeviceInput(device: camera) {
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                videoInput = input
            }
        }

        // Audio input
        if let mic = AVCaptureDevice.default(for: .audio),
           let input = try? AVCaptureDeviceInput(device: mic) {
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                audioInput = input
            }
        }

        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }

        captureSession.commitConfiguration()
    }

    func startSession() {
        guard !captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
    }

    func switchCamera() {
        guard !isRecording else { return }

        currentCameraPosition = currentCameraPosition == .back ? .front : .back

        captureSession.beginConfiguration()

        // Remove current video input
        if let videoInput {
            captureSession.removeInput(videoInput)
        }

        // Add new camera
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
           let input = try? AVCaptureDeviceInput(device: camera) {
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                videoInput = input
            }
        }

        captureSession.commitConfiguration()
    }

    func startRecording() {
        guard !isRecording else { return }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Padel_\(Int(Date().timeIntervalSince1970 * 1000))")
            .appendingPathExtension("mp4")

        movieOutput.startRecording(to: tempURL, recordingDelegate: self)
        isRecording = true
        recordingStartTime = Date()
    }

    func stopRecording() {
        guard isRecording else { return }
        movieOutput.stopRecording()
        isRecording = false
        recordingStartTime = nil
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error {
            print("Recording error: \(error.localizedDescription)")
            DispatchQueue.main.async { self.onRecordingFinished?(false) }
            return
        }

        // Save to Photos library
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else {
                DispatchQueue.main.async { self.onRecordingFinished?(false) }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
            }) { success, error in
                // Clean up temp file
                try? FileManager.default.removeItem(at: outputFileURL)
                DispatchQueue.main.async { self.onRecordingFinished?(success) }
            }
        }
    }
}
