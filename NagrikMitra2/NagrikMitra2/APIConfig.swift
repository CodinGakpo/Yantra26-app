//
//  APIConfig.swift
//  NagrikMitra2
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
        
        // Reports
        static let reports = "/reports/"
        static let communityResolved = "/reports/community/resolved/"
        static let userHistory = "/reports/history/"
        static let presignS3 = "/reports/s3/presign/"
        
        // Profile
        static let profile = "/profile/me/"
        
        // Aadhaar
        static let verifyAadhaar = "/aadhaar/verify/"
        
        // Tracking
        static func trackingDetail(_ id: String) -> String {
            return "/track/detail/\(id)/"
        }
    }
}
