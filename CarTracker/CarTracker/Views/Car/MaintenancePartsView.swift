import SwiftUI
import CoreData

struct MaintenancePartsView: View {
    @ObservedObject var car: Car
    @Environment(\.managedObjectContext) private var context

    @State private var searchText        = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedPart: MaintenancePart? = nil
    @State private var showAddPart       = false

    var allParts: [MaintenancePart] { car.partsArray }
    var categories: [String] { Array(Set(allParts.map { $0.category ?? "" })).sorted() }
    var goodCount: Int { allParts.filter { $0.status(currentMileage: car.mileage) == .good }.count }

    var filteredParts: [MaintenancePart] {
        allParts.filter { part in
            let matchCat    = selectedCategory == nil || part.category == selectedCategory
            let matchSearch = searchText.isEmpty || (part.name ?? "").contains(searchText)
            return matchCat && matchSearch
        }
        .sorted { a, b in
            let ra = rankPart(a), rb = rankPart(b)
            if ra != rb { return ra > rb }
            return a.urgencyScore(currentMileage: car.mileage) > b.urgencyScore(currentMileage: car.mileage)
        }
    }

    private func rankPart(_ p: MaintenancePart) -> Int {
        switch p.status(currentMileage: car.mileage) {
        case .overdue: return 2
        case .warning: return 1
        case .good:    return 0
        }
    }

    var groupedParts: [(String, [MaintenancePart])] {
        Dictionary(grouping: filteredParts, by: { $0.category ?? "أخرى" })
            .map { ($0.key, $0.value) }
            .sorted { a, b in
                let au = a.1.contains { $0.status(currentMileage: car.mileage) == .overdue }
                let bu = b.1.contains { $0.status(currentMileage: car.mileage) == .overdue }
                if au != bu { return au }
                return a.0 < b.0
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            if allParts.isEmpty {
                emptyState
            } else {
                // Stats bar
                statsBar
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .background(Color.appCard)
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)

                // Category chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        AppChipButton(label: "الكل", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(categories, id: \.self) { cat in
                            AppChipButton(label: cat, isSelected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, 18).padding(.vertical, 12)
                }
                .background(Color.appBG)

                List {
                    ForEach(groupedParts, id: \.0) { category, parts in
                        Section {
                            ForEach(parts, id: \.objectID) { part in
                                PartRow(part: part, mileage: car.mileage)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedPart = part }
                                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete { offsets in
                                for i in offsets { context.delete(parts[i]) }
                                PersistenceController.shared.save()
                            }
                        } header: {
                            Text(category)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.appTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.top, 6)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.appBG)
            }
        }
        .background(Color.appBG)
        .navigationTitle("قطع الصيانة")
        .searchable(text: $searchText, prompt: "بحث عن قطعة...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddPart = true } label: {
                    Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(item: $selectedPart) { part in PartDetailSheet(part: part, car: car) }
        .sheet(isPresented: $showAddPart)  { AddPartView(car: car) }
    }

    // MARK: - Stats Bar
    var statsBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "speedometer").font(.system(size: 11)).foregroundStyle(Color.appAccent)
                Text("\(car.mileage.formatted()) كم")
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(Color.appAccent)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.appAccent.opacity(0.08)).clipShape(Capsule())
            Spacer()
            HStack(spacing: 16) {
                MiniStat(count: goodCount,              label: "جيدة",   color: .appGreen)
                Rectangle().fill(Color(.systemGray5)).frame(width: 1, height: 24)
                MiniStat(count: car.warningPartsCount,  label: "قريبة",  color: .appOrange)
                Rectangle().fill(Color(.systemGray5)).frame(width: 1, height: 24)
                MiniStat(count: car.urgentPartsCount,   label: "مستحقة", color: .appRed)
            }
        }
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 60)
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.appAccent.opacity(0.12), Color.appAccent.opacity(0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 110, height: 110)
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(Color.appAccent.opacity(0.7))
            }
            VStack(spacing: 8) {
                Text("لا توجد قطع صيانة").font(.system(size: 20, weight: .bold))
                Text("أضف قطع سيارتك لتتبع\nمواعيد التغيير تلقائياً")
                    .font(.system(size: 15)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            Button { showAddPart = true } label: {
                Label("إضافة قطعة", systemImage: "plus")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: 240).padding(.vertical, 15)
                    .background(LinearGradient(
                        colors: [Color.appAccent, Color.appAccent2],
                        startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.appAccent.opacity(0.30), radius: 12, x: 0, y: 5)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity).background(Color.appBG)
    }
}

// MARK: - Mini Stat
struct MiniStat: View {
    let count: Int; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(count > 0 ? color : Color(.systemGray4))
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(minWidth: 42)
    }
}

// MARK: - Chip Button
struct AppChipButton: View {
    let label: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(isSelected ? Color.appAccent : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : Color.appTextPrimary)
                .clipShape(Capsule())
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Part Row
struct PartRow: View {
    @ObservedObject var part: MaintenancePart
    let mileage: Int

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
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3).fill(statusColor).frame(width: 4)
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(statusColor.opacity(0.10))
                        .frame(width: 42, height: 42)
                    Image(systemName: statusIcon)
                        .font(.system(size: 16, weight: .semibold)).foregroundStyle(statusColor)
                }
                VStack(alignment: .trailing, spacing: 5) {
                    HStack {
                        if part.isCritical {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10)).foregroundStyle(Color.appRed)
                        }
                        Spacer()
                        Text(part.name ?? "").font(.system(size: 15, weight: .semibold))
                    }
                    Text(part.intervalDescription)
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    if part.intervalKm > 0 {
                        let ratio = part.progressRatio(currentMileage: mileage)
                        VStack(alignment: .trailing, spacing: 4) {
                            GeometryReader { geo in
                                ZStack(alignment: .trailing) {
                                    Capsule().fill(Color(.systemGray6)).frame(height: 5)
                                    Capsule().fill(statusColor)
                                        .frame(width: geo.size.width * CGFloat(min(ratio, 1.0)), height: 5)
                                }
                            }
                            .frame(height: 5)
                            if let rem = part.remainingKm(currentMileage: mileage) {
                                Text(rem == 0 ? "متأخرة!" : "متبقي \(rem.formatted()) كم")
                                    .font(.system(size: 11, weight: rem == 0 ? .bold : .regular))
                                    .foregroundStyle(rem == 0 ? Color.appRed : Color.appTextSecondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}
