//
//  ProfileView.swift
//  JanSaathi2
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
    
    // Aadhaar Verification
    @State private var showAadhaarVerification = false
    @State private var aadhaarNumber = ""
    @State private var isVerifyingAadhaar = false
    @State private var isAadhaarVerifiedInSheet = false
    
    // Report Detail
    @State private var selectedReport: Report?
    @State private var showReportDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
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
                            
                            // Aadhaar Verification Button
                            if !profile.isAadhaarVerified {
                                Button(action: { showAadhaarVerification = true }) {
                                    HStack {
                                        Image(systemName: "person.badge.shield.checkmark")
                                        Text("Verify Aadhaar")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(Theme.Colors.emerald600)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Theme.Colors.emerald50)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Theme.Colors.emerald600, lineWidth: 1)
                                    )
                                }
                            } else if let aadhaar = profile.aadhaar {
                                // Show Aadhaar Info
                                VStack(spacing: 4) {
                                    if let fullName = aadhaar.fullName {
                                        Text(fullName)
                                            .font(.subheadline.bold())
                                            .foregroundColor(Theme.Colors.gray900)
                                    }
                                    if let phone = aadhaar.phoneNumber {
                                        Text(phone)
                                            .font(.caption)
                                            .foregroundColor(Theme.Colors.gray600)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.surface)
                    
                    // Aadhaar Verification Section
                    // Show if profile hasn't loaded yet OR if loaded and not verified
                    if profile == nil || (profile?.isAadhaarVerified == false) {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Complete Your Profile")
                                        .font(.headline)
                                        .foregroundColor(Theme.Colors.gray900)
                                    
                                    Text("Verify your Aadhaar to enhance your profile and gain verified citizen status")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.Colors.gray600)
                                }
                                
                                Spacer()
                            }
                            
                            Button(action: { showAadhaarVerification = true }) {
                                HStack {
                                    Image(systemName: "person.badge.shield.checkmark")
                                    Text("Verify Aadhaar Now")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.Colors.emerald600)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    
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
                    
                    // Deactivation Banner
                    if let profile = profile, profile.isTemporarilyDeactivated == true {
                        DeactivationBannerView(deactivatedUntil: profile.deactivatedUntil)
                            .padding(.horizontal)
                    }
                    
                    // Trust Score Card
                    if let profile = profile {
                        TrustScoreCardView(profile: profile)
                            .padding(.horizontal)
                    }
                    
                    // Civic Incentive Card
                    if let profile = profile {
                        CivicIncentiveCardView(profile: profile)
                            .padding(.horizontal)
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
                                    .onTapGesture {
                                        selectedReport = report
                                        showReportDetail = true
                                    }
                            }
                        }
                    }
                    
                    
                .padding(.bottom, 20)
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .sheet(isPresented: $showAadhaarVerification) {
                AadhaarVerificationSheet(
                    aadhaarNumber: $aadhaarNumber,
                    isVerifying: $isVerifyingAadhaar,
                    isVerified: $isAadhaarVerifiedInSheet,
                    onVerify: verifyAadhaar
                )
            }
            .sheet(isPresented: $showReportDetail) {
                if let report = selectedReport {
                    ReportDetailModal(report: report)
                }
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
    
    private func verifyAadhaar() {
        isVerifyingAadhaar = true
        
        Task {
            do {
                let response = try await NetworkManager.shared.verifyAadhaar(aadhaarNumber: aadhaarNumber)
                
                await MainActor.run {
                    if response.verified {
                        isAadhaarVerifiedInSheet = true
                        // Keep the sheet open for 2 seconds to show verified state
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showAadhaarVerification = false
                            isAadhaarVerifiedInSheet = false
                            // Reload profile
                            Task {
                                await loadData()
                            }
                        }
                    } else {
                        errorMessage = response.error ?? "Aadhaar verification failed"
                        showError = true
                    }
                    isVerifyingAadhaar = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isVerifyingAadhaar = false
                }
            }
        }
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
    @State private var showCopiedConfirmation = false
    
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
            
            // Tracking ID with copy button
            if let trackingId = report.trackingId {
                Divider()
                    .padding(.vertical, 4)
                
                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.gray600)
                    
                    Text(trackingId)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Theme.Colors.gray700)
                    
                    Spacer()
                    
                    Button(action: copyTrackingId) {
                        HStack(spacing: 4) {
                            Image(systemName: showCopiedConfirmation ? "checkmark" : "doc.on.doc")
                                .font(.caption)
                            Text(showCopiedConfirmation ? "Copied" : "Copy")
                                .font(.caption.bold())
                        }
                        .foregroundColor(showCopiedConfirmation ? Theme.Colors.emerald600 : Theme.Colors.gray700)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(showCopiedConfirmation ? Theme.Colors.emerald50 : Theme.Colors.gray100)
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func copyTrackingId() {
        if let trackingId = report.trackingId {
            UIPasteboard.general.string = trackingId
            showCopiedConfirmation = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCopiedConfirmation = false
            }
        }
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

struct AadhaarVerificationSheet: View {
    @Binding var aadhaarNumber: String
    @Binding var isVerifying: Bool
    @Binding var isVerified: Bool
    let onVerify: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: isVerified ? "checkmark.seal.fill" : "person.badge.shield.checkmark.fill")
                        .font(.system(size: 60))
                        .foregroundColor(isVerified ? .green : Theme.Colors.emerald600)
                    
                    Text(isVerified ? "Aadhaar Verified!" : "Verify Your Aadhaar")
                        .font(.title2.bold())
                        .foregroundColor(Theme.Colors.gray900)
                    
                    Text(isVerified ? "Your Aadhaar has been successfully verified" : "Link your Aadhaar to submit reports and access verified citizen features")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.gray600)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Aadhaar Number", systemImage: "creditcard")
                        .font(.subheadline.bold())
                        .foregroundColor(isVerified ? .green : Theme.Colors.gray700)
                    
                    HStack {
                        TextField("Enter 12-digit Aadhaar", text: $aadhaarNumber)
                            .keyboardType(.numberPad)
                            .textFieldStyle(CustomTextFieldStyle())
                            .disabled(isVerified)
                            .onChange(of: aadhaarNumber) {
                                // Limit to 12 digits
                                if aadhaarNumber.count > 12 {
                                    aadhaarNumber = String(aadhaarNumber.prefix(12))
                                }
                            }
                        
                        if isVerified {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    .opacity(isVerified ? 0.7 : 1.0)
                    
                    Text(isVerified ? "This Aadhaar number has been verified and linked to your account" : "Your Aadhaar information is securely encrypted and only used for verification")
                        .font(.caption)
                        .foregroundColor(isVerified ? .green : Theme.Colors.gray500)
                }
                .padding(.horizontal)
                
                Button(action: onVerify) {
                    HStack {
                        if isVerifying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else if isVerified {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Verified")
                                .fontWeight(.semibold)
                        } else {
                            Image(systemName: "checkmark.shield")
                            Text("Verify Aadhaar")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isVerified ? Color.green : (aadhaarNumber.count == 12 ? Theme.Colors.emerald600 : Theme.Colors.gray300))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(aadhaarNumber.count != 12 || isVerifying || isVerified)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReportDetailModal: View {
    let report: Report
    @Environment(\.dismiss) var dismiss
    @State private var showCopiedConfirmation = false
    @State private var presignedImageUrl: String?
    @State private var presignedCompletionUrl: String?
    @State private var isLoadingImages = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Report Number Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Report Number")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.gray600)
                            .textCase(.uppercase)
                        
                        HStack {
                            Text(report.trackingId ?? "N/A")
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.Colors.gray900)
                            
                            Spacer()
                            
                            if report.trackingId != nil {
                                Button(action: copyTrackingId) {
                                    HStack(spacing: 6) {
                                        Image(systemName: showCopiedConfirmation ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 16))
                                        Text(showCopiedConfirmation ? "Copied!" : "Copy")
                                            .font(.subheadline.bold())
                                    }
                                    .foregroundColor(showCopiedConfirmation ? Theme.Colors.emerald600 : Theme.Colors.gray700)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(showCopiedConfirmation ? Theme.Colors.emerald50 : Theme.Colors.gray100)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Theme.Colors.emerald50)
                    .cornerRadius(16)
                    
                    // Status
                    HStack {
                        Text("Status")
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.Colors.gray700)
                        
                        Spacer()
                        
                        StatusBadge(status: report.status)
                    }
                    .padding()
                    .background(Theme.Colors.surface)
                    .cornerRadius(12)
                    
                    // Issue Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(icon: "flag.fill", label: "Issue Title", value: report.issueTitle)
                        
                        Divider()
                        
                        DetailRow(icon: "mappin.circle.fill", label: "Location", value: report.location)
                        
                        if let description = report.issueDescription {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(Theme.Colors.emerald600)
                                    Text("Description")
                                        .font(.subheadline.bold())
                                        .foregroundColor(Theme.Colors.gray700)
                                }
                                
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.Colors.gray600)
                            }
                        }
                        
                        if let department = report.department {
                            Divider()
                            
                            DetailRow(icon: "building.2.fill", label: "Department", value: department)
                        }
                        
                        if let allocatedTo = report.allocatedTo {
                            Divider()
                            
                            DetailRow(icon: "person.fill", label: "Allocated To", value: allocatedTo)
                        }
                        
                        Divider()
                        
                        DetailRow(icon: "calendar", label: "Submitted", value: formatDate(report.createdAt))
                        
                        Divider()
                        
                        DetailRow(icon: "clock.fill", label: "Updated", value: formatDate(report.updatedAt))
                    }
                    .padding()
                    .background(Theme.Colors.surface)
                    .cornerRadius(12)
                    
                    // Images
                    if report.imageUrl != nil || presignedImageUrl != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "photo.fill")
                                    .foregroundColor(Theme.Colors.emerald600)
                                Text("Issue Photo")
                                    .font(.subheadline.bold())
                                    .foregroundColor(Theme.Colors.gray700)
                            }
                            
                            if let presignedUrl = presignedImageUrl, let url = URL(string: presignedUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(12)
                                } placeholder: {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 200)
                                }
                            } else if isLoadingImages {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                            }
                        }
                        .padding()
                        .background(Theme.Colors.surface)
                        .cornerRadius(12)
                    }
                    
                    if report.completionUrl != nil || presignedCompletionUrl != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Completion Photo")
                                    .font(.subheadline.bold())
                                    .foregroundColor(Theme.Colors.gray700)
                            }
                            
                            if let presignedUrl = presignedCompletionUrl, let url = URL(string: presignedUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(12)
                                } placeholder: {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 200)
                                }
                            } else if isLoadingImages {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                            }
                        }
                        .padding()
                        .background(Theme.Colors.surface)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(Theme.Colors.background)
            .navigationTitle("Report Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadPresignedUrls()
            }
        }
    }
    
    private func loadPresignedUrls() {
        Task {
            do {
                let presignedUrls = try await NetworkManager.shared.getPresignedImageURLs(reportId: report.id)
                await MainActor.run {
                    presignedImageUrl = presignedUrls.imageUrl
                    presignedCompletionUrl = presignedUrls.completionUrl
                    isLoadingImages = false
                }
            } catch {
                print("Error loading presigned URLs: \(error)")
                await MainActor.run {
                    isLoadingImages = false
                }
            }
        }
    }
    
    private func copyTrackingId() {
        if let trackingId = report.trackingId {
            UIPasteboard.general.string = trackingId
            showCopiedConfirmation = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCopiedConfirmation = false
            }
        }
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

