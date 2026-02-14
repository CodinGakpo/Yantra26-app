//
//  ReportView.swift
//  JanSaathi2
//
//  Report submission screen
//

import SwiftUI
import PhotosUI

struct ReportView: View {
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var authManager: AuthManager
    
    @State private var title = ""
    @State private var location = ""
    @State private var description = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var trackingId: String?
    @State private var isDetectingLocation = false
    @State private var showCopiedConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.Colors.emerald600)
                        
                        Text("Report an Issue")
                            .font(.title2.bold())
                            .foregroundColor(Theme.Colors.gray900)
                        
                        Text("Help improve your community by reporting civic issues")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.gray600)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Issue Title", systemImage: "text.alignleft")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.Colors.gray700)
                            
                            TextField("e.g., Pothole on Main Street", text: $title)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Location", systemImage: "location.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.Colors.gray700)
                            
                            HStack(spacing: 8) {
                                TextField("e.g., Main Street, near Park", text: $location)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                Button(action: detectLocation) {
                                    HStack {
                                        if isDetectingLocation {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.emerald600))
                                        } else {
                                            Image(systemName: "location.circle.fill")
                                                .font(.title3)
                                        }
                                    }
                                    .foregroundColor(Theme.Colors.emerald600)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(Theme.Colors.emerald50)
                                    .cornerRadius(12)
                                }
                                .disabled(isDetectingLocation)
                            }
                            
                            if let locationError = locationManager.errorMessage {
                                Text(locationError)
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.error)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Description", systemImage: "doc.text")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.Colors.gray700)
                            
                            TextEditor(text: $description)
                                .frame(height: 120)
                                .padding(12)
                                .background(Theme.Colors.surface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.Colors.gray300, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Photo Evidence", systemImage: "photo")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.Colors.gray700)
                            
                            PhotosPicker(selection: $selectedPhoto,
                                       matching: .images) {
                                HStack {
                                    Image(systemName: selectedImageData == nil ? "photo.badge.plus" : "photo.fill")
                                    Text(selectedImageData == nil ? "Choose Photo" : "Photo Selected")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.Colors.emerald50)
                                .foregroundColor(Theme.Colors.emerald600)
                                .cornerRadius(12)
                            }
                            .onChange(of: selectedPhoto) {
                                Task {
                                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                                        selectedImageData = data
                                    }
                                }
                            }
                            
                            if let imageData = selectedImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button(action: submitReport) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Submit Report")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Theme.Colors.emerald600 : Theme.Colors.gray300)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || isSubmitting)
                    }
                    .padding()
                    .background(Theme.Colors.surface)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                        .padding()
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSuccess) {
                SuccessView(trackingId: trackingId ?? "", onDismiss: {
                    clearForm()
                    showSuccess = false
                })
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Request location permission on appear
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestPermission()
                }
            }
            .onChange(of: locationManager.locationString) {
                if !locationManager.locationString.isEmpty {
                    location = locationManager.locationString
                    isDetectingLocation = false
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !location.isEmpty && !description.isEmpty
    }
    
    private func detectLocation() {
        isDetectingLocation = true
        locationManager.getCurrentLocation()
    }
    
    private func submitReport() {
        isSubmitting = true
        
        Task {
            do {
                var imageUrl: String?
                
                // Upload image if selected
                if let imageData = selectedImageData {
                    imageUrl = try await NetworkManager.shared.uploadImage(imageData)
                }
                
                // Submit report
                let report = try await NetworkManager.shared.submitReport(
                    title: title,
                    location: location,
                    description: description,
                    imageUrl: imageUrl
                )
                
                await MainActor.run {
                    trackingId = report.trackingId
                    showSuccess = true
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
    
    private func clearForm() {
        title = ""
        location = ""
        description = ""
        selectedPhoto = nil
        selectedImageData = nil
        trackingId = nil
    }
}

struct SuccessView: View {
    let trackingId: String
    let onDismiss: () -> Void
    @State private var showCopiedConfirmation = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.emerald50)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.emerald600)
            }
            
            // Success Message
            VStack(spacing: 8) {
                Text("Report Submitted!")
                    .font(.title2.bold())
                    .foregroundColor(Theme.Colors.gray900)
                
                Text("Your report has been successfully submitted and will be reviewed shortly.")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.gray600)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Tracking ID Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Report Number")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.gray600)
                    .textCase(.uppercase)
                
                HStack {
                    Text(trackingId)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.gray900)
                    
                    Spacer()
                    
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
            .padding()
            .background(Theme.Colors.emerald50)
            .cornerRadius(16)
            .padding(.horizontal)
            
            Text("Use this number to track your report status")
                .font(.caption)
                .foregroundColor(Theme.Colors.gray600)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Done Button
            Button(action: onDismiss) {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.emerald600)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Theme.Colors.background)
    }
    
    private func copyTrackingId() {
        UIPasteboard.general.string = trackingId
        showCopiedConfirmation = true
        
        // Reset the confirmation after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedConfirmation = false
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Theme.Colors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.Colors.gray300, lineWidth: 1)
            )
    }
}

#Preview {
    ReportView()
}
