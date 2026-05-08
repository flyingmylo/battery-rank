import AppKit

struct AppRanking: Identifiable {
    let id: String
    let appName: String
    let subtitle: String?
    let icon: NSImage?
    let totalMilliampHours: Double
    let percentage: Double
}

enum RankingGrouping: String, CaseIterable {
    case byApp = "按 App"
    case byProcess = "按进程"
}