// MARK: - Deactivation Banner View

struct DeactivationBannerView: View {
    let deactivatedUntil: String?
    
    var body: some View {
        if let deactivatedUntil = deactivatedUntil {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Temporarily Deactivated")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.gray900)
                        
                        Text("Account activates on \(formatDeactivationDate(deactivatedUntil))")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.gray600)
                        
                        Text("You cannot submit new reports during this period")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.gray500)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    private func formatDeactivationDate(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH:mm, dd MMMM yyyy"
        
        return outputFormatter.string(from: date)
    }
}

// MARK: - Trust Score Card View

struct TrustScoreCardView: View {
    let profile: UserProfile
    
    private var trustScore: Int {
        profile.trustScore ?? 100
    }
    
    private var scoreColor: Color {
        switch trustScore {
        case 110:
            return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 100..<110:
            return .green
        case 50..<100:
            return .orange
        default:
            return .red
        }
    }
    
    private var scoreLabel: String {
        switch trustScore {
        case 110:
            return "Trusted Citizen"
        case 100..<110:
            return "Good Standing"
        case 50..<100:
            return "Fair Standing"
        default:
            return "Low Trust"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.title2)
                    .foregroundColor(scoreColor)
                
                Text("Trust Score")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.gray900)
                
                Spacer()
                
