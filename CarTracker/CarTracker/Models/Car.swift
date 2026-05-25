import CoreData

@objc(Car)
public class Car: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var make: String?
    @NSManaged public var year: Int32
    @NSManaged public var color: String?
    @NSManaged public var plateNumber: String?
    @NSManaged public var currentMileage: Int32
    @NSManaged public var lastMileageUpdate: Date?
    @NSManaged public var imageData: Data?
    @NSManaged public var suspensionType: String?
    @NSManaged public var steeringType: String?
    @NSManaged public var timingType: String?
    @NSManaged public var sparkPlugType: String?
    @NSManaged public var onboardingCompleted: Bool
    @NSManaged public var parts: NSSet?
    @NSManaged public var issues: NSSet?
    @NSManaged public var serviceRecords: NSSet?

    override public func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        objectWillChange.send()
    }

    static func fetchRequest() -> NSFetchRequest<Car> {
        NSFetchRequest<Car>(entityName: "Car")
    }
}

extension Car {
    var displayName: String { name ?? "سيارة" }
    var displayYear: Int    { Int(year) }
    var mileage: Int        { Int(currentMileage) }

    var displaySubtitle: String {
        let m = make ?? ""
        return m.isEmpty ? "\(displayYear)" : "\(m) \(displayYear)"
    }

    var partsArray: [MaintenancePart] {
        (parts as? Set<MaintenancePart> ?? [])
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    var issuesArray: [InspectionIssue] {
        (issues as? Set<InspectionIssue> ?? [])
            .sorted { ($0.dateAdded ?? .distantPast) > ($1.dateAdded ?? .distantPast) }
    }
    var recordsArray: [ServiceRecord] {
        (serviceRecords as? Set<ServiceRecord> ?? [])
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    var urgentPartsCount: Int  { partsArray.filter { $0.status(currentMileage: mileage) == .overdue }.count }
    var warningPartsCount: Int { partsArray.filter { $0.status(currentMileage: mileage) == .warning }.count }
    var totalExpenses: Double  { recordsArray.reduce(0) { $0 + $1.cost } }

    var nextAlertPart: MaintenancePart? {
        partsArray
            .filter { $0.status(currentMileage: mileage) != .good }
            .sorted { $0.urgencyScore(currentMileage: mileage) > $1.urgencyScore(currentMileage: mileage) }
            .first
    }
}
