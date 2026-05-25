import SwiftUI
import CoreData
import PhotosUI

struct CarProfileView: View {
    @ObservedObject var car: Car
    @Environment(\.managedObjectContext) private var context
    @State private var showMileageSheet = false
    @State private var showEditSheet    = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                photoHeader
                quickStatsCard
                mileageCard
                specsCard
                infoCard
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 36)
        }
        .background(Color.appBG)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("تعديل") { showEditSheet = true }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.appAccent)
            }
        }
        .sheet(isPresented: $showMileageSheet) { UpdateMileageSheet(car: car) }
        .sheet(isPresented: $showEditSheet)    { EditCarSheet(car: car) }
        .onChange(of: selectedPhoto) { photo in
            Task {
                if let data = try? await photo?.loadTransferable(type: Data.self) {
                    car.imageData = data
                    PersistenceController.shared.save()
                }
            }
        }
    }

    // MARK: - Photo Header
    var photoHeader: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let data = car.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color.appAccent, Color.appAccent2],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.60)],
                startPoint: .top, endPoint: .bottom)
            .frame(maxWidth: .infinity).frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            HStack(alignment: .bottom) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        Circle().fill(.ultraThinMaterial).frame(width: 40, height: 40)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 15)).foregroundStyle(.primary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text(car.displayName)
                        .font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                    Text(car.displaySubtitle)
                        .font(.system(size: 14)).foregroundStyle(.white.opacity(0.80))
                }
            }
            .padding(.horizontal, 18).padding(.bottom, 18)
        }
        .shadow(color: Color.appAccent.opacity(0.22), radius: 20, x: 0, y: 8)
    }

    // MARK: - Quick Stats
    var quickStatsCard: some View {
        HStack(spacing: 0) {
            statItem(value: car.totalExpenses.formatted(.currency(code: "SAR")),
                     label: "إجمالي المصاريف", icon: "creditcard.fill", color: Color.appAccent)
            Rectangle().fill(Color(.systemGray5)).frame(width: 1, height: 44)
            statItem(value: "\(car.urgentPartsCount)", label: "مستحقة",
                     icon: "exclamationmark.triangle.fill",
                     color: car.urgentPartsCount > 0 ? .appRed : Color.appTextSecondary)
            Rectangle().fill(Color(.systemGray5)).frame(width: 1, height: 44)
            statItem(value: "\(car.warningPartsCount)", label: "قريبة",
                     icon: "clock.fill",
                     color: car.warningPartsCount > 0 ? .appOrange : Color.appTextSecondary)
        }
        .padding(.vertical, 16).appCard()
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 16, weight: .medium)).foregroundStyle(color)
            Text(value).font(.system(size: 14, weight: .bold)).foregroundStyle(color)
                .minimumScaleFactor(0.6).lineLimit(1).padding(.horizontal, 4)
            Text(label).font(.system(size: 11)).foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Mileage Card
    var mileageCard: some View {
        VStack(spacing: 0) {
            profileCardHeader("الممشى الحالي", icon: "speedometer", color: Color.appAccent)
            Divider().padding(.horizontal, 18)
            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("آخر تحديث").font(.system(size: 11)).foregroundStyle(.tertiary)
                    Text((car.lastMileageUpdate ?? Date()).formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("كم").font(.system(size: 14)).foregroundStyle(.secondary)
                    Text(car.mileage.formatted())
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appAccent)
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            Divider().padding(.horizontal, 18)
            Button { showMileageSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("تحديث الممشى")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
        }
        .appCard()
    }

    // MARK: - Specs Card
    var specsCard: some View {
        VStack(spacing: 0) {
            profileCardHeader("مواصفات السيارة", icon: "gearshape.2.fill", color: Color.appPurple)
            Divider().padding(.horizontal, 18)
            VStack(spacing: 0) {
                specRow(icon: "figure.walk.motion", label: "التعليق",   value: car.suspensionType ?? "—",  color: Color.appPurple)
                Divider().padding(.leading, 18)
                specRow(icon: "steeringwheel",      label: "الدركسيون", value: car.steeringType   ?? "—",  color: Color.appTeal)
                Divider().padding(.leading, 18)
                specRow(icon: "timer",              label: "التوقيت",   value: car.timingType     ?? "—",  color: Color.appOrange)
                Divider().padding(.leading, 18)
                specRow(icon: "bolt.fill",          label: "الشمعات",   value: car.sparkPlugType  ?? "—",  color: Color.appGreen)
            }
            .padding(.bottom, 8)
        }
        .appCard()
    }

    // MARK: - Info Card
    var infoCard: some View {
        VStack(spacing: 0) {
            profileCardHeader("معلومات السيارة", icon: "info.circle.fill", color: Color.appAccent)
            Divider().padding(.horizontal, 18)
            VStack(spacing: 0) {
                infoRow(label: "الاسم",      value: car.displayName)
                Divider().padding(.leading, 18)
                infoRow(label: "الماركة",    value: car.make ?? "—")
                Divider().padding(.leading, 18)
                infoRow(label: "سنة الصنع", value: "\(car.displayYear)")
                Divider().padding(.leading, 18)
                infoRow(label: "اللوحة",    value: car.plateNumber ?? "—")
                Divider().padding(.leading, 18)
                infoRow(label: "اللون",     value: car.color ?? "—")
            }
            .padding(.bottom, 8)
        }
        .appCard()
    }

    // MARK: - Helpers
    func profileCardHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Spacer()
            Text(title).font(.system(size: 16, weight: .semibold))
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(color)
            }
        }
        .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 14)
    }

    func specRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Text(value).font(.system(size: 14)).foregroundStyle(.primary)
            Spacer()
            Text(label).font(.system(size: 14)).foregroundStyle(.secondary)
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.10)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 13, weight: .medium)).foregroundStyle(color)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 13)
    }

    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(value).font(.system(size: 14)).foregroundStyle(.primary)
            Spacer()
            Text(label).font(.system(size: 14)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18).padding(.vertical, 13)
    }
}

