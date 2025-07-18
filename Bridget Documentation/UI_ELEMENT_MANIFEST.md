// NOTE: Loading experience section and TODOs updated to reflect HIG-aligned plans and current app state as of this commit.
// See below for details on launch, loading, and planned improvements.

// NOTE: LaunchScreen.storyboard has been removed as of this commit. A HIG-compliant launch screen matching the bridge list layout will be restored in a future update. See TODOs below for details.

# UI_ELEMENT_MANIFEST.md

## Launch Screen

- **Status:** Temporarily removed (LaunchScreen.storyboard deleted)
- **Planned:** Will be re-implemented in a future update to match HIG guidance and visually mirror the initial bridge list layout (static, minimal, no logo or catchphrase).
- **TODO:**
  - Recreate LaunchScreen.storyboard
  - Add navigation bar with "Bridges" title
  - Add 2–3 light gray placeholder rows for bridge cards
  - Set background to system background color
  - Ensure no spinners, taglines, or logos unless present in the main UI

---

## Loading Experience (Post-Launch)

- **Current:**
  - After launch, the first SwiftUI screen may show a blank or static state while bridge data is fetched.
  - Logo/catchphrase overlays and global loading screens have been removed.
  - No in-content loading indicator is currently shown.
- **Planned Improvements:**
  - Show cached bridge data instantly if available (never show a blank or static screen).
  - Overlay a small ProgressView (spinner) near the bridge list content during async fetch, not as a global modal.
  - If fetch may take >1s, show skeleton rows or a friendly "Loading bridges…" label to reassure/entertain users.
  - Replace placeholders with real data and remove the indicator as soon as loading completes.
  - Respect Low Power Mode: pause non-essential animations if `ProcessInfo.processInfo.isLowPowerModeEnabled` is true.
- **TODO:**
  - [ ] Implement instant display of cached bridge data on first SwiftUI screen
  - [ ] Add in-content ProgressView (spinner) during data fetch
  - [ ] Add skeleton rows or "Loading bridges…" label for long fetches
  - [ ] Remove loading indicators as soon as data is ready
  - [ ] Pause non-essential animations in Low Power Mode

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
| `BridgeCardView`    | Card-style bridge info with statistics      | Text, Color, VStack, HStack | HIG, tokens      | Yes           | Snapshot     |
| `StatItem`          | Statistics display component                | Text, VStack         | HIG, tokens      | Yes           | Snapshot     |
| `StatisticsCard`    | Advanced statistics with data-driven thresholds | Text, VStack, Color | HIG, tokens      | Yes           | Snapshot     |
| `EnhancedStatisticsCard` | Advanced statistics with drill-down capabilities | Text, VStack, Color, Button | HIG, tokens      | Yes           | Snapshot     |
| `SparklineView`     | Daily activity trend visualization              | Rectangle, Color    | HIG, tokens      | Yes           | Snapshot     |
| `DrillDownView`     | Expandable detailed statistics view            | Text, VStack, Color | HIG, tokens      | Yes           | Snapshot     |
| `FrequencyBadge`    | Color-coded frequency indicator (Low/Medium/High) | Text, Color      | HIG, tokens      | Yes           | Snapshot     |
| `TrafficFlowRowView`| Row for traffic flow info                   | Text, Color, VStack  | HIG, tokens      | Yes           | Snapshot     |
| `RouteRowView`      | Row for route info in list                  | Text, Color, VStack  | HIG, tokens      | Yes           | Snapshot     |

---

## Organisms
*Complex UI sections composed of molecules and atoms.*

| Name                | Description                                 | Molecules/Atoms Used         | HIG/Design Token | Accessibility | Test Coverage |
|---------------------|---------------------------------------------|------------------------------|------------------|---------------|--------------|
| `BridgesListView`   | List of all bridges with card-style statistics | BridgeCardView, StatItem, ContentUnavailableView, LoadingOverlayView | HIG, tokens | Yes | UI/Integration |
| `DashboardView`     | Main dashboard with statistical insights     | StatisticsCard, BridgeCardView, StatItem, ContentUnavailableView | HIG, tokens | Yes | UI/Integration |
| `TrafficFlowView`   | List of all traffic flows                   | TrafficFlowRowView, ContentUnavailableView               | HIG, tokens | Yes | UI/Integration |
| `RoutesView`        | List of all user routes                     | RouteRowView, ContentUnavailableView                     | HIG, tokens | Yes | UI/Integration |
| `SettingsView`      | App settings, data management, info with logo and API link | Button, Text, ProgressView, LoadingOverlayView, Image, Link | HIG, tokens | Yes | UI/Integration |
| `AppBrandingView`   | Logo with laurel decorations, catchphrase, and API link | Text, Image, Link, HStack, VStack | HIG, tokens | Yes | UI/Integration |
| `AboutSectionView`  | Reusable about section with logo, catchphrase, and API link | Text, Image, Link, HStack, VStack | HIG, tokens | Yes | UI/Integration |

