//
//  MainTabView.swift
//  NagrikMitra2
//
//  Main tab navigation
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogin = false
    
    var body: some View {
        ZStack {
            if authManager.isAuthenticated {
                TabView {
                    ReportView()
                        .tabItem {
                            Label("Report", systemImage: "exclamationmark.bubble.fill")
                        }
                    
                    TrackView()
                        .tabItem {
                            Label("Track", systemImage: "magnifyingglass")
                        }
                    
                    CommunityView()
                        .tabItem {
                            Label("Community", systemImage: "person.3.fill")
                        }
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
                .accentColor(Theme.Colors.emerald600)
            } else {
                LandingView(showLogin: $showLogin)
                    .sheet(isPresented: $showLogin) {
                        LoginView()
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all, edges: .all)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
}
