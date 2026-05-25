import SwiftUI
import CoreData

struct IssueTemplate: Identifiable {
    let id = UUID()
    let category: String
    let description: String
    let suggestedPriority: IssuePriority

    static let all: [IssueTemplate] = [
        .init(category: "المحرك",    description: "تسريب زيت المحرك",              suggestedPriority: .critical),
        .init(category: "المحرك",    description: "صوت طرق داخل المحرك",           suggestedPriority: .critical),
        .init(category: "المحرك",    description: "ارتفاع درجة حرارة المحرك",      suggestedPriority: .critical),
        .init(category: "المحرك",    description: "استهلاك زيت زائد",              suggestedPriority: .medium),
        .init(category: "المحرك",    description: "دخان من العادم",                suggestedPriority: .medium),
        .init(category: "الفرامل",   description: "تيل الفرامل منتهي",             suggestedPriority: .critical),
        .init(category: "الفرامل",   description: "صوت صفير عند الفرملة",          suggestedPriority: .medium),
        .init(category: "الفرامل",   description: "الدسك محتاج تغيير",             suggestedPriority: .medium),
        .init(category: "الفرامل",   description: "الكاليبر مسدود",               suggestedPriority: .critical),
        .init(category: "التعليق",   description: "المساعد الأمامي تالف",          suggestedPriority: .medium),
        .init(category: "التعليق",   description: "صوت طقطقة في التعليق",          suggestedPriority: .medium),
        .init(category: "التعليق",   description: "الكرة السفلية تالفة",           suggestedPriority: .critical),
        .init(category: "التعليق",   description: "بوكي المقص تالف",              suggestedPriority: .low),
        .init(category: "الدركسيون", description: "صعوبة في الدوران",              suggestedPriority: .medium),
        .init(category: "الدركسيون", description: "السيارة تشد ناحية",             suggestedPriority: .medium),
        .init(category: "الدركسيون", description: "طرف الدركسيون رخو",             suggestedPriority: .critical),
        .init(category: "الكهرباء",  description: "البطارية ضعيفة",               suggestedPriority: .medium),
        .init(category: "الكهرباء",  description: "الدينامو لا يشحن",             suggestedPriority: .critical),
        .init(category: "الكهرباء",  description: "مشكلة في إضاءة السيارة",       suggestedPriority: .low),
        .init(category: "التكييف",   description: "المكيف لا يبرد بكفاءة",        suggestedPriority: .low),
        .init(category: "التكييف",   description: "صوت في كومبروسير المكيف",       suggestedPriority: .medium),
        .init(category: "الإطارات",  description: "الإطار يحتاج تغيير",            suggestedPriority: .medium),
        .init(category: "الإطارات",  description: "اهتزاز عند السرعة العالية",     suggestedPriority: .medium),
        .init(category: "أخرى",      description: "رائحة وقود داخل السيارة",       suggestedPriority: .critical),
        .init(category: "أخرى",      description: "تسريب في نظام التبريد",         suggestedPriority: .critical),
        .init(category: "أخرى",      description: "ضعف عام في أداء المحرك",        suggestedPriority: .medium),
    ]
}

struct InspectionIssuesView: View {
    @ObservedObject var car: Car
    @Environment(\.managedObjectContext) private var context
    @State private var showAddIssue  = false
    @State private var showTemplates = false
    @State private var filterStatus  = "الكل"

    let statusFilters = ["الكل", "معلقة", "شغّال عليها", "خلصت"]

    var filteredIssues: [InspectionIssue] {
        car.issuesArray
            .filter { filterStatus == "الكل" || $0.status == filterStatus }
            .sorted {
                let order = ["حرجة": 0, "متوسطة": 1, "منخفضة": 2]
                return (order[$0.priority ?? ""] ?? 3) < (order[$1.priority ?? ""] ?? 3)
            }
    }

    var criticalCount: Int { car.issuesArray.filter { $0.priority == IssuePriority.critical.rawValue && $0.status != IssueStatus.resolved.rawValue }.count }
    var pendingCount:  Int { car.issuesArray.filter { $0.status == IssueStatus.pending.rawValue }.count }
    var resolvedCount: Int { car.issuesArray.filter { $0.status == IssueStatus.resolved.rawValue }.count }

