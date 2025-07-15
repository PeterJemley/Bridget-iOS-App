// SharedModelSchema.swift
// Defines the unified SwiftData schema for the Bridget app, aggregating all @Model types used across modules.
// This centralizes schema management for easier migrations and consistency.

import SwiftData
import BridgetCore

/// Returns the unified SwiftData schema for the Bridget app, including all core @Model types.
/// Update this function whenever a new @Model is added to the data layer.
public func makeBridgetModelSchema() -> Schema {
    Schema([
        Item.self,
        DrawbridgeEvent.self,
        DrawbridgeInfo.self,
        TrafficFlow.self,
        Route.self
    ])
} 
