# 🛠️ Bridget Development Reference

**Purpose:** Quick reference for development workflow, commands, and project structure for the Bridget iOS app rebuild.
**Target:** Xcode 16.4+, iOS 18.5+, Swift 6.0+, SwiftUI 6.0+, SwiftData 2.0+

---

## 📋 Executive Summary

This document provides essential commands, workflow patterns, and project structure information to support a proactive, stepwise development process for Bridget.

---

## 🏗️ Project Structure

```
Bridget/
├── Bridget/                    # Main app
├── Packages/                   # Modular Swift packages
│   ├── BridgetCore/           # Data models & services
│   ├── BridgetSharedUI/       # Shared UI components
│   ├── BridgetDashboard/      # Dashboard views
│   ├── BridgetBridgesList/    # Bridge listing
│   ├── BridgetBridgeDetail/   # Bridge details
│   ├── BridgetHistory/        # Historical data
│   ├── BridgetStatistics/     # Statistics & analytics
│   ├── BridgetSettings/       # App settings
│   ├── BridgetRouting/        # Routing features
│   ├── BridgetLocation/       # Location services
│   └── BridgetTraffic/        # Traffic analysis
├── Documentation/             # Organized documentation
└── Scripts/                   # Automation tools
```

---

## 🛠️ Essential Commands

### **Development**
```sh
# Build the project
xcodebuild -scheme Bridget -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Run all tests
xcodebuild -scheme Bridget -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test

# Format code
swiftformat .

# Lint code
swiftlint lint
```

### **Branching & GitHub**
```sh
# Create a new feature branch
git checkout -b feat/feature-name

# Push branch to GitHub
git push -u origin feat/feature-name

# Create a PR using GitHub CLI
gh pr create --fill --web
```

### **Scripts**
```sh
# Run UI element discovery
./Scripts/ui_element_discovery.sh

# Add Finder tags to documentation
./Scripts/add_finder_tags.sh
```

---

## 🔄 Workflow Patterns

- **Proactive, stepwise development:** Follow the implementation phases and checklists
- **Branch per feature/fix:** Use feature branches for all work
- **PRs for all changes:** All code must be reviewed via pull requests
- **Reference issues:** Link all commits and PRs to GitHub Issues
- **Automated checks:** Pre-commit hooks and CI for linting, formatting, and tests
- **Documentation updates:** Update docs as part of every PR

---

## 🏷️ Tagging & Organization

- **Priority tags:** #critical, #high, #medium, #low
- **Audience tags:** #developer, #qa, #pm, #user
- **Content tags:** #guide, #reference, #analysis, #checklist

---

## 📚 Quick Reference

- **Feature Specifications:** See FEATURE_SPECIFICATIONS.md
- **Implementation Phases:** See IMPLEMENTATION_PHASES.md
- **Technical Architecture:** See TECHNICAL_ARCHITECTURE.md
- **Commit & GitHub Workflow:** See COMMIT_AND_GITHUB_WORKFLOW.md

---

*This development reference ensures all contributors have quick access to the workflow, commands, and structure needed for a proactive, stepwise rebuild of Bridget.* 

---

## ⚠️ SwiftData & Toolchain Note

**SwiftData macros and features (e.g., @Model) require macOS 14+ and iOS 17+.**

- Building in Xcode 16.4+ with iOS 17+ works as expected.
- Building in the terminal (e.g., `swift build`) may fail if the Command Line Tools or an older toolchain is active, even if Xcode is installed.
- If you see errors about missing SwiftData macros or plugins in the terminal, check your toolchain with `xcode-select -p` and switch to Xcode with:
  ```sh
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  ```
- For CI or scripts, ensure the environment matches your Xcode version and platform requirements.
- When in doubt, use Xcode for all SwiftData development and testing.

*This prevents confusion and ensures a smooth, proactive workflow for all contributors.* 