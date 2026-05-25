import CoreData

@objc(ServiceRecord)
public class ServiceRecord: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var partName: String?
    @NSManaged public var category: String?
    @NSManaged public var mileageAtService: Int32
    @NSManaged public var cost: Double
    @NSManaged public var workshop: String?
    @NSManaged public var notes: String?
    @NSManaged public var car: Car?

    override public func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        objectWillChange.send()
    }

    static func fetchRequest() -> NSFetchRequest<ServiceRecord> {
        NSFetchRequest<ServiceRecord>(entityName: "ServiceRecord")
    }
}
