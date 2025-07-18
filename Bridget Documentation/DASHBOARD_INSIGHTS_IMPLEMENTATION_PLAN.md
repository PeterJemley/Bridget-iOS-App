# 🏗️ Proactive Stepwise Coding Plan for Dashboard Insight Cards

**Last Updated:** July 17, 2025

> **Testing Policy:** All tests for SwiftData methods must be written using XCTest, follow a proactive stepwise plan, comply with Apple's SwiftData guidelines, and be discoverable and runnable in Xcode.

This document outlines a modular, actionable plan for implementing four key dashboard insight cards in the Bridget app. Each phase is designed for smooth progress, easy testing, and maintainability.

---

## 📈 Overall Recommendations for Dashboard Metrics

- **Trade σ for Ranges:** Standard deviation is great for analysts, but everyday users grasp “5–10 min” far better than “μ=7 min, σ=2 min.”
- **Always show time horizons:** Prefix every stat with “Over the last X days/weeks” so nobody misinterprets the raw numbers.
- **Use labels, not raw numbers:** “Rarely,” “Sometimes,” “Often” map directly to user intuition; behind the scenes you can tie them to quartiles or fixed cutoffs.
- **Visualize distributions:** A small histogram or sparkline can show the full spread of delays or strengths at a glance.
- **Keep math off the main UI:** If you really need to expose median or percentiles, tuck them into a “More details” drill-down, not the headline stats.

By reframing each of these calculations into user-centric language, time-bounded metrics, and intuitive visuals (ranges, bars, labels), you’ll turn a suite of “advanced statistics” into actionable insights that drive better decisions—without ever mentioning σ or quartiles on the surface.

---

## Phase 1: Data Layer Preparation

### Statistical Best Practices & Implementation Notes

- **Use unbiased estimators** (divide by N-1 for sample σ) unless you are truly working with the full population.
- **Compute true medians** for even N by averaging the two center values.
- **Handle outliers** by considering trimmed means or reporting percentile ranges (e.g., 10–90th percentile).
- **Fix time windows** (e.g., always use the last 30 days) for rate calculations to avoid retroactive changes.
- **Suppress or annotate metrics** for small sample sizes (e.g., “only 2 openings in this period”).
- **Prefer ranges and percentiles** over mean±σ, especially for skewed data.
- **Label rates and rankings** clearly, and indicate ties or statistical similarity when differences are small.
- **Edge case handling:** Always check for empty sets, tiny N, and calendar rounding issues.

### Data Queries to Implement

1. **Event counts by hour/day (for heatmap)**
   - Group events by hour or day using `openDateTime`.
   - Return a dictionary of counts for each time bucket.
   - Always specify the time window (e.g., "last 30 days").
   - Write unit tests for this method in BridgetCoreTests.swift, covering normal and edge cases.

2. **Average duration by day/week**
   - Group completed events by day or week.
   - Compute average, median, and percentile ranges for `minutesOpen`.
   - Return both a typical range (e.g., 25th–75th percentile) and a callout for tail risk (e.g., “10% of events > 15 min”).
   - Write unit tests for this method in BridgetCoreTests.swift, covering normal and edge cases.

3. **Monthly event counts**
   - Group events by month.
   - Return counts and annotate months with very low event numbers.
   - Write unit tests for this method in BridgetCoreTests.swift, covering normal and edge cases.

4. **Per-bridge stats (frequency, avg duration, impact)**
   - For each bridge, compute:
     - Event frequency (rate per fixed window, e.g., per week or per month)
     - Average and median duration
     - Impact label (e.g., “Rarely,” “Sometimes,” “Often”) based on quartiles or business rules
   - Suppress or annotate stats for bridges with very few events.
   - Write unit tests for this method in BridgetCoreTests.swift, covering normal and edge cases.

5. **Cascade Strength and Delay Stats (if applicable)**
   - For cascade events, compute mean, median, unbiased σ, and percentile ranges for strength and delay.
   - Prefer reporting ranges and typical values over raw σ.
   - Use robust quantile methods for thresholds, or fix thresholds to business rules.
   - Write unit tests for this method in BridgetCoreTests.swift, covering normal and edge cases.

6. **Top Bridges by Rate**
   - Sort bridges by event rate (over a fixed window).
   - Show actual rates and indicate ties or statistical similarity.
   - Smooth rates over a rolling window to avoid one-off spikes.
   - Write unit tests for this method in BridgetCoreTests.swift, covering normal and edge cases.

