import CoreData
import Foundation

enum PartStatus: String {
    case good    = "جيدة"
    case warning = "قريبة"
    case overdue = "مستحقة"
}

@objc(MaintenancePart)
public class MaintenancePart: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var category: String?
    @NSManaged public var intervalKm: Int32
    @NSManaged public var intervalMonths: Int32
    @NSManaged public var intervalYears: Int32
    @NSManaged public var lastChangedMileage: Int32
    @NSManaged public var lastChangedDate: Date?
    @NSManaged public var notes: String?
    @NSManaged public var isCritical: Bool
    @NSManaged public var car: Car?

    override public func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        objectWillChange.send()
    }

    static func fetchRequest() -> NSFetchRequest<MaintenancePart> {
        NSFetchRequest<MaintenancePart>(entityName: "MaintenancePart")
    }
}

extension MaintenancePart {
    func status(currentMileage: Int, currentDate: Date = Date()) -> PartStatus {
        if intervalKm > 0 {
            let ratio = Double(currentMileage - Int(lastChangedMileage)) / Double(intervalKm)
            if ratio >= 1.0  { return .overdue }
            if ratio >= 0.85 { return .warning }
            return .good
        }
        if intervalMonths > 0 {
            let months = Calendar.current.dateComponents(
                [.month], from: lastChangedDate ?? Date(), to: currentDate).month ?? 0
            let ratio = Double(months) / Double(intervalMonths)
            if ratio >= 1.0  { return .overdue }
            if ratio >= 0.85 { return .warning }
            return .good
        }
        if intervalYears > 0 {
            let years = Calendar.current.dateComponents(
                [.year], from: lastChangedDate ?? Date(), to: currentDate).year ?? 0
            let ratio = Double(years) / Double(intervalYears)
            if ratio >= 1.0  { return .overdue }
            if ratio >= 0.85 { return .warning }
            return .good
        }
        return .good
    }

    func urgencyScore(currentMileage: Int) -> Double { progressRatio(currentMileage: currentMileage) }

    func progressRatio(currentMileage: Int) -> Double {
        if intervalKm > 0 {
            return Double(currentMileage - Int(lastChangedMileage)) / Double(intervalKm)
        }
        if intervalMonths > 0 {
            let m = Calendar.current.dateComponents([.month], from: lastChangedDate ?? Date(), to: Date()).month ?? 0
            return Double(m) / Double(intervalMonths)
        }
        if intervalYears > 0 {
            let y = Calendar.current.dateComponents([.year], from: lastChangedDate ?? Date(), to: Date()).year ?? 0
            return Double(y) / Double(intervalYears)
        }
        return 0
    }

    func remainingKm(currentMileage: Int) -> Int? {
        guard intervalKm > 0 else { return nil }
        return max(0, Int(intervalKm) - (currentMileage - Int(lastChangedMileage)))
    }

    var intervalDescription: String {
        if intervalKm > 0     { return "\(Int(intervalKm).formatted()) كم" }
        if intervalMonths > 0 { return intervalMonths % 12 == 0 ? "\(intervalMonths/12) سنة" : "\(intervalMonths) شهر" }
        if intervalYears > 0  { return "\(intervalYears) سنة" }
        return "فحص"
    }
}
