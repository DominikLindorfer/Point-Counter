import SwiftUI
import AVFoundation

struct CameraOverlayView: View {
    let onClose: () -> Void

    @Environment(\.layout) private var layout
    @StateObject private var cameraService = CameraService()
    @State private var blinkVisible = true

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewRepresentable(session: cameraService.captureSession)
                .frame(width: layout.cameraWidth, height: layout.cameraHeight)
                .clipShape(RoundedRectangle(cornerRadius: layout.cameraCorner))
                .overlay(
                    RoundedRectangle(cornerRadius: layout.cameraCorner)
                        .stroke(cameraService.isRecording ? RecordRed : Color(white: 0.2), lineWidth: 2)
                )

            // Recording indicator — top left
            if cameraService.isRecording {
                VStack {
                    HStack {
                        TimelineView(.periodic(from: .now, by: 0.5)) { context in
                            let blinkOn = Int(context.date.timeIntervalSince1970 * 2) % 2 == 0
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(blinkOn ? RecordRed : Color.clear)
                                    .frame(width: layout.cameraRecordDot, height: layout.cameraRecordDot)

                                if let start = cameraService.recordingStartTime {
                                    let elapsed = Int(context.date.timeIntervalSince(start))
                                    let min = elapsed / 60
                                    let sec = elapsed % 60
                                    Text(String(format: "%d:%02d", min, sec))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        Spacer()
                    }
                    .padding(6)
                    Spacer()
                }
                .frame(width: layout.cameraWidth, height: layout.cameraHeight)
            }

            // Bottom controls
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    // Switch camera
                    Button(action: { cameraService.switchCamera() }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: layout.cameraIconSize))
                            .foregroundColor(cameraService.isRecording ? .gray : .white)
                    }
                    .disabled(cameraService.isRecording)
                    .frame(width: layout.cameraButtonSize, height: layout.cameraButtonSize)

                    Spacer()

                    // Record / Stop
                    Button(action: {
                        HapticService.recordToggle()
                        if cameraService.isRecording {
                            cameraService.stopRecording()
                        } else {
                            cameraService.startRecording()
                        }
                    }) {
                        if cameraService.isRecording {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white)
                                .frame(width: layout.cameraRecordIcon, height: layout.cameraRecordIcon)
                        } else {
                            Circle()
                                .fill(RecordRed)
                                .frame(width: layout.cameraRecordIcon, height: layout.cameraRecordIcon)
                        }
                    }
                    .frame(width: layout.cameraButtonSize, height: layout.cameraButtonSize)

                    Spacer()

                    // Close
                    Button(action: {
                        if cameraService.isRecording {
                            cameraService.stopRecording()
                        }
                        cameraService.stopSession()
                        onClose()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: layout.cameraIconSize))
                            .foregroundColor(.white)
                    }
                    .frame(width: layout.cameraButtonSize, height: layout.cameraButtonSize)

                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.5))
            }
            .frame(width: layout.cameraWidth, height: layout.cameraHeight)
            .clipShape(RoundedRectangle(cornerRadius: layout.cameraCorner))
        }
        .onAppear { cameraService.startSession() }
        .onDisappear {
            if cameraService.isRecording { cameraService.stopRecording() }
            cameraService.stopSession()
        }
    }
}

/// UIViewRepresentable wrapping AVCaptureVideoPreviewLayer.
struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