---

## Templates & Pages (for future expansion)
*Layouts arranging organisms into full screens.*

| Name                | Description                                 | Organisms Used               | HIG/Design Token | Accessibility | Test Coverage |
|---------------------|---------------------------------------------|------------------------------|------------------|---------------|--------------|
| `ContentView`       | Main app tab view                           | BridgesListView, EventsListView, TrafficFlowView, RoutesView, SettingsView | HIG, tokens | Yes | UI/Integration |

---

## Branding & Identity Elements
*Core branding components for app identity and user experience.*

| Element              | Description                                 | Implementation Status | Design Tokens |
|----------------------|---------------------------------------------|----------------------|---------------|
| `App Logo`           | "Bridget" with laurel.leading/laurel.trailing decorations | ✅ Complete (2025-07-17) | Green laurels, bold title |
| `Catchphrase`        | "Ditch the spanxiety: Bridge the gap between *you* and on time" | ✅ Complete (2025-07-17) | Italic "you", secondary color |
| `API Attribution`    | Seattle Open Data API link with info.circle and arrow.up.right | ✅ Complete (2025-07-17) | Blue link, caption font |
| `Color Palette`      | Green laurels, blue links, system colors    | ✅ Complete (2025-07-17) | HIG-compliant |

**Branding Features:**
- **Laurel Decorations**: Green laurel.leading and laurel.trailing icons flanking the app name
- **Memorable Catchphrase**: Emphasizes the app's value proposition with italicized "you"
- **Data Attribution**: Clear attribution to Seattle Open Data API with external link indicators
- **HIG Compliance**: Uses system colors and typography for accessibility and consistency

---

## Statistical Capabilities (BridgetStatistics Package)
*Advanced statistical methods for data-driven insights.*

| Capability                    | Description                                 | Implementation Status | Test Coverage |
|-------------------------------|---------------------------------------------|----------------------|---------------|
| `DataDrivenThresholds`        | Adaptive thresholds based on data percentiles | ✅ Complete         | 22/22 tests   |
| `ConfidenceIntervals`         | Statistical confidence intervals for estimates | ✅ Complete         | 22/22 tests   |
| `OutlierDetection`            | IQR-based outlier detection and handling    | ✅ Complete         | 22/22 tests   |
| `SeasonalThresholds`          | Time-based seasonal threshold adjustments   | ✅ Complete         | 22/22 tests   |
| `CascadeStatisticsService`    | User-facing cascade strength statistics     | ✅ Complete         | 22/22 tests   |
| `FrequencyLabels`             | User-friendly frequency categorization (Low/Medium/High) | ✅ Complete         | 22/22 tests   |
| `DurationRangeCalculation`    | Fixed: Uses actual duration values for "Typical Duration" display | ✅ Fixed (2025-07-17) | 22/22 tests   |
| `DetailedTimeWindowStrings`   | Context-aware time window descriptions     | ✅ Complete         | 22/22 tests   |
| `SparklineDataGeneration`     | Daily activity data for visualization       | ✅ Complete         | 22/22 tests   |
| `WeekdayWeekendDistribution`  | Activity distribution analysis              | ✅ Complete         | 22/22 tests   |
| `TypicalWaitTimeCalculation`  | Median wait time with confidence intervals  | ✅ Complete         | 22/22 tests   |

**Key Features:**
- **Robust Statistical Methods**: Unbiased estimators, proper percentile calculations, trimmed means
- **User-Focused Output**: "Low", "Medium", "High" labels instead of technical terms
- **Adaptive Thresholds**: Data-driven thresholds that adjust to actual data distribution
- **Confidence Intervals**: Statistical uncertainty quantification for all estimates
- **Outlier Handling**: Automatic detection and handling of statistical outliers
- **Seasonal Analysis**: Support for monthly, weekly, and daily seasonal patterns
- **Duration Range Display**: Fixed "0-0" issue by using actual duration values instead of normalized cascade strengths
- **Enhanced Time Context**: Detailed time window descriptions for better user understanding
- **Sparkline Visualization**: Daily activity trends for quick pattern recognition
- **Weekday/Weekend Analysis**: Activity distribution insights for planning
- **Wait Time Insights**: Typical wait times with confidence intervals for better expectations

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