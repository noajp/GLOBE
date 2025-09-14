import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            var selectedImage: UIImage?
            
            if let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
                print("📷 CameraView - Using edited image")
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImage = originalImage
                print("📷 CameraView - Using original image")
            }
            
            if let image = selectedImage {
                // 画像を正しい向きで保存（fixOrientationメソッドがない場合は直接使用）
                let imageData = image.jpegData(compressionQuality: 0.8)
                print("📷 CameraView - Image selected, size: \(imageData?.count ?? 0) bytes")
                
                // メインスレッドで状態更新
                DispatchQueue.main.async {
                    print("📷 CameraView - Setting selectedImageData: \(imageData?.count ?? 0) bytes")
                    self.parent.selectedImageData = imageData
                    print("📷 CameraView - Dismissing camera view")
                    self.parent.dismiss()
                }
            } else {
                print("❌ CameraView - No image found in info")
                parent.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}