import SwiftUI

struct TimerHubView: View {
    var body: some View {
        List {
            Section {
                NavigationLink("Start Timer", destination: TimerView())
                NavigationLink("Timer History", destination: TimerHistoryView())
                NavigationLink("Guest Timer", destination: GuestTimerView())
                NavigationLink("Manually Add Seizure Time", destination: ManualTimerEntryView())
            }
        }
        .navigationTitle("Timer")
    }
}
