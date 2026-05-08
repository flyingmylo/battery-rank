import Foundation

struct AppEnergy {
    let bundleIdentifier: String
    let appName: String
    let processName: String
    let cpuTimeDelta: UInt64
    let cpuPercentage: Double
    let attributedmAh: Double
}

class EnergyAttributor {

    /// Attribute battery drain to individual apps based on CPU time proportion.
    /// - Parameters:
    ///   - current: Current process snapshot
    ///   - previous: Previous process snapshot (nil for first sample)
    ///   - batteryDrainPercent: Battery percentage drop since last sample
    ///   - batteryCapacitymAh: Battery's max capacity in mAh
    /// - Returns: Array of per-app energy attributions
    func attribute(
        current: ProcessSnapshot,
        previous: ProcessSnapshot?,
        batteryDrainPercent: Double,
        batteryCapacitymAh: Double
    ) -> [AppEnergy] {
        guard let previous = previous else { return [] }
        guard batteryDrainPercent > 0 else { return [] }

        let totalDrainmAh = batteryCapacitymAh * batteryDrainPercent / 100.0

        // Build lookup from previous snapshot
        var prevEntries: [Int32: ProcessEntry] = [:]
        for entry in previous.entries {
            prevEntries[entry.pid] = entry
        }

        // Compute per-process deltas first. App-level grouping happens later in DataStore.
        var processDeltas: [ProcessEnergyData] = []
        for entry in current.entries {
            let prevEntry = prevEntries[entry.pid]
            let prevCPUTime = prevEntry?.totalCPUTime ?? 0
            let delta = entry.totalCPUTime > prevCPUTime ? entry.totalCPUTime - prevCPUTime : 0

            guard delta > 0 else { continue }

            processDeltas.append(
                ProcessEnergyData(
                    bundleIdentifier: entry.bundleIdentifier ?? entry.name,
                    appName: entry.displayName ?? entry.name,
                    processName: entry.name,
                    cpuTimeDelta: delta
                )
            )
        }

        guard !processDeltas.isEmpty else { return [] }

        // Calculate total CPU delta
        let totalCPUDelta = processDeltas.reduce(UInt64(0)) { $0 + $1.cpuTimeDelta }
        guard totalCPUDelta > 0 else { return [] }

        // Attribute energy
        let results = processDeltas.map { process -> AppEnergy in
            let cpuPercentage = Double(process.cpuTimeDelta) / Double(totalCPUDelta) * 100.0
            let attributedmAh = Double(process.cpuTimeDelta) / Double(totalCPUDelta) * totalDrainmAh
            return AppEnergy(
                bundleIdentifier: process.bundleIdentifier,
                appName: process.appName,
                processName: process.processName,
                cpuTimeDelta: process.cpuTimeDelta,
                cpuPercentage: cpuPercentage,
                attributedmAh: attributedmAh
            )
        }

        return results.sorted { $0.attributedmAh > $1.attributedmAh }
    }
}

private struct ProcessEnergyData {
    let bundleIdentifier: String
    let appName: String
    let processName: String
    let cpuTimeDelta: UInt64
}
