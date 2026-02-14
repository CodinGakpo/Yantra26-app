//
//  AuthManager.swift
//  JanSaathi2
//
//  Authentication manager
//

import Foundation
import SwiftUI
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var accessToken: String?
    
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    
    var isLoggedIn: Bool {
        return isAuthenticated && accessToken != nil
    }
    
    private init() {
        // Check if user is already logged in
        if let token = UserDefaults.standard.string(forKey: accessTokenKey) {
            self.accessToken = token
            self.isAuthenticated = true
            
            // Load current user
            Task {
                try? await loadCurrentUser()
            }
        }
    }
    
    func login(email: String, password: String) async throws {
        let response = try await NetworkManager.shared.login(email: email, password: password)
        
        await MainActor.run {
            saveTokens(access: response.access, refresh: response.refresh)
            self.currentUser = response.user
        }
    }
    
    func register(email: String, password: String, confirmPassword: String) async throws {
        let response = try await NetworkManager.shared.register(email: email, password: password, confirmPassword: confirmPassword)
        
        await MainActor.run {
            saveTokens(access: response.access, refresh: response.refresh)
            self.currentUser = response.user
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        self.accessToken = nil
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    func loadCurrentUser() async throws {
        let user = try await NetworkManager.shared.getCurrentUser()
        await MainActor.run {
            self.currentUser = user
        }
    }
    
    func requestOTP(email: String) async throws {
        try await NetworkManager.shared.requestOTP(email: email)
    }
    
    func verifyOTP(email: String, otp: String) async throws {
        let response = try await NetworkManager.shared.verifyOTP(email: email, otp: otp)
        
        await MainActor.run {
            saveTokens(access: response.access, refresh: response.refresh)
            self.currentUser = response.user
        }
    }
    
    func googleAuth(token: String) async throws {
        let response = try await NetworkManager.shared.googleAuth(token: token)
        
        await MainActor.run {
            saveTokens(access: response.access, refresh: response.refresh)
            self.currentUser = response.user
        }
    }
    
    private func saveTokens(access: String, refresh: String) {
        UserDefaults.standard.set(access, forKey: accessTokenKey)
        UserDefaults.standard.set(refresh, forKey: refreshTokenKey)
        self.accessToken = access
        self.isAuthenticated = true
    }
}
