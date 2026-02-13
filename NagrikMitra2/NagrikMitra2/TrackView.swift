//
//  TrackView.swift
//  NagrikMitra2
//
//  Track report status screen
//

import SwiftUI

struct TrackView: View {
    @State private var trackingId = ""
    @State private var report: Report?
    @State private var isSearching = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.Colors.emerald600)
                        
                        Text("Track Your Report")
                            .font(.title2.bold())
                            .foregroundColor(Theme.Colors.gray900)
                        
                        Text("Enter your tracking ID to view report status")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.gray600)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Search
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "number")
                                .foregroundColor(Theme.Colors.gray600)
                            
                            TextField("Enter Tracking ID", text: $trackingId)
                                .autocapitalization(.none)
                            
                            if !trackingId.isEmpty {
                                Button(action: { trackingId = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Theme.Colors.gray400)
                                }
                            }
                        }
                        .padding()
                        .background(Theme.Colors.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.gray300, lineWidth: 1)
                        )
                        
                        Button(action: searchReport) {
                            HStack {
                                if isSearching {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "magnifyingglass")
                                    Text("Search")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(trackingId.isEmpty ? Theme.Colors.gray300 : Theme.Colors.emerald600)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(trackingId.isEmpty || isSearching)
                    }
                    .padding()
                    .background(Theme.Colors.surface)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    .padding()
                    
                    // Results
                    if let report = report {
                        ReportDetailCard(report: report)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func searchReport() {
        isSearching = true
        
        Task {
            do {
                let foundReport = try await NetworkManager.shared.getReportByTrackingId(trackingId)
                await MainActor.run {
                    report = foundReport
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSearching = false
                }
            }
        }
    }
}

struct ReportDetailCard: View {
    let report: Report
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Status Badge
            HStack {
                Spacer()
                StatusBadge(status: report.status)
            }
            
            // Title
            Text(report.issueTitle)
                .font(.title3.bold())
                .foregroundColor(Theme.Colors.gray900)
            
            // Details
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(icon: "mappin.circle.fill", label: "Location", value: report.location)
                
                if let description = report.issueDescription {
                    DetailRow(icon: "doc.text.fill", label: "Description", value: description)
                }
                
                if let trackingId = report.trackingId {
                    DetailRow(icon: "number", label: "Tracking ID", value: trackingId)
                }
                
                DetailRow(icon: "calendar", label: "Reported", value: formatDate(report.createdAt))
                DetailRow(icon: "clock", label: "Updated", value: formatDate(report.updatedAt))
            }
            
            // Image
            if let imageUrl = report.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                } placeholder: {
                    ProgressView()
                        .frame(height: 200)
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
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        outputFormatter.timeStyle = .short
        
        return outputFormatter.string(from: date)
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.emerald600)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.gray600)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.gray900)
            }
        }
    }
}

struct StatusBadge: View {
    let status: String
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "resolved":
            return .green
        case "in_progress", "in progress":
            return .orange
        case "pending":
            return .green
        default:
            return .gray
        }
    }
    
    var body: some View {
        Text(status.capitalized.replacingOccurrences(of: "_", with: " "))
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(20)
    }
}

#Preview {
    TrackView()
}
