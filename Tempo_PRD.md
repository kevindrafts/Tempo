# Tempo — Product Requirements Document
**Version:** 1.0 (MVP)
**Platform:** macOS 13 (Ventura) and later
**Last Updated:** March 2026

---

## 1. Overview

### 1.1 Product Summary
Tempo is a native macOS app that unifies Apple Calendar events and Apple Reminders into a single, cohesive experience. Rather than switching between two separate system apps, users get one clean window with a consistent design language across both. Tempo does not reinvent either product — it wraps both via EventKit into a unified shell with a shared visual identity.

### 1.2 Problem Statement
macOS ships Calendar and Reminders as two completely separate apps with different visual designs, different interaction patterns, and no shared UI. Users who rely on both are forced to context-switch constantly. Tempo solves this by housing both in one app under a unified tab structure.

### 1.3 Goals
- Provide full read/write access to the user's existing Calendar events via EventKit
- Provide full read/write access to the user's existing Reminders via EventKit
- Present both in a unified, native macOS UI with consistent design language
- Sync automatically with iCloud (inherited from EventKit — no custom sync layer needed)
- Ship a focused MVP; no novel or experimental UX

### 1.4 Non-Goals (MVP)
- No iOS or iPadOS companion app
- No overlaying reminders onto the calendar grid
- No natural language input (e.g. "remind me Tuesday at 3pm")
- No custom calendar/reminder list creation in MVP (read existing lists only, though items can be created within them)
- No Siri integration
- No widgets

---

## 2. App Name & Identity

**Name:** Tempo
**Tagline:** Your calendar and reminders, together.
**Bundle ID:** com.tempo.app
**Target Users:** macOS power users who actively use both Apple Calendar and Apple Reminders and want them consolidated into one place.

---

## 3. Architecture & Tech Stack

### 3.1 Language & Frameworks
| Layer | Choice |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI (primary), AppKit via `NSApplicationDelegateAdaptor` where needed |
| Data Framework | EventKit |
| Minimum OS | macOS 13 Ventura |
| App Lifecycle | SwiftUI `@main` App struct |
| Notifications | UserNotifications framework |

### 3.2 Architecture Pattern
MVVM (Model-View-ViewModel) with a single shared data service.

- **`EventKitManager`** — a singleton `ObservableObject` that owns the `EKEventStore`, handles permissions, and exposes `@Published` data arrays. Injected as an `@EnvironmentObject` at the root so both tabs share the same instance.
- **`CalendarViewModel`** — manages calendar state: selected date, current month, view mode. Transforms `EKEvent` arrays into display-ready structures.
- **`RemindersViewModel`** — manages reminder state: selected list, items within that list, completion toggling, sorting.
- **Views** — dumb. They render what the ViewModel exposes and forward user actions back up. No EventKit calls directly from views.

### 3.3 Data Flow
```
EventKit (iCloud / local) 
    ↓  EKEventStore
EventKitManager  (@EnvironmentObject, single source of truth)
    ↓  @Published arrays
CalendarViewModel / RemindersViewModel
    ↓  @StateObject / @EnvironmentObject
SwiftUI Views  →  render UI
    ↓  user action
ViewModel  →  EventKitManager  →  writes back to EventKit
```

### 3.4 Key Implementation Notes
- Observe `EKEventStoreChangedNotification` to refresh data live when the system calendar or Reminders changes externally.
- Request EventKit permissions for Calendar and Reminders separately on first launch. Handle denial gracefully with an in-app prompt directing users to System Settings.
- No local database or custom persistence layer — EventKit is the single source of truth.

---

## 4. Permissions

On first launch, Tempo must request:
1. **Calendar access** — `EKEntityType.event` — Full access required (read + write)
2. **Reminders access** — `EKEntityType.reminder` — Full access required (read + write)

**Behavior if denied:**
- Show a non-blocking banner inside the relevant tab explaining that access was denied
- Provide a button that deep-links to System Settings > Privacy & Security
- App remains open and usable for the other tab if only one permission is denied

---

## 5. Navigation Structure

```
Tempo (NSWindow)
└── TabView (top-level)
    ├── Tab 1: Calendar
    └── Tab 2: Reminders
```

