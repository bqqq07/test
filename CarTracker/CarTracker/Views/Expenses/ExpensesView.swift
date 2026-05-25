import SwiftUI
import Charts
import CoreData

struct ExpensesView: View {
    @ObservedObject var car: Car
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)], animation: .default)
    private var allCars: FetchedResults<Car>

    var monthlyData: [(String, Double)] {
        let cal = Calendar.current
        var grouped: [String: Double] = [:]
        for r in car.recordsArray {
            let c = cal.dateComponents([.year, .month], from: r.date ?? Date())
            let key = "\(c.year ?? 0)-\(String(format: "%02d", c.month ?? 0))"
            grouped[key, default: 0] += r.cost
        }
        return grouped.sorted { $0.key < $1.key }.map { (monthLabel($0.key), $0.value) }
    }

    var yearlyData: [(String, Double)] {
        let cal = Calendar.current
        var grouped: [String: Double] = [:]
        for r in car.recordsArray {
            let year = cal.component(.year, from: r.date ?? Date())
            grouped["\(year)", default: 0] += r.cost
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var categoryData: [(String, Double)] {
        Dictionary(grouping: car.recordsArray, by: { ($0.category ?? "").isEmpty ? "أخرى" : ($0.category ?? "أخرى") })
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.cost }) }
            .filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
    }

    func monthLabel(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2, let month = Int(parts[1]) else { return key }
        let months = ["يناير","فبراير","مارس","أبريل","مايو","يونيو",
                      "يوليو","أغسطس","سبتمبر","أكتوبر","نوفمبر","ديسمبر"]
        return month >= 1 && month <= 12 ? months[month - 1] : key
    }

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    heroCard
                    if !monthlyData.isEmpty { chartCard(title: "المصاريف الشهرية",  icon: "calendar",       data: monthlyData) }
                    if !yearlyData.isEmpty  { chartCard(title: "المصاريف السنوية",   icon: "chart.bar.fill", data: yearlyData) }
                    if allCars.count > 1 { comparisonCard }
                    if !categoryData.isEmpty { categoryCard }
                }
                .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 36)
            }
        }
        .navigationTitle("المصاريف")
    }

    var heroCard: some View {
        ZStack {
            LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            Circle().fill(.white.opacity(0.07)).frame(width: 150).offset(x: -60, y: -35)
            Circle().fill(.white.opacity(0.04)).frame(width: 100).offset(x: -95, y: 25)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "chart.bar.fill").font(.system(size: 16)).foregroundStyle(.white.opacity(0.75))
                        Text("\(car.recordsArray.count) عملية")
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    Text("SAR").font(.system(size: 11)).foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text("إجمالي مصاريف \(car.displayName)")
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.75))
                    Text(car.totalExpenses.formatted(.number.precision(.fractionLength(0))))
                        .font(.system(size: 40, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        .minimumScaleFactor(0.6).lineLimit(1)
                }
            }
            .padding(22)
        }
        .frame(height: 135)
        .shadow(color: Color.appAccent.opacity(0.30), radius: 20, x: 0, y: 8)
    }

    func chartCard(title: String, icon: String, data: [(String, Double)]) -> some View {
        VStack(alignment: .trailing, spacing: 16) {
            HStack(spacing: 10) {
                Spacer()
                Text(title).font(.system(size: 16, weight: .semibold))
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(Color.appAccent.opacity(0.12)).frame(width: 34, height: 34)
                    Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.appAccent)
                }
            }
            Chart {
                ForEach(data, id: \.0) { label, value in
                    BarMark(x: .value("الفترة", label), y: .value("المبلغ", value))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.appAccent, Color.appAccent.opacity(0.55)],
                            startPoint: .top, endPoint: .bottom))
                        .cornerRadius(7)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                    AxisValueLabel().font(.system(size: 10))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                    AxisValueLabel().font(.system(size: 10))
                }
            }
        }
        .padding(18).appCard()
    }

    var comparisonCard: some View {
        VStack(alignment: .trailing, spacing: 16) {
            HStack(spacing: 10) {
                Spacer()
                Text("مقارنة السيارات").font(.system(size: 16, weight: .semibold))
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(Color.appAccent.opacity(0.12)).frame(width: 34, height: 34)
                    Image(systemName: "chart.bar.xaxis").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.appAccent)
                }
            }
            let maxExpense = max(allCars.map { $0.totalExpenses }.max() ?? 1, 1)
            VStack(spacing: 16) {
                ForEach(allCars, id: \.objectID) { c in
                    let isCurrent = c.id == car.id
                    VStack(spacing: 6) {
                        HStack {
                            Text(c.totalExpenses.formatted(.currency(code: "SAR")))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(isCurrent ? Color.appAccent : .primary)
                            Spacer()
                            HStack(spacing: 4) {
                                if isCurrent {
                                    Image(systemName: "chevron.left").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.appAccent)
                                }
                                Text(c.displayName).font(.system(size: 14))
                                    .foregroundStyle(isCurrent ? Color.appAccent : .primary)
                            }
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .trailing) {
                                Capsule().fill(Color(.systemGray5)).frame(height: 8)
                                Capsule()
                                    .fill(isCurrent
                                        ? LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [Color(.systemGray3), Color(.systemGray3)], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * CGFloat(c.totalExpenses / maxExpense), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    if allCars.last !== c { Divider() }
                }
            }
        }
        .padding(18).appCard()
    }

    var categoryCard: some View {
        VStack(alignment: .trailing, spacing: 16) {
            HStack(spacing: 10) {
                Spacer()
                Text("توزيع المصاريف").font(.system(size: 16, weight: .semibold))
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(Color.appAccent.opacity(0.12)).frame(width: 34, height: 34)
                    Image(systemName: "chart.pie.fill").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.appAccent)
                }
            }
            let total = max(categoryData.reduce(0) { $0 + $1.1 }, 1)
            VStack(spacing: 14) {
                ForEach(Array(categoryData.enumerated()), id: \.offset) { idx, item in
                    let (cat, amount) = item
                    let ratio = amount / total
                    let catColor = catColor(idx)
                    VStack(spacing: 6) {
                        HStack {
                            HStack(spacing: 4) {
                                Circle().fill(catColor).frame(width: 8, height: 8)
                                Text(amount.formatted(.currency(code: "SAR")))
                                    .font(.system(size: 14, weight: .bold)).foregroundStyle(catColor)
                                Text("(\(Int(ratio * 100))%)")
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(cat).font(.system(size: 14))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .trailing) {
                                Capsule().fill(Color(.systemGray5)).frame(height: 7)
                                Capsule().fill(catColor)
                                    .frame(width: geo.size.width * CGFloat(ratio), height: 7)
                            }
                        }
                        .frame(height: 7)
                    }
                }
            }
        }
        .padding(18).appCard()
    }

    private func catColor(_ index: Int) -> Color {
        let colors: [Color] = [.appAccent, .appGreen, .appOrange, .appPurple, .appTeal, .appRed,
                                Color(red: 0.60, green: 0.50, blue: 0.40)]
        return colors[index % colors.count]
    }
}