    var body: some View {
        VStack(spacing: 0) {
            if !car.issuesArray.isEmpty {
                HStack(spacing: 0) {
                    issueStatChip(count: criticalCount,         label: "حرجة",  color: .appRed)
                    Spacer()
                    issueStatChip(count: pendingCount,          label: "معلقة", color: .appOrange)
                    Spacer()
                    issueStatChip(count: resolvedCount,         label: "خلصت",  color: .appGreen)
                    Spacer()
                    issueStatChip(count: car.issuesArray.count, label: "الكل",  color: .appAccent)
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(Color.appCard)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(statusFilters, id: \.self) { f in
                        AppChipButton(label: f, isSelected: filterStatus == f) { filterStatus = f }
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
            }
            .background(Color.appBG)

            if filteredIssues.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredIssues, id: \.objectID) { issue in
                        IssueRow(issue: issue)
                            .listRowInsets(EdgeInsets(top: 5, leading: 18, bottom: 5, trailing: 18))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { offsets in
                        for i in offsets { context.delete(filteredIssues[i]) }
                        PersistenceController.shared.save()
                    }
                }
                .listStyle(.plain).scrollContentBackground(.hidden).background(Color.appBG)
            }
        }
        .background(Color.appBG)
        .navigationTitle("مشاكل الفحص")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddIssue = true } label: {
                    Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button { showTemplates = true } label: {
                    Label("شائعة", systemImage: "list.bullet.clipboard")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.appAccent)
                }
            }
        }
        .sheet(isPresented: $showAddIssue)  { AddIssueView(car: car) }
        .sheet(isPresented: $showTemplates) { TemplateIssuesSheet(car: car) }
    }

    func issueStatChip(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(count)").font(.system(size: 18, weight: .bold))
                .foregroundStyle(count > 0 ? color : Color(.systemGray4))
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(minWidth: 52)
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Color.appGreen.opacity(0.08)).frame(width: 100, height: 100)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 42, weight: .light)).foregroundStyle(Color.appGreen)
            }
            VStack(spacing: 8) {
                Text(filterStatus == "الكل" ? "لا توجد مشاكل" : "لا توجد مشاكل بهذه الحالة")
                    .font(.system(size: 20, weight: .bold))
                if filterStatus == "الكل" {
                    Text("اضغط + لتسجيل أي مشكلة تلاحظها")
                        .font(.system(size: 15)).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity).background(Color.appBG)
    }
}

struct IssueRow: View {
    @ObservedObject var issue: InspectionIssue

    var priorityColor: Color {
        switch issue.priorityEnum {
        case .critical: return Color.appRed
        case .medium:   return Color.appOrange
        case .low:      return Color.appAccent
        }
    }
    var statusColor: Color {
        switch issue.statusEnum {
        case .pending:    return Color.appOrange
        case .inProgress: return Color.appAccent
        case .resolved:   return Color.appGreen
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3).fill(priorityColor).frame(width: 4)
            VStack(alignment: .trailing, spacing: 10) {
                HStack {
                    Menu {
                        ForEach(IssueStatus.allCases, id: \.rawValue) { s in
                            Button(s.rawValue) {
                                issue.status = s.rawValue
                                PersistenceController.shared.save()
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Circle().fill(statusColor).frame(width: 7, height: 7)
                            Text(issue.statusEnum.rawValue)
                                .font(.system(size: 12, weight: .semibold)).foregroundStyle(statusColor)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(statusColor.opacity(0.08)).clipShape(Capsule())
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: issue.priorityEnum.icon).font(.system(size: 10))
                        Text(issue.priorityEnum.rawValue).font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(priorityColor)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(priorityColor.opacity(0.08)).clipShape(Capsule())
                }
                Text(issue.issueDescription ?? "")
                    .font(.system(size: 15, weight: .medium))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                if let notes = issue.notes, !notes.isEmpty {
                    Text(notes).font(.system(size: 12)).foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing).frame(maxWidth: .infinity, alignment: .trailing)
                }
                Text((issue.dateAdded ?? Date()).formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11)).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct AddIssueView: View {
    let car: Car
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var description   = ""
    @State private var priority      = IssuePriority.medium
    @State private var notes         = ""
    @State private var showTemplates = false
    @FocusState private var descFocused: Bool

    var canSave: Bool { !description.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    VStack(alignment: .trailing, spacing: 10) {
                        Text("وصف المشكلة").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        ZStack(alignment: .topTrailing) {
                            if description.isEmpty {
                                Text("مثال: فجأة ظهر صوت في الذراع الخلفي...")
                                    .foregroundStyle(Color(.placeholderText)).font(.system(size: 14))
                                    .padding(.top, 12).padding(.trailing, 12).allowsHitTesting(false)
                            }
                            TextEditor(text: $description).focused($descFocused)
                                .multilineTextAlignment(.trailing).frame(minHeight: 110).padding(8)
                        }
                        .padding(6).background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(.systemGray4), lineWidth: 0.7))
                        Button { showTemplates = true } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "list.bullet.clipboard")
                                Text("اختر من مشاكل شائعة")
                            }
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.appAccent)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(16).appCard()