                // Status badge
                Text(scoreLabel)
                    .font(.caption.bold())
                    .foregroundColor(scoreColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(scoreColor.opacity(0.15))
                    .cornerRadius(8)
            }
            
            // Score Display
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(trustScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)
                    
                    Text("/ 110")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.gray500)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Theme.Colors.gray200)
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(scoreColor)
                            .frame(width: geometry.size.width * CGFloat(trustScore) / 110.0, height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
            
            // Description
            Text("Your trust score reflects your reporting behavior and credibility. Maintain good standing by submitting accurate reports.")
                .font(.caption)
                .foregroundColor(Theme.Colors.gray600)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Civic Incentive Card View

struct CivicIncentiveCardView: View {
    let profile: UserProfile
    
    private var rewardValue: Int {
        profile.incentiveRewardValue ?? 50
    }
    
    private var targetReports: Int {
        profile.incentiveTargetResolvedReports ?? 6
    }
    
    private var resolvedCount: Int {
        profile.incentiveLatestResolvedCount ?? 0
    }
    
    private var hasRequiredTrustScore: Bool {
        profile.incentiveHasRequiredTrustScore ?? false
    }
    
    private var isEligible: Bool {
        profile.incentiveIsEligibleNow ?? false
    }
    
    private var rewardGranted: Bool {
        profile.incentiveRewardGranted ?? false
    }
    
    private var rewardJustGranted: Bool {
        profile.incentiveRewardJustGranted ?? false
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: rewardGranted ? "trophy.fill" : "gift.fill")
                    .font(.title2)
                    .foregroundColor(rewardGranted ? Color(red: 1.0, green: 0.84, blue: 0.0) : Theme.Colors.emerald600)
                
                Text("Civic Incentive Reward")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.gray900)
                
                Spacer()
            }
            
            if rewardGranted {
                // Reward Unlocked
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Reward Unlocked!")
                        .font(.title3.bold())
                        .foregroundColor(Theme.Colors.gray900)
                    
                    Text("You received Rs. \(rewardValue)\(rewardJustGranted ? " for meeting this milestone." : "")")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.gray600)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("\(profile.incentiveRewardAmount ?? rewardValue)")
                                .font(.title2.bold())
                                .foregroundColor(Theme.Colors.emerald600)
                            Text("Total Earned")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.gray500)
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack(spacing: 4) {
                            Text("\(resolvedCount)")
                                .font(.title2.bold())
                                .foregroundColor(Theme.Colors.emerald600)
                            Text("Reports Resolved")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.gray500)
                        }
                    }
                    .padding()
                    .background(Theme.Colors.emerald50)
                    .cornerRadius(12)
                }
            } else {
                // Progress Towards Reward
                VStack(spacing: 16) {
                    // Reward Amount
                    HStack {
                        Text("Reward Value:")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.gray600)
                        
                        Spacer()
                        
                        Text("Rs. \(rewardValue)")
                            .font(.title3.bold())
                            .foregroundColor(Theme.Colors.emerald600)
                    }
                    
                    Divider()
                    
                    // Progress
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Requirements:")
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.Colors.gray700)
                        
                        // Resolved Reports Progress
                        HStack(spacing: 12) {
                            Image(systemName: resolvedCount >= targetReports ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(resolvedCount >= targetReports ? .green : Theme.Colors.gray400)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(resolvedCount) / \(targetReports) latest reports resolved")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.Colors.gray700)
                                
                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Theme.Colors.gray200)
                                            .frame(height: 6)
                                            .cornerRadius(3)
                                        
                                        Rectangle()
                                            .fill(Theme.Colors.emerald600)
                                            .frame(width: geometry.size.width * CGFloat(min(resolvedCount, targetReports)) / CGFloat(targetReports), height: 6)
                                            .cornerRadius(3)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                        
                        // Trust Score Requirement
                        HStack(spacing: 12) {
                            Image(systemName: hasRequiredTrustScore ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(hasRequiredTrustScore ? .green : Theme.Colors.gray400)
                            
                            Text(hasRequiredTrustScore ? "Trust score requirement met (110)" : "Reach trust score of 110")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.gray700)
                        }
                    }
                    
                    // Eligibility Status
                    if isEligible {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(Theme.Colors.emerald600)
                            
                            Text("You're eligible! Reward will be granted shortly.")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.Colors.emerald600)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.emerald50)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Info Text
            if !rewardGranted {
                Text("Submit quality reports that get resolved to earn this one-time civic reward")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.gray600)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
}
