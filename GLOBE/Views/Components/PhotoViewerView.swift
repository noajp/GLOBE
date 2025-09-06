//======================================================================
// MARK: - PhotoViewerView.swift
// Purpose: Full-screen photo viewer for post images with simple controls
// Path: GLOBE/Views/Components/PhotoViewerView.swift
//======================================================================

import SwiftUI

struct PhotoViewerView: View {
    let image: UIImage?
    let imageURL: URL?
    let onClose: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastDrag: CGSize = .zero

    init(image: UIImage, onClose: @escaping () -> Void) {
        self.image = image
        self.imageURL = nil
        self.onClose = onClose
    }

    init(imageURL: URL, onClose: @escaping () -> Void) {
        self.image = nil
        self.imageURL = imageURL
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if let ui = image {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                } else if let url = imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFit()
                        case .failure(_):
                            placeholder
                        case .empty:
                            ProgressView().tint(.white)
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .scaleEffect(scale)
            .offset(offset)
            .gesture(magnification)
            .gesture(pan)

            // Close button
            VStack {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .font(.system(size: 48))
            .foregroundColor(.white.opacity(0.6))
    }

    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                scale = max(1.0, min(3.0, scale * delta))
                lastScale = value
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }

    private var pan: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(width: lastDrag.width + value.translation.width,
                                height: lastDrag.height + value.translation.height)
            }
            .onEnded { _ in
                lastDrag = offset
            }
    }
}

