//======================================================================
// MARK: - QRCodeScannerView.swift
// Purpose: QR code scanner for sharing user profiles
// Path: GLOBE/Views/Profile/QRCodeScannerView.swift
//======================================================================

import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    @Binding var isPresented: Bool
    @Binding var scannedUserId: String?
    @State private var showingProfile = false
    @State private var scannedUserName: String?

    var body: some View {
        ZStack {
            // Camera preview
            QRCodeScannerViewController(
                scannedUserId: $scannedUserId,
                scannedUserName: $scannedUserName,
                isPresented: $isPresented
            )
            .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)

                    Spacer()
                }
                .padding(.top, 16)

                Spacer()

                // Scanning frame
                VStack(spacing: 20) {
                    Text("Scan QR Code")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    // Scanning frame outline
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 250, height: 250)

                    Text("Point camera at a QR code")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }
        }
        .onChange(of: scannedUserId) { _, newValue in
            if newValue != nil {
                // Show profile when QR code is scanned
                showingProfile = true
            }
        }
        .fullScreenCover(isPresented: $showingProfile) {
            if let userId = scannedUserId {
                UserProfileView(
                    userName: scannedUserName ?? "User",
                    userId: userId,
                    isPresented: $showingProfile
                )
            }
        }
    }
}

// MARK: - QRCodeScannerViewController (UIKit wrapper)
struct QRCodeScannerViewController: UIViewControllerRepresentable {
    @Binding var scannedUserId: String?
    @Binding var scannedUserName: String?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, QRScannerDelegate {
        let parent: QRCodeScannerViewController

        init(_ parent: QRCodeScannerViewController) {
            self.parent = parent
        }

        func didScanQRCode(userId: String, userName: String?) {
            parent.scannedUserId = userId
            parent.scannedUserName = userName

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Close scanner after successful scan
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.parent.isPresented = false
            }
        }
    }
}

// MARK: - QRScannerDelegate Protocol
protocol QRScannerDelegate: AnyObject {
    func didScanQRCode(userId: String, userName: String?)
}

// MARK: - QRScannerViewController (UIKit)
class QRScannerViewController: UIViewController {
    weak var delegate: QRScannerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.stopRunning()
            }
        }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            SecureLogger.shared.error("Failed to get video capture device")
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            SecureLogger.shared.error("Failed to create video input: \(error.localizedDescription)")
            return
        }

        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        } else {
            SecureLogger.shared.error("Failed to add video input")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            SecureLogger.shared.error("Failed to add metadata output")
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            // Parse QR code content
            // Expected format: "globe://user/{userId}?name={userName}"
            if let url = URL(string: stringValue),
               url.scheme == "globe",
               url.host == "user" {

                let userId = url.pathComponents.last ?? ""
                let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
                let userName = queryItems?.first(where: { $0.name == "name" })?.value

                if !userId.isEmpty {
                    SecureLogger.shared.info("QR Code scanned: userId=\(userId), userName=\(userName ?? "none")")

                    // Stop scanning
                    captureSession?.stopRunning()

                    // Notify delegate
                    delegate?.didScanQRCode(userId: userId, userName: userName)
                }
            } else {
                SecureLogger.shared.warning("Invalid QR code format: \(stringValue)")
            }
        }
    }
}

#Preview {
    QRCodeScannerView(
        isPresented: .constant(true),
        scannedUserId: .constant(nil)
    )
}
