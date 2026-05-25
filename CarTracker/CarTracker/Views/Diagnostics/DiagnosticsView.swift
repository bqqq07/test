import SwiftUI

struct DiagnosisResult {
    let cause: String
    let likelihood: String
    let advice: String
    let isUrgent: Bool
}

struct DiagnosticsView: View {
    @State private var selectedSound:  String? = nil
    @State private var selectedSource: String? = nil
    @State private var selectedTiming: String? = nil
    @State private var showResults = false

    let sounds  = ["طقطقة", "صفير", "دندنة", "خشخشة", "أزيز", "طرق", "نقر"]
    let sources = ["محرك", "فرامل", "تعليق", "دركسيون", "عادم", "إطارات", "جيربوكس", "أخرى"]
    let timings = ["عند الإقلاع", "عند الفرملة", "على السرعة", "عند الدوران", "دائماً", "عند التسخين"]

    var canDiagnose: Bool { selectedSound != nil && selectedSource != nil && selectedTiming != nil }
    var results: [DiagnosisResult] {
        diagnose(sound: selectedSound ?? "", source: selectedSource ?? "", timing: selectedTiming ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        progressBar
                        SelectionCard(title: "نوع الصوت",  icon: "waveform",      items: sounds,  selected: $selectedSound)
                        SelectionCard(title: "مصدر الصوت", icon: "location.fill", items: sources, selected: $selectedSource)
                        SelectionCard(title: "متى يحدث",   icon: "clock.fill",    items: timings, selected: $selectedTiming)
                        if canDiagnose {
                            Button {
                                withAnimation(.spring(response: 0.35)) { showResults = true }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "stethoscope").font(.system(size: 16))
                                    Text("تشخيص الآن").font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.appAccent.opacity(0.30), radius: 12, x: 0, y: 5)
                            }
                            .padding(.horizontal, 18)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        if showResults && canDiagnose {
                            resultsSection.transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.top, 8).padding(.bottom, 36)
                    .animation(.spring(response: 0.3), value: canDiagnose)
                }
            }
            .navigationTitle("تشخيص الأصوات")
            .toolbar {
                if selectedSound != nil || selectedSource != nil || selectedTiming != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("مسح") {
                            withAnimation(.spring(response: 0.28)) {
                                selectedSound = nil; selectedSource = nil
                                selectedTiming = nil; showResults = false
                            }
                        }
                        .foregroundStyle(Color.appRed)
                    }
                }
            }
        }
    }

    var progressBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { i in
                let filled = (i == 0 && selectedSound != nil) || (i == 1 && selectedSource != nil) || (i == 2 && selectedTiming != nil)
                let labels = ["الصوت", "المصدر", "الوقت"]
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().fill(filled ? Color.appAccent : Color(.systemGray5)).frame(width: 30, height: 30)
                            if filled {
                                Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                            } else {
                                Text("\(i + 1)").font(.system(size: 12, weight: .bold)).foregroundStyle(Color(.systemGray3))
                            }
                        }
                        Text(labels[i]).font(.system(size: 10)).foregroundStyle(filled ? Color.appAccent : .secondary)
                    }
                    if i < 2 {
                        Rectangle()
                            .fill(i == 0 && selectedSound != nil ? Color.appAccent : Color(.systemGray5))
                            .frame(maxWidth: .infinity).frame(height: 2)
                    }
                }
            }
        }
        .padding(.horizontal, 40).padding(.vertical, 16).appCard().padding(.horizontal, 18)
    }

    var resultsSection: some View {
        VStack(alignment: .trailing, spacing: 14) {
            VStack(alignment: .trailing, spacing: 4) {
                HStack { Spacer(); Text("نتائج التشخيص").font(.system(size: 18, weight: .bold)) }
                HStack(spacing: 6) {
                    Spacer()
                    ForEach([(selectedSound, "waveform"), (selectedSource, "location.fill"), (selectedTiming, "clock.fill")], id: \.0) { item, icon in
                        if let val = item {
                            Label(val, systemImage: icon).font(.system(size: 11)).foregroundStyle(.secondary)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color(.systemGray6)).clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            if results.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "questionmark.circle").font(.system(size: 42)).foregroundStyle(Color(.systemGray3))
                    Text("لم يتم التعرف على هذا النمط").font(.system(size: 15, weight: .bold))
                    Text("يُنصح بمراجعة ورشة متخصصة").font(.system(size: 14)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).padding(32).appCard().padding(.horizontal, 18)
            } else {
                ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                    DiagnosisCard(result: result, rank: index + 1).padding(.horizontal, 18)
                }
            }
        }
    }
}

