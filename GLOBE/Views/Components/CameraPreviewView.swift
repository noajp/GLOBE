import SwiftUI
import AVFoundation
import UIKit

struct CameraPreviewView: View {
    @Binding var capturedImage: UIImage?
    @State private var isCapturing = false
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    
    var body: some View {
        ZStack {
            CameraPreview(capturedImage: $capturedImage, position: cameraPosition)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    // Flip camera (front/back)
                    Button(action: { toggleCamera() }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Capsule())
                    }
                    .padding([.top, .trailing], 16)
                }
                Spacer()
                
                // Capture button
                Button(action: {
                    isCapturing = true
                    NotificationCenter.default.post(name: NSNotification.Name("CapturePhoto"), object: nil)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    private func toggleCamera() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        NotificationCenter.default.post(name: NSNotification.Name("SwitchCamera"), object: cameraPosition)
    }
}

struct CameraPreview: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    var position: AVCaptureDevice.Position = .back
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraPreview
        var captureSession: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        init(_ parent: CameraPreview) {
            self.parent = parent
            super.init()
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(capturePhoto),
                name: NSNotification.Name("CapturePhoto"),
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleSwitchCamera(_:)),
                name: NSNotification.Name("SwitchCamera"),
                object: nil
            )
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
            captureSession?.stopRunning()
        }
        
        @objc func capturePhoto() {
            guard let photoOutput = photoOutput else {
                print("Photo output not available")
                return
            }
            
            var settings = AVCapturePhotoSettings()
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            settings.flashMode = .auto
            
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                print("Error capturing photo: \(error)")
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                print("Failed to convert photo to image")
                return
            }
            
            DispatchQueue.main.async {
                self.parent.capturedImage = image
            }
        }
        
        @objc func handleSwitchCamera(_ note: Notification) {
            guard let newPos = note.object as? AVCaptureDevice.Position else { return }
            switchCamera(to: newPos)
        }

        func setupCamera(for view: UIView, position: AVCaptureDevice.Position = .back) {
            // Check camera permission first
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
            guard authStatus == .authorized else {
                print("Camera not authorized: \(authStatus)")
                // Show a placeholder view instead of failing silently
                DispatchQueue.main.async {
                    let label = UILabel()
                    label.text = "カメラへのアクセスが許可されていません"
                    label.textColor = .white
                    label.textAlignment = .center
                    label.frame = view.bounds
                    label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    view.addSubview(label)
                }
                return
            }
            
            let captureSession = AVCaptureSession()
            captureSession.sessionPreset = .photo
            
            guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
                print("No back camera found, trying default video device")
                guard let fallbackDevice = AVCaptureDevice.default(for: .video) else {
                    print("No camera device found at all")
                    DispatchQueue.main.async {
                        let label = UILabel()
                        label.text = "カメラデバイスが見つかりません"
                        label.textColor = .white
                        label.textAlignment = .center
                        label.frame = view.bounds
                        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        view.addSubview(label)
                    }
                    return
                }
                // Use fallback device
                do {
                    let videoInput = try AVCaptureDeviceInput(device: fallbackDevice)
                    if captureSession.canAddInput(videoInput) {
                        captureSession.addInput(videoInput)
                    } else {
                        print("Cannot add fallback video input")
                        return
                    }
                } catch {
                    print("Error with fallback camera: \(error)")
                    return
                }
                
                let photoOutput = AVCapturePhotoOutput()
                if captureSession.canAddOutput(photoOutput) {
                    captureSession.addOutput(photoOutput)
                } else {
                    print("Cannot add photo output")
                    return
                }
                
                self.captureSession = captureSession
                self.photoOutput = photoOutput
                
                let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.frame = view.bounds
                view.layer.addSublayer(previewLayer)
                self.previewLayer = previewLayer
                
                DispatchQueue.global(qos: .userInitiated).async {
                    captureSession.startRunning()
                }
                return
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                
                if captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                } else {
                    print("Cannot add video input")
                    return
                }
                
                let photoOutput = AVCapturePhotoOutput()
                if captureSession.canAddOutput(photoOutput) {
                    captureSession.addOutput(photoOutput)
                } else {
                    print("Cannot add photo output")
                    return
                }
                
                self.captureSession = captureSession
                self.photoOutput = photoOutput
                
                let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.frame = view.bounds
                view.layer.addSublayer(previewLayer)
                self.previewLayer = previewLayer
                
                DispatchQueue.global(qos: .userInitiated).async {
                    captureSession.startRunning()
                }
            } catch {
                print("Error setting up camera: \(error)")
            }
        }
        
        func updatePreviewLayer(for view: UIView) {
            DispatchQueue.main.async {
                self.previewLayer?.frame = view.bounds
            }
        }
        
        func switchCamera(to position: AVCaptureDevice.Position) {
            guard let session = captureSession else { return }
            session.beginConfiguration()
            // Remove existing video inputs
            if let inputs = session.inputs as? [AVCaptureDeviceInput] {
                for input in inputs {
                    if input.device.hasMediaType(.video) {
                        session.removeInput(input)
                    }
                }
            }
            // Add new device input
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
                do {
                    let newInput = try AVCaptureDeviceInput(device: device)
                    if session.canAddInput(newInput) {
                        session.addInput(newInput)
                    }
                } catch {
                    print("Failed to switch camera: \(error)")
                }
            }
            session.commitConfiguration()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Setup camera with proper error handling
        context.coordinator.setupCamera(for: view, position: position)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updatePreviewLayer(for: uiView)
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.captureSession?.stopRunning()
        coordinator.previewLayer?.removeFromSuperlayer()
    }
}
