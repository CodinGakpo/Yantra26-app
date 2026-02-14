//
//  LandingView.swift
//  JanSaathi2
//
//  Landing/Welcome screen
//

import SwiftUI

struct LandingView: View {
    @Binding var showLogin: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                // Hero Section
                VStack(spacing: 24) {
                    // Logo
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .padding(.top, 60)
                    
                    Text("JanSaathi")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your Voice, Your City, Your Platform")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("Report civic issues, track progress in real-time, and be part of making your community better.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: { showLogin = true }) {
                        HStack {
                            Text("Get Started")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(Theme.Colors.emerald600)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 80)
                .background(Theme.Gradients.heroGradient)
                
                // Stats Section
                VStack(spacing: 32) {
                    Text("Platform Impact")
                        .font(.title2.bold())
                        .foregroundColor(Theme.Colors.gray900)
                        .padding(.top, 40)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 24) {
                        StatCard(
                            icon: "checkmark.circle.fill",
                            value: "15K+",
                            label: "Issues Resolved",
                            color: Theme.Colors.emerald600
                        )
                        StatCard(
                            icon: "person.3.fill",
                            value: "50K+",
                            label: "Active Citizens",
                            color: Theme.Colors.emerald600
                        )
                        StatCard(
                            icon: "clock.fill",
                            value: "48hrs",
                            label: "Avg Response Time",
                            color: Theme.Colors.emerald700
                        )
                        StatCard(
                            icon: "chart.line.uptrend.xyaxis",
                            value: "94%",
                            label: "Success Rate",
                            color: Theme.Colors.emerald500
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
                
                // Features Section
                VStack(spacing: 32) {
                    Text("How It Works")
                        .font(.title2.bold())
                        .foregroundColor(Theme.Colors.gray900)
                    
                    VStack(spacing: 24) {
                        FeatureRow(
                            icon: "camera.fill",
                            title: "Report Issues",
                            description: "Snap a photo of civic problems in your area - potholes, broken streets, garbage, or any infrastructure issue."
                        )
                        FeatureRow(
                            icon: "magnifyingglass",
                            title: "Track Progress",
                            description: "Get real-time updates on your reports. Track when authorities acknowledge and resolve issues."
                        )
                        
                        FeatureRow(
                            icon: "person.2.fill",
                            title: "Community Impact",
                            description: "See what others are reporting. Join forces to highlight urgent problems in your neighborhood."
                        )
                        
                        FeatureRow(
                            icon: "checkmark.shield.fill",
                            title: "Verified Action",
                            description: "Blockchain-verified reports ensure transparency. Your voice is recorded immutably and securely."
                        )
                    }
                    .padding(.horizontal)
                }
                    .padding(.bottom, 60)
                }
                .frame(minHeight: geometry.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(Theme.Colors.gray900)
            
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.Colors.gray600)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.emerald600)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.Colors.gray900)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.gray600)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
    LandingView(showLogin: .constant(false))
}
