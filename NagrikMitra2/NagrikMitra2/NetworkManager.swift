//
//  NetworkManager.swift
//  JanSaathi2
//
//  Network layer for API communication
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Unauthorized. Please login again."
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    // MARK: - Generic Request
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        authenticated: Bool = false,
        useBaseURL: Bool = false
    ) async throws -> T {
        let baseUrl = useBaseURL ? APIConfig.baseURL : APIConfig.apiURL
        guard let url = URL(string: baseUrl + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        print("🌐 API Request: \(method) \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if authenticated, let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.noData
            }
            
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                // Debug: Print server response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Server error response (\(httpResponse.statusCode)): \(responseString)")
                }
                
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorResponse["error"] ?? errorResponse["detail"] {
                    throw NetworkError.serverError(errorMessage)
                }
                throw NetworkError.serverError("Server error: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            // Note: Not using .convertFromSnakeCase because models have explicit CodingKeys
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw NetworkError.decodingError
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }
    
    // MARK: - Authentication Helpers
    private func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: "accessToken")
    }
    
    // MARK: - Image Upload
    func uploadImage(_ imageData: Data) async throws -> String {
        // Get presigned URL
        let requestBody = S3PresignRequest(
            fileName: "image-\(UUID().uuidString).jpg",
            contentType: "image/jpeg"
        )
        
        let encoder = JSONEncoder()
        let body = try encoder.encode(requestBody)
        
        // Debug: Print what we're sending
        if let jsonString = String(data: body, encoding: .utf8) {
            print("🔍 Sending to presign endpoint: \(jsonString)")
        }
        
        let presignResponse: S3PresignResponse = try await request(
            endpoint: APIConfig.Endpoints.presignS3,
            method: "POST",
            body: body,
            authenticated: true
        )
        
        // Upload directly to S3 using the presigned URL
        guard let url = URL(string: presignResponse.url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError("Failed to upload image")
        }
        
        // Return the key/path that was generated
        return presignResponse.key
    }
}

// MARK: - API Methods
extension NetworkManager {
    // MARK: - Auth
    func login(email: String, password: String) async throws -> LoginResponse {
        let body = try JSONEncoder().encode([
            "email": email,
            "password": password
        ])
        
        return try await request(
            endpoint: APIConfig.Endpoints.login,
            method: "POST",
            body: body
        )
    }
    
    func register(email: String, password: String, confirmPassword: String) async throws -> LoginResponse {
        let body = try JSONEncoder().encode([
            "email": email,
            "password": password,
            "password2": confirmPassword
        ])
        
        return try await request(
            endpoint: APIConfig.Endpoints.register,
            method: "POST",
            body: body
        )
    }
    
    func getCurrentUser() async throws -> User {
        return try await request(
            endpoint: APIConfig.Endpoints.currentUser,
            authenticated: true
        )
    }
    
    func requestOTP(email: String) async throws {
        struct OTPResponse: Codable {
            let message: String
            let expiresIn: String?
            
            enum CodingKeys: String, CodingKey {
                case message
                case expiresIn = "expires_in"
            }
        }
        
        let body = try JSONEncoder().encode([
            "email": email
        ])
        
        let _: OTPResponse = try await request(
            endpoint: APIConfig.Endpoints.requestOTP,
            method: "POST",
            body: body
        )
    }
    
    func verifyOTP(email: String, otp: String) async throws -> LoginResponse {
        let body = try JSONEncoder().encode([
            "email": email,
            "otp": otp
        ])
        
        return try await request(
            endpoint: APIConfig.Endpoints.verifyOTP,
            method: "POST",
            body: body
        )
    }
    
    func googleAuth(token: String) async throws -> LoginResponse {
        let body = try JSONEncoder().encode([
            "token": token
        ])
        
        return try await request(
            endpoint: "/users/google-auth/",
            method: "POST",
            body: body
        )
    }
    
