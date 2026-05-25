import SwiftUI
import CoreData

struct AddCarView: View {
    var onCarSaved: ((Car) -> Void)? = nil

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name           = ""
    @State private var selectedYear   = Calendar.current.component(.year, from: Date())
    @State private var carColor       = ""
    @State private var plateNumber    = ""
    @State private var currentMileage = ""
    @State private var make           = ""
    @State private var suspensionType = ""
    @State private var steeringType   = ""
    @State private var timingType     = ""
    @State private var sparkPlugType  = ""

    let years: [Int] = Array(stride(
        from: Calendar.current.component(.year, from: Date()),
        through: 1990, by: -1))

    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && Int(currentMileage) != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        heroSection
                        yearCard
                        infoCard
                        specsCard
                        mileageCard
                        saveButton
                    }
                    .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 36)
                }
            }
            .navigationTitle("إضافة سيارة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إلغاء") { dismiss() }.foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Hero
    var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appAccent, Color.appAccent2],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            Circle().fill(.white.opacity(0.07)).frame(width: 150).offset(x: -60, y: -35)
            Circle().fill(.white.opacity(0.04)).frame(width: 100).offset(x: -95, y: 25)
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("سيارة جديدة")
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.75))
                    Text(name.isEmpty ? "سيارتي" : name)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .animation(.spring(response: 0.3), value: name)
                    Text("\(selectedYear)")
                        .font(.system(size: 14)).foregroundStyle(.white.opacity(0.80))
                        .animation(.spring(response: 0.3), value: selectedYear)
                }
            }
            .padding(22)
        }
        .frame(height: 115)
        .shadow(color: Color.appAccent.opacity(0.30), radius: 20, x: 0, y: 8)
    }

    // MARK: - Year Card
    var yearCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            cardHeader("سنة الصنع", icon: "calendar.badge.clock", color: Color.appAccent)
            inputRow(label: "الماركة", placeholder: "تويوتا، هيونداي...", text: $make, icon: "car.fill")
            HStack {
                Spacer()
                Text("السنة").font(.system(size: 13)).foregroundStyle(.secondary)
                Picker("السنة", selection: $selectedYear) {
                    ForEach(years, id: \.self) { y in Text(String(y)).tag(y) }
                }
                .pickerStyle(.wheel).frame(width: 120, height: 100).clipped()
            }
        }
        .padding(18).appCard()
    }

    // MARK: - Info Card
    var infoCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            cardHeader("معلومات السيارة", icon: "info.circle.fill", color: Color.appAccent)
            Divider()
            VStack(spacing: 10) {
                inputRow(label: "اسم مخصص *", placeholder: "مثال: سيارة بابا", text: $name, icon: "tag.fill")
                inputRow(label: "رقم اللوحة", placeholder: "أ ب ج 0000", text: $plateNumber, icon: "rectangle.and.pencil.and.ellipsis")
                inputRow(label: "اللون", placeholder: "فضي، أبيض...", text: $carColor, icon: "paintpalette.fill")
            }
        }
        .padding(18).appCard()
    }

    // MARK: - Specs Card
    var specsCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            cardHeader("المواصفات", icon: "gearshape.fill", color: Color.appPurple)
            Divider()
            VStack(spacing: 10) {
                inputRow(label: "التعليق",    placeholder: "كهربائي، هيدروليك", text: $suspensionType, icon: "figure.walk.motion")
                inputRow(label: "الدركسيون", placeholder: "كهربائي، هيدروليك", text: $steeringType,   icon: "steeringwheel")
                inputRow(label: "التوقيت",   placeholder: "سلسلة، حزام",        text: $timingType,     icon: "timer")
                inputRow(label: "الشمعات",   placeholder: "بلاتيني، عادي",      text: $sparkPlugType,  icon: "bolt.fill")
            }
        }
        .padding(18).appCard()
    }

    // MARK: - Mileage Card
    var mileageCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            cardHeader("الممشى الحالي", icon: "gauge.high", color: Color.appTeal)
            Divider()
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.appTeal.opacity(0.10)).frame(width: 38, height: 38)
                    Image(systemName: "gauge.high")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appTeal)
                }
                Spacer()
                TextField("150000", text: $currentMileage)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appAccent)
                Text("كم").font(.system(size: 16)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 12))
            Text("سيتم احتساب مواعيد الصيانة من هذا الممشى")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .padding(18).appCard()
    }

    // MARK: - Save Button
    var saveButton: some View {
        Button { saveCar() } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("حفظ السيارة")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(canSave
                ? LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [Color(.systemGray3), Color(.systemGray3)], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: canSave ? Color.appAccent.opacity(0.28) : .clear, radius: 10, x: 0, y: 5)
        }
        .disabled(!canSave)
    }

    // MARK: - Helpers
    func cardHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Spacer()
            Text(title).font(.system(size: 16, weight: .semibold))
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(color)
            }
        }
    }

    func inputRow(label: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 10) {
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 14))
            Text(label).font(.system(size: 12)).foregroundStyle(.secondary).fixedSize()
            ZStack {
                Circle().fill(Color.appAccent.opacity(0.08)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 13, weight: .medium)).foregroundStyle(Color.appAccent)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func saveCar() {
        guard let mileage = Int(currentMileage) else { return }
        let car = Car(context: context)
        car.id                = UUID()
        car.name              = name.trimmingCharacters(in: .whitespaces)
        car.make              = make.isEmpty ? nil : make
        car.year              = Int32(selectedYear)
        car.color             = carColor.isEmpty ? nil : carColor
        car.plateNumber       = plateNumber.isEmpty ? nil : plateNumber
        car.currentMileage    = Int32(mileage)
        car.lastMileageUpdate = Date()
        car.suspensionType    = suspensionType.isEmpty ? nil : suspensionType
        car.steeringType      = steeringType.isEmpty ? nil : steeringType
        car.timingType        = timingType.isEmpty ? nil : timingType
        car.sparkPlugType     = sparkPlugType.isEmpty ? nil : sparkPlugType
        car.onboardingCompleted = false
        insertDefaultParts(for: car, in: context)
        PersistenceController.shared.save()
        onCarSaved?(car)
        dismiss()
    }
}
