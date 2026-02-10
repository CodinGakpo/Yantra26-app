//
//  ProfileView.swift
//  NagrikMitra2
//
//  User profile screen
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var profile: UserProfile?
    @State private var reports: [Report] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Theme.Gradients.emeraldGradient)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(getInitials())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(spacing: 4) {
                            Text(authManager.currentUser?.username ?? "User")
                                .font(.title2.bold())
                                .foregroundColor(Theme.Colors.gray900)
                            
                            Text(authManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.gray600)
                        }
                        
                        if let profile = profile {
                            HStack(spacing: 8) {
                                Image(systemName: profile.isAadhaarVerified ? "checkmark.seal.fill" : "xmark.seal.fill")
                                    .foregroundColor(profile.isAadhaarVerified ? .green : .orange)
                                
                                Text(profile.isAadhaarVerified ? "Verified User" : "Not Verified")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.Colors.gray700)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.Colors.emerald50)
                            .cornerRadius(20)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.surface)
                    
                    // Stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatBox(icon: "flag.fill", value: "\(reports.count)", label: "Reports")
                        StatBox(icon: "checkmark.circle.fill", value: "\(resolvedCount)", label: "Resolved")
                        StatBox(icon: "clock.fill", value: "\(pendingCount)", label: "Pending")
                        StatBox(icon: "chart.line.uptrend.xyaxis", value: "\(successRate)%", label: "Success")
                    }
                    .padding(.horizontal)
                    
                    // Recent Reports
                    VStack(alignment: .leading, spacing: 16) {
                        Text("My Reports")
                            .font(.title3.bold())
                            .foregroundColor(Theme.Colors.gray900)
                            .padding(.horizontal)
                        
                        if reports.isEmpty && !isLoading {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 50))
                                    .foregroundColor(Theme.Colors.gray400)
                                
                                Text("No reports yet")
                                    .font(.headline)
                                    .foregroundColor(Theme.Colors.gray600)
                                
                                Text("Submit your first report to get started!")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.Colors.gray500)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                            .background(Theme.Colors.surface)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        } else {
                            ForEach(reports) { report in
                                ReportHistoryCard(report: report)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Logout Button
                    Button(action: { authManager.logout() }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.error.opacity(0.1))
                        .foregroundColor(Theme.Colors.error)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func getInitials() -> String {
        if let username = authManager.currentUser?.username {
            return String(username.prefix(2).uppercased())
        } else if let email = authManager.currentUser?.email {
            return String(email.prefix(2).uppercased())
        }
        return "U"
    }
    
    private var resolvedCount: Int {
        reports.filter { $0.status.lowercased() == "resolved" }.count
    }
    
    private var pendingCount: Int {
        reports.filter { $0.status.lowercased() == "pending" }.count
    }
    
    private var successRate: Int {
        guard !reports.isEmpty else { return 0 }
        return (resolvedCount * 100) / reports.count
    }
    
    private func loadData() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            async let profileTask = NetworkManager.shared.getUserProfile()
            async let reportsTask = NetworkManager.shared.getUserHistory()
            
            let (loadedProfile, loadedReports) = try await (profileTask, reportsTask)
            
            await MainActor.run {
                profile = loadedProfile
                reports = loadedReports
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
}

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.emerald600)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(Theme.Colors.gray900)
            
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.Colors.gray600)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct ReportHistoryCard: View {
    let report: Report
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusBadge(status: report.status)
                Spacer()
                Text(formatDate(report.createdAt))
                    .font(.caption)
                    .foregroundColor(Theme.Colors.gray500)
            }
            
            Text(report.issueTitle)
                .font(.subheadline.bold())
                .foregroundColor(Theme.Colors.gray900)
            
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.emerald600)
                
                Text(report.location)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.gray600)
            }
        }
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        
        return outputFormatter.string(from: date)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
