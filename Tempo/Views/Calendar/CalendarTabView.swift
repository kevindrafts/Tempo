import SwiftUI
import EventKit

struct CalendarTabView: View {
    @EnvironmentObject var eventKitManager: EventKitManager
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingEventEditor = false
    @State private var editingEvent: EKEvent?

    var body: some View {
        Group {
            if !eventKitManager.calendarAccessGranted {
                PermissionDeniedView(type: "Calendar")
            } else {
                calendarContent
            }
        }
        .onAppear {
            refreshEvents()
        }
        .onChange(of: viewModel.currentMonth) { _ in
            refreshEvents()
        }
        .onChange(of: viewModel.selectedDate) { _ in
            refreshEvents()
        }
        .onChange(of: viewModel.viewMode) { _ in
            refreshEvents()
        }
    }

    @ViewBuilder
    private var calendarContent: some View {
        VStack(spacing: 0) {
            calendarToolbar
            Divider()
            HSplitView {
                CalendarSidebarView(viewModel: viewModel)
                    .frame(minWidth: 200, idealWidth: 220, maxWidth: 280)

                VStack(spacing: 0) {
                    switch viewModel.viewMode {
                    case .month:
                        MonthView(viewModel: viewModel, events: eventKitManager.visibleEvents) { event in
                            editingEvent = event
                            showingEventEditor = true
                        }
                    case .week:
                        WeekView(viewModel: viewModel, events: eventKitManager.visibleEvents) { event in
                            editingEvent = event
                            showingEventEditor = true
                        }
                        .environmentObject(eventKitManager)
                    case .day:
                        DayView(viewModel: viewModel, events: eventKitManager.visibleEvents) { event in
                            editingEvent = event
                            showingEventEditor = true
                        }
                        .environmentObject(eventKitManager)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEventEditor) {
            EventEditorSheet(
                event: editingEvent,
                onSave: {
                    refreshEvents()
                    showingEventEditor = false
                    editingEvent = nil
                },
                onCancel: {
                    showingEventEditor = false
                    editingEvent = nil
                },
                onDelete: {
                    refreshEvents()
                    showingEventEditor = false
                    editingEvent = nil
                }
            )
        }
    }

    private var calendarToolbar: some View {
        HStack(spacing: 12) {
            Picker("View", selection: $viewModel.viewMode) {
                ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Spacer()

            Button(action: { viewModel.goToPrevious() }) {
                Image(systemName: "chevron.left")
            }

            Text(viewModel.monthTitle)
                .font(.headline)
                .frame(minWidth: 150)

            Button(action: { viewModel.goToNext() }) {
                Image(systemName: "chevron.right")
            }

            Button("Today") {
                viewModel.goToToday()
            }

            Spacer()

            Button(action: {
                editingEvent = nil
                showingEventEditor = true
            }) {
                Image(systemName: "plus")
            }
            .help("New Event")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func refreshEvents() {
        eventKitManager.fetchEvents(from: viewModel.fetchStartDate, to: viewModel.fetchEndDate)
    }
}
