import Foundation

// MARK: - NetworkProcessor Messages

/// Messages sent to NetworkProcessor actor
public enum NetworkProcessorMessage: Sendable {
    case fetchBridgeData(limit: Int, offset: Int)
    case fetchEventData(limit: Int, offset: Int)
    case fetchTrafficData(bridgeID: String?)
    case validateConnection
    case fetchAllData(limit: Int, offset: Int)
    case retryFailedRequest(endpoint: String, retryCount: Int)
}

/// Responses from NetworkProcessor actor
public enum NetworkProcessorResponse: Sendable {
    case bridgeData([BridgeInfoDTO])
    case eventData([BridgeEventDTO])
    case trafficData([TrafficFlowDTO])
    case allData(SyncDataDTO)
    case connectionStatus(Bool)
    case error(ActorError)
    case progress(NetworkProgressDTO)
}

// MARK: - BackgroundDataProcessor Messages

/// Messages sent to BackgroundDataProcessor actor
public enum BackgroundProcessorMessage: Sendable {
    case processSyncData(SyncDataDTO)
    case cleanupOldData(olderThan: Date)
    case analyzeTrafficPatterns(bridgeID: String)
    case generateStatistics
    case validateDataIntegrity(SyncDataDTO)
    case compressData(SyncDataDTO)
    case backupData(SyncDataDTO)
}

/// Responses from BackgroundDataProcessor actor
public enum BackgroundProcessorResponse: Sendable {
    case syncComplete(SyncDataDTO)
    case cleanupComplete(Int) // Number of records deleted
    case analysisComplete(TrafficAnalysisDTO)
    case statisticsComplete(StatisticsDTO)
    case validationComplete(DataValidationDTO)
    case compressionComplete(CompressedDataDTO)
    case backupComplete(BackupResultDTO)
    case error(ActorError)
    case progress(ProcessingProgressDTO)
}

// MARK: - Data Transfer Objects for Messages

/// Progress tracking for network operations
public struct NetworkProgressDTO: Sendable, Codable {
    public let currentStep: String
    public let totalSteps: Int
    public let currentStepNumber: Int
    public let percentage: Double
    public let estimatedTimeRemaining: TimeInterval?
    public let timestamp: Date
    
    public init(
        currentStep: String,
        totalSteps: Int,
        currentStepNumber: Int,
        percentage: Double,
        estimatedTimeRemaining: TimeInterval? = nil,
        timestamp: Date = Date()
    ) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.currentStepNumber = currentStepNumber
        self.percentage = percentage
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.timestamp = timestamp
    }
    
    public var isComplete: Bool {
        currentStepNumber >= totalSteps
    }
    
    public var progressDisplay: String {
        "\(currentStep) (\(currentStepNumber)/\(totalSteps))"
    }
    
    public var percentageDisplay: String {
        String(format: "%.1f%%", percentage * 100)
    }
}

/// Progress tracking for background processing
public struct ProcessingProgressDTO: Sendable, Codable {
    public let operation: String
    public let currentItem: Int
    public let totalItems: Int
    public let percentage: Double
    public let estimatedTimeRemaining: TimeInterval?
    public let timestamp: Date
    
    public init(
        operation: String,
        currentItem: Int,
        totalItems: Int,
        percentage: Double,
        estimatedTimeRemaining: TimeInterval? = nil,
        timestamp: Date = Date()
    ) {
        self.operation = operation
        self.currentItem = currentItem
        self.totalItems = totalItems
        self.percentage = percentage
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.timestamp = timestamp
    }
    
    public var isComplete: Bool {
        currentItem >= totalItems
    }
    
    public var progressDisplay: String {
        "\(operation) (\(currentItem)/\(totalItems))"
    }
    
    public var percentageDisplay: String {
        String(format: "%.1f%%", percentage * 100)
    }
}

/// Traffic analysis results
public struct TrafficAnalysisDTO: Sendable, Codable {
    public let bridgeID: String
    public let analysisTimestamp: Date
    public let congestionTrend: String
    public let peakHours: [Int]
    public let averageCongestion: Double
    public let correlationWithBridgeActivity: Double
    public let recommendations: [String]
    
    public init(
        bridgeID: String,
        analysisTimestamp: Date = Date(),
        congestionTrend: String,
        peakHours: [Int],
        averageCongestion: Double,
        correlationWithBridgeActivity: Double,
        recommendations: [String]
    ) {
        self.bridgeID = bridgeID
        self.analysisTimestamp = analysisTimestamp
        self.congestionTrend = congestionTrend
        self.peakHours = peakHours
        self.averageCongestion = averageCongestion
        self.correlationWithBridgeActivity = correlationWithBridgeActivity
        self.recommendations = recommendations
    }
}

/// Statistical analysis results
public struct StatisticsDTO: Sendable, Codable {
    public let totalBridges: Int
    public let totalEvents: Int
    public let totalRoutes: Int
    public let totalTrafficFlows: Int
    public let openBridges: Int
    public let recentEvents: Int
    public let averageEventDuration: TimeInterval
    public let mostActiveBridge: String?
    public let busiestHour: Int?
    public let busiestDay: String?
    public let generatedAt: Date
    
