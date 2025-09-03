//======================================================================
// MARK: - PostPopupView.swift
// Purpose: Post creation popup with full-screen photo background
// Path: GLOBE/Views/Components/PostPopupView.swift
//======================================================================
import SwiftUI
import CoreLocation
import MapKit
import AVFoundation
import Combine

struct PostPopupView: View {
    @Binding var isPresented: Bool
    @ObservedObject var mapManager: MapManager
    @StateObject private var locationManager = PostLocationManager()
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var postManager = PostManager.shared
    
    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    
    @State private var postText = ""
    @State private var selectedImageData: Data?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingCamera = false
    @State private var showingCameraPermissionAlert = false
    @State private var postLocation: CLLocationCoordinate2D?
    @State private var areaName: String = ""
    @State private var showPrivacySelection = false
    @State private var selectedPrivacyType: PostPrivacyType = .publicPost
    
    enum PostPrivacyType {
        case followersOnly
        case publicPost
        case anonymous
    }
    
    // Computed properties to reduce complexity
    private var isButtonDisabled: Bool {
        let disabled = postText.isEmpty && selectedImageData == nil
        print("🔘 PostPopup - isButtonDisabled calculated: \(disabled) (text='\(postText)', hasImage=\(selectedImageData != nil))")
        return disabled
    }
    
    private var maxTextLength: Int {
        selectedImageData != nil ? 30 : 60
    }
    
    var body: some View {
        ZStack {
            // Popup content with speech bubble tail
            VStack(spacing: 0) {
                if !showPrivacySelection {
                    postCreationView
                } else {
                    privacySelectionView
                }
            }
            .frame(width: 240, height: 350)
            .background(customBlack)
            .cornerRadius(12)
            .onTapGesture {} // Prevent closing when tapping on card
            .overlay(speechBubbleTail, alignment: .bottom)
            .shadow(radius: 10)
        }
        .animation(.easeInOut(duration: 0.3), value: showPrivacySelection)
        .sheet(isPresented: $showingCamera) {
            CameraView(selectedImageData: $selectedImageData)
                .ignoresSafeArea()
                .onDisappear {
                    print("📷 PostPopup - Camera dismissed")
                    print("📝 PostPopup - After camera: text='\(postText)', hasImage=\(selectedImageData != nil)")
                    if let imageData = selectedImageData {
                        print("📸 PostPopup - Image data after camera: \(imageData.count) bytes")
                    }
                }
        }
        .alert("カメラへのアクセスが必要です", isPresented: $showingCameraPermissionAlert) {
            Button("設定を開く") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("写真を撮影するために、カメラへのアクセスを許可してください。")
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            updatePostLocation()
        }
        .onChange(of: selectedImageData) { oldValue, newValue in
            print("📸 PostPopup - selectedImageData changed: \(newValue?.count ?? 0) bytes (was: \(oldValue?.count ?? 0) bytes)")
            print("📝 PostPopup - After change - text: '\(postText)', hasImage: \(newValue != nil)")
            print("🔘 PostPopup - Button should be disabled: \(postText.isEmpty && newValue == nil)")
        }
    }
    
