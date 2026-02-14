//
//  CommunityView.swift
//  JanSaathi2
//
//  Community feed of resolved issues
//

import SwiftUI

struct CommunityView: View {
    @State private var reports: [Report] = []
    @State private var isLoading = false
    @State private var nextUrl: String?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.Colors.emerald600)
                        
                        Text("Community Feed")
                            .font(.title2.bold())
                            .foregroundColor(Theme.Colors.gray900)
                        
                        Text("See what issues have been resolved in your area")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.gray600)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.surface)
                    
                    // Feed
                    if reports.isEmpty && !isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.Colors.gray400)
                            
                            Text("No reports yet")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.gray600)
                            
                            Text("Be the first to report an issue!")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.gray500)
                        }
                        .padding(40)
                    } else {
                        ForEach(reports) { report in
                            CommunityReportCard(report: report)
                                .padding(.horizontal)
                        }
                        
                        // Load more
                        if nextUrl != nil {
                            Button(action: loadMore) {
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Text("Load More")
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .padding(.vertical)
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await refresh()
            }
            .task {
                await loadInitial()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadInitial() async {
        guard reports.isEmpty else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let response = try await NetworkManager.shared.getCommunityPosts()
            await MainActor.run {
                reports = response.results
                nextUrl = response.next
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
    
    private func refresh() async {
        do {
            let response = try await NetworkManager.shared.getCommunityPosts()
            await MainActor.run {
                reports = response.results
                nextUrl = response.next
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func loadMore() {
        guard let nextUrl = nextUrl, !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                let response = try await NetworkManager.shared.getCommunityPosts(nextUrl: nextUrl)
                await MainActor.run {
                    reports.append(contentsOf: response.results)
                    self.nextUrl = response.next
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
}

struct CommunityReportCard: View {
    let report: Report
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status
            HStack {
                StatusBadge(status: report.status)
                Spacer()
                Text(formatDate(report.updatedAt))
                    .font(.caption)
                    .foregroundColor(Theme.Colors.gray500)
            }
            
            // Title
            Text(report.issueTitle)
                .font(.headline)
                .foregroundColor(Theme.Colors.gray900)
            
            // Location
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Theme.Colors.emerald600)
                    .font(.caption)
                
                Text(report.location)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.gray700)
            }
            
            // Description
            if let description = report.issueDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.gray600)
                    .lineLimit(3)
            }
            
            // Image
            if let imageUrl = report.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.gray200)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            ProgressView()
                        )
                }
            }
        }
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = RelativeDateTimeFormatter()
        outputFormatter.unitsStyle = .abbreviated
        
        return outputFormatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    CommunityView()
}
