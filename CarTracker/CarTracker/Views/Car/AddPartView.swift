import SwiftUI
import CoreData

struct AddPartView: View {
    let car: Car
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name          = ""
    @State private var category      = ""
    @State private var intervalType  = 0
    @State private var intervalValue = ""
    @State private var lastMileage   = ""
    @State private var lastDate      = Date()
    @State private var isCritical    = false
    @State private var showTemplatePicker = false

    private let intervalLabels = ["كيلومترات", "أشهر", "سنوات"]
    private let intervalUnits  = ["كم", "شهر", "سنة"]
    private let predefinedCategories: [String] = [
        PartCategory.oils, PartCategory.filters, PartCategory.ignition,
        PartCategory.timing, PartCategory.cooling, PartCategory.ac,
        PartCategory.frontSuspension, PartCategory.rearSuspension,
        PartCategory.steering, PartCategory.cvJoints, PartCategory.brakes,
        PartCategory.bearings, PartCategory.electrical, PartCategory.sensors,
        PartCategory.fuel, PartCategory.engineTop, PartCategory.mounts,
        PartCategory.exhaust, PartCategory.tires, PartCategory.cleaning,
        PartCategory.treatments, PartCategory.misc, PartCategory.safety
    ]

    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        nameCard
                        categoryCard
                        intervalCard
                        lastChangeCard
                        criticalCard
                        saveBtn
                    }
                    .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 36)
                }
            }
            .navigationTitle("إضافة قطعة")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { lastMileage = "\(car.mileage)" }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إلغاء") { dismiss() }.foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                PartTemplatePicker(carYear: Int(car.year)) { t in
                    name = t.name; category = t.category
                    if t.intervalKm > 0     { intervalType = 0; intervalValue = "\(t.intervalKm)" }
                    else if t.intervalMonths > 0 { intervalType = 1; intervalValue = "\(t.intervalMonths)" }
                    else if t.intervalYears > 0  { intervalType = 2; intervalValue = "\(t.intervalYears)" }
                    isCritical = t.isCritical
                }
            }
        }
    }

    var nameCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            partHeader("اسم القطعة", icon: "wrench.fill", color: Color.appAccent)
            Divider()
            HStack(spacing: 10) {
                TextField("مثال: زيت المحرك", text: $name)
                    .multilineTextAlignment(.trailing).font(.system(size: 14))
                ZStack {
                    Circle().fill(Color.appAccent.opacity(0.08)).frame(width: 32, height: 32)
                    Image(systemName: "tag.fill").font(.system(size: 13)).foregroundStyle(Color.appAccent)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 12))
            Button { showTemplatePicker = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left").font(.system(size: 11, weight: .bold))
                    Spacer()
                    Text("اختر من قطع شائعة").font(.system(size: 14))
                    Image(systemName: "list.bullet.clipboard.fill").font(.system(size: 14))
                }
                .foregroundStyle(Color.appAccent)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.appAccent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(18).appCard()
    }

    var categoryCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            partHeader("الفئة", icon: "folder.fill", color: Color.appPurple)
            Divider()
            Menu {
                Button("—") { category = "" }
                ForEach(predefinedCategories, id: \.self) { cat in Button(cat) { category = cat } }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer()
                    Text(category.isEmpty ? "اختر الفئة" : category)
                        .font(.system(size: 14))
                        .foregroundStyle(category.isEmpty ? .secondary : .primary)
                    ZStack {
                        Circle().fill(Color.appPurple.opacity(0.08)).frame(width: 32, height: 32)
                        Image(systemName: "folder.fill").font(.system(size: 13)).foregroundStyle(Color.appPurple)
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(18).appCard()
    }

    var intervalCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            partHeader("فترة التغيير", icon: "clock.arrow.circlepath", color: Color.appTeal)
            Divider()
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.25)) { intervalType = i; intervalValue = "" }
                    } label: {
                        Text(intervalLabels[i])
                            .font(.system(size: 13, weight: intervalType == i ? .semibold : .regular))
                            .foregroundStyle(intervalType == i ? .white : Color.appAccent)
                            .frame(maxWidth: .infinity).padding(.vertical, 9)
                            .background(intervalType == i ? Color.appAccent : Color.appAccent.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.appTeal.opacity(0.10)).frame(width: 38, height: 38)
                    Image(systemName: "clock.fill").font(.system(size: 14)).foregroundStyle(Color.appTeal)
                }
                Spacer()
                TextField("القيمة", text: $intervalValue)
                    .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    .font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(Color.appAccent)
                Text(intervalUnits[intervalType]).font(.system(size: 14)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(18).appCard()
    }

    var lastChangeCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            partHeader("آخر تغيير", icon: "calendar.badge.checkmark", color: Color.appGreen)
            Divider()
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.appGreen.opacity(0.10)).frame(width: 38, height: 38)
                    Image(systemName: "gauge.high").font(.system(size: 14)).foregroundStyle(Color.appGreen)
                }
                Spacer()
                TextField(car.mileage.formatted(), text: $lastMileage)
                    .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    .font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(Color.appAccent)
                Text("كم").font(.system(size: 14)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 12))
            DatePicker("التاريخ", selection: $lastDate, displayedComponents: .date)
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(18).appCard()
    }

    var criticalCard: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: $isCritical).labelsHidden().tint(Color.appRed)
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Label("قطعة حرجة", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isCritical ? Color.appRed : .primary)
                Text("تظهر في تنبيهات الصفحة الرئيسية")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
        .padding(18).appCard()
    }

    var saveBtn: some View {
        Button { savePart() } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("حفظ القطعة")
            }
            .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(canSave
                ? LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [Color(.systemGray3), Color(.systemGray3)], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: canSave ? Color.appAccent.opacity(0.28) : .clear, radius: 10, x: 0, y: 5)
        }
        .disabled(!canSave)
    }

    func partHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Spacer()
            Text(title).font(.system(size: 16, weight: .semibold))
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(color)
            }
        }
    }

    func savePart() {
        let part = MaintenancePart(context: context)
        part.id             = UUID()
        part.name           = name.trimmingCharacters(in: .whitespaces)
        part.category       = category.isEmpty ? "أخرى" : category
        part.intervalKm     = intervalType == 0 ? (Int32(intervalValue) ?? 0) : 0
        part.intervalMonths = intervalType == 1 ? (Int32(intervalValue) ?? 0) : 0
        part.intervalYears  = intervalType == 2 ? (Int32(intervalValue) ?? 0) : 0
        part.lastChangedMileage = Int32(lastMileage) ?? car.currentMileage
        part.lastChangedDate    = lastDate
        part.isCritical         = isCritical
        part.notes              = ""
        part.car                = car
        PersistenceController.shared.save()
        dismiss()
    }
}

