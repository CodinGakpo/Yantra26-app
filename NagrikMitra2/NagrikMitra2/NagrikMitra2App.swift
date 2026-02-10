//
//  NagrikMitra2App.swift
//  NagrikMitra2
//
//  Created by Avadhoot Ganesh Mahadik on 10/02/26.
//

import SwiftUI

@main
struct NagrikMitra2App: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(authManager)
        }
    }
}
