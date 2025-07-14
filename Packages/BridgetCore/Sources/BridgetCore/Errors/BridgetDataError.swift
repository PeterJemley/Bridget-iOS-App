import Foundation

public enum BridgetDataError: Error, LocalizedError {
    case invalidData
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    case saveError(Error)
    case fetchError(Error)
    case deleteError(Error)
    case updateError(Error)
    case invalidDateFormat
    case invalidCoordinateFormat
    case bridgeNotFound(String)
    case duplicateBridge(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Data encoding error: \(error.localizedDescription)"
        case .saveError(let error):
            return "Save error: \(error.localizedDescription)"
        case .fetchError(let error):
            return "Fetch error: \(error.localizedDescription)"
        case .deleteError(let error):
            return "Delete error: \(error.localizedDescription)"
        case .updateError(let error):
            return "Update error: \(error.localizedDescription)"
        case .invalidDateFormat:
            return "Invalid date format"
        case .invalidCoordinateFormat:
            return "Invalid coordinate format"
        case .bridgeNotFound(let bridgeID):
            return "Bridge not found: \(bridgeID)"
        case .duplicateBridge(let bridgeID):
            return "Duplicate bridge: \(bridgeID)"
        }
    }
} 