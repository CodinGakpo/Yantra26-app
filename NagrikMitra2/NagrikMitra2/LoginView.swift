//
//  LoginView.swift
//  JanSaathi2
//
//  Login and registration screen
//

import SwiftUI
import GoogleSignIn

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
    
    // OTP Login
    @State private var showOTPLogin = false
    @State private var otpCode = ""
    @State private var otpSent = false
    
    // Auth method
    @State private var authMethod: AuthMethod = .emailPassword
    
    enum AuthMethod {
        case emailPassword
        case otp
    }
    
    var body: some View {
        GeometryReader { geometry in
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
                        
                        Text("JanSaathi")
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
                        
                        // Auth method toggle
                        if isLogin {
                            Button(action: { withAnimation { authMethod = authMethod == .emailPassword ? .otp : .emailPassword } }) {
                                Text(authMethod == .emailPassword ? "Login with OTP instead" : "Login with password instead")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        // OTP Section
                        if isLogin && authMethod == .otp {
                            if !otpSent {
                                Button(action: requestOTP) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "envelope.badge")
                                            Text("Send OTP")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.Colors.emerald600)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(isLoading || email.isEmpty)
                                .opacity((isLoading || email.isEmpty) ? 0.6 : 1.0)
                            } else {
                                FormField(
                                    icon: "number",
                                    placeholder: "Enter OTP",
                                    text: $otpCode,
                                    keyboardType: .numberPad
                                )
                                
                                Button(action: verifyOTP) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "checkmark.shield")
                                            Text("Verify OTP")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.Colors.emerald600)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(isLoading || otpCode.isEmpty)
                                .opacity((isLoading || otpCode.isEmpty) ? 0.6 : 1.0)
                            }
                        }
                        
                        // Regular login/register button
                        if authMethod == .emailPassword {
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
                        
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)
                        
                        // Google OAuth Button
                        Button(action: handleGoogleAuth) {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                Text(isLogin ? "Continue with Google" : "Sign up with Google")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Theme.Colors.gray900)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.6 : 1.0)
                        
                        Button(action: { withAnimation { isLogin.toggle(); authMethod = .emailPassword; otpSent = false } }) {
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
                    .frame(minHeight: geometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func requestOTP() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.requestOTP(email: email)
                await MainActor.run {
                    otpSent = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func verifyOTP() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.verifyOTP(email: email, otp: otpCode)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func handleGoogleAuth() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get ID token from Google Sign-In
                let idToken = try await GoogleSignInManager.shared.signIn()
                
                // Send token to backend
                try await authManager.googleAuth(token: idToken)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch let error as GoogleSignInError {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.errorDescription ?? "Google Sign-In failed"
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
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