    public init(
        totalBridges: Int,
        totalEvents: Int,
        totalRoutes: Int,
        totalTrafficFlows: Int,
        openBridges: Int,
        recentEvents: Int,
        averageEventDuration: TimeInterval,
        mostActiveBridge: String? = nil,
        busiestHour: Int? = nil,
        busiestDay: String? = nil,
        generatedAt: Date = Date()
    ) {
        self.totalBridges = totalBridges
        self.totalEvents = totalEvents
        self.totalRoutes = totalRoutes
        self.totalTrafficFlows = totalTrafficFlows
        self.openBridges = openBridges
        self.recentEvents = recentEvents
        self.averageEventDuration = averageEventDuration
        self.mostActiveBridge = mostActiveBridge
        self.busiestHour = busiestHour
        self.busiestDay = busiestDay
        self.generatedAt = generatedAt
    }
}

/// Data validation results
public struct DataValidationDTO: Sendable, Codable {
    public let isValid: Bool
    public let validationErrors: [String]
    public let warnings: [String]
    public let dataQualityScore: Double
    public let validatedAt: Date
    
    public init(
        isValid: Bool,
        validationErrors: [String] = [],
        warnings: [String] = [],
        dataQualityScore: Double,
        validatedAt: Date = Date()
    ) {
        self.isValid = isValid
        self.validationErrors = validationErrors
        self.warnings = warnings
        self.dataQualityScore = dataQualityScore
        self.validatedAt = validatedAt
    }
    
    public var qualityDisplay: String {
        String(format: "%.1f%%", dataQualityScore * 100)
    }
    
    public var hasErrors: Bool {
        !validationErrors.isEmpty
    }
    
    public var hasWarnings: Bool {
        !warnings.isEmpty
    }
}

/// Compressed data for storage optimization
public struct CompressedDataDTO: Sendable, Codable {
    public let originalSize: Int
    public let compressedSize: Int
    public let compressionRatio: Double
    public let compressionAlgorithm: String
    public let compressedAt: Date
    
    public init(
        originalSize: Int,
        compressedSize: Int,
        compressionAlgorithm: String = "gzip",
        compressedAt: Date = Date()
    ) {
        self.originalSize = originalSize
        self.compressedSize = compressedSize
        self.compressionRatio = Double(compressedSize) / Double(originalSize)
        self.compressionAlgorithm = compressionAlgorithm
        self.compressedAt = compressedAt
    }
    
    public var spaceSaved: Int {
        originalSize - compressedSize
    }
    
    public var spaceSavedDisplay: String {
        let bytes = spaceSaved
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
    
    public var compressionRatioDisplay: String {
        String(format: "%.1f%%", (1.0 - compressionRatio) * 100)
    }
}

/// Backup operation results
public struct BackupResultDTO: Sendable, Codable {
    public let success: Bool
    public let backupLocation: String
    public let backupSize: Int
    public let backupTimestamp: Date
    public let error: String?
    
    public init(
        success: Bool,
        backupLocation: String,
        backupSize: Int,
        backupTimestamp: Date = Date(),
        error: String? = nil
    ) {
        self.success = success
        self.backupLocation = backupLocation
        self.backupSize = backupSize
        self.backupTimestamp = backupTimestamp
        self.error = error
    }
    
    public var backupSizeDisplay: String {
        let bytes = backupSize
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
}

// MARK: - Actor Error Types

/// Comprehensive error types for actor communication
public enum ActorError: Sendable, LocalizedError {
    case networkError(String)
    case dataError(String)
    case processingError(String)
    case validationError(String)
    case timeoutError(String)
    case resourceError(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .dataError(let message):
            return "Data error: \(message)"
        case .processingError(let message):
            return "Processing error: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .timeoutError(let message):
            return "Timeout error: \(message)"
        case .resourceError(let message):
            return "Resource error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again."
        case .dataError:
            return "The data may be corrupted. Try refreshing."
        case .processingError:
            return "The operation failed. Please try again."
        case .validationError:
            return "The data format is invalid. Please check your input."
        case .timeoutError:
            return "The operation took too long. Please try again."
        case .resourceError:
            return "System resources are unavailable. Please try again later."
        case .configurationError:
            return "The system is not properly configured. Please contact support."
        }
    }
    
    public var shouldRetry: Bool {
        switch self {
        case .networkError, .timeoutError, .resourceError:
            return true
        case .dataError, .validationError, .configurationError:
            return false
        case .processingError:
            return false // Depends on the specific error
        }
    }
    
    public var retryDelay: TimeInterval {
        switch self {
        case .networkError:
            return 5.0
        case .timeoutError:
            return 2.0
        case .resourceError:
            return 10.0
        case .dataError, .validationError, .configurationError, .processingError:
            return 0.0
        }
    }
}

// MARK: - Actor Protocol Definitions

/// Protocol for network processing operations
public protocol NetworkProcessing {
    func fetchBridgeData(limit: Int, offset: Int) async throws -> [BridgeInfoDTO]
    func fetchEventData(limit: Int, offset: Int) async throws -> [BridgeEventDTO]
    func fetchTrafficData(bridgeID: String?) async throws -> [TrafficFlowDTO]
    func validateConnection() async throws -> Bool
    func fetchAllData(limit: Int, offset: Int) async throws -> SyncDataDTO
}

/// Protocol for background processing operations
public protocol BackgroundProcessing {
    func processSyncData(_ data: SyncDataDTO) async throws -> SyncDataDTO
    func cleanupOldData(olderThan: Date) async throws -> Int
    func analyzeTrafficPatterns(bridgeID: String) async throws -> TrafficAnalysisDTO
    func generateStatistics() async throws -> StatisticsDTO
    func validateDataIntegrity(_ data: SyncDataDTO) async throws -> DataValidationDTO
    func compressData(_ data: SyncDataDTO) async throws -> CompressedDataDTO
    func backupData(_ data: SyncDataDTO) async throws -> BackupResultDTO
} 