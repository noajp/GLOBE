import SwiftUI
import Combine

struct AuthenticationView: View {
    @State private var showingSignUp = false
    @State private var showingSignIn = false
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var authManager = AuthManager.shared
    
    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    private let accentColor = Color(hex: "FF6B6B")
    
    var body: some View {
        ZStack {
            // シンプルな黒背景
            customBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 60)
                
                // シンプルなヘッダー
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                
                // ロゴエリア - Liquid Glass Card
                VStack(spacing: 12) {
                    // シンプルなGLOBEロゴ
                    Text("GLOBE")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text("Connect with the World")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)
                }
                .padding(.bottom, 80)
                
                Spacer()
                
                // ボタンレイアウト
                VStack(spacing: 16) {
                    // サインアップボタン（メイン）
                    Button(action: {
                        showingSignIn = false
                        showingSignUp = true
                    }) {
                        Text("Create Account")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(customBlack)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(.white)
                            .cornerRadius(26)
            
                    }
                    
                    // ログインボタン（セカンダリ）
                    Button(action: {
                        showingSignUp = false
                        showingSignIn = true
                    }) {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 26)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
            
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                
                // フッター
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
        }
            .sheet(isPresented: $showingSignUp) { SignUpView() }
            .sheet(isPresented: $showingSignIn) { SignInView() }
            .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
    }
}



#Preview {
    AuthenticationView()
}