struct SelectionCard: View {
    let title: String; let icon: String; let items: [String]
    @Binding var selected: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 14) {
            HStack(spacing: 10) {
                Spacer()
                Text(title).font(.system(size: 16, weight: .semibold))
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(Color.appAccent.opacity(0.12)).frame(width: 34, height: 34)
                    Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.appAccent)
                }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 8)], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    let isSel = selected == item
                    Button {
                        withAnimation(.spring(response: 0.22)) { selected = selected == item ? nil : item }
                    } label: {
                        Text(item)
                            .font(.system(size: 14, weight: isSel ? .semibold : .regular))
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .background(isSel
                                ? LinearGradient(colors: [Color.appAccent, Color.appAccent2], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color(.systemGray6), Color(.systemGray6)], startPoint: .top, endPoint: .bottom))
                            .foregroundStyle(isSel ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: isSel ? Color.appAccent.opacity(0.28) : .clear, radius: 6, x: 0, y: 3)
                            .scaleEffect(isSel ? 1.03 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.22), value: selected)
                }
            }
        }
        .padding(18).appCard().padding(.horizontal, 18)
    }
}

struct DiagnosisCard: View {
    let result: DiagnosisResult; let rank: Int
    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack(spacing: 8) {
                if result.isUrgent {
                    HStack(spacing: 5) {
                        Circle().fill(Color.appRed).frame(width: 7, height: 7)
                        Text("عاجل").font(.system(size: 11, weight: .bold)).foregroundStyle(Color.appRed)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Color.appRed.opacity(0.08)).clipShape(Capsule())
                }
                Spacer()
                HStack(spacing: 6) {
                    Text(result.likelihood).font(.system(size: 12)).foregroundStyle(.secondary)
                    ZStack {
                        Circle().fill(Color.appAccent).frame(width: 26, height: 26)
                        Text("\(rank)").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    }
                }
            }
            Text(result.cause).font(.system(size: 16, weight: .bold)).frame(maxWidth: .infinity, alignment: .trailing)
            HStack(spacing: 8) {
                Spacer()
                Text(result.advice).font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color.appAccent.opacity(0.10)).frame(width: 34, height: 34)
                    Image(systemName: "lightbulb.fill").font(.system(size: 13)).foregroundStyle(Color.appAccent)
                }
            }
        }
        .padding(18)
        .background(result.isUrgent ? Color.appRed.opacity(0.03) : Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: result.isUrgent ? Color.appRed.opacity(0.10) : Color.black.opacity(0.055), radius: 14, x: 0, y: 5)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(result.isUrgent ? Color.appRed.opacity(0.15) : Color.clear, lineWidth: 1))
    }
}

