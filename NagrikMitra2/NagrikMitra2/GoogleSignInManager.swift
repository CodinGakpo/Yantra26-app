//
//  GoogleSignInManager.swift
//  JanSaathi2
//
//  Google Sign-In helper manager
//

import SwiftUI
import GoogleSignIn

class GoogleSignInManager {
    static let shared = GoogleSignInManager()
    
    private init() {}
    
    /// Configure Google Sign-In with client ID from Info.plist
    func configure() {
        guard let clientID = getClientID() else {
            print("⚠️ Google Sign-In: Client ID not found in Info.plist")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    /// Sign in with Google and return ID token
    func signIn() async throws -> String {
        guard let presentingViewController = getRootViewController() else {
            throw GoogleSignInError.noViewController
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleSignInError.noIDToken
        }
        
        return idToken
    }
    
    /// Sign out from Google
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    
    /// Handle URL callback from Google Sign-In
    func handleURL(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    /// Restore previous sign-in if available
    func restorePreviousSignIn() async throws -> String? {
        guard GIDSignIn.sharedInstance.hasPreviousSignIn() else {
            return nil
        }
        
        let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
        return user.idToken?.tokenString
    }
    
    // MARK: - Private Helpers
    
    private func getClientID() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String
    }
    
    @MainActor
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        
        // Get the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        return topController
    }
}

// MARK: - Errors

enum GoogleSignInError: LocalizedError {
    case noViewController
    case noIDToken
    case signInCancelled
    case configurationMissing
    
    var errorDescription: String? {
        switch self {
        case .noViewController:
            return "Could not find view controller for sign in"
        case .noIDToken:
            return "Failed to get ID token from Google"
        case .signInCancelled:
            return "Sign in was cancelled"
        case .configurationMissing:
            return "Google Sign-In is not properly configured. Please check your client ID."
        }
    }
}
