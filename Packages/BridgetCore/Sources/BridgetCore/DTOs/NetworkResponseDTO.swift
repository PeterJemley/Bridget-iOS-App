import Foundation

/// Sendable Data Transfer Object for network responses
/// Used for safe actor boundary crossing in concurrent operations
public struct NetworkResponseDTO: Sendable, Codable, Hashable {
    public let success: Bool
    public let data: Data?
    public let error: String?
    public let timestamp: Date
    public let endpoint: String
    public let statusCode: Int?
    public let responseTime: TimeInterval?
    
    /// Initialize with all required parameters
    /// - Parameters:
    ///   - success: Whether the request was successful
    ///   - data: Response data (optional)
    ///   - error: Error message (optional)
    ///   - timestamp: When the response was received
    ///   - endpoint: API endpoint that was called
    ///   - statusCode: HTTP status code (optional)
    ///   - responseTime: Response time in seconds (optional)
    public init(
        success: Bool,
        data: Data? = nil,
        error: String? = nil,
        timestamp: Date = Date(),
        endpoint: String,
        statusCode: Int? = nil,
        responseTime: TimeInterval? = nil
    ) {
        self.success = success
        self.data = data
        self.error = error
        self.timestamp = timestamp
        self.endpoint = endpoint
        self.statusCode = statusCode
        self.responseTime = responseTime
    }
    
    /// Create successful response
    /// - Parameters:
    ///   - data: Response data
    ///   - endpoint: API endpoint that was called
    ///   - statusCode: HTTP status code
    ///   - responseTime: Response time in seconds
    /// - Returns: Successful NetworkResponseDTO
    public static func success(
        data: Data,
        endpoint: String,
        statusCode: Int = 200,
        responseTime: TimeInterval? = nil
    ) -> NetworkResponseDTO {
        NetworkResponseDTO(
            success: true,
            data: data,
            error: nil,
            timestamp: Date(),
            endpoint: endpoint,
            statusCode: statusCode,
            responseTime: responseTime
        )
    }
    
    /// Create error response
    /// - Parameters:
    ///   - error: Error message
    ///   - endpoint: API endpoint that was called
    ///   - statusCode: HTTP status code (optional)
    ///   - responseTime: Response time in seconds (optional)
    /// - Returns: Error NetworkResponseDTO
    public static func error(
        _ error: String,
        endpoint: String,
        statusCode: Int? = nil,
        responseTime: TimeInterval? = nil
    ) -> NetworkResponseDTO {
        NetworkResponseDTO(
            success: false,
            data: nil,
            error: error,
            timestamp: Date(),
            endpoint: endpoint,
            statusCode: statusCode,
            responseTime: responseTime
        )
    }
    
    /// Create timeout response
    /// - Parameters:
    ///   - endpoint: API endpoint that was called
    ///   - timeout: Timeout duration
    /// - Returns: Timeout NetworkResponseDTO
    public static func timeout(
        endpoint: String,
        timeout: TimeInterval
    ) -> NetworkResponseDTO {
        NetworkResponseDTO(
            success: false,
            data: nil,
            error: "Request timed out after \(Int(timeout)) seconds",
            timestamp: Date(),
            endpoint: endpoint,
            statusCode: nil,
            responseTime: timeout
        )
    }
    
    /// Create network error response
    /// - Parameters:
    ///   - networkError: Network error description
    ///   - endpoint: API endpoint that was called
    /// - Returns: Network error NetworkResponseDTO
    public static func networkError(
        _ networkError: String,
        endpoint: String
    ) -> NetworkResponseDTO {
        NetworkResponseDTO(
            success: false,
            data: nil,
            error: "Network error: \(networkError)",
            timestamp: Date(),
            endpoint: endpoint,
            statusCode: nil,
            responseTime: nil
        )
    }
}

// MARK: - Convenience Extensions

public extension NetworkResponseDTO {
    /// Check if response indicates a client error (4xx)
    var isClientError: Bool {
        guard let statusCode = statusCode else { return false }
        return statusCode >= 400 && statusCode < 500
    }
    
    /// Check if response indicates a server error (5xx)
    var isServerError: Bool {
        guard let statusCode = statusCode else { return false }
        return statusCode >= 500 && statusCode < 600
    }
    
