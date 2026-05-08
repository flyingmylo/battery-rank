import Foundation

struct ProcessSnapshot {
    let timestamp: Date
    let entries: [ProcessEntry]
}

struct ProcessEntry {
    let pid: Int32
    let name: String
    let displayName: String?
    let bundleIdentifier: String?
    let totalUserTime: UInt64
    let totalSystemTime: UInt64
    let residentSize: UInt64

    var totalCPUTime: UInt64 {
        totalUserTime + totalSystemTime
    }
}
