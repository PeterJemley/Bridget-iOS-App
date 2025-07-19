import Foundation
import SwiftData

/// Sendable Data Transfer Object for TrafficFlow
/// Used for safe actor boundary crossing in concurrent operations
public struct TrafficFlowDTO: Sendable, Codable, Identifiable, Hashable {
    public let id: UUID
    public let bridgeID: String // Bridge identifier
    public let timestamp: Date
    public let congestionLevel: Double
    public let trafficVolume: Double
    public let correlationScore: Double
    
    /// Initialize from a TrafficFlow model
    /// - Parameter flow: The TrafficFlow model to convert
    public init(from flow: TrafficFlow) {
        self.id = flow.id
        self.bridgeID = flow.bridgeID
        self.timestamp = flow.timestamp
        self.congestionLevel = flow.congestionLevel
        self.trafficVolume = flow.trafficVolume
        self.correlationScore = flow.correlationScore
    }
    
    /// Initialize with individual properties
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - bridgeID: Bridge identifier
    ///   - timestamp: Flow measurement timestamp
    ///   - congestionLevel: Congestion level (0-1)
    ///   - trafficVolume: Traffic volume measurement
    ///   - correlationScore: Correlation score with bridge activity
    public init(
        id: UUID = UUID(),
        bridgeID: String,
        timestamp: Date = Date(),
        congestionLevel: Double,
        trafficVolume: Double,
        correlationScore: Double = 0.0
    ) {
        self.id = id
        self.bridgeID = bridgeID
        self.timestamp = timestamp
        self.congestionLevel = congestionLevel
        self.trafficVolume = trafficVolume
        self.correlationScore = correlationScore
    }
}

// MARK: - Convenience Extensions

public extension TrafficFlowDTO {
    /// Get congestion level as percentage
    var congestionPercentage: Double {
        congestionLevel * 100.0
    }
    
    /// Get congestion level as display string
    var congestionDisplay: String {
        String(format: "%.1f%%", congestionPercentage)
    }
    
    /// Get congestion level category
    var congestionCategory: CongestionCategory {
        switch congestionLevel {
        case 0.0..<0.3:
            return .low
        case 0.3..<0.7:
            return .medium
        case 0.7..<0.9:
            return .high
        default:
            return .severe
        }
    }
    
    /// Get congestion category color (for UI)
    var congestionColor: String {
        switch congestionCategory {
        case .low:
            return "green"
        case .medium:
            return "yellow"
        case .high:
            return "orange"
        case .severe:
            return "red"
        }
    }
    
    /// Get traffic volume as display string
    var trafficVolumeDisplay: String {
        if trafficVolume >= 1000 {
            return String(format: "%.1fk", trafficVolume / 1000)
        } else {
            return String(format: "%.0f", trafficVolume)
        }
    }
    
    /// Get correlation score as percentage
    var correlationPercentage: Double {
        correlationScore * 100.0
    }
    
    /// Get correlation score as display string
    var correlationDisplay: String {
        String(format: "%.1f%%", correlationPercentage)
    }
    
    /// Check if correlation is significant (> 0.5)
    var hasSignificantCorrelation: Bool {
        correlationScore > 0.5
    }
    
    /// Check if data is recent (within last hour)
    var isRecent: Bool {
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        return timestamp > oneHourAgo
    }
    
    /// Check if data is stale (older than 24 hours)
    var isStale: Bool {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return timestamp < oneDayAgo
    }
    
    /// Get data age in minutes
    var ageInMinutes: Int {
        Calendar.current.dateComponents([.minute], from: timestamp, to: Date()).minute ?? 0
    }
    
    /// Get data age as display string
    var ageDisplay: String {
        let minutes = ageInMinutes
        switch minutes {
        case 0...1:
            return "Just now"
        case 2...59:
            return "\(minutes)m ago"
        case 60...119:
            return "1h ago"
        case 120...1439:
            let hours = minutes / 60
            return "\(hours)h ago"
        default:
            let days = minutes / 1440
            return "\(days)d ago"
        }
    }
    
    /// Calculate traffic density (volume per unit area)
    /// - Parameter area: Area in square meters
    /// - Returns: Traffic density
    func trafficDensity(area: Double) -> Double {
        guard area > 0 else { return 0 }
        return trafficVolume / area
    }
    
    /// Check if traffic flow indicates potential bridge opening
    var indicatesBridgeOpening: Bool {
        // High congestion + significant correlation suggests bridge might open
        congestionLevel > 0.7 && correlationScore > 0.6
    }
    
    /// Get traffic flow summary
    var summary: String {
        "\(congestionDisplay) congestion, \(trafficVolumeDisplay) volume"
    }
}

// MARK: - Congestion Category

public enum CongestionCategory: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case severe = "Severe"
    
    public var description: String {
        switch self {
        case .low:
            return "Light traffic, normal flow"
        case .medium:
            return "Moderate traffic, some delays"
        case .high:
            return "Heavy traffic, significant delays"
        case .severe:
            return "Gridlock, major delays expected"
        }
    }
    
    public var icon: String {
        switch self {
        case .low:
            return "car.fill"
        case .medium:
            return "car.2.fill"
        case .high:
            return "car.3.fill"
        case .severe:
            return "car.3.fill"
        }
    }
}

// MARK: - Equatable Implementation

public extension TrafficFlowDTO {
    static func == (lhs: TrafficFlowDTO, rhs: TrafficFlowDTO) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Comparable Implementation

extension TrafficFlowDTO: Comparable {
    public static func < (lhs: TrafficFlowDTO, rhs: TrafficFlowDTO) -> Bool {
        // Sort by timestamp (newest first)
        lhs.timestamp > rhs.timestamp
    }
} 