// MARK: - Part Template Picker
struct PartTemplatePicker: View {
    let carYear: Int
    let onSelect: (PartTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var templates: [PartTemplate] {
        allPartTemplates.filter { t in
            let yearMatch   = carYear >= 2005 ? t.forYear2011 : t.forYear2000
            let searchMatch = searchText.isEmpty || t.name.contains(searchText)
            return yearMatch && searchMatch
        }
    }

    var grouped: [(String, [PartTemplate])] {
        Dictionary(grouping: templates, by: \.category)
            .map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                List {
                    ForEach(grouped, id: \.0) { category, parts in
                        Section {
                            ForEach(Array(parts.enumerated()), id: \.offset) { _, t in
                                Button {
                                    onSelect(t); dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        if t.isCritical {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.system(size: 11)).foregroundStyle(Color.appRed)
                                        }
                                        VStack(alignment: .trailing, spacing: 3) {
                                            Text(t.name).font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.primary)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                            Text(intervalLabel(t)).font(.system(size: 12)).foregroundStyle(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.white)
                                .listRowSeparator(.hidden)
                            }
                        } header: {
                            Text(category).font(.system(size: 11, weight: .bold)).foregroundStyle(Color.appAccent)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
                .listStyle(.insetGrouped).scrollContentBackground(.hidden)
            }
            .searchable(text: $searchText, prompt: "بحث في القطع...")
            .navigationTitle("قطع شائعة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("إلغاء") { dismiss() } } }
        }
    }

    private func intervalLabel(_ t: PartTemplate) -> String {
        if t.intervalKm > 0     { return "كل \(Int(t.intervalKm).formatted()) كم" }
        if t.intervalMonths > 0 { return "كل \(t.intervalMonths) شهر" }
        if t.intervalYears > 0  { return "كل \(t.intervalYears) سنة" }
        return "فحص دوري"
    }
}
