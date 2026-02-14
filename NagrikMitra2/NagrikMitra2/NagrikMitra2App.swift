//
//  JanSaathi2App.swift
//  JanSaathi2
//
//  Created by Avadhoot Ganesh Mahadik on 10/02/26.
//

import SwiftUI
import GoogleSignIn

@main
struct NagrikMitra2App: App {
    @ObservedObject private var authManager = AuthManager.shared
    
    init() {
        // Configure Google Sign-In on app launch
        GoogleSignInManager.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    // Handle Google Sign-In callback URL
                    _ = GoogleSignInManager.shared.handleURL(url)
                }
        }
    }
}
