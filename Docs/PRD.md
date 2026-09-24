# Job Referral Tracker — Product Requirements Document

| | |
|---|---|
| **Product** | Job Referral Tracker (iOS) |
| **Platform** | iPhone and iPad, iOS 16.0+ |
| **UI framework** | SwiftUI with `NavigationStack` |
| **Storage** | Core Data, on-device only |
| **Networking** | None — the app is fully offline |
| **Status** | Draft v1.0 — 2026-09-25 |

Related: [Technical Architecture](TechArchitecture.md)

---

## 1. Overview

Job Referral Tracker helps job seekers organize the job opportunities they are pursuing and the people who can refer them. For every job, the user records referral contacts and tracks each referral through a simple pipeline (Pending → Contacted → Interview → Hired / Rejected). An analytics screen summarizes how referrals are progressing per job and across all jobs.

All data lives on the device. There is no account, no sign-in and no server.

## 2. Goals and Non-Goals

### Goals
1. Let a user capture a job opportunity in a few seconds.
2. Let a user attach any number of referral contacts to a job and update each referral's status.
3. Give the user a clear view of where every referral stands, per job and overall.
4. Persist everything locally so data survives app relaunches and device restarts.
5. Ship a codebase that follows Clean Architecture with dependency injection and is covered by unit tests.

### Non-Goals (v1)
- Networking, cloud sync, iCloud/CloudKit, or backups to a server.
- User accounts, authentication or multi-user support.
- Importing jobs from job boards or LinkedIn.
- Push or local notifications and reminders.
- Status change history (only the current status and when it last changed are stored).
- Localization beyond English (strings are still kept out of business logic so localization can be added later).

## 3. Target User

An individual job seeker who is actively applying to several roles and asking friends, former colleagues or recruiters to refer them. They want one place to see who they asked, for which job, and what happened.

## 4. Glossary

| Term | Meaning |
|---|---|
| **Job** | A job opportunity the user is pursuing (title, company, description, location). |
| **Referral** | A contact person who may refer the user for a specific job, with a tracked status. |
| **Status** | The stage a referral is in: Pending, Contacted, Interview, Hired, Rejected. |
| **Summary card** | The compact representation of a job on the Home screen. |

## 5. Information Architecture and Navigation

The app root is a `TabView` with two tabs. Each tab owns its own `NavigationStack`, so each keeps its own back-stack.

```
TabView
├── Jobs tab (NavigationStack)
│   ├── Home — Job List
│   │   ├── [sheet] Add Job
│   │   └── [push]  Job Detail (Referral Screen)
│   │       ├── [sheet] Edit Job
│   │       ├── [sheet] Add Referral
│   │       └── [push]  Referral Detail (Tracking)
│   │           └── [sheet] Edit Referral
└── Analytics tab (NavigationStack)
    └── Analytics
        ├── Segment "By Job"        → [push] Job Detail
        └── Segment "All Referrals" → [push] Referral Detail
```

Navigation rules:
- **Push** (`NavigationStack` + typed routes) is used for drilling into content: Job Detail, Referral Detail.
- **Sheets** are used for create and edit forms. A form always has **Cancel** and **Save**. Save is disabled until the form is valid.
- **Destructive actions** (delete job, delete referral) always ask for confirmation.
- After deleting the item shown on a pushed screen, the app pops back to the previous screen.

## 6. Functional Requirements

Priority: **P0** = required for v1, **P1** = should have, **P2** = nice to have.

### 6.1 Home Screen — Job List (P0)

Shows every job the user has saved as a summary card.

| ID | Requirement |
|---|---|
| HOME-1 | Show one summary card per job with **job title**, **company** and **number of referrals**. |
| HOME-2 | Sort jobs newest first (by creation date). |
| HOME-3 | Tapping a card pushes **Job Detail**. |
| HOME-4 | A **+** toolbar button opens the **Add Job** sheet. |
| HOME-5 | Swipe-to-delete on a card, with a confirmation that states how many referrals will also be deleted. |
| HOME-6 | When there are no jobs, show an empty state with a short explanation and an **Add Job** button. |
| HOME-7 | The list updates automatically when jobs or referrals are added, edited or deleted anywhere in the app. |
| HOME-8 (P1) | Show the job's location on the card when present. |

### 6.2 Add / Edit Job Screen (P0)

A form presented as a sheet, used for both creating and editing a job.

