//
//  Models.swift
//  JanSaathi2
//
//  Data models for the app
//

import Foundation

// MARK: - User & Auth

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let username: String?
    let firstName: String?
    let lastName: String?
    let isEmailVerified: Bool?
    let authMethod: String?
    let googleId: String?
    let profilePicture: String?
    let dateJoined: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case isEmailVerified = "is_email_verified"
        case authMethod = "auth_method"
        case googleId = "google_id"
        case profilePicture = "profile_picture"
        case dateJoined = "date_joined"
    }
}

struct AuthTokens: Codable {
    let access: String
    let refresh: String
}

struct LoginResponse: Codable {
    let message: String?
    let user: User
    let tokens: AuthTokens

    // Backward compatibility
    var access: String { tokens.access }
    var refresh: String { tokens.refresh }
}

// MARK: - Report

struct Report: Codable, Identifiable {
    let id: Int
    let user: Int?
    let issueTitle: String
    let location: String
    let issueDescription: String?
    let imageUrl: String?
    let completionUrl: String?
    let issueDate: String?
    let status: String
    let updatedAt: String
    let trackingId: String?
    let department: String?
    let confidenceScore: Double?
    let allocatedTo: String?
    
    // Additional fields from community/tracking endpoints
    let userName: String?
    let username: String?
    let likesCount: Int?
    let dislikesCount: Int?
    let commentsCount: Int?
    let isLiked: Bool?
    let isDisliked: Bool?
    let appealStatus: String?
    let trustScoreDelta: Int?
    let likes: [Int]?
    let dislikes: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case user
        case issueTitle = "issue_title"
        case location
        case issueDescription = "issue_description"
        case imageUrl = "image_url"
        case completionUrl = "completion_url"
        case issueDate = "issue_date"
        case status
        case updatedAt = "updated_at"
        case trackingId = "tracking_id"
        case department
        case confidenceScore = "confidence_score"
        case allocatedTo = "allocated_to"
        case userName = "user_name"
        case username
        case likesCount = "likes_count"
        case dislikesCount = "dislikes_count"
        case commentsCount = "comments_count"
        case isLiked = "is_liked"
        case isDisliked = "is_disliked"
        case appealStatus = "appeal_status"
        case trustScoreDelta = "trust_score_delta"
        case likes
        case dislikes
    }

    // Backward compatibility
    var createdAt: String { issueDate ?? updatedAt }
}

// MARK: - Profile

struct UserProfile: Codable {
    let id: Int
    let isAadhaarVerified: Bool
    let aadhaar: AadhaarData?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case isAadhaarVerified = "is_aadhaar_verified"
        case aadhaar
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AadhaarData: Codable {
    let aadhaarNumber: String?
    let fullName: String?
    let firstName: String?
    let middleName: String?
    let lastName: String?
    let dateOfBirth: String?
    let address: String?
    let gender: String?
    let phoneNumber: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case aadhaarNumber = "aadhaar_number"
        case fullName = "full_name"
        case firstName = "first_name"
        case middleName = "middle_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case address
        case gender
        case phoneNumber = "phone_number"
        case createdAt = "created_at"
    }

    // Backward compatibility helpers
    var midName: String? { middleName }
    var phone: String? { phoneNumber }
}

// MARK: - Aadhaar Verification Response

struct VerifyAadhaarResponse: Codable {
    let verified: Bool
    let aadhaarNumber: String?
    let aadhaar: AadhaarData?
    let profile: AadhaarProfile?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case verified
        case aadhaarNumber = "aadhaar_number"
        case aadhaar
        case profile
        case error
    }
}

struct AadhaarProfile: Codable {
    let isAadhaarVerified: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case isAadhaarVerified = "is_aadhaar_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Stats

struct AppStats {
    let issuesResolved: String
    let activeCitizens: String
    let avgResolution: String
    let successRate: String
}

// MARK: - ML Prediction

struct MLPredictionResponse: Codable {
    let department: String
    let confidence: Double
    let isValid: Bool
    let method: String?
    let reason: String?
    let imageResult: MLResult?
    let textResult: MLTextResult?
    
    enum CodingKeys: String, CodingKey {
        case department
        case confidence
        case isValid = "is_valid"
        case method
        case reason
        case imageResult = "image_result"
        case textResult = "text_result"
    }
}

struct MLResult: Codable {
    let department: String
    let confidence: Double
}

struct MLTextResult: Codable {
    let department: String
    let confidence: Double
    let intent: String?
}

// MARK: - S3 Upload

struct S3PresignResponse: Codable {
    let url: String
    let key: String
}

struct S3PresignRequest: Codable {
    let fileName: String
    let contentType: String
}

struct PresignGetResponse: Codable {
    let imageUrl: String?
    let completionUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case completionUrl = "completion_url"
    }
}

// MARK: - Blockchain

struct BlockchainStatusResponse: Codable {
    let trackingId: String
    let blockchainVerified: Bool
    let slaEscalated: Bool
    let latestTxHash: String?
    let events: [BlockchainEvent]?
    let evidence: [BlockchainEvidence]?
    let slaStatus: SLAStatus?
    
    enum CodingKeys: String, CodingKey {
        case trackingId = "tracking_id"
        case blockchainVerified = "blockchain_verified"
        case slaEscalated = "sla_escalated"
        case latestTxHash = "latest_tx_hash"
        case events
        case evidence
        case slaStatus = "sla_status"
    }
}

struct BlockchainEvent: Codable {
    let eventType: String
    let txHash: String?
    let blockNumber: Int?
    let timestamp: String?
    let status: String?
    let explorerUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case txHash = "tx_hash"
        case blockNumber = "block_number"
        case timestamp
        case status
        case explorerUrl = "explorer_url"
    }
}

struct BlockchainEvidence: Codable {
    let fileName: String
    let filePath: String
    let fileUrl: String
    let fileHash: String
    let txHash: String?
    let verified: Bool
    let blockTimestamp: Int?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case filePath = "file_path"
        case fileUrl = "file_url"
        case fileHash = "file_hash"
        case txHash = "tx_hash"
        case verified
        case blockTimestamp = "block_timestamp"
        case createdAt = "created_at"
    }
}

struct SLAStatus: Codable {
    let withinSla: Bool
    let daysElapsed: Int
    let daysRemaining: Int
    
    enum CodingKeys: String, CodingKey {
        case withinSla = "within_sla"
        case daysElapsed = "days_elapsed"
        case daysRemaining = "days_remaining"
    }
}
