import SwiftUI
import CoreData

@main
struct CarTrackerApp: App {
    let persistence = PersistenceController.shared

    init() {
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environment(\.layoutDirection, .rightToLeft)
                .onAppear {
                    let ctx = persistence.container.viewContext
                    let cars = (try? ctx.fetch(Car.fetchRequest())) ?? []
                    NotificationManager.shared.scheduleAllAlerts(for: cars)
                }
        }
    }
}
