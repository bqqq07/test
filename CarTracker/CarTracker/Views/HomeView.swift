import SwiftUI
import CoreData

struct HomeView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)], animation: .default)
    private var cars: FetchedResults<Car>

    var urgentCars:  [Car] { cars.filter { $0.urgentPartsCount > 0 } }
    var warningCars: [Car] { cars.filter { $0.warningPartsCount > 0 && $0.urgentPartsCount == 0 } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                if cars.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            summaryCard
                            if !urgentCars.isEmpty  { alertSection(title: "تحتاج صيانة الآن",   cars: urgentCars,  color: .appRed) }
                            if !warningCars.isEmpty { alertSection(title: "موعد الصيانة قريب",  cars: warningCars, color: .appOrange) }
                            allCarsSection
                        }
                        .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 36)
                    }
                }
            }
            .navigationTitle("الرئيسية")
        }
    }

    // MARK: - Summary Card
    var summaryCard: some View {
        HStack(spacing: 0) {
            summaryItem(value: "\(cars.count)",
                        label: "سياراتي",
                        icon: "car.2.fill",
                        color: Color.appAccent)
            Rectangle().fill(Color(.systemGray5)).frame(width: 1, height: 44)
            summaryItem(value: "\(urgentCars.count)",
                        label: "تحتاج صيانة",
                        icon: "exclamationmark.triangle.fill",
                        color: urgentCars.isEmpty ? Color.appTextSecondary : Color.appRed)
            Rectangle().fill(Color(.systemGray5)).frame(width: 1, height: 44)
            summaryItem(
                value: cars.reduce(0) { $0 + $1.totalExpenses }
                    .formatted(.number.precision(.fractionLength(0))),
                label: "إجمالي المصاريف",
                icon: "creditcard.fill",
                color: Color.appAccent)
        }
        .padding(.vertical, 16)
        .appCard()
    }

    private func summaryItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6).lineLimit(1).padding(.horizontal, 4)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Alert Section
    private func alertSection(title: String, cars: [Car], color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack(spacing: 8) {
                Spacer()
                Text(title).font(.system(size: 16, weight: .semibold))
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.12)).frame(width: 32, height: 32)
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(color)
                }
            }
            ForEach(cars, id: \.objectID) { car in
                NavigationLink(destination: CarTabView(car: car)) {
                    HStack(spacing: 12) {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(car.displayName).font(.system(size: 15, weight: .semibold))
                            Text(car.displaySubtitle).font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(spacing: 3) {
                            Image(systemName: color == .appRed ? "exclamationmark.triangle.fill" : "clock.fill")
                                .font(.system(size: 12, weight: .bold)).foregroundStyle(color)
                            Text("\(color == .appRed ? car.urgentPartsCount : car.warningPartsCount)")
                                .font(.system(size: 13, weight: .bold)).foregroundStyle(color)
                        }
                        .frame(width: 34)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 13)
                    .background(color.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.15), lineWidth: 1))
                }
                .foregroundStyle(.primary)
            }
        }
        .padding(18).appCard()
    }

    // MARK: - All Cars Section
    var allCarsSection: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack(spacing: 8) {
                Spacer()
                Text("كل سياراتي").font(.system(size: 16, weight: .semibold))
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(Color.appAccent.opacity(0.12)).frame(width: 32, height: 32)
                    Image(systemName: "car.2.fill")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.appAccent)
                }
            }
            ForEach(cars, id: \.objectID) { car in
                NavigationLink(destination: CarTabView(car: car)) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appAccent.opacity(0.08))
                                .frame(width: 46, height: 46)
                            if let data = car.imageData, let img = UIImage(data: data) {
                                Image(uiImage: img).resizable().scaledToFill()
                                    .frame(width: 46, height: 46)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Image(systemName: "car.fill")
                                    .font(.system(size: 19)).foregroundStyle(Color.appAccent)
                            }
                        }
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(car.displayName).font(.system(size: 15, weight: .semibold))
                            Text("\(car.displaySubtitle) · \(car.mileage.formatted()) كم")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Circle()
                            .fill(car.urgentPartsCount > 0 ? Color.appRed :
                                  car.warningPartsCount > 0 ? Color.appOrange : Color.appGreen)
                            .frame(width: 10, height: 10)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(Color.appBG)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .foregroundStyle(.primary)
            }
        }
        .padding(18).appCard()
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.appAccent.opacity(0.12), Color.appAccent.opacity(0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 110, height: 110)
                Image(systemName: "car.2")
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(Color.appAccent.opacity(0.7))
            }
            VStack(spacing: 8) {
                Text("مرحباً بك في كار تراكر")
                    .font(.system(size: 22, weight: .bold))
                Text("أضف سيارتك من تبويب \"سياراتي\" للبدء")
                    .font(.system(size: 15)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
