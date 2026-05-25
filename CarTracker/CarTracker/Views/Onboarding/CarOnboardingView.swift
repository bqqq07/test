import SwiftUI
import CoreData

// MARK: - Answer Type
enum OnboardingAnswer {
    case recent
    case atMileage(Int)
    case unknown
}

// MARK: - Question Model
struct OnboardingQuestion: Identifiable {
    let id = UUID()
    let part: MaintenancePart
    var answer: OnboardingAnswer? = nil

    var answerColor: Color {
        guard let answer = answer else { return .secondary }
        switch answer {
        case .recent:      return Color.appGreen
        case .atMileage:   return Color.appAccent
        case .unknown:     return Color.appOrange
        }
    }
}

// MARK: - Main View
struct CarOnboardingView: View {
    @ObservedObject var car: Car
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [OnboardingQuestion] = []
    @State private var showSummary = false

    var answeredCount: Int { questions.filter { $0.answer != nil }.count }
    var progress: Double   { questions.isEmpty ? 0 : Double(answeredCount) / Double(questions.count) }

    var overdueAfter:  [MaintenancePart] { car.partsArray.filter { $0.status(currentMileage: car.mileage) == .overdue } }
    var warningAfter:  [MaintenancePart] { car.partsArray.filter { $0.status(currentMileage: car.mileage) == .warning } }
    var goodAfter:     [MaintenancePart] { car.partsArray.filter { $0.status(currentMileage: car.mileage) == .good } }

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            if showSummary {
                summaryView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if questions.isEmpty {
                allGoodView
            } else {
                questionnaireView
                    .transition(.opacity)
            }
        }
        .onAppear { buildQuestions() }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showSummary)
    }

    // MARK: - Build Questions
    func buildQuestions() {
        let mileage = car.mileage
        var result: [OnboardingQuestion] = []

        for part in car.partsArray {
            if part.intervalKm > 0 {
                let interval = Int(part.intervalKm)
                let cyclePos = mileage % interval
                let ratio    = Double(cyclePos) / Double(interval)
                // عرض السؤال إذا قريب من نهاية الدورة أو الممشى يتجاوز دورة كاملة
                if ratio >= 0.70 || mileage >= interval {
                    result.append(OnboardingQuestion(part: part))
                }
            } else if part.intervalMonths > 0 || part.intervalYears > 0 {
                // القطع الزمنية للسيارات المستعملة
                if mileage > 30000 {
                    result.append(OnboardingQuestion(part: part))
                }
            }
        }

        // ترتيب: الحرجة أولاً ثم الأعلى نسبة في الدورة
        questions = result.sorted {
            if $0.part.isCritical != $1.part.isCritical { return $0.part.isCritical }
            let interval0 = max(Int($0.part.intervalKm), 1)
            let interval1 = max(Int($1.part.intervalKm), 1)
            let r0 = Double(mileage % interval0) / Double(interval0)
            let r1 = Double(mileage % interval1) / Double(interval1)
            return r0 > r1
        }
    }

    // MARK: - Questionnaire View
    var questionnaireView: some View {
        VStack(spacing: 0) {
            headerBar
            progressSection
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(questions.enumerated()), id: \.element.id) { idx, q in
                        QuestionCard(
                            question: q,
                            carMileage: car.mileage,
                            onAnswer: { answer in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    questions[idx].answer = answer
                                    applyAnswer(index: idx, answer: answer)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 36)
            }
            bottomActionBar
        }
    }

    // MARK: - Header Bar
    var headerBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button("تخطي") { skipAll() }
                    .font(.system(size: 15)).foregroundStyle(.secondary)
                Spacer()
                VStack(spacing: 2) {
                    Text("استبيان الحالة").font(.system(size: 17, weight: .semibold))
                    Text(car.displayName).font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(answeredCount)/\(questions.count)")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.appAccent)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            Divider()
        }
        .background(Color.appCard)
    }

    // MARK: - Progress Section
    var progressSection: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5)).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(progress), height: 5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 5).padding(.horizontal, 20)
            HStack {
                Text("ممشى السيارة: \(car.mileage.formatted()) كم")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(progress * 100))% مكتمل")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.appAccent)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 10).background(Color.appBG)
    }

    // MARK: - Bottom Bar
    var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 14) {
                HStack(spacing: 14) {
                    bottomStat(count: overdueAfter.count,  label: "مستحقة", color: .appRed)
                    bottomStat(count: warningAfter.count,  label: "قريبة",  color: .appOrange)
                    bottomStat(count: goodAfter.count,     label: "جيدة",   color: .appGreen)
                }
                Spacer()
                Button { finishOnboarding() } label: {
                    HStack(spacing: 6) {
                        Text(answeredCount == questions.count ? "عرض النتائج" : "إنهاء")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "arrow.left").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Color.appCard)
    }

    func bottomStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(count)").font(.system(size: 17, weight: .bold)).foregroundStyle(count > 0 ? color : Color(.systemGray4))
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
    }

    // MARK: - Summary View
    var summaryView: some View {
        VStack(spacing: 0) {
            // Hero
            ZStack {
                LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea(edges: .top)
                VStack(spacing: 18) {
                    Spacer(minLength: 50)
                    ZStack {
                        Circle().fill(.white.opacity(0.15)).frame(width: 96, height: 96)
                        Image(systemName: overdueAfter.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 42)).foregroundStyle(.white)
                    }
                    VStack(spacing: 6) {
                        Text("تقرير حالة السيارة").font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
                        Text(car.displayName).font(.system(size: 15)).foregroundStyle(.white.opacity(0.80))
                    }
                    Spacer(minLength: 16)
                }
            }
            .frame(height: 260)

            // Stats Row
            HStack(spacing: 0) {
                summaryStatItem(count: overdueAfter.count, label: "تحتاج صيانة", color: .appRed,    icon: "exclamationmark.triangle.fill")
                Rectangle().fill(Color(.systemGray5)).frame(width: 1, height: 50)
                summaryStatItem(count: warningAfter.count, label: "موعدها قريب", color: .appOrange, icon: "clock.fill")
                Rectangle().fill(Color(.systemGray5)).frame(width: 1, height: 50)
                summaryStatItem(count: goodAfter.count,    label: "حالتها جيدة", color: .appGreen,  icon: "checkmark.circle.fill")
            }
            .padding(.vertical, 18)
            .background(Color.appCard)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if !overdueAfter.isEmpty {
                        summaryPartsSection(title: "تحتاج صيانة الآن", parts: overdueAfter, color: .appRed)
                    }
                    if !warningAfter.isEmpty {
                        summaryPartsSection(title: "موعدها قريب", parts: warningAfter, color: .appOrange)
                    }
                    if overdueAfter.isEmpty && warningAfter.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 50)).foregroundStyle(Color.appGreen)
                            Text("سيارتك في حالة ممتازة!").font(.system(size: 18, weight: .bold))
                            Text("كل قطع الصيانة بخير بناءً على المعلومات المدخلة")
                                .font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                        .padding(32).frame(maxWidth: .infinity).appCard()
                    }
                }
                .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 40)
            }

            VStack(spacing: 0) {
                Divider()
                Button { completeOnboarding() } label: {
                    HStack(spacing: 8) {
                        Text("ابدأ تتبع سيارتك").font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.left").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.appAccent.opacity(0.28), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
            }
            .background(Color.appCard)
        }
    }

    func summaryStatItem(count: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(count > 0 ? color : Color(.systemGray4))
            Text("\(count)").font(.system(size: 26, weight: .bold)).foregroundStyle(count > 0 ? color : Color(.systemGray4))
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    func summaryPartsSection(title: String, parts: [MaintenancePart], color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 10) {
                Spacer()
                Text(title).font(.system(size: 16, weight: .semibold))
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.12)).frame(width: 34, height: 34)
                    Image(systemName: color == .appRed ? "exclamationmark.triangle.fill" : "clock.fill")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(color)
                }
            }
            .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 12)
            Divider().padding(.horizontal, 18)
            ForEach(parts, id: \.objectID) { part in
                HStack(spacing: 10) {
                    Text(part.intervalDescription)
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(color)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(color.opacity(0.08)).clipShape(Capsule())
                    Spacer()
                    Text(part.name ?? "").font(.system(size: 14, weight: .medium))
                    if part.isCritical {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10)).foregroundStyle(Color.appRed)
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 11)
                if part.objectID != parts.last?.objectID {
                    Divider().padding(.leading, 18)
                }
            }
            .padding(.bottom, 8)
        }
        .appCard()
    }

    // MARK: - All Good View (when no questions needed)
    var allGoodView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { completeOnboarding() } label: {
                    Text("تخطي").font(.system(size: 15)).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20).padding(.top, 14)
            Spacer()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.appGreen.opacity(0.15), Color.appGreen.opacity(0.05)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52)).foregroundStyle(Color.appGreen)
                }
                VStack(spacing: 10) {
                    Text("حالة سيارتك ممتازة!").font(.system(size: 24, weight: .bold))
                    Text("لا توجد قطع مستحقة الصيانة\nبناءً على ممشى سيارتك الحالي")
                        .font(.system(size: 15)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
            }
            Spacer()
            Button { completeOnboarding() } label: {
                HStack(spacing: 8) {
                    Text("ابدأ").font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.left").font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Actions
    func applyAnswer(index: Int, answer: OnboardingAnswer) {
        let part = questions[index].part
        switch answer {
        case .recent:
            part.lastChangedMileage = car.currentMileage
            part.lastChangedDate    = Date()
        case .atMileage(let km):
            part.lastChangedMileage = Int32(km)
            part.lastChangedDate    = Date()
        case .unknown:
            part.lastChangedMileage = 0
            part.lastChangedDate    = Calendar.current.date(byAdding: .year, value: -10, to: Date())
        }
        PersistenceController.shared.save()
    }

    func finishOnboarding() {
        // القطع غير المجاب عنها → unknown
        for i in questions.indices where questions[i].answer == nil {
            questions[i].answer = .unknown
            applyAnswer(index: i, answer: .unknown)
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { showSummary = true }
    }

    func skipAll() { completeOnboarding() }

    func completeOnboarding() {
        car.onboardingCompleted = true
        PersistenceController.shared.save()
        NotificationManager.shared.scheduleAlert(for: car)
        dismiss()
    }
}

// MARK: - Question Card
struct QuestionCard: View {
    let question: OnboardingQuestion
    let carMileage: Int
    let onAnswer: (OnboardingAnswer) -> Void

    @State private var showMileageInput = false
    @State private var mileageInput     = ""
    @State private var inputError       = false

    var part: MaintenancePart { question.part }
    var interval: Int         { Int(part.intervalKm) }
    var cycleCount: Int       { interval > 0 ? carMileage / interval : 0 }
    var cycleRatio: Double    {
        guard interval > 0 else { return 0 }
        return Double(carMileage % interval) / Double(interval)
    }
    var isAnswered: Bool      { question.answer != nil }

    var statusColor: Color {
        if cycleRatio >= 0.90 || cycleRatio == 0 && interval > 0 && carMileage >= interval { return Color.appRed }
        if cycleRatio >= 0.70 { return Color.appOrange }
        return Color.appAccent
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Part header
            HStack(spacing: 12) {
                if isAnswered {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22)).foregroundStyle(question.answerColor)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(statusColor.opacity(0.10)).frame(width: 38, height: 38)
                        Image(systemName: part.isCritical ? "exclamationmark.triangle.fill" : "wrench.fill")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(statusColor)
                    }
                }
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 6) {
                        if part.isCritical {
                            Text("حرجة").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.appRed).clipShape(Capsule())
                        }
                        Text(part.name ?? "").font(.system(size: 16, weight: .semibold))
                    }
                    HStack(spacing: 6) {
                        Text("كل \(part.intervalDescription)").font(.system(size: 11)).foregroundStyle(.secondary)
                        if interval > 0 && cycleCount > 0 {
                            Text("·").foregroundStyle(.tertiary)
                            Text("مرّت \(cycleCount) دورة").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 12)

            // Progress bar (km parts only)
            if interval > 0 {
                VStack(spacing: 5) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemGray6)).frame(height: 5)
                            Capsule()
                                .fill(LinearGradient(colors: [statusColor.opacity(0.6), statusColor], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * CGFloat(min(cycleRatio, 1.0)), height: 5)
                        }
                    }
                    .frame(height: 5)
                    HStack {
                        Text("بداية الدورة").font(.system(size: 9)).foregroundStyle(Color(.systemGray4))
                        Spacer()
                        Text("\(Int(cycleRatio * 100))% من الدورة الحالية")
                            .font(.system(size: 10, weight: .medium)).foregroundStyle(statusColor)
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 12)
            }

            Divider()

            // Question prompt
            if !isAnswered {
                Text("آخر مرة غيّرت \(part.name ?? "هذه القطعة")؟")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                Divider()
            }

            // Mileage input field
            if showMileageInput && !isAnswered {
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 10) {
                        Button {
                            guard let km = Int(mileageInput), km > 0, km <= carMileage else {
                                withAnimation { inputError = true }; return
                            }
                            onAnswer(.atMileage(km)); showMileageInput = false
                        } label: {
                            Text("تأكيد").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(Color.appAccent).clipShape(Capsule())
                        }
                        TextField("الممشى عند آخر تغيير", text: $mileageInput)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                            .font(.system(size: 15))
                            .onChange(of: mileageInput) { _ in inputError = false }
                        Text("كم").font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    if inputError {
                        Text("أدخل ممشى صحيح (أقل من \(carMileage.formatted()) كم)")
                            .font(.system(size: 11)).foregroundStyle(Color.appRed)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color.appAccent.opacity(0.04))
                Divider()
            }

            // Answer buttons or answered state
            if !isAnswered {
                HStack(spacing: 8) {
                    answerBtn(label: "ما أعرف",    icon: "questionmark.circle", color: .appOrange) {
                        onAnswer(.unknown); showMileageInput = false
                    }
                    answerBtn(label: "أدخل الممشى", icon: "speedometer",        color: .appAccent) {
                        withAnimation(.spring(response: 0.3)) { showMileageInput.toggle() }
                    }
                    answerBtn(label: "مؤخراً",      icon: "checkmark.circle",    color: .appGreen) {
                        onAnswer(.recent); showMileageInput = false
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            } else {
                HStack(spacing: 8) {
                    Spacer()
                    answeredBadge
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
        }
        .appCard()
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isAnswered)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showMileageInput)
    }

    func answerBtn(label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color)
                Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(color)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(color.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    var answeredBadge: some View {
        switch question.answer {
        case .recent:
            Label("غيّرته مؤخراً", systemImage: "checkmark.circle.fill").foregroundStyle(Color.appGreen)
        case .atMileage(let km):
            Label("عند \(km.formatted()) كم", systemImage: "speedometer").foregroundStyle(Color.appAccent)
        case .unknown:
            Label("يحتاج فحص", systemImage: "exclamationmark.circle.fill").foregroundStyle(Color.appOrange)
        case nil:
            EmptyView()
        }
    }
}
