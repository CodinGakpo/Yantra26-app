//
//  PostDetailsView.swift
//  NagrikMitra2
//
//  Detailed view for community posts with social features
//

import SwiftUI

struct PostDetailsView: View {
    let report: Report
    @Environment(\.dismiss) var dismiss
    @State private var beforeImageUrl: String?
    @State private var afterImageUrl: String?
    @State private var currentImageIndex = 0
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isSubmittingComment = false
    @State private var localLikesCount: Int
    @State private var localDislikesCount: Int
    @State private var localIsLiked: Bool
    @State private var localIsDisliked: Bool
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(report: Report) {
        self.report = report
        _localLikesCount = State(initialValue: report.likesCount ?? 0)
        _localDislikesCount = State(initialValue: report.dislikesCount ?? 0)
        _localIsLiked = State(initialValue: report.isLiked ?? false)
        _localIsDisliked = State(initialValue: report.isDisliked ?? false)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image Viewer
                    imageViewer
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // User & Location Info
                        userInfoSection
                        
                        Divider()
                        
                        // Title & Description
                        titleDescriptionSection
                        
                        Divider()
                        
                        // Metadata
                        metadataSection
                        
                        Divider()
                        
                        // Social Interactions
                        socialButtonsSection
                        
                        Divider()
                        
                        // Comments Section
                        commentsSection
                    }
                    .padding()
                }
            }
            .background(Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.Colors.gray700)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Issue Details")
                        .font(.headline)
                }
            }
            .task {
                await loadImages()
                await loadComments()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Image Viewer
    private var imageViewer: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentImageIndex) {
                // Before Image
                if let beforeUrl = beforeImageUrl {
                    imageCard(url: beforeUrl, label: "BEFORE", index: 0)
                        .tag(0)
                } else {
                    placeholderImage(label: "BEFORE")
                        .tag(0)
                }
                
                // After Image
                if let afterUrl = afterImageUrl {
                    imageCard(url: afterUrl, label: "AFTER", index: 1)
                        .tag(1)
                } else {
                    placeholderImage(label: "AFTER")
                        .tag(1)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 300)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
    
    private func imageCard(url: String, label: String, index: Int) -> some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: URL(string: url)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    Theme.Colors.gray200
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipped()
            
            // Badge
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(index == 0 ? Color.orange : Theme.Colors.emerald600)
                )
                .padding(12)
        }
    }
    
    private func placeholderImage(label: String) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Theme.Colors.gray200)
                .frame(height: 300)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.Colors.gray400)
                        Text("No image available")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.gray500)
                    }
                )
            
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Theme.Colors.gray400)
                )
                .padding(12)
        }
    }
    
    // MARK: - User Info Section
    private var userInfoSection: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.Colors.emerald100)
                    .frame(width: 44, height: 44)
                
                Text(getInitials(from: report.userName ?? report.username ?? "U"))
                    .font(.headline)
                    .foregroundColor(Theme.Colors.emerald700)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(report.userName ?? report.username ?? "Anonymous Citizen")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.gray900)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                    Text(report.location)
                        .font(.subheadline)
                }
                .foregroundColor(Theme.Colors.gray600)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Title & Description Section
    private var titleDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(report.issueTitle)
                .font(.title3.bold())
                .foregroundColor(Theme.Colors.gray900)
            
            if let description = report.issueDescription {
                Text(description)
                    .font(.body)
                    .foregroundColor(Theme.Colors.gray700)
                    .lineSpacing(4)
            }
        }
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            metadataChip(icon: "calendar", label: "Reported", value: formatDate(report.issueDate ?? report.updatedAt))
            metadataChip(icon: "checkmark.circle.fill", label: "Resolved", value: formatDate(report.updatedAt))
            if let department = report.department {
                metadataChip(icon: "building.2.fill", label: "Department", value: department)
            }
            if let trackingId = report.trackingId {
                metadataChip(icon: "number", label: "Tracking ID", value: trackingId)
            }
        }
    }
    
    private func metadataChip(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Theme.Colors.emerald600)
                .frame(width: 20)
            
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.gray600)
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.Colors.gray900)
        }
    }
    
    // MARK: - Social Buttons Section
    private var socialButtonsSection: some View {
        HStack(spacing: 20) {
            // Like Button
            Button(action: { Task { await handleLike() } }) {
                HStack(spacing: 8) {
                    Image(systemName: localIsLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.title3)
                    Text("\(localLikesCount)")
                        .font(.headline)
                }
                .foregroundColor(localIsLiked ? .blue : Theme.Colors.gray600)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(localIsLiked ? Color.blue.opacity(0.1) : Theme.Colors.gray100)
                )
            }
            .disabled(!AuthManager.shared.isLoggedIn)
            
            // Dislike Button
            Button(action: { Task { await handleDislike() } }) {
                HStack(spacing: 8) {
                    Image(systemName: localIsDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.title3)
                    Text("\(localDislikesCount)")
                        .font(.headline)
                }
                .foregroundColor(localIsDisliked ? .red : Theme.Colors.gray600)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(localIsDisliked ? Color.red.opacity(0.1) : Theme.Colors.gray100)
                )
            }
            .disabled(!AuthManager.shared.isLoggedIn)
            
            Spacer()
            
            // Comment count badge
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.fill")
                    .font(.subheadline)
                Text("\(comments.count)")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(Theme.Colors.gray600)
        }
    }
    
    // MARK: - Comments Section
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comments")
                .font(.headline)
                .foregroundColor(Theme.Colors.gray900)
            
            // Comment input
            if AuthManager.shared.isLoggedIn {
                HStack(spacing: 12) {
                    TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    
                    Button(action: { Task { await submitComment() } }) {
                        if isSubmittingComment {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .foregroundColor(newCommentText.isEmpty ? Theme.Colors.gray400 : Theme.Colors.emerald600)
                        }
                    }
                    .disabled(newCommentText.isEmpty || isSubmittingComment)
                }
            } else {
                Text("Please login to comment")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.gray500)
                    .italic()
            }
            
            // Comments list
            if comments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.gray400)
                    Text("No comments yet")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.gray500)
                    Text("Be the first to share your thoughts!")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.gray400)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(comments) { comment in
                        CommentBubble(comment: comment)
                    }
                }
            }
        }
    }
    
    // MARK: - Functions
    private func loadImages() async {
        do {
            let response = try await NetworkManager.shared.getPresignedImageURLs(reportId: report.id)
            await MainActor.run {
                beforeImageUrl = response.imageUrl
                afterImageUrl = response.completionUrl
            }
        } catch {
            print("Failed to load images: \(error)")
        }
    }
    
    private func loadComments() async {
        do {
            let loadedComments = try await NetworkManager.shared.getComments(reportId: report.id)
            await MainActor.run {
                comments = loadedComments
            }
        } catch {
            print("Failed to load comments: \(error)")
        }
    }
    
    private func handleLike() async {
        guard AuthManager.shared.isLoggedIn else { return }
        
        // Optimistic update
        let wasLiked = localIsLiked
        let wasDisliked = localIsDisliked
        
        await MainActor.run {
            if localIsLiked {
                localIsLiked = false
                localLikesCount -= 1
            } else {
                localIsLiked = true
                localLikesCount += 1
                if localIsDisliked {
                    localIsDisliked = false
                    localDislikesCount -= 1
                }
            }
        }
        
        do {
            let response = try await NetworkManager.shared.likeReport(reportId: report.id)
            await MainActor.run {
                localLikesCount = response.likesCount
                localDislikesCount = response.dislikesCount
                localIsLiked = response.liked ?? false
                localIsDisliked = response.disliked ?? false
            }
        } catch {
            // Rollback on error
            await MainActor.run {
                localIsLiked = wasLiked
                localIsDisliked = wasDisliked
                localLikesCount = report.likesCount ?? 0
                localDislikesCount = report.dislikesCount ?? 0
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleDislike() async {
        guard AuthManager.shared.isLoggedIn else { return }
        
        // Optimistic update
        let wasLiked = localIsLiked
        let wasDisliked = localIsDisliked
        
        await MainActor.run {
            if localIsDisliked {
                localIsDisliked = false
                localDislikesCount -= 1
            } else {
                localIsDisliked = true
                localDislikesCount += 1
                if localIsLiked {
                    localIsLiked = false
                    localLikesCount -= 1
                }
            }
        }
        
        do {
            let response = try await NetworkManager.shared.dislikeReport(reportId: report.id)
            await MainActor.run {
                localLikesCount = response.likesCount
                localDislikesCount = response.dislikesCount
                localIsLiked = response.liked ?? false
                localIsDisliked = response.disliked ?? false
            }
        } catch {
            // Rollback on error
            await MainActor.run {
                localIsLiked = wasLiked
                localIsDisliked = wasDisliked
                localLikesCount = report.likesCount ?? 0
                localDislikesCount = report.dislikesCount ?? 0
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func submitComment() async {
        guard !newCommentText.isEmpty else { return }
        
        await MainActor.run {
            isSubmittingComment = true
        }
        
        do {
            let newComment = try await NetworkManager.shared.postComment(
                reportId: report.id,
                text: newCommentText
            )
            
            await MainActor.run {
                comments.append(newComment)
                newCommentText = ""
                isSubmittingComment = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isSubmittingComment = false
            }
        }
    }
    
    private func getInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        outputFormatter.timeStyle = .none
        
        return outputFormatter.string(from: date)
    }
}

// MARK: - Comment Bubble
struct CommentBubble: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Theme.Colors.gray200)
                        .frame(width: 32, height: 32)
                    
                    Text(getInitials(from: comment.displayName))
                        .font(.caption.bold())
                        .foregroundColor(Theme.Colors.gray700)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.Colors.gray900)
                    
                    Text(formatRelativeTime(comment.createdAt))
                        .font(.caption)
                        .foregroundColor(Theme.Colors.gray500)
                }
                
                Spacer()
            }
            
            Text(comment.text)
                .font(.body)
                .foregroundColor(Theme.Colors.gray800)
                .padding(.leading, 40)
        }
        .padding(12)
        .background(Theme.Colors.gray50)
        .cornerRadius(12)
    }
    
    private func getInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
    
    private func formatRelativeTime(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    PostDetailsView(report: Report(
        id: 1,
        user: 1,
        issueTitle: "Broken Streetlight",
        location: "MG Road, Bangalore",
        issueDescription: "The streetlight has been non-functional for 2 weeks, causing safety issues at night.",
        imageUrl: nil,
        completionUrl: nil,
        issueDate: "2026-02-01T10:00:00Z",
        status: "resolved",
        updatedAt: "2026-02-14T15:30:00Z",
        trackingId: "BLR2026001",
        department: "PWD",
        confidenceScore: nil,
        allocatedTo: nil,
        userName: "Raj Kumar",
        username: "rajk",
        likesCount: 42,
        dislikesCount: 3,
        commentsCount: 12,
        isLiked: false,
        isDisliked: false,
        appealStatus: nil,
        trustScoreDelta: nil,
        likes: nil,
        dislikes: nil
    ))
}
