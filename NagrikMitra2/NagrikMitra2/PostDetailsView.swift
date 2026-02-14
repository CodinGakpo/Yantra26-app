//
//  PostDetailsView.swift
//  NagrikMitra2
//
//  Instagram-style detailed view for community posts
//

import SwiftUI

struct PostDetailsView: View {
    let report: Report
    @Environment(\.dismiss) var dismiss
    @State private var beforeImageUrl: String?
    @State private var afterImageUrl: String?
    @State private var currentImageIndex = 0
    @State private var comments: [Comment] = []
    @State private var localLikesCount: Int
    @State private var localDislikesCount: Int
    @State private var localIsLiked: Bool
    @State private var localIsDisliked: Bool
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCommentsSheet = false
    
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
                VStack(spacing: 0) {
                    // Instagram-style post
                    instagramPost
                }
            }
            .background(Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.gray400)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Post")
                        .font(.headline)
                }
            }
            .task {
                await loadImages()
                await loadComments()
            }
            .sheet(isPresented: $showCommentsSheet) {
                CommentsSheet(
                    report: report,
                    comments: $comments,
                    onCommentAdded: { comment in
                        comments.append(comment)
                    }
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Instagram-Style Post
    private var instagramPost: some View {
        VStack(spacing: 0) {
            // Header: User info
            postHeader
            
            // Image carousel
            imageCarousel
            
            // Action buttons (like Instagram)
            actionButtons
            
            // Likes count
            likesSection
            
            // Caption & Description
            captionSection
            
            // View all comments button
            viewCommentsButton
            
            // Metadata chips
            metadataChips
        }
        .background(Theme.Colors.surface)
    }
    
    // MARK: - Post Header
    private var postHeader: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.Colors.emerald100)
                    .frame(width: 40, height: 40)
                
                Text(getInitials(from: report.userName ?? report.username ?? "U"))
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.Colors.emerald700)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(report.userName ?? report.username ?? "Anonymous Citizen")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.Colors.gray900)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                    Text(report.location)
                        .font(.caption)
                }
                .foregroundColor(Theme.Colors.gray600)
            }
            
            Spacer()
            
            // Resolved badge
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                Text("RESOLVED")
                    .font(.caption2.bold())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.Colors.emerald600)
            .cornerRadius(12)
        }
        .padding()
    }
    
    // MARK: - Image Carousel
    private var imageCarousel: some View {
        TabView(selection: $currentImageIndex) {
            // Before Image
            imageCard(
                url: beforeImageUrl,
                label: "BEFORE",
                color: Color.orange,
                index: 0
            )
            .tag(0)
            
            // After Image
            imageCard(
                url: afterImageUrl,
                label: "AFTER",
                color: Theme.Colors.emerald600,
                index: 1
            )
            .tag(1)
        }
        .frame(height: 400)
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
    
    private func imageCard(url: String?, label: String, color: Color, index: Int) -> some View {
        ZStack(alignment: .topLeading) {
            if let urlString = url, let imageUrl = URL(string: urlString) {
                AsyncImage(url: imageUrl) { image in
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
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.Colors.gray400)
                        Text("No image")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.gray500)
                    }
                }
            }
            
            // Badge
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(color))
                .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
    
    // MARK: - Action Buttons (Instagram-style)
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Like button
            Button(action: { Task { await handleLike() } }) {
                HStack(spacing: 4) {
                    Image(systemName: localIsLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.title2)
                        .symbolEffect(.bounce, value: localIsLiked)
                }
                .foregroundColor(localIsLiked ? .blue : Theme.Colors.gray800)
            }
            .disabled(!AuthManager.shared.isLoggedIn)
            
            // Dislike button
            Button(action: { Task { await handleDislike() } }) {
                HStack(spacing: 4) {
                    Image(systemName: localIsDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.title2)
                        .symbolEffect(.bounce, value: localIsDisliked)
                }
                .foregroundColor(localIsDisliked ? .red : Theme.Colors.gray800)
            }
            .disabled(!AuthManager.shared.isLoggedIn)
            
            // Comment button
            Button(action: { showCommentsSheet = true }) {
                Image(systemName: "bubble.right")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.gray800)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Likes Section
    private var likesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if localLikesCount > 0 || localDislikesCount > 0 {
                HStack(spacing: 12) {
                    if localLikesCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("\(localLikesCount) \(localLikesCount == 1 ? "like" : "likes")")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.Colors.gray900)
                        }
                    }
                    
                    if localDislikesCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsdown.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("\(localDislikesCount)")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.Colors.gray900)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Caption Section
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title (like Instagram caption)
            HStack(alignment: .top, spacing: 6) {
                Text(report.userName ?? report.username ?? "Anonymous")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.Colors.gray900)
                +
                Text(" ")
                +
                Text(report.issueTitle)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.gray900)
            }
            
            // Description
            if let description = report.issueDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.gray700)
                    .lineSpacing(4)
            }
            
            // Timestamp
            Text(formatRelativeDate(report.updatedAt))
                .font(.caption)
                .foregroundColor(Theme.Colors.gray500)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - View Comments Button
    private var viewCommentsButton: some View {
        Button(action: { showCommentsSheet = true }) {
            HStack(spacing: 6) {
                if comments.isEmpty {
                    Text("Be the first to comment")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.gray500)
                } else {
                    Text("View all \(comments.count) \(comments.count == 1 ? "comment" : "comments")")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.gray600)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.gray400)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Metadata Chips
    private var metadataChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Details")
                    .font(.caption.bold())
                    .foregroundColor(Theme.Colors.gray600)
                    .textCase(.uppercase)
                
                metadataChip(icon: "calendar", text: "Reported: \(formatShortDate(report.issueDate ?? report.updatedAt))")
                metadataChip(icon: "checkmark.circle.fill", text: "Resolved: \(formatShortDate(report.updatedAt))")
                
                if let department = report.department {
                    metadataChip(icon: "building.2.fill", text: "Department: \(department)")
                }
                
                if let trackingId = report.trackingId {
                    metadataChip(icon: "number", text: "ID: \(trackingId)")
                }
            }
            .padding()
            .background(Theme.Colors.gray50)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private func metadataChip(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Theme.Colors.emerald600)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(Theme.Colors.gray700)
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
    
    private func getInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
    
    private func formatRelativeDate(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        
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

// MARK: - Comments Sheet (Instagram-style popup)
struct CommentsSheet: View {
    let report: Report
    @Binding var comments: [Comment]
    let onCommentAdded: (Comment) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var newCommentText = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Comments list
                if comments.isEmpty {
                    emptyCommentsView
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(comments) { comment in
                                    CommentRow(comment: comment)
                                        .id(comment.id)
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                Divider()
                
                // Comment input
                commentInputBar
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var emptyCommentsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.gray300)
            
            Text("No comments yet")
                .font(.title3.bold())
                .foregroundColor(Theme.Colors.gray600)
            
            Text("Be the first to share your thoughts!")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.gray500)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var commentInputBar: some View {
        HStack(spacing: 12) {
            if AuthManager.shared.isLoggedIn {
                // User avatar
                ZStack {
                    Circle()
                        .fill(Theme.Colors.emerald100)
                        .frame(width: 36, height: 36)
                    
                    // You could show current user's initials here
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.emerald600)
                }
                
                // Text field
                TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .padding(10)
                    .background(Theme.Colors.gray100)
                    .cornerRadius(20)
                
                // Send button
                Button(action: { Task { await submitComment() } }) {
                    if isSubmitting {
                        ProgressView()
                            .frame(width: 30, height: 30)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(newCommentText.isEmpty ? Theme.Colors.gray400 : Theme.Colors.emerald600)
                    }
                }
                .disabled(newCommentText.isEmpty || isSubmitting)
            } else {
                Text("Please login to comment")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.gray500)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.gray100)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Theme.Colors.surface)
    }
    
    private func submitComment() async {
        guard !newCommentText.isEmpty else { return }
        
        await MainActor.run {
            isSubmitting = true
        }
        
        do {
            let newComment = try await NetworkManager.shared.postComment(
                reportId: report.id,
                text: newCommentText
            )
            
            await MainActor.run {
                onCommentAdded(newComment)
                newCommentText = ""
                isSubmitting = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isSubmitting = false
            }
        }
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.Colors.gray200)
                    .frame(width: 36, height: 36)
                
                Text(getInitials(from: comment.displayName))
                    .font(.caption.bold())
                    .foregroundColor(Theme.Colors.gray700)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Username and comment
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.Colors.gray900)
                    
                    Text(comment.text)
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.gray800)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Theme.Colors.gray50)
                .cornerRadius(16)
                
                // Timestamp
                Text(formatRelativeTime(comment.createdAt))
                    .font(.caption)
                    .foregroundColor(Theme.Colors.gray500)
                    .padding(.leading, 4)
            }
        }
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
        issueTitle: "Broken Streetlight on MG Road",
        location: "MG Road, Bangalore",
        issueDescription: "The streetlight has been non-functional for 2 weeks, causing safety issues for pedestrians and motorists during night time.",
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
