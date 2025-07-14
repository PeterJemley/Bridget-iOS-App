import Foundation

public enum BridgetDataError: Error, LocalizedError {
    case invalidData(String)
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case updateFailed(Error)
    case invalidDateFormat
    case invalidCoordinateFormat
    case bridgeNotFound(String)
    case duplicateBridge(String)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Data encoding error: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update data: \(error.localizedDescription)"
        case .invalidDateFormat:
            return "Invalid date format"
        case .invalidCoordinateFormat:
            return "Invalid coordinate format"
        case .bridgeNotFound(let bridgeID):
            return "Bridge not found: \(bridgeID)"
        case .duplicateBridge(let bridgeID):
            return "Duplicate bridge: \(bridgeID)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
} 