func diagnose(sound: String, source: String, timing: String) -> [DiagnosisResult] {
    var results: [DiagnosisResult] = []
    switch (sound, source, timing) {
    case ("طقطقة", "تعليق", "عند الدوران"):
        results = [
            .init(cause: "الجلب الخارجي (CV Joint)", likelihood: "الأكثر شيوعاً", advice: "فحص الكاوتش الخارجي — إذا كان ممزقاً غيّر الجلب فوراً", isUrgent: true),
            .init(cause: "رأس المساعد (Strut Mount)", likelihood: "شائع", advice: "اضغط على غطاء المحرك — إذا صدر صوت فرأس المساعد هو السبب", isUrgent: false),
            .init(cause: "شفرة الاتزان (Sway Bar Link)", likelihood: "محتمل", advice: "فحص بصري سهل — تكلفة تغيير منخفضة", isUrgent: false)
        ]
    case ("طقطقة", "تعليق", "على السرعة"):
        results = [
            .init(cause: "مساعد (Shock Absorber) تالف", likelihood: "الأكثر شيوعاً", advice: "المساعد التالف خطير على السرعة", isUrgent: true),
            .init(cause: "بوكي مقص (Control Arm Bushing)", likelihood: "شائع", advice: "فحص في الورشة — يحتاج رفع السيارة", isUrgent: false),
            .init(cause: "زنبرك مكسور", likelihood: "محتمل", advice: "خطير جداً — افحص فوراً", isUrgent: true)
        ]
    case ("طقطقة", "تعليق", "عند الإقلاع"):
        results = [
            .init(cause: "بوكيات ساعد المحرك", likelihood: "الأكثر شيوعاً", advice: "شائع في السيارات القديمة", isUrgent: false),
            .init(cause: "الكرة السفلية (Lower Ball Joint)", likelihood: "شائع", advice: "خطير — فحص فوري إلزامي", isUrgent: true)
        ]
    case ("طقطقة", "محرك", "عند الإقلاع"):
        results = [
            .init(cause: "الصبابات تحتاج ضبط (Valve Clearance)", likelihood: "الأكثر شيوعاً", advice: "ضبط الصبابات عند 60,000 كم", isUrgent: false),
            .init(cause: "ضغط الزيت منخفض", likelihood: "شائع", advice: "تحقق من مستوى الزيت فوراً", isUrgent: true)
        ]
    case ("طقطقة", "محرك", "دائماً"):
        results = [
            .init(cause: "زيت المحرك منخفض أو قديم", likelihood: "الأكثر شيوعاً", advice: "افحص مستوى الزيت فوراً", isUrgent: true),
            .init(cause: "الصبابات (Valves)", likelihood: "شائع", advice: "ضبط الصبابات", isUrgent: false)
        ]
    case ("صفير", "فرامل", "عند الفرملة"):
        results = [
            .init(cause: "تيل الفرامل منتهي (Brake Pads)", likelihood: "الأكثر شيوعاً", advice: "غيّر التيل فوراً", isUrgent: true),
            .init(cause: "الدسك (Rotor) محتاج تغيير", likelihood: "شائع", advice: "تحقق من سماكة الدسك", isUrgent: true),
            .init(cause: "رطوبة على الدسك (صباحاً)", likelihood: "محتمل", advice: "إذا اختفى بعد كبسة أو اثنتين فلا مشكلة", isUrgent: false)
        ]
    case ("صفير", "فرامل", "دائماً"):
        results = [
            .init(cause: "الكاليبر مسدود (Stuck Caliper)", likelihood: "الأكثر شيوعاً", advice: "العجلة تسخن؟ الكاليبر مسدود — خطير", isUrgent: true),
            .init(cause: "تيل الفرامل تالف تماماً", likelihood: "شائع", advice: "لا تسوق — غيّر التيل فوراً", isUrgent: true)
        ]
    case ("دندنة", "إطارات", "على السرعة"):
        results = [
            .init(cause: "محمل العجلة (Wheel Bearing)", likelihood: "الأكثر شيوعاً", advice: "الدندنة تزيد بالسرعة = محمل — غيّره قبل أن يكسر", isUrgent: true),
            .init(cause: "الإطار غير متوازن (Imbalanced)", likelihood: "شائع", advice: "ضبط الجنوط (Balancing) — رخيص وسريع", isUrgent: false)
        ]
    case ("طقطقة", "دركسيون", "عند الدوران"):
        results = [
            .init(cause: "طرف الدركسيون (Tie Rod End)", likelihood: "الأكثر شيوعاً", advice: "إذا كان رخواً غيّره فوراً", isUrgent: true),
            .init(cause: "الجلب الخارجي (CV Joint)", likelihood: "شائع", advice: "الطقطقة مع الدوران = جلب خارجي في الغالب", isUrgent: true)
        ]
    case ("صفير", "دركسيون", "عند الدوران"):
        results = [
            .init(cause: "سائل الدركسيون منخفض", likelihood: "الأكثر شيوعاً", advice: "افحص سائل الدركسيون وأضف إذا ناقص", isUrgent: true),
            .init(cause: "مضخة الدركسيون (Power Steering Pump)", likelihood: "شائع", advice: "صفير مستمر مع الدوران = مضخة تالفة", isUrgent: true)
        ]
    case ("دندنة", "محرك", "دائماً"):
        results = [
            .init(cause: "بكرة متحركة أو سير الملحقات", likelihood: "الأكثر شيوعاً", advice: "افحص الأسيار (Belts) وبكراتها", isUrgent: false),
            .init(cause: "الكومبروسر (AC Compressor)", likelihood: "شائع", advice: "أوقف التكييف — هل اختفى الصوت؟", isUrgent: false)
        ]
    case ("خشخشة", "عادم", "دائماً"):
        results = [
            .init(cause: "الكتم (Muffler) مرتخي أو مثقوب", likelihood: "الأكثر شيوعاً", advice: "فحص بصري من الأسفل", isUrgent: false),
            .init(cause: "واشر العادم محروق", likelihood: "شائع", advice: "رائحة عادم قوية داخل السيارة؟ واشر محروق", isUrgent: true)
        ]
    case ("طرق", "محرك", "دائماً"):
        results = [
            .init(cause: "ياطات الكرنك (Main Bearings)", likelihood: "الأكثر شيوعاً", advice: "صوت طرق عميق = خطير جداً — أوقف السيارة فوراً", isUrgent: true),
            .init(cause: "زيت المحرك منتهٍ تماماً", likelihood: "شائع", advice: "تحقق من الزيت الآن", isUrgent: true)
        ]
    case ("نقر", "محرك", "على السرعة"):
        results = [
            .init(cause: "الوقود (Detonation/Knocking)", likelihood: "الأكثر شيوعاً", advice: "استخدم أوكتين أعلى", isUrgent: true),
            .init(cause: "حساس الدق (Knock Sensor) تالف", likelihood: "محتمل", advice: "فحص بجهاز OBD2", isUrgent: false)
        ]
    case ("صفير", "محرك", "عند الإقلاع"):
        results = [
            .init(cause: "سير محرك (Belt) يزلق", likelihood: "الأكثر شيوعاً", advice: "السير قديم أو مرتخي — افحصه وشد أو غيّر", isUrgent: false),
            .init(cause: "سير الدينامو (Alternator Belt)", likelihood: "شائع", advice: "لمبة البطارية؟ الدينامو لا يشحن — راجع السير", isUrgent: true)
        ]
    case (_, "جيربوكس", _):
        results = [
            .init(cause: "سائل الجيربوكس ATF منخفض أو قديم", likelihood: "الأكثر شيوعاً", advice: "افحص مستوى ATF وغيّره عند 40,000 كم", isUrgent: true),
            .init(cause: "الجيربوكس الأوتوماتيك يحتاج صيانة", likelihood: "شائع", advice: "لا تؤخر صيانة الجيربوكس", isUrgent: true)
        ]
    default: break
    }
    return results
}
