import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func scheduleAlert(for car: Car) {
        let ids = car.partsArray.compactMap { $0.id?.uuidString }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        for part in car.partsArray {
            let status = part.status(currentMileage: car.mileage)
            guard status != .good else { continue }
            let content = UNMutableNotificationContent()
            content.title = "تنبيه صيانة — \(car.displayName)"
            content.body  = "\(part.name ?? "قطعة") — \(status.rawValue)"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: part.id?.uuidString ?? UUID().uuidString,
                content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func scheduleAllAlerts(for cars: [Car]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for car in cars { scheduleAlert(for: car) }
    }
}