### Unit Testing
- Write unit tests for each query, including edge cases (empty sets, small N, even/odd N, outliers).
- Validate that all queries return user-friendly, time-bounded, and robust results.

---

## Phase 2: UI Component Scaffolding

3. **Create a Reusable Card Container**
   - [ ] Implement a `DashboardCard` SwiftUI view for consistent card styling (padding, background, shadow, title).

4. **Scaffold Each Card UI with Mock Data**
   - [ ] **Heatmap Card:**  
     - Grid layout, color mapping, weekday/weekend toggle.
   - [ ] **Duration Trend Card:**  
     - Histogram or sparkline, summary text, range labels.
   - [ ] **Monthly Trends Card:**  
     - Line graph, month labels, context text.
   - [ ] **Leaderboard Card:**  
     - List or bar chart, bridge name, frequency label, avg duration, impact icon.

5. **Preview Each Card in Isolation**
   - [ ] Use SwiftUI previews with mock data to validate layout and interactivity.

---

## Phase 3: Data Integration

6. **Connect Cards to Live Data**
   - [ ] Replace mock data with real data from your queries.
   - [ ] Ensure correct filtering (e.g., “today” = calendar day, not last 24h).
   - [ ] Always show the time window for each stat.

7. **Add State Management & Interactivity**
   - [ ] Implement toggles for weekday/weekend, per-bridge selection, etc.
   - [ ] Add loading/error states if needed.

---

## Phase 4: Dashboard Assembly & Polish

8. **Assemble Cards in Main Dashboard View**
   - [ ] Stack cards vertically, add spacing, ensure scrollability.
   - [ ] Add section headers if needed.

9. **Accessibility & Responsiveness**
   - [ ] Add accessibility labels/hints.
   - [ ] Test on different device sizes and in dark mode.

10. **User Feedback & Iteration**
    - [ ] Share with users/testers, gather feedback, and iterate on design and data clarity.

---

## Phase 5: Documentation & Testing

11. **Update UI_ELEMENT_MANIFEST.md**
    - [ ] Document each new card and its data source, including user-facing metric descriptions.

12. **Write UI Tests**
    - [ ] Test rendering and interaction for each card.

---

## 📋 Current Implementation To-Dos

### Phase 1: Data Layer Preparation ✅
- [x] Implement `eventCountsByHour` method in `DrawbridgeEventService`
- [x] Implement `eventCountsByDay` method in `DrawbridgeEventService`
- [x] Implement `averageEventDurations` method in `DrawbridgeEventService`
- [x] Implement `monthlyEventCounts` method in `DrawbridgeEventService`
- [x] Implement `perBridgeEventStats` method in `DrawbridgeEventService`
- [x] Write unit tests for all data query methods (using XCTest)

### Phase 2: Statistical Foundation ✅
- [x] Create `StatisticsAPI` with unbiased estimators and robust statistical methods
- [x] Implement mean, median, unbiased standard deviation calculations
- [x] Implement percentile calculations (25th, 75th, 95th)
- [x] Implement trimmed mean calculations
- [x] Add user-facing label helpers (frequency labels, range strings)
- [x] Create `CascadeStatisticsService` for user-facing cascade strength statistics
- [x] Write comprehensive unit tests for `StatisticsAPI` (9 tests)
- [x] Write comprehensive unit tests for `CascadeStatisticsService` (3 tests)
- [x] Ensure all tests pass (12/12 tests passing)

### Phase 3: Statistical Method Refactoring ✅ COMPLETED
- [x] **Cascade Strength Stats** - Review and refactor for statistical soundness
  - [x] Implement data-driven thresholds instead of hardcoded values
  - [x] Add confidence intervals for cascade strength estimates
  - [x] Improve small-N handling with appropriate statistical methods
  - [x] Add outlier detection and handling

- [x] **Data-Driven Thresholds** - Replace hardcoded thresholds
  - [x] Implement percentile-based thresholds (e.g., 75th percentile for "high" strength)
  - [x] Add adaptive thresholds based on historical data
  - [x] Implement seasonal adjustment for thresholds

- [ ] **Delay Statistics** - Improve delay analysis
  - [ ] Add median delay calculations (more robust than mean)
  - [ ] Implement delay distribution analysis
  - [ ] Add delay trend analysis over time
  - [ ] Implement delay clustering detection

