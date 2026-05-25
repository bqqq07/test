import CoreData

struct PartTemplate {
    let name: String
    let category: String
    let intervalKm: Int32
    let intervalMonths: Int32
    let intervalYears: Int32
    let isCritical: Bool
    let notes: String
    let forYear2000: Bool
    let forYear2011: Bool

    init(_ name: String, category: String,
         km: Int32 = 0, months: Int32 = 0, years: Int32 = 0,
         critical: Bool = false, notes: String = "",
         both: Bool = true, only2000: Bool = false, only2011: Bool = false) {
        self.name = name; self.category = category
        self.intervalKm = km; self.intervalMonths = months; self.intervalYears = years
        self.isCritical = critical; self.notes = notes
        self.forYear2000 = both || only2000
        self.forYear2011 = both || only2011
    }
}

enum PartCategory {
    static let oils            = "الزيوت والسوائل"
    static let filters         = "الفلاتر"
    static let ignition        = "الإشعال"
    static let timing          = "نظام التوقيت"
    static let cooling         = "نظام التبريد"
    static let ac              = "التكييف"
    static let frontSuspension = "التعليق الأمامي"
    static let rearSuspension  = "التعليق الخلفي"
    static let steering        = "الدركسيون"
    static let cvJoints        = "الجلب والكاردان"
    static let brakes          = "الفرامل"
    static let bearings        = "المحامل"
    static let electrical      = "الكهرباء"
    static let sensors         = "الحساسات"
    static let fuel            = "نظام الوقود"
    static let engineTop       = "أعلى المحرك"
    static let mounts          = "ساعدات المحرك والجيربوكس"
    static let exhaust         = "العادم"
    static let tires           = "الإطارات"
    static let cleaning        = "التنظيف الدوري"
    static let treatments      = "المعالجات"
    static let misc            = "الهيكل والمتنوع"
    static let safety          = "السلامة"
}

// المستخدم يضيف القوالب هنا
let allPartTemplates: [PartTemplate] = []

func insertDefaultParts(for car: Car, in context: NSManagedObjectContext) {
    let useNewer = Int(car.year) >= 2005
    let templates = allPartTemplates.filter { useNewer ? $0.forYear2011 : $0.forYear2000 }
    for t in templates {
        let part = MaintenancePart(context: context)
        part.id                 = UUID()
        part.name               = t.name
        part.category           = t.category
        part.intervalKm         = t.intervalKm
        part.intervalMonths     = t.intervalMonths
        part.intervalYears      = t.intervalYears
        part.isCritical         = t.isCritical
        part.notes              = t.notes
        part.lastChangedMileage = car.currentMileage
        part.lastChangedDate    = Date()
        part.car                = car
    }
}