| Field | Type | Required | Rules |
|---|---|---|---|
| Title | Single-line text | Yes | Trimmed; must not be empty; max 120 characters. |
| Company | Single-line text | Yes | Trimmed; must not be empty; max 120 characters. |
| Location | Single-line text | No | Trimmed; max 120 characters (e.g. "Remote", "Berlin, DE"). |
| Job description | Multi-line text | No | Trimmed; max 5,000 characters. |

| ID | Requirement |
|---|---|
| JOB-1 | **Save** is disabled until all required fields are valid. |
| JOB-2 | Inline validation messages appear under an invalid field once the user has edited it. |
| JOB-3 | On save the sheet dismisses and the new or updated job appears immediately. |
| JOB-4 | **Cancel** discards changes. If there are unsaved edits, ask to discard first. |
| JOB-5 | In edit mode the form is pre-filled and titled "Edit Job". |

### 6.3 Job Detail — Referral Screen (P0)

Shows one job and the referrals attached to it.

| ID | Requirement |
|---|---|
| REF-1 | Header shows title, company, location and the full description (collapsed to a few lines with "More" when long). |
| REF-2 | A status summary row shows referral counts per status for this job. |
| REF-3 | List every referral for the job with the contact name, email and a colored status badge. Sort by most recently updated first. |
| REF-4 | An **Add Referral** button opens the **Add Referral** sheet. |
| REF-5 | Tapping a referral pushes **Referral Detail**. |
| REF-6 | Swipe-to-delete on a referral, with confirmation. |
| REF-7 | Toolbar menu offers **Edit Job** and **Delete Job** (with confirmation; pops back after delete). |
| REF-8 | Empty state when the job has no referrals, with an **Add Referral** button. |

### 6.4 Add / Edit Referral Screen (P0)

A form presented as a sheet, used for both creating and editing a referral.

| Field | Type | Required | Rules |
|---|---|---|---|
| Contact name | Single-line text | Yes | Trimmed; must not be empty; max 120 characters. |
| Email | Email keyboard | Yes | Trimmed and lower-cased; must be a valid email address; must be unique among referrals **of the same job**. |
| LinkedIn profile | URL keyboard | Yes | Trimmed; must be a `linkedin.com` URL (any subdomain such as `www.`). A missing scheme is accepted and saved as `https://`. |
| Note | Multi-line text | No | Trimmed; max 2,000 characters. Saved as empty/absent when blank. |
| Status | Picker | Yes | Defaults to **Pending** for a new referral. |

| ID | Requirement |
|---|---|
| RFORM-1 | **Save** is disabled until all required fields are valid. |
| RFORM-2 | Inline validation messages explain exactly what is wrong (e.g. "Enter a valid email address"). |
| RFORM-3 | Saving a duplicate email for the same job shows an error and does not save. |
| RFORM-4 | Cancel with unsaved edits asks to discard first. |

### 6.5 Referral Tracking Detail (P0)

Shows one referral and lets the user move it through the pipeline.

| ID | Requirement |
|---|---|
| TRACK-1 | Show contact name, the job it belongs to (title @ company), email, LinkedIn profile, note, created date and "status last changed" date. |
| TRACK-2 | Show the current status prominently with its badge color. |
| TRACK-3 | The user can change the status to any of **Pending, Contacted, Interview, Hired, Rejected**. The change saves immediately — no separate Save button. |
| TRACK-4 | Changing status updates "status last changed", and every other screen (Job Detail, Home, Analytics) reflects it right away. |
| TRACK-5 | The email opens the Mail composer (`mailto:`); the LinkedIn profile opens in the browser or LinkedIn app. |
| TRACK-6 | Toolbar menu offers **Edit Referral** and **Delete Referral** (with confirmation; pops back after delete). |

#### Referral statuses

| Status | Meaning | Badge color |
|---|---|---|
| Pending | Contact identified, not reached out yet. | Gray |
| Contacted | The user reached out to the contact. | Blue |
| Interview | The referral led to an interview. | Orange |
| Hired | The user got the job through this referral. | Green |
| Rejected | The referral did not work out. | Red |

Any status can change to any other status, so the user can correct mistakes. Hired and Rejected are considered **closed**; the others are **open**.

### 6.6 Analytics Screen (P0)

Shows a simple breakdown of referral statuses per job, and a unified, filterable list of all referrals. A segmented control at the top switches between the two views.

**Segment "By Job"**