- [ ] **Bridge Event Rates** - Enhance rate calculations
  - [ ] Add rate confidence intervals
  - [ ] Implement rate trend analysis
  - [ ] Add seasonal rate adjustments
  - [ ] Implement rate comparison between bridges

- [ ] **Top Bridges by Rate** - Improve ranking methodology
  - [ ] Add statistical significance testing for rate differences
  - [ ] Implement minimum sample size requirements
  - [ ] Add rate stability metrics
  - [ ] Implement rate confidence intervals

### Phase 4: User Experience Improvements
- [ ] **User-Focused Labels** - Improve user-facing statistics
  - [ ] Replace technical terms with user-friendly language
  - [ ] Add context-aware descriptions
  - [ ] Implement progressive disclosure for detailed statistics
  - [ ] Add actionable insights and recommendations

- [ ] **Visualization Enhancements**
  - [ ] Add confidence interval visualizations
  - [ ] Implement trend line displays
  - [ ] Add statistical significance indicators
  - [ ] Create user-friendly chart annotations

### Phase 5: UI Component Scaffolding
- [ ] **Create a Reusable Card Container**
  - [ ] Implement a `DashboardCard` SwiftUI view for consistent card styling

- [ ] **Scaffold Each Card UI with Mock Data**
  - [ ] **Heatmap Card:** Grid layout, color mapping, weekday/weekend toggle
  - [ ] **Duration Trend Card:** Histogram or sparkline, summary text, range labels
  - [ ] **Monthly Trends Card:** Line graph, month labels, context text
  - [ ] **Leaderboard Card:** List or bar chart, bridge name, frequency label, avg duration, impact icon

- [ ] **Preview Each Card in Isolation**
  - [ ] Use SwiftUI previews with mock data to validate layout and interactivity

### Phase 6: Data Integration
- [ ] **Connect Cards to Live Data**
  - [ ] Replace mock data with real data from queries
  - [ ] Ensure correct filtering (e.g., "today" = calendar day, not last 24h)
  - [ ] Always show the time window for each stat

- [ ] **Add State Management & Interactivity**
  - [ ] Implement toggles for weekday/weekend, per-bridge selection, etc.
  - [ ] Add loading/error states if needed

### Phase 7: Dashboard Assembly & Polish
- [ ] **Assemble Cards in Main Dashboard View**
  - [ ] Stack cards vertically, add spacing, ensure scrollability
  - [ ] Add section headers if needed

- [ ] **Accessibility & Responsiveness**
  - [ ] Add accessibility labels/hints
  - [ ] Test on different device sizes and in dark mode

### Phase 8: Testing and Validation
- [ ] **Comprehensive Testing**
  - [ ] Add edge case tests for all statistical methods
  - [ ] Implement performance tests for large datasets
  - [ ] Add integration tests with real data scenarios
  - [ ] Create user acceptance tests for statistical outputs

- [ ] **Statistical Validation**
  - [ ] Validate statistical methods against known datasets
  - [ ] Implement cross-validation for threshold methods
  - [ ] Add statistical power analysis
  - [ ] Create regression tests for statistical consistency

### Phase 9: Documentation & Maintenance
- [ ] **Documentation**
  - [ ] Document statistical methodology and assumptions
  - [ ] Create user guides for interpreting statistics
  - [ ] Add developer documentation for statistical APIs
  - [ ] Create troubleshooting guides for common issues

- [ ] **Maintenance**
  - [ ] Implement statistical method versioning
  - [ ] Add deprecation policies for statistical methods
  - [ ] Create migration guides for statistical changes
  - [ ] Implement monitoring for statistical method performance

### 🔧 **Technical Debt**
- [ ] **Project Configuration**
  - [ ] Fix main project build issues (BridgetCore module not found)
  - [ ] Resolve package linking problems
  - [ ] Add package tests to main project test targets
  - [ ] Ensure tests appear in Xcode Test Navigator

- [ ] **Code Quality**
  - [ ] Add comprehensive error handling for statistical methods
  - [ ] Implement logging for statistical calculations
  - [ ] Add performance monitoring for statistical operations
  - [ ] Create statistical method benchmarks

### 🎯 **Immediate Next Steps**
1. **Fix main project build issues** to enable integration testing
2. **Continue with Phase 4** - User Experience Improvements
3. **Implement user-focused labels** to replace technical terms
4. **Add progressive disclosure** for detailed statistics
5. **Create actionable insights** and recommendations 