- Tabs are persistent and always visible
- Tab icons: SF Symbols — `calendar` for Calendar, `checklist` for Reminders
- Default tab on launch: Calendar
- Window minimum size: 900 × 600pt

---

## 6. Tab 1 — Calendar

### 6.1 Layout
Two-column layout:
- **Left sidebar** (~220pt wide): calendar source/account list, mini month picker
- **Main content area**: calendar grid or day detail, depending on view mode

### 6.2 View Modes
Three modes, switchable via a segmented control in the toolbar:
- **Month view** (default)
- **Week view**
- **Day view**

### 6.3 Month View
- Standard calendar grid: 7 columns (days of week), rows for each week
- Each day cell shows: the day number, and up to 3 event titles (truncated if needed) with a colored dot matching the calendar color
- Overflow indicator (e.g. "+2 more") if a day has more than 3 events; tapping/clicking expands a popover with the full list
- Selected day is highlighted
- Today's date is always visually distinct (accent color ring or fill)
- Clicking a day selects it and shows that day's events in a detail panel below or in a right-side panel (see 6.6)
- Prev/Next month navigation arrows in toolbar
- "Today" button in toolbar jumps to current date

### 6.4 Week View
- 7-column layout showing Mon–Sun (or Sun–Sat, respecting system locale setting)
- Time-slotted rows (hourly) from configurable start/end time (default 6am–10pm)
- Events displayed as blocks in their time slot, colored by calendar
- All-day events shown in a dedicated row at the top
- Current time indicated by a horizontal line

### 6.5 Day View
- Single-day time-slotted view
- Same time-slot layout as Week view, full width
- Event blocks show title, time, and location (if set)
- All-day events shown at top

### 6.6 Event Detail Panel
When a day or event is selected, a panel (bottom or right side) shows:
- List of events for the selected day
- Each event row: colored dot, title, time, calendar name
- Clicking an event opens the Event Editor Sheet (see 6.7)
- "+" button to create a new event on the selected day

### 6.7 Event Editor Sheet (Modal)
Fields:
- Title (required)
- Date & Time (start and end)
- All-day toggle
- Calendar selector (dropdown of available calendars)
- Location (optional text field)
- Notes (optional multiline text field)
- URL (optional)
- Repeat (None, Daily, Weekly, Monthly, Yearly — basic recurrence only for MVP)
- Alert (None, At time of event, 5/15/30/60 min before, 1 day before)

Actions:
- Save
- Cancel
- Delete (only shown when editing an existing event; requires confirmation alert)

