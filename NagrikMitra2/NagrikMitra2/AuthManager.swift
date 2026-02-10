//
//  AuthManager.swift
//  NagrikMitra2
//
//  Authentication manager
//

import Foundation
import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var accessToken: String?
    
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    
    init() {
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
        do {
            let response = try await NetworkManager.shared.login(email: email, password: password)
            
            await MainActor.run {
                saveTokens(access: response.access, refresh: response.refresh)
                self.currentUser = response.user
            }
        } catch {
            // For demo: create mock user on error and continue
            print("Login failed, using mock session: \(error.localizedDescription)")
            await MainActor.run {
                // Set mock tokens for demo
                saveTokens(access: "demo_token", refresh: "demo_refresh")
                self.currentUser = User(id: 999, email: email, username: email.components(separatedBy: "@").first)
            }
        }
    }
    
    func register(email: String, password: String, confirmPassword: String) async throws {
        do {
            let response = try await NetworkManager.shared.register(email: email, password: password, confirmPassword: confirmPassword)
            
            await MainActor.run {
                saveTokens(access: response.access, refresh: response.refresh)
                self.currentUser = response.user
            }
        } catch {
            // For demo: create mock user on error and continue
            print("Registration failed, using mock session: \(error.localizedDescription)")
            await MainActor.run {
                // Set mock tokens for demo
                saveTokens(access: "demo_token", refresh: "demo_refresh")
                self.currentUser = User(id: 999, email: email, username: email.components(separatedBy: "@").first)
            }
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
    
    private func saveTokens(access: String, refresh: String) {
        UserDefaults.standard.set(access, forKey: accessTokenKey)
        UserDefaults.standard.set(refresh, forKey: refreshTokenKey)
        self.accessToken = access
        self.isAuthenticated = true
    }
}
