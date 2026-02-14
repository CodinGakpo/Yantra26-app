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
    @State private var selectedReport: Report?
    @State private var showDetailsView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.Colors.emerald600)
                            .symbolEffect(.pulse)
                        
                        Text("Community Updates")
                            .font(.title.bold())
                            .foregroundColor(Theme.Colors.gray900)
                        
                        Text("Success Stories of Civic Impact")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.emerald700)
                        
                        Text("See what issues have been resolved in your area")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.gray600)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(checkmark.seal.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.Colors.emerald400)
                            
                            Text("No resolved issues yet")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.gray600)
                            
                            Text("Check back soon for success stories!")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.gray500)
                        }
                        .padding(40)
                    } else {
                        ForEach(reports) { report in
                            CommunityPostCard(
                                report: report,
                                onTap: {
                                    selectedReport = report
                                    showDetailsView = true
                                },
                                onLike: { await handleLike(report: report) },
                                onDislike: { await handleDislike(report: report) }
                            )
                                .padding(.horizontal)
                        }
                        
                        // Load more indicator
                        if nextUrl != nil {
                            if isLoading {
                                ProgressView()
                                    .padding()
                            } else {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        loadMore()
                                    }
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
            .sheet(isPresented: $showDetailsView) {
                if let report = selectedReport {
                    PostDetailsView(report: report)
                }
            }
        }
    }
    
    private func handleLike(report: Report) async {
        guard AuthManager.shared.isLoggedIn,
              let index = reports.firstIndex(where: { $0.id == report.id }) else { return }
        
        // Optimistic update
        var updatedReport = reports[index]
        let wasLiked = updatedReport.isLiked ?? false
        let wasDisliked = updatedReport.isDisliked ?? false
        
        updatedReport = Report(
            id: updatedReport.id,
            user: updatedReport.user,
            issueTitle: updatedReport.issueTitle,
            location: updatedReport.location,
            issueDescription: updatedReport.issueDescription,
            imageUrl: updatedReport.imageUrl,
            completionUrl: updatedReport.completionUrl,
            issueDate: updatedReport.issueDate,
            status: updatedReport.status,
            updatedAt: updatedReport.updatedAt,
            trackingId: updatedReport.trackingId,
            department: updatedReport.department,
            confidenceScore: updatedReport.confidenceScore,
            allocatedTo: updatedReport.allocatedTo,
            userName: updatedReport.userName,
            username: updatedReport.username,
            likesCount: wasLiked ? (updatedReport.likesCount ?? 1) - 1 : (updatedReport.likesCount ?? 0) + 1,
            dislikesCount: wasDisliked ? (updatedReport.dislikesCount ?? 1) - 1 : updatedReport.dislikesCount,
            commentsCount: updatedReport.commentsCount,
            isLiked: !wasLiked,
            isDisliked: wasDisliked ? false : updatedReport.isDisliked,
            appealStatus: updatedReport.appealStatus,
            trustScoreDelta: updatedReport.trustScoreDelta,
            likes: updatedReport.likes,
            dislikes: updatedReport.dislikes
        )
        
        await MainActor.run {
            reports[index] = updatedReport
        }
        
        do {
            let response = try await NetworkManager.shared.likeReport(reportId: report.id)
            await MainActor.run {
                var finalReport = reports[index]
                finalReport = Report(
                    id: finalReport.id,
                    user: finalReport.user,
                    issueTitle: finalReport.issueTitle,
                    location: finalReport.location,
                    issueDescription: finalReport.issueDescription,
                    imageUrl: finalReport.imageUrl,
                    completionUrl: finalReport.completionUrl,
                    issueDate: finalReport.issueDate,
                    status: finalReport.status,
                    updatedAt: finalReport.updatedAt,
                    trackingId: finalReport.trackingId,
                    department: finalReport.department,
                    confidenceScore: finalReport.confidenceScore,
                    allocatedTo: finalReport.allocatedTo,
                    userName: finalReport.userName,
                    username: finalReport.username,
                    likesCount: response.likesCount,
                    dislikesCount: response.dislikesCount,
                    commentsCount: finalReport.commentsCount,
                    isLiked: response.liked,
                    isDisliked: response.disliked,
                    appealStatus: finalReport.appealStatus,
                    trustScoreDelta: finalReport.trustScoreDelta,
                    likes: finalReport.likes,
                    dislikes: finalReport.dislikes
                )
                reports[index] = finalReport
            }
        } catch {
            // Rollback on error
            await MainActor.run {
                reports[index] = report
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleDislike(report: Report) async {
        guard AuthManager.shared.isLoggedIn,
              let index = reports.firstIndex(where: { $0.id == report.id }) else { return }
        
        // Optimistic update
        var updatedReport = reports[index]
        let wasLiked = updatedReport.isLiked ?? false
        let wasDisliked = updatedReport.isDisliked ?? false
        
        updatedReport = Report(
            id: updatedReport.id,
            user: updatedReport.user,
            issueTitle: updatedReport.issueTitle,
            location: updatedReport.location,
            issueDescription: updatedReport.issueDescription,
            imageUrl: updatedReport.imageUrl,
            completionUrl: updatedReport.completionUrl,
            issueDate: updatedReport.issueDate,
            status: updatedReport.status,
            updatedAt: updatedReport.updatedAt,
            trackingId: updatedReport.trackingId,
            department: updatedReport.department,
            confidenceScore: updatedReport.confidenceScore,
            allocatedTo: updatedReport.allocatedTo,
            userName: updatedReport.userName,
            username: updatedReport.username,
            likesCount: wasLiked ? (updatedReport.likesCount ?? 1) - 1 : updatedReport.likesCount,
            dislikesCount: wasDisliked ? (updatedReport.dislikesCount ?? 1) - 1 : (updatedReport.dislikesCount ?? 0) + 1,
            commentsCount: updatedReport.commentsCount,
            isLiked: wasLiked ? false : updatedReport.isLiked,
            isDisliked: !wasDisliked,
            appealStatus: updatedReport.appealStatus,
            trustScoreDelta: updatedReport.trustScoreDelta,
            likes: updatedReport.likes,
            dislikes: updatedReport.dislikes
        )
        
        await MainActor.run {
            reports[index] = updatedReport
        }
        
        do {
            let response = try await NetworkManager.shared.dislikeReport(reportId: report.id)
            await MainActor.run {
                var finalReport = reports[index]
                finalReport = Report(
                    id: finalReport.id,
                    user: finalReport.user,
                    issueTitle: finalReport.issueTitle,
                    location: finalReport.location,
                    issueDescription: finalReport.issueDescription,
                    imageUrl: finalReport.imageUrl,
                    completionUrl: finalReport.completionUrl,
                    issueDate: finalReport.issueDate,
                    status: finalReport.status,
                    updatedAt: finalReport.updatedAt,
                    trackingId: finalReport.trackingId,
                    department: finalReport.department,
                    confidenceScore: finalReport.confidenceScore,
                    allocatedTo: finalReport.allocatedTo,
                    userName: finalReport.userName,
                    username: finalReport.username,
                    likesCount: response.likesCount,
                    dislikesCount: response.dislikesCount,
                    commentsCount: finalReport.commentsCount,
                    isLiked: response.liked,
                    isDisliked: response.disliked,
                    appealStatus: finalReport.appealStatus,
                    trustScoreDelta: finalReport.trustScoreDelta,
                    likes: finalReport.likes,
                    dislikes: finalReport.dislikes
                )
                reports[index] = finalReport
            }
        } catch {
            // Rollback on error
            await MainActor.run {
                reports[index] = report
                errorMessage = error.localizedDescription
                showError = true
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

// MARK: - Community Post Card
struct CommunityPostCard: View {
    let report: Report
    let onTap: () -> Void
    let onLike: () async -> Void
    let onDislike: () async -> Void
    
    @State private var beforeImageUrl: String?
    @State private var afterImageUrl: String?
    @State private var isLoadingImages = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Before/After Images
                imageSection
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Status Badge
                    HStack {
                        StatusBadge(status: report.status)
                        Spacer()
                        Text(formatRelativeDate(report.updatedAt))
                            .font(.caption)
                            .foregroundColor(Theme.Colors.gray500)
                    }
                    
                    // Title
                    Text(report.issueTitle)
                        .font(.headline)
                        .foregroundColor(Theme.Colors.gray900)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Description
                    if let description = report.issueDescription {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.gray600)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Metadata
                    VStack(spacing: 6) {
                        metadataRow(icon: "calendar", text: "Reported: \(formatShortDate(report.issueDate ?? report.updatedAt))")
                        metadataRow(icon: "checkmark.circle.fill", text: "Resolved: \(formatShortDate(report.updatedAt))")
                        metadataRow(icon: "mappin.circle.fill", text: report.location)
                        if let department = report.department {
                            metadataRow(icon: "building.2.fill", text: department)
                        }
                    }
                    
                    Divider()
                    
                    // Social Stats
                    socialStatsSection
                }
                .padding()
            }
            .background(Theme.Colors.surface)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .task {
            await loadImages()
        }
    }
    
    // MARK: - Image Section
    private var imageSection: some View {
        HStack(spacing: 0) {
            // Before Image
            ZStack(alignment: .topLeading) {
                if let beforeUrl = beforeImageUrl {
                    AsyncImage(url: URL(string: beforeUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ZStack {
                            Theme.Colors.gray200
                            ProgressView()
                        }
                    }
                } else {
                    ZStack {
                        Theme.Colors.gray200
                        if isLoadingImages {
                            ProgressView()
                        } else {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(Theme.Colors.gray400)
                        }
                    }
                }
                
                Text("BEFORE")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange)
                    )
                    .padding(8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipped()
            
            // Divider
            Rectangle()
                .fill(Color.white)
                .frame(width: 3)
            
            // After Image
            ZStack(alignment: .topTrailing) {
                if let afterUrl = afterImageUrl {
                    AsyncImage(url: URL(string: afterUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ZStack {
                            Theme.Colors.gray200
                            ProgressView()
                        }
                    }
                } else {
                    ZStack {
                        Theme.Colors.gray200
                        if isLoadingImages {
                            ProgressView()
                        } else {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(Theme.Colors.gray400)
                        }
                    }
                }
                
                Text("AFTER")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.emerald600)
                    )
                    .padding(8)
                
                // Resolved Badge Overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.emerald600)
                                .frame(width: 50, height: 50)
                                .shadow(color: .black.opacity(0.2), radius: 4)
                            
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .padding(12)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipped()
        }
        .cornerRadius(16, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Social Stats Section
    private var socialStatsSection: some View {
        HStack(spacing: 20) {
            // Like Button
            Button(action: { Task { await onLike() } }) {
                HStack(spacing: 6) {
                    Image(systemName: (report.isLiked ?? false) ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.subheadline)
                    Text("\(report.likesCount ?? 0)")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor((report.isLiked ?? false) ? .blue : Theme.Colors.gray600)
            }
            .disabled(!AuthManager.shared.isLoggedIn)
            
            // Dislike Button
            Button(action: { Task { await onDislike() } }) {
                HStack(spacing: 6) {
                    Image(systemName: (report.isDisliked ?? false) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.subheadline)
                    Text("\(report.dislikesCount ?? 0)")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor((report.isDisliked ?? false) ? .red : Theme.Colors.gray600)
            }
            .disabled(!AuthManager.shared.isLoggedIn)
            
            // Comments
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.fill")
                    .font(.subheadline)
                Text("\(report.commentsCount ?? 0)")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(Theme.Colors.gray600)
            
            Spacer()
            
            // Tap to view details hint
            Text("Tap for details")
                .font(.caption)
                .foregroundColor(Theme.Colors.emerald600)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Theme.Colors.emerald50)
                )
        }
    }
    
    // MARK: - Helper Views
    private func metadataRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Theme.Colors.emerald600)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(Theme.Colors.gray600)
        }
    }
    
    // MARK: - Functions
    private func loadImages() async {
        isLoadingImages = true
        do {
            let response = try await NetworkManager.shared.getPresignedImageURLs(reportId: report.id)
            await MainActor.run {
                beforeImageUrl = response.imageUrl
                afterImageUrl = response.completionUrl
                isLoadingImages = false
            }
        } catch {
            await MainActor.run {
                isLoadingImages = false
            }
            print("Failed to load images for report \(report.id): \(error)")
        }
    }
    
    private func formatRelativeDate(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatShortDate(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d MMM yyyy"
        
        return outputFormatter.string(from: date)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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