// MARK: - Update Mileage Sheet
struct UpdateMileageSheet: View {
    @ObservedObject var car: Car
    @Environment(\.dismiss) private var dismiss
    @State private var mileageText = ""
    @State private var showError   = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.appAccent.opacity(0.10)).frame(width: 68, height: 68)
                        Image(systemName: "speedometer")
                            .font(.system(size: 28)).foregroundStyle(Color.appAccent)
                    }
                    Text("تحديث الممشى").font(.system(size: 20, weight: .bold))
                    Text("الحالي: \(car.mileage.formatted()) كم")
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                }
                .padding(.top, 32).padding(.bottom, 28)

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("كم").font(.system(size: 16)).foregroundStyle(.secondary)
                        TextField("", text: $mileageText)
                            .focused($focused)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.appAccent)
                    }
                    .padding(.horizontal, 24).padding(.vertical, 18)
                    .background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 16))

                    if showError {
                        Label("الممشى الجديد يجب أن يكون أكبر من الحالي", systemImage: "exclamationmark.circle")
                            .font(.system(size: 12)).foregroundStyle(Color.appRed)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    guard let val = Int(mileageText), val > car.mileage else { showError = true; return }
                    car.currentMileage    = Int32(val)
                    car.lastMileageUpdate = Date()
                    PersistenceController.shared.save()
                    NotificationManager.shared.scheduleAlert(for: car)
                    dismiss()
                } label: {
                    Text("حفظ")
                        .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(mileageText.isEmpty ? Color(.systemGray4) :
                            LinearGradient(colors: [Color.appAccent, Color.appAccent2],
                                           startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
                .disabled(mileageText.isEmpty)
            }
            .onAppear { focused = true }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("إلغاء") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Edit Car Sheet
struct EditCarSheet: View {
    @ObservedObject var car: Car
    @Environment(\.dismiss) private var dismiss

    @State private var name           = ""
    @State private var make           = ""
    @State private var color          = ""
    @State private var plateNumber    = ""
    @State private var selectedYear   = 2020
    @State private var suspensionType = ""
    @State private var steeringType   = ""
    @State private var timingType     = ""
    @State private var sparkPlugType  = ""

    let years: [Int] = Array(stride(
        from: Calendar.current.component(.year, from: Date()),
        through: 1990, by: -1))

    var body: some View {
        NavigationStack {
            Form {
                Section("معلومات السيارة") {
                    rtlRow(label: "الاسم",       text: $name,        placeholder: "اسم مخصص")
                    rtlRow(label: "الماركة",     text: $make,        placeholder: "تويوتا، هيونداي...")
                    rtlRow(label: "رقم اللوحة", text: $plateNumber,  placeholder: "أ ب ج 0000")
                    rtlRow(label: "اللون",       text: $color,       placeholder: "فضي، أبيض...")
                    HStack {
                        Picker("السنة", selection: $selectedYear) {
                            ForEach(years, id: \.self) { y in Text(String(y)).tag(y) }
                        }
                        Spacer()
                        Text("سنة الصنع").foregroundStyle(.secondary)
                    }
                }
                Section("المواصفات") {
                    rtlRow(label: "التعليق",    text: $suspensionType, placeholder: "كهربائي، هيدروليك")
                    rtlRow(label: "الدركسيون", text: $steeringType,   placeholder: "كهربائي، هيدروليك")
                    rtlRow(label: "التوقيت",   text: $timingType,     placeholder: "سلسلة، حزام")
                    rtlRow(label: "الشمعات",   text: $sparkPlugType,  placeholder: "بلاتيني، عادي")
                }
            }
            .navigationTitle("تعديل السيارة")
            .onAppear {
                name = car.name ?? ""; make = car.make ?? ""
                color = car.color ?? ""; plateNumber = car.plateNumber ?? ""
                selectedYear = car.displayYear
                suspensionType = car.suspensionType ?? ""; steeringType = car.steeringType ?? ""
                timingType = car.timingType ?? ""; sparkPlugType = car.sparkPlugType ?? ""
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading)  { Button("إلغاء") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("حفظ") {
                        car.name = name.isEmpty ? nil : name
                        car.make = make.isEmpty ? nil : make
                        car.color = color.isEmpty ? nil : color
                        car.plateNumber = plateNumber.isEmpty ? nil : plateNumber
                        car.year = Int32(selectedYear)
                        car.suspensionType = suspensionType.isEmpty ? nil : suspensionType
                        car.steeringType = steeringType.isEmpty ? nil : steeringType
                        car.timingType = timingType.isEmpty ? nil : timingType
                        car.sparkPlugType = sparkPlugType.isEmpty ? nil : sparkPlugType
                        PersistenceController.shared.save()
                        dismiss()
                    }.bold()
                }
            }
        }
    }

    private func rtlRow(label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            TextField(placeholder, text: text).multilineTextAlignment(.trailing)
            Text(label).foregroundStyle(.secondary).fixedSize()
        }
    }
}

// MARK: - Shared helpers used across views
struct LabeledRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(value).foregroundStyle(.primary)
            Spacer()
            Text(label).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
