//
//  LoginView.swift
//  NagrikMitra2
//
//  Login and registration screen
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Background gradient
            Theme.Gradients.heroGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("NagrikMitra")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Text(isLogin ? "Welcome Back" : "Create Your Account")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 60)
                    
                    // Form
                    VStack(spacing: 20) {
                        FormField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        FormField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true
                        )
                        
                        if !isLogin {
                            FormField(
                                icon: "lock.fill",
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                isSecure: true
                            )
                        }
                        
                        Button(action: handleAuth) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isLogin ? "Login" : "Register")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.Colors.emerald600)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
                        
                        Button(action: { withAnimation { isLogin.toggle() } }) {
                            HStack {
                                Text(isLogin ? "Don't have an account?" : "Already have an account?")
                                    .foregroundColor(.white.opacity(0.8))
                                Text(isLogin ? "Register" : "Login")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && (isLogin || (!confirmPassword.isEmpty && password == confirmPassword))
    }
    
    private func handleAuth() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isLogin {
                    try await authManager.login(email: email, password: password)
                } else {
                    try await authManager.register(email: email, password: password, confirmPassword: confirmPassword)
                }
            } catch {
                // For demo: silently continue even on error
                print("Registration error (continuing): \(error.localizedDescription)")
            }
            
            // Always proceed to next page
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct FormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.gray600)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
            }
        }
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(12)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
