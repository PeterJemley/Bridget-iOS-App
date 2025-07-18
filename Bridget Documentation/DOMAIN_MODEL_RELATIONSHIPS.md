# Domain Model Relationships Documentation

## Overview

This document describes the relationship rules and delete behaviors for the Bridget app's domain model, specifically the relationship between `DrawbridgeInfo` (bridges) and `DrawbridgeEvent` (events).

## Domain Rules

### Core Principle
**Events are meaningless without a bridge.** This fundamental domain rule drives all relationship configurations and delete behaviors.

### Relationship Structure

```
DrawbridgeInfo (Parent) ←→ DrawbridgeEvent (Child)
    1 bridge                    many events
```

## Model Configuration

### DrawbridgeInfo (Parent)
```swift
@Model
public final class DrawbridgeInfo {
    // ... other properties
    
    @Relationship(deleteRule: .cascade, inverse: \DrawbridgeEvent.bridge) 
    public var events: [DrawbridgeEvent] = []
}
```

**Delete Rule: `.cascade`**
- **Behavior**: When a `DrawbridgeInfo` is deleted, all related `DrawbridgeEvent` objects are automatically deleted
- **Rationale**: Events are meaningless without their parent bridge, so they should be removed when the bridge is deleted
- **Domain Logic**: If a bridge no longer exists, its historical events are no longer relevant

### DrawbridgeEvent (Child)
```swift
@Model
public final class DrawbridgeEvent {
    // ... other properties
    
    @Relationship(deleteRule: .nullify) 
    public var bridge: DrawbridgeInfo  // Non-optional
}
```

**Delete Rule: `.nullify`**
- **Behavior**: When a `DrawbridgeEvent` is deleted, the bridge relationship is set to nil (though this should never happen due to cascade)
- **Rationale**: If an event is deleted, the bridge should remain intact
- **Domain Logic**: Bridge existence is independent of individual events

## Delete Rule Choices Explained

### Why `.cascade` on Parent?
1. **Domain Semantics**: Events cannot exist without a bridge
2. **Data Integrity**: Prevents orphaned events in the database
3. **Business Logic**: If a bridge is removed from the system, its events are no longer relevant
4. **Performance**: Automatic cleanup reduces manual relationship management

### Why `.nullify` on Child?
1. **Bidirectional Safety**: Ensures proper cleanup if events are manually deleted
2. **SwiftData Best Practice**: One side of bidirectional relationship should use cascade, the other nullify
3. **Defensive Programming**: Handles edge cases gracefully

## Code Patterns

### Safe Access Patterns

#### ✅ Recommended (Current Implementation)
```swift
// In UI Views
if let bridge = event.bridge {
    Text("Bridge Name: \(bridge.entityName)")
} else {
    Text("Bridge Name: Unknown")
        .foregroundColor(.secondary)
}

// In Tests
XCTAssertEqual(events.first?.bridge.entityID, bridges.first?.entityID)
```

#### ❌ Avoid
```swift
// Force unwrapping - dangerous
Text("Bridge Name: \(event.bridge!.entityName)")

// Unnecessary nil handling - bridge should never be nil
guard let bridge = event.bridge else {
    // This should never happen in normal operation
    return
}
```

## Test Implications

### Teardown Strategy
With cascade delete rules, test teardown is simplified:

```swift
override func tearDown() async throws {
    // With cascade delete rules, deleting bridges will automatically delete their events
    if let modelContext = modelContext {
        let bridges = try modelContext.fetch(FetchDescriptor<DrawbridgeInfo>())
        for bridge in bridges {
            modelContext.delete(bridge)
        }
    }
    // Events are automatically cleaned up by cascade delete
}
```

### Test Data Creation
Always ensure events have valid bridge references:

```swift
let bridge = DrawbridgeInfo(entityID: "BRIDGE001", ...)
let event = DrawbridgeEvent(bridge: bridge, ...)  // Valid reference
```

## Migration Considerations

### Schema Changes
- **From `.nullify` to `.cascade`**: Safe migration, existing data remains intact
- **From `.cascade` to `.nullify`**: Requires careful consideration of orphaned events

### Data Validation
After migration, validate that no orphaned events exist:

```swift
let orphanedEvents = try modelContext.fetch(
    FetchDescriptor<DrawbridgeEvent>(
        predicate: #Predicate { $0.bridge == nil }
    )
)
XCTAssertTrue(orphanedEvents.isEmpty, "No orphaned events should exist")
```

## Best Practices

### 1. Never Assume Bridge is Nil
- Bridge is non-optional in the model
- Use defensive programming in UI code
- Add nil checks for unexpected edge cases

### 2. Leverage Cascade Delete
- Simplify teardown logic
- Trust SwiftData to handle relationship cleanup
- Focus on business logic, not relationship management

### 3. Test Relationship Integrity
- Verify cascade delete works correctly
- Test that no orphaned events are created
- Ensure bidirectional relationships are properly configured

### 4. Document Domain Rules
- Clear documentation of relationship semantics
- Rationale for delete rule choices
- Examples of safe access patterns

## Troubleshooting

### Common Issues

#### "Cannot remove DrawbridgeInfo from relationship bridge"
- **Cause**: Orphaned events with nil bridge references
- **Solution**: Ensure cascade delete is properly configured
- **Prevention**: Use cascade delete rules and proper teardown

#### EXC_BAD_ACCESS in Tests
- **Cause**: Memory access issues during relationship cleanup
- **Solution**: Clean build and derived data
- **Prevention**: Proper test isolation and teardown

### Debugging Tips
1. Check relationship configuration in model files
2. Verify cascade delete rules are applied
3. Use SwiftData debugging tools to inspect relationships
4. Test with minimal data sets to isolate issues

## Future Considerations

### Potential Enhancements
1. **Audit Trail**: Consider soft deletes for historical preservation
2. **Event Archiving**: Move old events to separate storage
3. **Relationship Validation**: Add runtime checks for data integrity
4. **Performance Monitoring**: Track relationship operation performance

### Scalability
- Current design supports thousands of events per bridge
- Consider indexing strategies for large datasets
- Monitor memory usage with large relationship graphs 