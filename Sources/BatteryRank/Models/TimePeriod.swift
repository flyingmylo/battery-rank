import Foundation

enum TimePeriod: String, CaseIterable {
    case last1h = "1h"
    case last6h = "6h"
    case last12h = "12h"
    case last24h = "24h"
    case custom = "custom"

    var startDate: Date {
        switch self {
        case .last1h:  return Date().addingTimeInterval(-3600)
        case .last6h:  return Date().addingTimeInterval(-6 * 3600)
        case .last12h: return Date().addingTimeInterval(-12 * 3600)
        case .last24h: return Date().addingTimeInterval(-24 * 3600)
        case .custom:  return Date().addingTimeInterval(-3600)
        }
    }

    var displayName: String {
        switch self {
        case .last1h:  return "过去 1 小时"
        case .last6h:  return "过去 6 小时"
        case .last12h: return "过去 12 小时"
        case .last24h: return "过去 24 小时"
        case .custom:  return "自定义"
        }
    }
}
