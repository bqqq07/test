import CoreData

enum IssuePriority: String, CaseIterable {
    case critical = "حرجة"
    case medium   = "متوسطة"
    case low      = "منخفضة"

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .medium:   return "exclamationmark.circle.fill"
        case .low:      return "info.circle.fill"
        }
    }
}

enum IssueStatus: String, CaseIterable {
    case pending    = "معلقة"
    case inProgress = "شغّال عليها"
    case resolved   = "خلصت"

    var icon: String {
        switch self {
        case .pending:    return "clock.fill"
        case .inProgress: return "wrench.fill"
        case .resolved:   return "checkmark.circle.fill"
        }
    }
}

@objc(InspectionIssue)
public class InspectionIssue: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var issueDescription: String?
    @NSManaged public var priority: String?
    @NSManaged public var status: String?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var dateResolved: Date?
    @NSManaged public var notes: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var car: Car?

    override public func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        objectWillChange.send()
    }

    static func fetchRequest() -> NSFetchRequest<InspectionIssue> {
        NSFetchRequest<InspectionIssue>(entityName: "InspectionIssue")
    }

    var priorityEnum: IssuePriority { IssuePriority(rawValue: priority ?? "") ?? .medium }
    var statusEnum: IssueStatus     { IssueStatus(rawValue: status ?? "")     ?? .pending }
}