| ID | Requirement |
|---|---|
| ANA-1 | An overall summary at the top: total referrals and the count per status across all jobs. |
| ANA-2 | A chart (Swift Charts, iOS 16) of the overall status distribution. |
| ANA-3 | One row per job: title, company, total referrals, and the count for each status (e.g. "Hired 1 · Interview 2 · Rejected 1"). A small stacked bar shows the proportions. |
| ANA-4 | Jobs with no referrals are listed last with "No referrals yet". |
| ANA-5 | Tapping a job row pushes **Job Detail**. |

**Segment "All Referrals"**

| ID | Requirement |
|---|---|
| ANA-6 | One list of every referral across all jobs, showing contact name, job title @ company and status badge. Sorted by most recently updated first. |
| ANA-7 | A status filter: **All** plus each of the five statuses. Each option shows its count. |
| ANA-8 | Tapping a referral pushes **Referral Detail**. |
| ANA-9 | Empty state when nothing matches the filter. |

Both segments update live when data changes.

### 6.7 Data Management (P0)

| ID | Requirement |
|---|---|
| DATA-1 | All jobs and referrals persist locally with Core Data and survive app relaunch. |
| DATA-2 | A job can have zero or more referrals. A referral always belongs to exactly one job. |
| DATA-3 | Users can add, edit and delete jobs and referrals. |
| DATA-4 | Deleting a job deletes all of its referrals (cascade). |
| DATA-5 | Nothing is sent over the network. |
| DATA-6 | If the local store fails to load, show a readable error screen instead of crashing. |

## 7. Non-Functional Requirements

### 7.1 Architecture
- **Clean Architecture**: separate Domain (business logic), Data (Core Data storage) and Presentation (SwiftUI) layers. Details in [TechArchitecture.md](TechArchitecture.md).
- **Dependency injection**: no singletons for services. All repositories and use cases are created in one composition root and passed in through initializers.
- **State management**: modern Swift concurrency (`async`/`await`, `AsyncStream`) for data flow; `ObservableObject` ViewModels on the main actor for UI state.

### 7.2 UX and Accessibility
- Clean, native iOS look using standard SwiftUI components.
- Supports Light and Dark Mode.
- Supports Dynamic Type; layouts must not truncate essential information at large sizes.
- VoiceOver: every interactive element has a meaningful label; status badges read as "Status: Interview", not only as a color.
- Status is never shown by color alone — always with its text label.
- Works in portrait and landscape on iPhone, and on iPad.

### 7.3 Performance
- App launch to interactive Home screen in under 1 second on a recent device with 500 jobs and 5,000 referrals.
- Saves and status changes appear in the UI in under 100 ms.
- Core Data work runs off the main thread; the UI never blocks on disk I/O.

### 7.4 Privacy
- Contact data (names, emails, LinkedIn URLs) never leaves the device.
- No analytics SDKs or third-party dependencies.
- Uses iOS Data Protection (the default file protection class) for the store.

## 8. Testing Requirements

| ID | Requirement |
|---|---|
| TEST-1 | Unit tests cover **job creation** logic: validation (required fields, trimming, length limits) and a successful save. |
| TEST-2 | Unit tests cover **referral creation** logic: email and LinkedIn validation, duplicate-email rule, default status Pending. |
| TEST-3 | Unit tests cover status updates and the analytics breakdown calculation. |
| TEST-4 | Repository tests run against an **in-memory** Core Data store: create, fetch, update, delete, cascade delete. |
| TEST-5 | ViewModel tests use mocked use cases or repositories — no Core Data needed. |

## 9. Acceptance Criteria (v1 release)

1. A user can add a job, add three referrals to it, move one referral to Interview and one to Hired, force-quit the app, relaunch it and see exactly the same data.
2. The Home card for that job shows "3 referrals".
3. Analytics "By Job" shows that job with Pending 1 · Interview 1 · Hired 1.
4. Analytics "All Referrals" filtered to **Hired** shows exactly the one hired referral.
5. Deleting the job removes it and all three referrals from every screen.
6. Invalid input (empty title, bad email, non-LinkedIn URL) cannot be saved and shows a clear message.
7. The project builds with no warnings and all unit tests pass.
8. The codebase has no service singletons, and the Domain layer does not import Core Data or SwiftUI.

## 10. Future Considerations (post-v1)
- Status change history timeline per referral.
- Follow-up reminders via local notifications.
- Search and sort options on the Home screen.
- iCloud sync via `NSPersistentCloudKitContainer` (the Data layer is designed so it can be swapped in).
- Export to CSV.
