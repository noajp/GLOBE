import SwiftUI
import CoreLocation
import Combine
import MapKit
import AVFoundation

struct CreatePostView: View {
    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    @Binding var isPresented: Bool
    @ObservedObject var mapManager: MapManager
    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var postManager = PostManager.shared
    
    @State private var postText = ""
    @State private var selectedImageData: Data?
    @State private var showingLocationError = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingCamera = false
    @State private var showingCameraPermissionAlert = false
    @State private var capturedUIImage: UIImage?
    @State private var displayLocation: CLLocationCoordinate2D?
    @State private var areaName: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                createHeader()
                createMainPostSection()
                createLocationSection()
                Spacer()
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            locationManager.requestLocationPermission()
            // 少し遅延してから位置情報更新を開始
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                updateAreaLocation()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LocationUpdated"))) { _ in
            updateAreaLocation()
        }
        .onChange(of: selectedImageData) {
            // selectedImageDataが更新されたときの処理
        }
        .alert("位置情報エラー", isPresented: $showingLocationError) {
            Button("OK") {}
        } message: {
            Text("位置情報を取得できませんでした。設定から位置情報の使用を許可してください。")
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .alert("カメラへのアクセス", isPresented: $showingCameraPermissionAlert) {
            Button("設定を開く") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("カメラを使用するには、設定からカメラへのアクセスを許可してください。")
        }
    }
    
    private func createHeader() -> some View {
        HStack {
            Button("キャンセル") {
                isPresented = false
            }
            .foregroundColor(.white)
            
            Spacer()
            
            Text("新規投稿")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("投稿") {
                createPost()
            }
            .foregroundColor(postText.isEmpty ? .gray : .white)
            .disabled(postText.isEmpty)
        }
        .padding()
        .background(customBlack)
    }
    
    private func createMainPostSection() -> some View {
        VStack(spacing: 0) {
            // 写真プレビューエリア（写真がある場合のみ表示）
            if let selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                ZStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                    
                    // 削除ボタン
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                self.selectedImageData = nil
                                self.capturedUIImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(customBlack.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }
                .frame(height: 200)
            }
            
            // テキスト入力エリア
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("何を投稿しますか？")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // カメラボタン
                    Button(action: {
                        checkCameraPermissionAndOpen()
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // テキスト入力
                ScrollView {
                    TextEditor(text: $postText)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal)
                        .frame(minHeight: selectedImageData != nil ? 100 : 200)
                }
                .background(Color(UIColor.systemGray6).opacity(0.3))
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(selectedImageData: $selectedImageData)
                .ignoresSafeArea()
        }
    }
    
    private func createLocationSection() -> some View {
        HStack {
            Image(systemName: displayLocation != nil ? "location.fill" : "location.slash")
                .foregroundColor(displayLocation != nil ? .blue : .gray)
                .font(.system(size: 14))
            
            Text(areaName.isEmpty ? "エリアを取得中..." : areaName)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
    }
    
    
    private func createPost() {
        Task {
            // 位置情報がない場合はデフォルト位置（東京駅）を使用
            let location = displayLocation ?? locationManager.location ?? CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
            
            // セキュリティ検証: コンテンツ
            let contentValidation = InputValidator.validatePostContent(postText)
            guard contentValidation.isValid, let validContent = contentValidation.value else {
                errorMessage = contentValidation.errorMessage ?? "Invalid post content"
                showError = true
                SecureLogger.shared.securityEvent("Invalid post content", details: ["reason": contentValidation.errorMessage ?? "unknown"])
                return
            }
            
            // セキュリティ検証: 位置情報
            let locationValidation = InputValidator.validateLocationSafety(latitude: location.latitude, longitude: location.longitude)
            guard locationValidation.isValid else {
                errorMessage = locationValidation.errorMessage ?? "Invalid location"
                showError = true
                SecureLogger.shared.securityEvent("Invalid post location", details: [
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                    "reason": locationValidation.errorMessage ?? "unknown"
                ])
                return
            }
            
            do {
                SecureLogger.shared.info("Creating post with enhanced security validation")
                
                // Save to Supabase
                try await postManager.createPost(
                    content: validContent, // 検証済みコンテンツを使用
                    imageData: selectedImageData,
                    location: location,
                    locationName: areaName.isEmpty ? nil : areaName
                )
                
                SecureLogger.shared.info("Post created successfully with security validation")
                
                // Dismiss keyboard before closing view
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
                // Small delay to ensure keyboard dismissal completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Add to local map view
                    // 投稿完了後の処理
                    // PostManagerが自動的にMapManagerと同期するため、追加の処理は不要
                    isPresented = false
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                SecureLogger.shared.error("Failed to create post: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkCameraPermission() {
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        self.showingCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showingCameraPermissionAlert = true
            }
        case .authorized:
            // Camera is authorized, ready to use
            break
        @unknown default:
            DispatchQueue.main.async {
                self.showingCameraPermissionAlert = true
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
    
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location.coordinate
        locationManager.stopUpdatingLocation()
        
        // Notify parent view to update area location
        NotificationCenter.default.post(name: NSNotification.Name("LocationUpdated"), object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}



// MARK: - Area Location Methods
extension CreatePostView {
    private func updateAreaLocation() {
        guard let location = locationManager.location else {
            return
        }
        
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        Task {
            do {
                // まず施設名・POI情報を検索
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = "\(clLocation.coordinate.latitude),\(clLocation.coordinate.longitude)"
                request.region = MKCoordinateRegion(center: clLocation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
                
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                // 大学・施設名を優先的に探す
                var bestLocationName = ""
                var bestCoordinate = clLocation.coordinate
                
                for mapItem in response.mapItems {
                    if let name = mapItem.name {
                        // 大学、病院、商業施設、駅などの重要な施設を優先
                        if name.contains("大学") || name.contains("University") || 
                           name.contains("病院") || name.contains("Hospital") ||
                           name.contains("駅") || name.contains("Station") ||
                           name.contains("空港") || name.contains("Airport") ||
                           name.contains("公園") || name.contains("Park") ||
                           name.contains("ショッピング") || name.contains("Mall") ||
                           name.contains("タワー") || name.contains("Tower") ||
                           name.contains("美術館") || name.contains("博物館") ||
                           name.contains("図書館") || name.contains("役所") {
                            bestLocationName = name
                            if #available(iOS 26.0, *) {
                                bestCoordinate = mapItem.location.coordinate
                            } else {
                                bestCoordinate = mapItem.placemark.coordinate
                            }
                            break
                        }
                    }
                }
                
                // 施設が見つからない場合は市町村名を取得
                if bestLocationName.isEmpty {
                    if #available(iOS 26.0, *) {
                        // iOS 26+ でもMKLocalSearchの逆ジオコーディングを使用（より安定）
                        let request = MKLocalSearch.Request()
                        request.naturalLanguageQuery = "\(clLocation.coordinate.latitude),\(clLocation.coordinate.longitude)"
                        request.region = MKCoordinateRegion(center: clLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
                        
                        let search = MKLocalSearch(request: request)
                        let reverseResponse = try await search.start()
                        
                        if let mapItem = reverseResponse.mapItems.first {
                            // iOS 26での新しいアプローチ
                            if #available(iOS 26.0, *) {
                                // 新しいAPIでplacemark以外の情報を優先的に使用
                                if let name = mapItem.name, !name.isEmpty {
                                    bestLocationName = name
                                } else {
                                    // フォールバックとして基本的な地域名を使用
                                    bestLocationName = "現在地周辺"
                                }
                            } else {
                                let placemark = mapItem.placemark
                                // 市区町村名を優先的に使用
                                if let city = placemark.locality {
                                    bestLocationName = city
                                } else if let subAdmin = placemark.subAdministrativeArea {
                                    bestLocationName = subAdmin
                                } else if let admin = placemark.administrativeArea {
                                    bestLocationName = admin
                                }
                            }
                            
                            // 市区町村の代表座標を設定
                            if let cityCenter = await getCityCenterCoordinate(cityName: bestLocationName) {
                                bestCoordinate = cityCenter
                            }
                        }
                    } else {
                        // iOS 25以下または26以上での逆ジオコーディング
                        let placemarks: [CLPlacemark]
                        
                        // iOS 26.0で非推奨になる予定ですが、現在利用可能な安定したAPIを使用
                        let geocoder = CLGeocoder()
                        // 非推奨警告を抑制（iOS 26.0で新しいAPIが利用可能になるまで）
                        placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
                        
                        if let placemark = placemarks.first {
                            // 市区町村名を優先的に使用
                            if let city = placemark.locality {
                                bestLocationName = city
                            } else if let subAdmin = placemark.subAdministrativeArea {
                                bestLocationName = subAdmin
                            } else if let admin = placemark.administrativeArea {
                                bestLocationName = admin
                            }
                            
                            // 市区町村の代表座標を設定（正確な位置ではなく、市区町村の中心部）
                            if let cityCenter = await getCityCenterCoordinate(cityName: bestLocationName) {
                                bestCoordinate = cityCenter
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    self.areaName = bestLocationName.isEmpty ? "現在地" : bestLocationName
                    self.displayLocation = bestCoordinate
                }
                
            } catch {
                await MainActor.run {
                    self.areaName = "現在地"
                    self.displayLocation = clLocation.coordinate
                }
            }
        }
    }
    
    private func getCityCenterCoordinate(cityName: String) async -> CLLocationCoordinate2D? {
        do {
            if #available(iOS 26.0, *) {
                // iOS 26+ でもMKLocalSearchを使用（より安定）
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = cityName
                
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                if #available(iOS 26.0, *) {
                    return response.mapItems.first?.location.coordinate
                } else {
                    return response.mapItems.first?.placemark.coordinate
                }
            } else {
                // iOS 25以下のレガシーAPI
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.geocodeAddressString(cityName)
                return placemarks.first?.location?.coordinate
            }
        } catch {
            return nil
        }
    }
}
