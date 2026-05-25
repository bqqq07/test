import SwiftUI

// MARK: - Design System
extension Color {
    static let appBG            = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let appCard          = Color.white
    static let appAccent        = Color(red: 0.22, green: 0.48, blue: 0.94)
    static let appAccent2       = Color(red: 0.16, green: 0.36, blue: 0.80)
    static let appGreen         = Color(red: 0.16, green: 0.68, blue: 0.38)
    static let appRed           = Color(red: 0.92, green: 0.22, blue: 0.22)
    static let appOrange        = Color(red: 0.98, green: 0.56, blue: 0.08)
    static let appPurple        = Color(red: 0.55, green: 0.35, blue: 0.90)
    static let appTeal          = Color(red: 0.18, green: 0.60, blue: 0.70)
    static let appTextPrimary   = Color(red: 0.10, green: 0.10, blue: 0.15)
    static let appTextSecondary = Color(red: 0.45, green: 0.45, blue: 0.52)
}

extension View {
    func appCard(radius: CGFloat = 20) -> some View {
        self
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .shadow(color: Color.black.opacity(0.055), radius: 16, x: 0, y: 5)
            .shadow(color: Color.black.opacity(0.025), radius: 3, x: 0, y: 1)
    }
    func appCardSubtle(radius: CGFloat = 16) -> some View {
        self
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("الرئيسية", systemImage: "house.fill") }
            CarsListView()
                .tabItem { Label("سياراتي", systemImage: "car.2.fill") }
            DiagnosticsView()
                .tabItem { Label("تشخيص", systemImage: "stethoscope") }
        }
        .tint(Color.appAccent)
        .preferredColorScheme(.light)
    }
}
