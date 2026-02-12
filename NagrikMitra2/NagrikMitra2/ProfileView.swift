//
//  ProfileView.swift
//  NagrikMitra2
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
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: Header
                    headerSection

                    // MARK: Aadhaar CTA
                    if profile == nil || (profile?.isAadhaarVerified == false) {
                        aadhaarCTA
                    }

                    // MARK: Stats
                    statsSection

                    // MARK: Reports
                    reportsSection

                    // MARK: Logout
                    logoutButton
                }
            }
            .background(Theme.Colors.background)
            .refreshable { await loadData() }
            .task { await loadData() }
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
}

// MARK: - Sections
private extension ProfileView {

    var headerSection: some View {
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

                Text(authManager.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if let profile = profile {
                HStack(spacing: 8) {
                    Image(systemName: profile.isAadhaarVerified ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundColor(profile.isAadhaarVerified ? .green : .orange)

                    Text(profile.isAadhaarVerified ? "Verified User" : "Not Verified")
                        .font(.subheadline)
                }

                if !profile.isAadhaarVerified {
                    Button("Verify Aadhaar") { showAadhaarVerification = true }
                } else if let aadhaar = profile.aadhaar {
                    VStack {
                        if let name = aadhaar.fullName { Text(name).bold() }
                        if let phone = aadhaar.phoneNumber { Text(phone).font(.caption) }
                    }
                }
            }
        }
        .padding()
        .background(Theme.Colors.surface)
    }

    var aadhaarCTA: some View {
        Button("Verify Aadhaar Now") {
            showAadhaarVerification = true
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.Colors.emerald600)
        .foregroundColor(.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatBox(icon: "flag.fill", value: "\(reports.count)", label: "Reports")
            StatBox(icon: "checkmark.circle.fill", value: "\(resolvedCount)", label: "Resolved")
            StatBox(icon: "clock.fill", value: "\(pendingCount)", label: "Pending")
            StatBox(icon: "chart.line.uptrend.xyaxis", value: "\(successRate)%", label: "Success")
        }
        .padding(.horizontal)
    }

    var reportsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Reports")
                .font(.title3.bold())
                .padding(.horizontal)

            if reports.isEmpty && !isLoading {
                Text("No reports yet")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(reports) { report in
                    ReportHistoryCard(report: report)
                        .padding(.horizontal)
                }
            }
        }
    }

    var logoutButton: some View {
        Button("Logout") { authManager.logout() }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(12)
            .padding()
    }
}

// MARK: - Logic
private extension ProfileView {

    func getInitials() -> String {
        if let username = authManager.currentUser?.username {
            return String(username.prefix(2)).uppercased()
        }
        if let email = authManager.currentUser?.email {
            return String(email.prefix(2)).uppercased()
        }
        return "U"
    }

    var resolvedCount: Int {
        reports.filter { $0.status.lowercased() == "resolved" }.count
    }

    var pendingCount: Int {
        reports.filter { $0.status.lowercased() == "pending" }.count
    }

    var successRate: Int {
        guard !reports.isEmpty else { return 0 }
        return (resolvedCount * 100) / reports.count
    }

    func verifyAadhaar() {
        isVerifyingAadhaar = true

        Task {
            do {
                let response = try await NetworkManager.shared.verifyAadhaar(aadhaarNumber: aadhaarNumber)

                await MainActor.run {
                    if response.verified {
                        isAadhaarVerifiedInSheet = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showAadhaarVerification = false
                            isAadhaarVerifiedInSheet = false
                            Task { await loadData() }
                        }
                    } else {
                        errorMessage = response.error ?? "Verification failed"
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

    func loadData() async {
        isLoading = true
        do {
            async let p = NetworkManager.shared.getUserProfile()
            async let r = NetworkManager.shared.getUserHistory()
            (profile, reports) = try await (p, r)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack {
            Image(systemName: icon)
            Text(value).bold()
            Text(label).font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ReportHistoryCard: View {
    let report: Report

    var body: some View {
        VStack(alignment: .leading) {
            Text(report.issueTitle).bold()
            Text(report.location).font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Aadhaar Verification Sheet

struct AadhaarVerificationSheet: View {
    @Binding var aadhaarNumber: String
    @Binding var isVerifying: Bool
    @Binding var isVerified: Bool
    let onVerify: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {

                VStack(spacing: 12) {
                    Image(systemName: isVerified ? "checkmark.seal.fill" : "person.badge.shield.checkmark")
                        .font(.system(size: 60))
                        .foregroundColor(isVerified ? .green : .blue)

                    Text(isVerified ? "Aadhaar Verified!" : "Verify Your Aadhaar")
                        .font(.title2.bold())

                    Text(
                        isVerified
                        ? "Your Aadhaar has been successfully linked."
                        : "Enter your 12-digit Aadhaar number to verify your identity."
                    )
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Aadhaar Number")
                        .font(.subheadline.bold())

                    TextField("Enter 12-digit Aadhaar", text: $aadhaarNumber)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isVerified)
                        .onChange(of: aadhaarNumber) {
                            if aadhaarNumber.count > 12 {
                                aadhaarNumber = String(aadhaarNumber.prefix(12))
                            }
                        }
                }
                .padding(.horizontal)

                Button(action: onVerify) {
                    HStack {
                        if isVerifying {
                            ProgressView()
                                .tint(.white)
                        } else if isVerified {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Verified")
                        } else {
                            Text("Verify Aadhaar")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        isVerified
                        ? Color.green
                        : (aadhaarNumber.count == 12 ? Color.blue : Color.gray)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(aadhaarNumber.count != 12 || isVerifying || isVerified)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Aadhaar Verification")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