    // MARK: - Post Creation View
    private var postCreationView: some View {
        VStack(spacing: 0) {
            headerView
            photoPreviewView
            textInputView
            Spacer()
            bottomSectionView
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: handleNextButtonPress) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isButtonDisabled ? .gray : .white)
            }
            .disabled(isButtonDisabled)
            .onAppear {
                print("🔘 PostPopup - Button state on appear: disabled=\(isButtonDisabled)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Photo Preview View
    @ViewBuilder
    private var photoPreviewView: some View {
        if let selectedImageData {
            let _ = print("📸 PostPopup - Displaying image preview: \(selectedImageData.count) bytes")
            if let uiImage = UIImage(data: selectedImageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 240, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.0)
                        )
                    
                    // Remove photo button
                    Button(action: {
                        self.selectedImageData = Optional<Data>.none
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(Color.red.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                .frame(width: 240, height: 180)
            } else {
                let _ = print("❌ PostPopup - Failed to create UIImage from data")
                EmptyView()
            }
        }
    }
    
    // MARK: - Text Input View
    private var textInputView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            TextField("何を投稿しますか？", text: Binding(
                get: { postText },
                set: { newValue in
                    postText = newValue
                }
            ), axis: .vertical)
            .font(.system(size: 16))
            .foregroundColor(postText.count > maxTextLength ? .red : .white)
            .lineLimit(10)
            .textFieldStyle(PlainTextFieldStyle())
            .scrollContentBackground(.hidden)
            
            // 文字数カウンター
            Text("\(postText.count)/\(maxTextLength)")
                .font(.system(size: 12))
                .foregroundColor(postText.count > maxTextLength ? .red : (postText.count >= maxTextLength ? .orange : .gray))
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Bottom Section View
    private var bottomSectionView: some View {
        HStack {
            // Location info button
            Button(action: getCurrentLocationAndMoveMap) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: postLocation != nil ? "location.fill" : "location")
                            .foregroundColor(postLocation != nil ? .white : .gray)
                            .font(.system(size: 14, weight: .medium))
                    }
                    

                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.3))
                .cornerRadius(16)
            }
            
            Spacer()
            
            Button(action: checkCameraPermissionAndOpen) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Privacy Selection View
    private var privacySelectionView: some View {
        VStack(spacing: 0) {
            privacyHeaderView
            Spacer()
            privacyButtonsView
            Spacer()
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
    
    // MARK: - Privacy Header View
    private var privacyHeaderView: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPrivacySelection = false
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("公開範囲")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // バランス用の空スペース
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.clear)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Privacy Buttons View
    private var privacyButtonsView: some View {
        VStack(spacing: 16) {
            // Followers Only
            Button(action: {
                selectedPrivacyType = .followersOnly
                createPost()
            }) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.green)
                    }
                    
                    Text("Followers Only")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 160, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Public
            Button(action: {
                selectedPrivacyType = .publicPost
                createPost()
            }) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "globe")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Public")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 160, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Anonymous
            Button(action: {
                selectedPrivacyType = .anonymous
                createPost()
            }) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 22))
                            .foregroundColor(.purple)
                    }
                    
                    Text("Anonymous")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 160, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Speech Bubble Tail
    private var speechBubbleTail: some View {
        Triangle()
            .fill(selectedImageData != nil ? Color.black.opacity(0.8) : customBlack)
            .frame(width: 20, height: 15)
            .rotationEffect(.degrees(180))
            .offset(y: 15)
    }
    
    // MARK: - Action Methods
    private func handleNextButtonPress() {
        print("🔘 PostPopup - Next button pressed")
        print("📝 PostPopup - Current state: text='\(postText)', hasImage=\(selectedImageData != nil)")
        print("🚫 PostPopup - Button disabled state: \(isButtonDisabled)")
        if let imageData = selectedImageData {
            print("📸 PostPopup - Image data size at button press: \(imageData.count) bytes")
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            showPrivacySelection = true
        }
    }
    
    private func createPost() {
        guard let location = postLocation else { 
            print("❌ PostPopup - No location available")
            return 
        }
        
        print("🚀 PostPopup - Starting post creation. Content: '\(postText)', HasImage: \(selectedImageData != nil), Location: \(areaName.isEmpty ? "unknown" : areaName)")
        if let imageData = selectedImageData {
            print("📸 PostPopup - Image data size: \(imageData.count) bytes")
        }
        print("📍 PostPopup - Location details: latitude=\(location.latitude), longitude=\(location.longitude)")
        let privacyDescription = switch selectedPrivacyType {
        case .followersOnly: "Followers Only"
        case .publicPost: "Public"
        case .anonymous: "Anonymous"
        }
        print("🔐 PostPopup - Privacy setting: \(privacyDescription)")
        
        Task { @MainActor in
            do {
                try await postManager.createPost(
                    content: postText,
                    imageData: selectedImageData,
                    location: location,
                    locationName: areaName,
                    isAnonymous: selectedPrivacyType == .anonymous
                )
                
                print("✅ PostPopup - Post created successfully")
                
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
                self.isPresented = false
                self.postText = ""
                self.selectedImageData = Optional<Data>.none
                self.showPrivacySelection = false
            } catch {
                print("❌ PostPopup - Error creating post: \(error)")
                self.errorMessage = "投稿の作成に失敗しました: \(error.localizedDescription)"
                self.showError = true
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showPrivacySelection = false
                }
            }
        }
    }
    
    private func checkCameraPermissionAndOpen() {
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthStatus {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showingCamera = true
                    } else {
                        self.showingCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showingCameraPermissionAlert = true
            }
        @unknown default:
            DispatchQueue.main.async {
                self.showingCameraPermissionAlert = true
            }
        }
    }
    
    private func getCurrentLocationAndMoveMap() {
        print("📍 PostPopup - Location button tapped, getting current location")
        locationManager.requestLocationPermission()
        
        if let currentLocation = locationManager.location {
            print("✅ PostPopup - Got current location: \(currentLocation.latitude), \(currentLocation.longitude)")
            mapManager.focusOnLocation(currentLocation)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.postLocation = self.mapManager.region.center
                self.updateAreaLocation(for: self.mapManager.region.center)
            }
        } else {
            print("🔄 PostPopup - Requesting location update...")
            locationManager.requestLocationUpdate { location in
                if let location = location {
                    print("✅ PostPopup - Got location update: \(location.latitude), \(location.longitude)")
                    self.mapManager.focusOnLocation(location)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.postLocation = self.mapManager.region.center
                        self.updateAreaLocation(for: self.mapManager.region.center)
                    }
                } else {
                    print("❌ PostPopup - Failed to get location")
                    self.areaName = "位置情報を取得できません"
                }
            }
        }
    }
    
    private func updatePostLocation() {
        print("🗺️ PostPopup - Using map center for post: \(mapManager.region.center.latitude), \(mapManager.region.center.longitude)")
        postLocation = mapManager.region.center
        updateAreaLocation(for: mapManager.region.center)
    }
    
    private func updateAreaLocation(for coordinate: CLLocationCoordinate2D) {
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = "\(coordinate.latitude),\(coordinate.longitude)"
                request.resultTypes = [.address]
                
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                if let mapItem = response.mapItems.first {
                    DispatchQueue.main.async {
                        var components: [String] = []
                        
                        if let name = mapItem.name {
                            let cleanedName = name
                                .replacingOccurrences(of: #"[0-9]+-[0-9]+.*"#, with: "", options: .regularExpression)
                                .replacingOccurrences(of: #"[0-9]+番地.*"#, with: "", options: .regularExpression)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if !cleanedName.isEmpty {
                                components.append(cleanedName)
                            }
                        }
                        
                        if components.isEmpty {
                            components.append("Near Current Location")
                        }
                        
                        self.areaName = components.prefix(2).joined(separator: " ")
                        
                        if self.areaName.isEmpty {
                            self.areaName = "不明な場所"
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.areaName = "位置情報を取得できませんでした"
                }
            }
        }
    }
}

// Triangle shape for speech bubble
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - PostLocationManager for PostPopup
class PostLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var locationUpdateCompletion: ((CLLocationCoordinate2D?) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    func requestLocationUpdate(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        locationUpdateCompletion = completion
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        } else if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            completion(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.location = location.coordinate
            self.locationUpdateCompletion?(location.coordinate)
            self.locationUpdateCompletion = nil
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationUpdateCompletion?(nil)
        locationUpdateCompletion = nil
    }
}