    // MARK: - Reports
    func submitReport(title: String, location: String, description: String, imageUrl: String?, department: String? = nil, confidenceScore: Double? = nil) async throws -> Report {
        struct ReportSubmission: Encodable {
            let issueTitle: String
            let location: String
            let issueDescription: String
            let imageUrl: String?
            let department: String?
            let confidenceScore: Double?
            
            enum CodingKeys: String, CodingKey {
                case issueTitle = "issue_title"
                case location
                case issueDescription = "issue_description"
                case imageUrl = "image_url"
                case department
                case confidenceScore = "confidence_score"
            }
        }
        
        let submission = ReportSubmission(
            issueTitle: title,
            location: location,
            issueDescription: description,
            imageUrl: imageUrl,
            department: department,
            confidenceScore: confidenceScore
        )
        
        let body = try JSONEncoder().encode(submission)
        
        return try await request(
            endpoint: APIConfig.Endpoints.reports,
            method: "POST",
            body: body,
            authenticated: true
        )
    }
    
    func getReportByTrackingId(_ trackingId: String) async throws -> Report {
        return try await request(
            endpoint: APIConfig.Endpoints.trackingDetail(trackingId),
            authenticated: false,
            useBaseURL: true
        )
    }
    
    func getPresignedImageURLs(reportId: Int) async throws -> PresignGetResponse {
        return try await request(
            endpoint: APIConfig.Endpoints.presignGet(reportId),
            authenticated: false
        )
    }
    
    func getCommunityPosts(nextUrl: String? = nil) async throws -> CommunityResponse {
        if let nextUrl = nextUrl {
            // Parse the full URL and extract just the path
            guard let url = URL(string: nextUrl),
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw NetworkError.invalidURL
            }
            
            let path = components.path.replacingOccurrences(of: "/api", with: "")
            let query = components.query ?? ""
            let endpoint = query.isEmpty ? path : "\(path)?\(query)"
            
            return try await request(endpoint: endpoint)
        } else {
            return try await request(endpoint: APIConfig.Endpoints.communityResolved)
        }
    }
    
    func getUserHistory() async throws -> [Report] {
        return try await request(
            endpoint: APIConfig.Endpoints.userHistory,
            authenticated: true
        )
    }
    
    // MARK: - Profile
    func getUserProfile() async throws -> UserProfile {
        return try await request(
            endpoint: APIConfig.Endpoints.profile,
            authenticated: true
        )
    }
    
    func verifyAadhaar(aadhaarNumber: String) async throws -> VerifyAadhaarResponse {
        let body = try JSONEncoder().encode([
            "aadhaar_number": aadhaarNumber
        ])
        
        return try await request(
            endpoint: APIConfig.Endpoints.verifyAadhaar,
            method: "POST",
            body: body,
            authenticated: true
        )
    }
    
    // MARK: - ML Prediction
    func predictDepartment(imageBase64: String, title: String, description: String) async throws -> MLPredictionResponse {
        struct PredictionRequest: Encodable {
            let imageBase64: String
            let title: String
            let description: String
            
            enum CodingKeys: String, CodingKey {
                case imageBase64 = "image_base64"
                case title
                case description
            }
        }
        
        let request = PredictionRequest(
            imageBase64: imageBase64,
            title: title,
            description: description
        )
        
        let body = try JSONEncoder().encode(request)
        
        return try await self.request(
            endpoint: "/ml/predict/",
            method: "POST",
            body: body,
            authenticated: true
        )
    }
    
    // MARK: - Blockchain
    func getBlockchainStatus(trackingId: String) async throws -> BlockchainStatusResponse {
        return try await request(
            endpoint: "/blockchain/reports/\(trackingId)/status/",
            authenticated: true
        )
    }
    
    // MARK: - Social Features
    func likeReport(reportId: Int) async throws -> LikeDislikeResponse {
        return try await request(
            endpoint: "/reports/\(reportId)/like/",
            method: "POST",
            authenticated: true
        )
    }
    
    func dislikeReport(reportId: Int) async throws -> LikeDislikeResponse {
        return try await request(
            endpoint: "/reports/\(reportId)/dislike/",
            method: "POST",
            authenticated: true
        )
    }
    
    func getComments(reportId: Int) async throws -> [Comment] {
        return try await request(
            endpoint: "/reports/\(reportId)/comments/",
            authenticated: false
        )
    }
    
    func postComment(reportId: Int, text: String) async throws -> Comment {
        let body = try JSONEncoder().encode([
            "text": text
        ])
        
        return try await request(
            endpoint: "/reports/\(reportId)/comments/",
            method: "POST",
            body: body,
            authenticated: true
        )
    }
}

// MARK: - Response Models
struct CommunityResponse: Codable {
    let next: String?
    let previous: String?
    let results: [Report]
}
