import SwiftUI

struct CarTabView: View {
    @ObservedObject var car: Car

    var body: some View {
        TabView {
            CarProfileView(car: car)
                .tabItem { Label("الملف", systemImage: "car.fill") }
            MaintenancePartsView(car: car)
                .tabItem { Label("الصيانة", systemImage: "wrench.and.screwdriver.fill") }
            InspectionIssuesView(car: car)
                .tabItem { Label("المشاكل", systemImage: "exclamationmark.bubble.fill") }
            ServiceHistoryView(car: car)
                .tabItem { Label("السجل", systemImage: "list.bullet.clipboard.fill") }
            ExpensesView(car: car)
                .tabItem { Label("المصاريف", systemImage: "creditcard.fill") }
        }
        .tint(Color.appAccent)
        .navigationTitle(car.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
