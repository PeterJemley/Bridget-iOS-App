import Foundation
import SwiftData

@Model
public final class TrafficFlow {
    @Attribute(.unique) public var id: UUID
    public var bridgeID: String
    public var timestamp: Date
    public var congestionLevel: Double
    public var trafficVolume: Double
    public var correlationScore: Double
    
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