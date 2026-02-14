//
//  APIConfig.swift
//  JanSaathi2
//
//  API configuration
//

import Foundation

struct APIConfig {
    // Change this to your backend URL
    // For local development: "http://localhost:8000"
    // For device testing: "http://192.168.x.x:8000" (use your computer's IP)
    // For production: "https://your-backend-url.com"
    static let baseURL = "http://localhost:8000"
    
    static let apiURL = "\(baseURL)/api"
    
    // Endpoints
    struct Endpoints {
        // Auth
        static let login = "/users/login/"
        static let register = "/users/register/"
        static let logout = "/users/logout/"
        static let currentUser = "/users/me/"
        static let requestOTP = "/users/request-otp/"
        static let verifyOTP = "/users/verify-otp/"
        static let changePassword = "/users/change-password/"
        static let tokenRefresh = "/users/token/refresh/"
        
        // Reports
        static let reports = "/reports/"
        static let communityResolved = "/reports/community/resolved/"
        static let userHistory = "/reports/history/"
        static let presignS3 = "/reports/s3/presign/"
        
        // Profile
        static let profile = "/profile/me/"
        
        // Aadhaar
        static let verifyAadhaar = "/aadhaar/verify/"
        
        // ML
        static let mlPredict = "/ml/predict/"
        static let mlHealth = "/ml/health/"
        
        // Blockchain
        static func blockchainStatus(_ trackingId: String) -> String {
            return "/blockchain/reports/\(trackingId)/status/"
        }
        
        static func blockchainEvidence(_ trackingId: String) -> String {
            return "/blockchain/reports/\(trackingId)/evidence/"
        }
        
        static func blockchainVerifyEvidence(_ trackingId: String) -> String {
            return "/blockchain/reports/\(trackingId)/evidence/verify/"
        }
        
        static func blockchainAuditTrail(_ trackingId: String) -> String {
            return "/blockchain/reports/\(trackingId)/audit-trail/"
        }
        
        // Tracking
        static func trackingDetail(_ id: String) -> String {
            return "/track/detail/\(id)/"
        }
        
        static func presignGet(_ reportId: Int) -> String {
            return "/reports/\(reportId)/presign-get/"
        }
    }
}
