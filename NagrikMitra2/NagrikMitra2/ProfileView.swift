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

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
