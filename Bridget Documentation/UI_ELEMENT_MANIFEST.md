# UI Element Manifest: Atomic Design System

This manifest catalogs all reusable UI components in the Bridget app, organized by Atomic Design methodology (Atoms, Molecules, Organisms). It is intended as a living document to support design, development, accessibility, and automated testing.

---

## Atoms
*Smallest, indivisible UI building blocks.*

| Name                | Description                                 | HIG/Design Token | Accessibility | Test Coverage |
|---------------------|---------------------------------------------|------------------|---------------|--------------|
| `ProgressView`      | System indeterminate loading spinner         | HIG-compliant    | Yes           | Snapshot/UI  |
| `Text`              | Typography, labels, captions                 | HIG, tokens      | Yes           | Snapshot     |
| `Button`            | Basic interactive button                     | HIG, tokens      | Yes           | Snapshot     |
| `Color`             | Color tokens (system, accent, etc.)          | HIG, tokens      | N/A           | N/A          |
| `Image`             | Icon glyphs, system images                   | HIG, tokens      | Yes           | Snapshot     |

---

## Molecules
*Combinations of atoms forming small, reusable components.*

| Name                | Description                                 | Atoms Used           | HIG/Design Token | Accessibility | Test Coverage |
|---------------------|---------------------------------------------|----------------------|------------------|---------------|--------------|
| `LoadingOverlayView`| Full-screen loading overlay with label      | ProgressView, Text   | HIG-compliant    | Yes           | Snapshot/UI  |
| `ContentUnavailableView` | Empty state for lists                   | Text, Image          | HIG, tokens      | Yes           | Snapshot     |
| `BridgeRowView`     | Row for bridge info in list                 | Text, Color, HStack  | HIG, tokens      | Yes           | Snapshot     |
| `EventRowView`      | Row for event info in list                  | Text, Color, VStack  | HIG, tokens      | Yes           | Snapshot     |
| `TrafficFlowRowView`| Row for traffic flow info                   | Text, Color, VStack  | HIG, tokens      | Yes           | Snapshot     |
| `RouteRowView`      | Row for route info in list                  | Text, Color, VStack  | HIG, tokens      | Yes           | Snapshot     |

---

## Organisms
*Complex UI sections composed of molecules and atoms.*

| Name                | Description                                 | Molecules/Atoms Used         | HIG/Design Token | Accessibility | Test Coverage |
|---------------------|---------------------------------------------|------------------------------|------------------|---------------|--------------|
| `BridgesListView`   | List of all bridges                         | BridgeRowView, ContentUnavailableView, LoadingOverlayView | HIG, tokens | Yes | UI/Integration |
| `EventsListView`    | List of all bridge events                   | EventRowView, ContentUnavailableView, LoadingOverlayView  | HIG, tokens | Yes | UI/Integration |
| `TrafficFlowView`   | List of all traffic flows                   | TrafficFlowRowView, ContentUnavailableView               | HIG, tokens | Yes | UI/Integration |
| `RoutesView`        | List of all user routes                     | RouteRowView, ContentUnavailableView                     | HIG, tokens | Yes | UI/Integration |
| `SettingsView`      | App settings, data management, info         | Button, Text, ProgressView, LoadingOverlayView           | HIG, tokens | Yes | UI/Integration |

---

## Templates & Pages (for future expansion)
*Layouts arranging organisms into full screens.*

| Name                | Description                                 | Organisms Used               | HIG/Design Token | Accessibility | Test Coverage |
|---------------------|---------------------------------------------|------------------------------|------------------|---------------|--------------|
| `ContentView`       | Main app tab view                           | BridgesListView, EventsListView, TrafficFlowView, RoutesView, SettingsView | HIG, tokens | Yes | UI/Integration |

---

## Manifest Usage & Automation
- **Scalability:** Add new atoms/molecules/organisms as they are created.
- **Clarity:** Each entry should link to its source file and design spec (future).
- **Automation:**
  - Lint rules for design tokens and spacing at atom/molecule level
  - Snapshot tests for molecules
  - Accessibility and integration tests for organisms
- **HIG Compliance:** All components must meet Apple’s Human Interface Guidelines for iOS.
- **Accessibility:** All interactive and visible elements must be accessible via VoiceOver and support Dynamic Type.

---

*This manifest is a living document. Update as new UI elements are added or refactored.* 