    /// Check if response indicates a successful status code
    var hasSuccessfulStatusCode: Bool {
        guard let statusCode = statusCode else { return false }
        return statusCode >= 200 && statusCode < 300
    }
    
    /// Check if response is a timeout
    var isTimeout: Bool {
        error?.contains("timed out") == true
    }
    
    /// Check if response is a network error
    var isNetworkError: Bool {
        error?.contains("Network error") == true
    }
    
    /// Get response size in bytes
    var responseSize: Int {
        data?.count ?? 0
    }
    
    /// Get response size as display string
    var responseSizeDisplay: String {
        let bytes = responseSize
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
    
    /// Get response time as display string
    var responseTimeDisplay: String {
        guard let responseTime = responseTime else { return "Unknown" }
        
        if responseTime < 1.0 {
            return String(format: "%.0fms", responseTime * 1000)
        } else {
            return String(format: "%.2fs", responseTime)
        }
    }
    
    /// Get response age in seconds
    var responseAgeInSeconds: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
    
    /// Check if response is recent (within last minute)
    var isRecent: Bool {
        responseAgeInSeconds < 60
    }
    
    /// Check if response is stale (older than 5 minutes)
    var isStale: Bool {
        responseAgeInSeconds > 300
    }
    
    /// Get response age as display string
    var responseAgeDisplay: String {
        let seconds = Int(responseAgeInSeconds)
        switch seconds {
        case 0...59:
            return "\(seconds)s ago"
        case 60...3599:
            let minutes = seconds / 60
            return "\(minutes)m ago"
        case 3600...86399:
            let hours = seconds / 3600
            return "\(hours)h ago"
        default:
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
    
    /// Get error type for categorization
    var errorType: NetworkErrorType {
        if isTimeout {
            return .timeout
        } else if isNetworkError {
            return .network
        } else if isClientError {
            return .client
        } else if isServerError {
            return .server
        } else if !success {
            return .unknown
        } else {
            return .none
        }
    }
    
    /// Get user-friendly error message
    var userFriendlyError: String {
        switch errorType {
        case .timeout:
            return "Request timed out. Please try again."
        case .network:
            return "Network connection issue. Please check your internet connection."
        case .client:
            return "Invalid request. Please try again."
        case .server:
            return "Server error. Please try again later."
        case .unknown:
            return error ?? "An unknown error occurred."
        case .none:
            return "No error"
        }
    }
    
    /// Check if response should be retried
    var shouldRetry: Bool {
        switch errorType {
        case .timeout, .network, .server:
            return true
        case .client, .unknown, .none:
            return false
        }
    }
    
    /// Get retry delay recommendation in seconds
    var retryDelay: TimeInterval {
        switch errorType {
        case .timeout:
            return 2.0
        case .network:
            return 5.0
        case .server:
            return 10.0
        case .client, .unknown, .none:
            return 0.0
        }
    }
    
    /// Decode response data to specified type
    /// - Parameter type: Type to decode to
    /// - Returns: Decoded object or nil if decoding fails
    func decode<T: Decodable>(as type: T.Type) -> T? {
        guard let data = data else { return nil }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            return nil
        }
    }
    
    /// Get response summary for logging
    var logSummary: String {
        if success {
            return "✅ \(endpoint) - \(statusCode ?? 0) (\(responseTimeDisplay))"
        } else {
            return "❌ \(endpoint) - \(errorType.rawValue): \(error ?? "Unknown error")"
        }
    }
}

// MARK: - Network Error Type

public enum NetworkErrorType: String, CaseIterable {
    case none = "None"
    case timeout = "Timeout"
    case network = "Network"
    case client = "Client"
    case server = "Server"
    case unknown = "Unknown"
}

// MARK: - Equatable Implementation

public extension NetworkResponseDTO {
    static func == (lhs: NetworkResponseDTO, rhs: NetworkResponseDTO) -> Bool {
        lhs.success == rhs.success &&
        lhs.data == rhs.data &&
        lhs.error == rhs.error &&
        lhs.timestamp == rhs.timestamp &&
        lhs.endpoint == rhs.endpoint &&
        lhs.statusCode == rhs.statusCode &&
        lhs.responseTime == rhs.responseTime
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(success)
        hasher.combine(data)
        hasher.combine(error)
        hasher.combine(timestamp)
        hasher.combine(endpoint)
        hasher.combine(statusCode)
        hasher.combine(responseTime)
    }
} 