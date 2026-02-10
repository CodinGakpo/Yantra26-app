//
//  Models.swift
//  NagrikMitra2
//
//  Data models for the app
//

import Foundation

// MARK: - User & Auth
struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let username: String?
}

struct LoginResponse: Codable {
    let access: String
    let refresh: String
    let user: User
}

// MARK: - Report
struct Report: Codable, Identifiable {
    let id: Int
    let issueTitle: String
    let location: String
    let issueDescription: String?
    let imageUrl: String?
    let status: String
    let createdAt: String
    let updatedAt: String
    let trackingId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case issueTitle = "issue_title"
        case location
        case issueDescription = "issue_description"
        case imageUrl = "image_url"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case trackingId = "tracking_id"
    }
}

// MARK: - Profile
struct UserProfile: Codable {
    let id: Int
    let user: User
    let isAadhaarVerified: Bool
    let aadhaar: AadhaarData?
    
    enum CodingKeys: String, CodingKey {
        case id, user, aadhaar
        case isAadhaarVerified = "is_aadhaar_verified"
    }
}

struct AadhaarData: Codable {
    let firstName: String?
    let midName: String?
    let lastName: String?
    let dateOfBirth: String?
    let phone: String?
    let address: String?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case midName = "mid_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case phone
        case address
    }
}

// MARK: - Stats
struct AppStats {
    let issuesResolved: String
    let activeCitizens: String
    let avgResolution: String
    let successRate: String
}
