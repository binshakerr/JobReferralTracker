# Job Referral Tracker

An iOS app for job seekers to track the jobs they are pursuing and the people who can refer them. For every job you save, you add referral contacts and move each one through a simple pipeline — **Pending → Contacted → Interview → Hired / Rejected** — then see how your referrals are doing on an analytics screen.

Everything is stored on the device with Core Data. There are no accounts, no servers and no network calls.

> **Status:** early development. The Xcode project, Core Data stack and product/technical documentation are in place. The features below are being implemented according to [Docs/PRD.md](Docs/PRD.md).

## Features

- **Jobs** — a home list of summary cards (title, company, number of referrals). Add, edit and delete jobs.
- **Referrals** — for each job, add contacts with name, email, LinkedIn profile and an optional note.
- **Tracking** — a detail screen per referral where you change its status with one tap.
- **Analytics** — a status breakdown per job and overall, plus one list of all referrals filterable by status.
- **Offline and private** — all data stays on the device and survives relaunches.

## Tech Stack

| | |
|---|---|
| Platform | iOS 16.0+ (iPhone and iPad) |
| Language | Swift 5 |
| UI | SwiftUI, `NavigationStack`, Swift Charts |
| Persistence | Core Data (SQLite, on-device) |
| Concurrency | `async`/`await`, `AsyncStream` |
| Architecture | Clean Architecture (Domain / Data / Presentation) with dependency injection |
| Tests | XCTest |
| Dependencies | None |

## Requirements

- macOS with **Xcode 15 or later** (developed with Xcode 26)
- iOS 16.0+ simulator or device
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — optional, only needed if you add or remove files through `project.yml`

## Getting Started

Clone the repository and open the project:

```bash
git clone https://github.com/binshakerr/JobReferralTracker.git
```

```bash
cd JobReferralTracker
```

```bash
open JobReferralTracker.xcodeproj
```

Select the **JobReferralTracker** scheme and an iPhone simulator, then press **⌘R** to run.

To run on a physical device, choose your development team under *Signing & Capabilities* for the `JobReferralTracker` target.

### Running tests

Press **⌘U** in Xcode, or run from the command line:

```bash
xcodebuild test -project JobReferralTracker.xcodeproj -scheme JobReferralTracker -destination 'platform=iOS Simulator,name=iPhone 17'
```

Change the simulator name to one installed on your Mac (`xcrun simctl list devices available`).

### Regenerating the Xcode project

The `.xcodeproj` is generated from [project.yml](project.yml) with XcodeGen and is committed, so you do not need XcodeGen to build. If you add, move or delete source files, update the project with:

```bash
xcodegen generate
```

## Architecture

The app follows Clean Architecture. Dependencies point inward, and the Domain layer is plain Swift with no Core Data or SwiftUI imports.

```
Presentation (SwiftUI Views + @MainActor ViewModels)
        │  calls
        ▼
Domain (Entities, Use Cases, Validators, Repository protocols)
        ▲  implements
        │
Data (Core Data stack, managed objects, mappers, repositories)

App (composition root) wires everything together through dependency injection.
```

- **Domain** — business rules for jobs and referrals, validation, analytics calculation and repository protocols.
- **Data** — Core Data implementation of those protocols. Managed objects never leave this layer; they are mapped to value types.
- **Presentation** — SwiftUI screens and ViewModels. ViewModels depend only on use cases.
- **App** — `AppContainer` builds the repositories, use cases and ViewModels. There are no service singletons.

The full design, including every data model and the Core Data schema, is in [Docs/TechArchitecture.md](Docs/TechArchitecture.md).

## Project Structure

```
.
├── Docs/
│   ├── PRD.md                  # Product requirements
│   └── TechArchitecture.md     # Architecture, data models, Core Data schema
├── JobReferralTracker/         # App source
├── JobReferralTrackerTests/    # Unit tests
├── JobReferralTracker.xcodeproj
└── project.yml                 # XcodeGen project spec
```

The target folder layout inside `JobReferralTracker/` (App, Domain, Data, Presentation) is described in [TechArchitecture.md § 3](Docs/TechArchitecture.md#3-project-structure).

## Documentation

| Document | Contents |
|---|---|
| [Product Requirements](Docs/PRD.md) | Goals, screens, field rules, statuses, acceptance criteria |
| [Technical Architecture](Docs/TechArchitecture.md) | Layers, data models, Core Data schema, navigation, DI, concurrency, testing strategy |

## Author

Eslam Shaker — [@binshakerr](https://github.com/binshakerr)
