# TODO: Periodic Background Traffic Data Refresh & Bridge Obstruction Inference

This plan outlines the steps to design, build, and ensure robust, efficient updates for inferred bridge obstruction status using periodic background refreshes from Apple Maps (or alternative) traffic data.

---

## 1. Define Requirements
- Decide refresh frequency (e.g., every 15 min, hourly, user-configurable)
- Confirm data source (Apple Maps, MapKit JS, or alternative)
- Determine privacy and permissions needed (location, background fetch, etc.)
- Design update logic (how traffic data maps to bridge obstruction status)
- Specify user experience (notifications, last update time, UI feedback)

## 2. Research API/Data Integration
- Research Apple Maps or alternative traffic data API access
- Document permissions, rate limits, and data granularity
- Plan fallback if Apple Maps API is not available

## 3. Data Model Design
- Extend SwiftData/CoreData models to store:
  - Traffic/obstruction status
  - Last update time for each bridge

## 4. Networking Service
- Implement a service to fetch and parse traffic data for bridge locations
- Handle API authentication, errors, and retries

## 5. Background Fetch Implementation
- Use BGAppRefreshTask (BackgroundTasks framework) for periodic fetches
- Support manual refresh as fallback
- Ensure fetches are efficient and respect battery/network

## 6. Robustness & Monitoring
- Implement error handling and logging
- Add analytics for background fetch success/failure
- Test on device, in background, and after device restarts

## 7. Obstruction Inference Logic
- Develop algorithm to infer bridge obstruction from traffic data
  - Define congestion thresholds, heuristics, etc.
- Simulate scenarios to validate accuracy

## 8. UI/UX Integration
- Display obstruction status and last update time in UI (bridge list, detail, map overlay)
- Show update indicators and allow manual refresh

## 9. Documentation & Maintenance
- Document feature in technical and user-facing docs
- Set up monitoring for API/iOS changes and user feedback

---

*Update this file as you make progress on each step. Break down further as needed.* 