                    VStack(alignment: .trailing, spacing: 12) {
                        Text("الأولوية").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        HStack(spacing: 10) {
                            ForEach(IssuePriority.allCases, id: \.rawValue) { p in
                                let sel = priority == p
                                let c   = priorityColor(p)
                                Button { priority = p } label: {
                                    VStack(spacing: 5) {
                                        Image(systemName: p.icon).font(.system(size: 18)).foregroundStyle(sel ? .white : c)
                                        Text(p.rawValue).font(.system(size: 12, weight: .bold)).foregroundStyle(sel ? .white : .primary)
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                                    .background(sel ? c : Color.appBG)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(sel ? c : Color(.systemGray4), lineWidth: sel ? 0 : 0.7))
                                }
                                .animation(.spring(response: 0.25), value: priority)
                            }
                        }
                    }
                    .padding(16).appCard()

                    VStack(alignment: .trailing, spacing: 10) {
                        Text("ملاحظات (اختياري)").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        TextEditor(text: $notes).multilineTextAlignment(.trailing).frame(minHeight: 70)
                            .padding(8).background(Color.appBG).clipShape(RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(.systemGray4), lineWidth: 0.7))
                    }
                    .padding(16).appCard()
                }
                .padding(18)
            }
            .background(Color.appBG)
            .navigationTitle("مشكلة جديدة").navigationBarTitleDisplayMode(.inline)
            .onAppear { descFocused = true }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("إلغاء") { dismiss() }.foregroundStyle(.secondary) }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("حفظ") { saveIssue() }.bold().disabled(!canSave)
                }
            }
            .sheet(isPresented: $showTemplates) {
                TemplatePickerSheet { selected in description = selected }
            }
        }
    }

    func priorityColor(_ p: IssuePriority) -> Color {
        switch p { case .critical: return .appRed; case .medium: return .appOrange; case .low: return .appAccent }
    }

    func saveIssue() {
        let issue = InspectionIssue(context: context)
        issue.id               = UUID()
        issue.issueDescription = description.trimmingCharacters(in: .whitespaces)
        issue.priority         = priority.rawValue
        issue.status           = IssueStatus.pending.rawValue
        issue.dateAdded        = Date()
        issue.notes            = notes.isEmpty ? nil : notes
        issue.car              = car
        PersistenceController.shared.save()
        dismiss()
    }
}

struct TemplatePickerSheet: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var grouped: [(String, [IssueTemplate])] {
        Dictionary(grouping: IssueTemplate.all, by: \.category)
            .map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { category, items in
                    Section(category) {
                        ForEach(items) { t in
                            Button { onSelect(t.description); dismiss() } label: {
                                HStack(spacing: 10) {
                                    let c = pColor(t.suggestedPriority)
                                    Circle().fill(c).frame(width: 8, height: 8)
                                    Text(t.description).font(.system(size: 14)).foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    Text(t.suggestedPriority.rawValue).font(.system(size: 11, weight: .bold)).foregroundStyle(c)
                                        .padding(.horizontal, 7).padding(.vertical, 3)
                                        .background(c.opacity(0.08)).clipShape(Capsule())
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("اختر مشكلة شائعة").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("إلغاء") { dismiss() } } }
        }
    }

    func pColor(_ p: IssuePriority) -> Color {
        switch p { case .critical: return .appRed; case .medium: return .appOrange; case .low: return .appAccent }
    }
}

struct TemplateIssuesSheet: View {
    let car: Car
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIDs: Set<UUID> = []

    var grouped: [(String, [IssueTemplate])] {
        Dictionary(grouping: IssueTemplate.all, by: \.category)
            .map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { category, items in
                    Section(category) {
                        ForEach(items) { t in
                            Button {
                                if selectedIDs.contains(t.id) { selectedIDs.remove(t.id) }
                                else { selectedIDs.insert(t.id) }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().stroke(selectedIDs.contains(t.id) ? Color.appAccent : Color(.systemGray4), lineWidth: 1.5)
                                            .frame(width: 22, height: 22)
                                        if selectedIDs.contains(t.id) {
                                            Circle().fill(Color.appAccent).frame(width: 22, height: 22)
                                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                                        }
                                    }
                                    Text(t.description).font(.system(size: 14)).foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("قائمة المشاكل الشائعة").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("إلغاء") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("إضافة (\(selectedIDs.count))") { addSelected() }
                        .bold().disabled(selectedIDs.isEmpty)
                }
            }
        }
    }

    func addSelected() {
        IssueTemplate.all.filter { selectedIDs.contains($0.id) }.forEach { t in
            let issue = InspectionIssue(context: context)
            issue.id = UUID(); issue.issueDescription = t.description
            issue.priority = t.suggestedPriority.rawValue
            issue.status = IssueStatus.pending.rawValue
            issue.dateAdded = Date(); issue.car = car
        }
        PersistenceController.shared.save(); dismiss()
    }
}
