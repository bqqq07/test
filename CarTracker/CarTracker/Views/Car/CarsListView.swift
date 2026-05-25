import SwiftUI
import CoreData

struct CarsListView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)], animation: .default)
    private var cars: FetchedResults<Car>
    @Environment(\.managedObjectContext) private var context

    @State private var showAddCar          = false
    @State private var savedCar: Car?      = nil
    @State private var showOnboarding      = false
    @State private var carPendingOnboarding: Car? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                if cars.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(cars, id: \.objectID) { car in
                            NavigationLink(destination: CarTabView(car: car)
                                .onAppear {
                                    if !car.onboardingCompleted {
                                        carPendingOnboarding = car
                                    }
                                }) {
                                CarListRow(car: car)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        }
                        .onDelete(perform: deleteCars)
                    }
                    .listStyle(.plain)
                    .background(Color.appBG)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("سياراتي")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddCar = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.appAccent)
                    }
                }
                if !cars.isEmpty {
                    ToolbarItem(placement: .topBarLeading) { EditButton() }
                }
            }
            .sheet(isPresented: $showAddCar) {
                AddCarView { car in
                    savedCar = car
                    showOnboarding = true
                }
                .environment(\.managedObjectContext, context)
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                if let car = savedCar {
                    CarOnboardingView(car: car)
                        .environment(\.managedObjectContext, context)
                }
            }
            .fullScreenCover(item: $carPendingOnboarding) { car in
                CarOnboardingView(car: car)
                    .environment(\.managedObjectContext, context)
            }
        }
    }

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
                Text("لا توجد سيارات")
                    .font(.system(size: 22, weight: .bold))
                Text("اضغط + لإضافة سيارتك الأولى")
                    .font(.system(size: 15)).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    func deleteCars(at offsets: IndexSet) {
        for i in offsets { context.delete(cars[i]) }
        PersistenceController.shared.save()
    }
}

// MARK: - Car List Row
struct CarListRow: View {
    @ObservedObject var car: Car

    var statusColor: Color {
        if car.urgentPartsCount  > 0 { return Color.appRed }
        if car.warningPartsCount > 0 { return Color.appOrange }
        return Color.appGreen
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(statusColor)
                .frame(width: 4)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(Color.appAccent.opacity(0.08))
                        .frame(width: 54, height: 54)
                    if let data = car.imageData, let img = UIImage(data: data) {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 54, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                    } else {
                        Image(systemName: "car.fill")
                            .font(.system(size: 22)).foregroundStyle(Color.appAccent)
                    }
                }

                VStack(alignment: .trailing, spacing: 5) {
                    Text(car.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text("\(car.displaySubtitle)  ·  \(car.mileage.formatted()) كم")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                VStack(spacing: 4) {
                    if car.urgentPartsCount > 0 {
                        VStack(spacing: 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.appRed)
                            Text("\(car.urgentPartsCount)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.appRed)
                        }
                    } else if car.warningPartsCount > 0 {
                        VStack(spacing: 2) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.appOrange)
                            Text("\(car.warningPartsCount)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.appOrange)
                        }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.appGreen)
                    }
                }
                .frame(width: 34)
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.055), radius: 14, x: 0, y: 4)
        .shadow(color: .black.opacity(0.025), radius: 3, x: 0, y: 1)
    }
}
