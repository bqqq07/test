import SwiftUI
import CoreData

struct ServiceHistoryView: View {
    @ObservedObject var car: Car
    @Environment(\.managedObjectContext) private var context
    @State private var showAddRecord = false
    @State private var searchText    = ""

    var filteredRecords: [ServiceRecord] {
        car.recordsArray.filter {
            searchText.isEmpty
            || ($0.partName ?? "").contains(searchText)
            || ($0.workshop ?? "").contains(searchText)
        }
    }

    var totalCost: Double { car.recordsArray.reduce(0) { $0 + $1.cost } }

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            if car.recordsArray.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 11)).foregroundStyle(Color.appAccent)
                            Text("\(car.recordsArray.count) عملية")
                                .font(.system(size: 12, weight: .bold)).foregroundStyle(Color.appAccent)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Color.appAccent.opacity(0.08)).clipShape(Capsule())
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("الإجمالي").font(.system(size: 11)).foregroundStyle(.secondary)
                            Text(totalCost.formatted(.currency(code: "SAR")))
                                .font(.system(size: 15, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .background(Color.appCard)
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                    List {
                        ForEach(filteredRecords, id: \.objectID) { record in
                            ServiceRecordRow(record: record)
                                .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for i in offsets { context.delete(filteredRecords[i]) }
                            PersistenceController.shared.save()
                        }
                    }
                    .listStyle(.plain).scrollContentBackground(.hidden).background(Color.appBG)
                    .searchable(text: $searchText, prompt: "بحث في السجل...")
                }
            }
        }
        .navigationTitle("سجل الإصلاحات")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddRecord = true } label: {
                    Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showAddRecord) { AddServiceRecordView(car: car) }
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Color.appAccent.opacity(0.08)).frame(width: 110, height: 110)
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 46, weight: .light)).foregroundStyle(Color.appAccent.opacity(0.6))
            }
            VStack(spacing: 8) {
                Text("لا يوجد سجل بعد").font(.system(size: 20, weight: .bold))
                Text("سيُضاف تلقائياً عند تسجيل تغيير قطعة\nأو يمكنك إضافته يدوياً")
                    .font(.system(size: 15)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct ServiceRecordRow: View {
    @ObservedObject var record: ServiceRecord

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .top, endPoint: .bottom))
                .frame(width: 4)
            HStack(spacing: 14) {
                VStack(spacing: 3) {
                    let comps = Calendar.current.dateComponents([.day, .month, .year], from: record.date ?? Date())
                    Text("\(comps.day ?? 1)")
                        .font(.system(size: 20, weight: .bold)).foregroundStyle(Color.appAccent)
                    Text(monthShort(comps.month ?? 1))
                        .font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                    Text("\(comps.year ?? 2024)")
                        .font(.system(size: 10)).foregroundStyle(.tertiary)
                }
                .frame(width: 38)
                Rectangle().fill(Color(.systemGray5)).frame(width: 1, height: 44)
                VStack(alignment: .trailing, spacing: 5) {
                    Text(record.partName ?? "")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    HStack(spacing: 8) {
                        if record.cost > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "creditcard.fill").font(.system(size: 10)).foregroundStyle(Color.appAccent.opacity(0.7))
                                Text(record.cost.formatted(.currency(code: "SAR")))
                                    .font(.system(size: 12, weight: .bold)).foregroundStyle(Color.appAccent)
                            }
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            if let w = record.workshop, !w.isEmpty {
                                HStack(spacing: 3) {
                                    Image(systemName: "wrench.fill").font(.system(size: 10)).foregroundStyle(.secondary)
                                    Text(w).font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                            }
                            if record.mileageAtService > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "gauge.high").font(.system(size: 10)).foregroundStyle(.secondary)
                                    Text("\(Int(record.mileageAtService).formatted()) كم")
                                        .font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    if let n = record.notes, !n.isEmpty {
                        Text(n).font(.system(size: 11)).foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func monthShort(_ month: Int) -> String {
        let months = ["يناير","فبراير","مارس","أبريل","مايو","يونيو",
                      "يوليو","أغسطس","سبتمبر","أكتوبر","نوفمبر","ديسمبر"]
        guard month >= 1 && month <= 12 else { return "" }
        return String(months[month - 1].prefix(3))
    }
}

struct AddServiceRecordView: View {
    let car: Car
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var partName = ""; @State private var category = ""
    @State private var cost = ""; @State private var workshop = ""
    @State private var notes = ""; @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("القطعة") {
                    rtlField("اسم القطعة *", text: $partName)
                    rtlField("الفئة",        text: $category)
                }
                Section("التفاصيل") {
                    DatePicker("التاريخ", selection: $date, displayedComponents: .date)
                    LabeledRow(label: "الممشى", value: "\(car.mileage.formatted()) كم")
                    HStack {
                        TextField("المبلغ", text: $cost).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        Text("التكلفة (ريال)").foregroundStyle(.secondary).fixedSize()
                    }
                    rtlField("الورشة", text: $workshop)
                }
                Section("ملاحظات") {
                    TextEditor(text: $notes).multilineTextAlignment(.trailing).frame(minHeight: 60)
                }
            }
            .navigationTitle("إضافة سجل")
            .toolbar {
                ToolbarItem(placement: .topBarLeading)  { Button("إلغاء") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("حفظ") {
                        let r = ServiceRecord(context: context)
                        r.id = UUID(); r.partName = partName; r.category = category
                        r.mileageAtService = car.currentMileage
                        r.cost = Double(cost) ?? 0; r.workshop = workshop
                        r.notes = notes; r.date = date; r.car = car
                        PersistenceController.shared.save(); dismiss()
                    }
                    .bold().disabled(partName.isEmpty)
                }
            }
        }
    }

    func rtlField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            TextField(label, text: text).multilineTextAlignment(.trailing)
            Text(label).foregroundStyle(.secondary).fixedSize()
        }
    }
}
