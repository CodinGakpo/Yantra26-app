//
//  ReportView.swift
//  NagrikMitra2
//
//  Report submission screen
//

import SwiftUI
import PhotosUI

struct ReportView: View {
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
    
    var body: some View {
        NavigationView {
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
                            
                            TextField("e.g., Main Street, near Park", text: $location)
                                .textFieldStyle(CustomTextFieldStyle())
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
            }
            .background(Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    clearForm()
                }
            } message: {
                if let trackingId = trackingId {
                    Text("Report submitted successfully!\nTracking ID: \(trackingId)")
                } else {
                    Text("Report submitted successfully!")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !location.isEmpty && !description.isEmpty
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