### 6.8 Sidebar
- List of calendar accounts and their individual calendars (mirrors Apple Calendar's sidebar)
- Each calendar shown with its color swatch and name
- Checkboxes to show/hide individual calendars
- Accounts collapsed/expanded with disclosure triangles

---

## 7. Tab 2 — Reminders

### 7.1 Layout
Two-column layout:
- **Left sidebar** (~220pt wide): reminder lists
- **Main content area**: items within the selected list

### 7.2 Sidebar — Reminder Lists
- Shows all reminder lists from all accounts (mirrors Apple Reminders sidebar)
- Each list shows its color/icon and name
- Selecting a list loads its items in the main content area
- List item count shown as a badge on the right
- "All" smart list at the top that aggregates all incomplete reminders

### 7.3 Main Content — Reminder Items
- Each reminder shown as a row with:
  - Completion circle (click to toggle complete/incomplete)
  - Title
  - Due date (if set), shown in red if overdue
  - Priority indicator (if set): low / medium / high
  - Notes preview (single line, truncated, if notes exist)
- Completed items shown in a collapsed "Completed" section at the bottom, toggled with a disclosure button
- "+" button or press Return at the bottom of the list to add a new reminder inline
- Clicking a reminder opens the Reminder Editor Sheet

### 7.4 Reminder Editor Sheet (Modal)
Fields:
- Title (required)
- Notes (optional multiline)
- Due Date toggle + date picker
- Due Time toggle + time picker
- List selector (dropdown of available lists)
- Priority (None, Low, Medium, High)
- Flag toggle
- URL (optional)

Actions:
- Save
- Cancel
- Delete (only shown when editing; requires confirmation alert)

### 7.5 Sorting & Filtering (MVP)
- Default sort: by due date (soonest first), then by creation date
- No custom filter UI in MVP; show all incomplete by default with completed collapsed

---

## 8. Toolbar & Global UI

### 8.1 Toolbar (per tab)
**Calendar tab toolbar:**
- View mode segmented control (Month / Week / Day)
- Prev / Next navigation arrows
- "Today" button
- "+" new event button
- Search (optional stretch goal for MVP)

**Reminders tab toolbar:**
- "+" new reminder button
- Search (optional stretch goal for MVP)

### 8.2 Design Language
- Follows macOS Human Interface Guidelines throughout
- Uses system accent color for interactive elements
- Calendar colors and Reminder list colors sourced directly from EventKit (matches what the user has set in Apple Calendar / Reminders)
- Supports both Light and Dark mode (automatic, follows system setting)
- SF Symbols used for all icons
- Standard macOS fonts (SF Pro)

### 8.3 Menu Bar
Standard macOS menu bar with:
- **File:** New Event, New Reminder, Close Window
- **View:** Switch to Calendar tab, Switch to Reminders tab, view mode options
- **Window:** Standard macOS window menu
- **Help:** Standard

---

## 9. Sync & Data Behavior

- Tempo does not manage sync. All sync is handled by EventKit and the user's iCloud/Exchange/CalDAV accounts configured in System Settings.
- On launch, fetch fresh data from `EKEventStore`
- Register for `EKEventStoreChangedNotification` and refresh affected data immediately when received
- All writes go through `EKEventStore.save()` — changes are immediately reflected in Apple Calendar and Apple Reminders

---

## 10. Error Handling

| Scenario | Behavior |
|---|---|
| Permission denied (Calendar) | Show banner in Calendar tab with link to System Settings |
| Permission denied (Reminders) | Show banner in Reminders tab with link to System Settings |
| Save fails | Show inline error message in the editor sheet |
| EventStore unavailable | Show full-tab error state with retry button |
| No events/reminders | Show empty state illustration with prompt to create one |

---

## 11. Non-Functional Requirements

- **Performance:** Month view must render within 200ms of tab load or date navigation. Reminder list with up to 500 items must scroll at 60fps.
- **Reliability:** No data loss. All saves must be confirmed by EventKit before dismissing the editor sheet.
- **Accessibility:** Full VoiceOver support. All interactive elements must have accessibility labels. Minimum tap/click target size per HIG (44×44pt).
- **Sandboxing:** App must be sandboxed for App Store distribution. Required entitlements: `com.apple.security.personal-information.calendars`, `com.apple.security.personal-information.reminders`.

---

## 12. MVP Scope Summary

### In Scope
- Two-tab app: Calendar + Reminders
- Month, Week, and Day views for Calendar
- Full CRUD for events and reminders
- Calendar sidebar with show/hide toggles
- Reminders sidebar with list selection
- Event and Reminder editor sheets with core fields
- Light/Dark mode support
- Live sync via EKEventStoreChangedNotification
- iCloud sync (inherited from EventKit)

### Out of Scope (Post-MVP)
- iOS / iPadOS app
- Overlaying reminders on calendar grid
- Natural language input
- Creating new calendar or reminder lists
- Drag-to-reschedule events
- Custom themes or accent colors
- Widgets or menu bar app
- Siri integration
- Keyboard shortcut customization
- Import/export (ICS, etc.)

---

## 13. Suggested Build Order

1. **`EventKitManager`** — permissions, fetch, save, delete, change observer. Validate all EventKit operations before touching UI.
2. **Reminders tab** — simpler data model, good place to validate the full MVVM stack end-to-end.
3. **Calendar month view** — custom grid UI, the most involved piece of the build.
4. **Calendar week + day views**
5. **Editor sheets** — Event and Reminder, with full field support
6. **Polish** — empty states, error states, Dark mode, accessibility pass
7. **Sandboxing + entitlements** — prepare for App Store submission

---

*Tempo is intentionally scoped to do two things and do them well: show your calendar, show your reminders, keep them in sync, and stay out of your way.*
