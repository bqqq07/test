import SwiftUI
import CoreData

struct PartDetailSheet: View {
    @ObservedObject var part: MaintenancePart
    @ObservedObject var car: Car
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showLogForm  = false
    @State private var serviceDate  = Date()
    @State private var serviceCost  = ""
    @State private var workshop     = ""
    @State private var serviceNotes = ""

    var mileage: Int { car.mileage }
    var partStatus: PartStatus { part.status(currentMileage: mileage) }

    var statusColor: Color {
        switch partStatus {
        case .good:    return Color.appGreen
        case .warning: return Color.appOrange
        case .overdue: return Color.appRed
        }
    }
    var statusIcon: String {
        switch partStatus {
        case .good:    return "checkmark.circle.fill"
        case .warning: return "clock.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        statusHero
                        progressCard
                        detailsCard
                        if showLogForm { logCard }
                    }
                    .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 36)
                }
            }
            .navigationTitle("تفاصيل القطعة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading)  { Button("إغلاق") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(showLogForm ? "إلغاء" : "سجّل تغيير") {
                        withAnimation(.spring(response: 0.3)) { showLogForm.toggle() }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(showLogForm ? .secondary : Color.appAccent)
                }
            }
        }
    }

    // MARK: - Status Hero
    var statusHero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(statusColor.opacity(0.10)).frame(width: 82, height: 82)
                Image(systemName: statusIcon)
                    .font(.system(size: 34, weight: .semibold)).foregroundStyle(statusColor)
            }
            VStack(spacing: 6) {
                Text(part.name ?? "").font(.system(size: 19, weight: .bold)).multilineTextAlignment(.center)
                HStack(spacing: 6) {
                    if part.isCritical {
                        Label("قطعة حرجة", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .bold)).foregroundStyle(Color.appRed)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.appRed.opacity(0.08)).clipShape(Capsule())
                    }
                    HStack(spacing: 5) {
                        Circle().fill(statusColor).frame(width: 7, height: 7)
                        Text(partStatus.rawValue)
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(statusColor)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(statusColor.opacity(0.08)).clipShape(Capsule())
                }
                if let cat = part.category {
                    Text(cat).font(.system(size: 12)).foregroundStyle(.secondary)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color(.systemGray6)).clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 24).appCard()
    }

    // MARK: - Progress Card
    var progressCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            detailCardHeader("التقدم", icon: "gauge.medium", color: statusColor)
            let ratio = part.progressRatio(currentMileage: mileage)
            VStack(alignment: .trailing, spacing: 10) {
                HStack {
                    Text("\(Int(min(ratio, 1.0) * 100))%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                    Spacer()
                    Text("مكتمل").font(.system(size: 14)).foregroundStyle(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray6)).frame(height: 10)
                        Capsule().fill(LinearGradient(
                            colors: [statusColor.opacity(0.7), statusColor],
                            startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(min(ratio, 1.0)), height: 10)
                    }
                }
                .frame(height: 10)
                if let rem = part.remainingKm(currentMileage: mileage) {
                    HStack {
                        Text(rem == 0 ? "متأخرة!" : "متبقي \(rem.formatted()) كم")
                            .font(.system(size: 13, weight: rem == 0 ? .bold : .regular))
                            .foregroundStyle(rem == 0 ? Color.appRed : Color.appTextSecondary)
                        Spacer()
                        Text("من \(part.intervalDescription)")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(18).appCard()
    }

    // MARK: - Details Card
    var detailsCard: some View {
        VStack(spacing: 0) {
            detailCardHeader("التفاصيل", icon: "info.circle.fill", color: Color.appAccent)
                .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 14)
            Divider().padding(.horizontal, 18)
            VStack(spacing: 0) {
                detailRow(label: "فترة التغيير",     value: part.intervalDescription)
                Divider().padding(.leading, 18)
                detailRow(label: "آخر تغيير عند",   value: "\(Int(part.lastChangedMileage).formatted()) كم")
                Divider().padding(.leading, 18)
                detailRow(label: "تاريخ آخر تغيير", value: (part.lastChangedDate ?? Date()).formatted(date: .abbreviated, time: .omitted))
                Divider().padding(.leading, 18)
                detailRow(label: "الممشى الحالي",   value: "\(mileage.formatted()) كم")
            }
            .padding(.bottom, 8)
        }
        .appCard()
    }

    // MARK: - Log Card
    var logCard: some View {
        VStack(alignment: .trailing, spacing: 16) {
            detailCardHeader("تسجيل تغيير", icon: "wrench.fill", color: Color.appAccent)
            VStack(spacing: 10) {
                DatePicker("التاريخ", selection: $serviceDate, displayedComponents: .date)
                    .padding(14).background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 12))
                logInputRow(label: "التكلفة (ريال)", placeholder: "المبلغ", text: $serviceCost, keyboard: .decimalPad)
                logInputRow(label: "الورشة", placeholder: "اسم الورشة", text: $workshop)
                logInputRow(label: "ملاحظات", placeholder: "ملاحظات إضافية", text: $serviceNotes)
            }
            Button { logService() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("حفظ التغيير")
                }
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(LinearGradient(
                    colors: [Color.appAccent, Color.appAccent2],
                    startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.appAccent.opacity(0.28), radius: 10, x: 0, y: 5)
            }
        }
        .padding(18).appCard()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Helpers
    func detailCardHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Spacer()
            Text(title).font(.system(size: 16, weight: .semibold))
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(color)
            }
        }
    }

    func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(value).font(.system(size: 14)).foregroundStyle(.primary)
            Spacer()
            Text(label).font(.system(size: 14)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18).padding(.vertical, 13)
    }

    func logInputRow(label: String, placeholder: String, text: Binding<String>,
                     keyboard: UIKeyboardType = .default) -> some View {
        HStack {
            TextField(placeholder, text: text).keyboardType(keyboard).multilineTextAlignment(.trailing)
                .font(.system(size: 14))
            Text(label).font(.system(size: 12)).foregroundStyle(.secondary).fixedSize()
        }
        .padding(14).background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func logService() {
        let record = ServiceRecord(context: context)
        record.id               = UUID()
        record.partName         = part.name
        record.category         = part.category
        record.mileageAtService = car.currentMileage
        record.cost             = Double(serviceCost) ?? 0
        record.workshop         = workshop.isEmpty ? nil : workshop
        record.notes            = serviceNotes.isEmpty ? nil : serviceNotes
        record.date             = serviceDate
        record.car              = car
        part.lastChangedMileage = car.currentMileage
        part.lastChangedDate    = serviceDate
        PersistenceController.shared.save()
        NotificationManager.shared.scheduleAlert(for: car)
        dismiss()
    }
}
