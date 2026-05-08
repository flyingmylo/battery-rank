import Foundation

// Lightweight JSON-file based persistence (SwiftData macros don't work with SPM CLI builds)

struct EnergyRecord: Codable {
    let bundleIdentifier: String
    let appName: String
    let processName: String
    let timestamp: Date
    let cpuTimeNanoseconds: Int64
    let cpuPercentage: Double
    let attributedMilliampHours: Double
    let batteryDrainPercent: Double

    init(
        bundleIdentifier: String,
        appName: String,
        processName: String,
        timestamp: Date,
        cpuTimeNanoseconds: Int64,
        cpuPercentage: Double,
        attributedMilliampHours: Double,
        batteryDrainPercent: Double
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.processName = processName
        self.timestamp = timestamp
        self.cpuTimeNanoseconds = cpuTimeNanoseconds
        self.cpuPercentage = cpuPercentage
        self.attributedMilliampHours = attributedMilliampHours
        self.batteryDrainPercent = batteryDrainPercent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        appName = try container.decode(String.self, forKey: .appName)
        processName = try container.decodeIfPresent(String.self, forKey: .processName) ?? appName
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        cpuTimeNanoseconds = try container.decode(Int64.self, forKey: .cpuTimeNanoseconds)
        cpuPercentage = try container.decode(Double.self, forKey: .cpuPercentage)
        attributedMilliampHours = try container.decode(Double.self, forKey: .attributedMilliampHours)
        batteryDrainPercent = try container.decode(Double.self, forKey: .batteryDrainPercent)
    }
}

struct BatteryRecord: Codable {
    let timestamp: Date
    let levelPercent: Double
    let isCharging: Bool
    let isOnBattery: Bool
}

@MainActor
class DataStore {
    private let fileManager = FileManager.default
    private let energyURL: URL
    private let batteryURL: URL

    private var energyRecords: [EnergyRecord] = []
    private var batteryRecords: [BatteryRecord] = []

    init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("BatteryRank", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        energyURL = dir.appendingPathComponent("energy.json")
        batteryURL = dir.appendingPathComponent("battery.json")
        load()
    }

    // MARK: - Write

    func saveEnergyReadings(_ energies: [AppEnergy], drainPercent: Double, timestamp: Date) {
        for energy in energies {
            let record = EnergyRecord(
                bundleIdentifier: energy.bundleIdentifier,
                appName: energy.appName,
                processName: energy.processName,
                timestamp: timestamp,
                cpuTimeNanoseconds: Int64(energy.cpuTimeDelta),
                cpuPercentage: energy.cpuPercentage,
                attributedMilliampHours: energy.attributedmAh,
                batteryDrainPercent: drainPercent
            )
            energyRecords.append(record)
        }
        save()
    }

    func saveBatteryEvent(_ info: BatteryInfo) {
        let record = BatteryRecord(
            timestamp: Date(),
            levelPercent: info.levelPercent,
            isCharging: info.isCharging,
            isOnBattery: !info.isOnAC
        )
        batteryRecords.append(record)
        save()
    }

    // MARK: - Read

    func fetchRankings(from startDate: Date, grouping: RankingGrouping) -> [AppRanking] {
        let filtered = energyRecords.filter { $0.timestamp >= startDate }
        guard !filtered.isEmpty else { return [] }

        let aggregated = aggregateRecords(filtered, grouping: grouping)

        let totalmAh = aggregated.values.reduce(0.0) { $0 + $1.totalmAh }
        guard totalmAh > 0 else { return [] }

        let iconCache = ProcessInfoHelper.shared

        return aggregated
            .sorted { $0.value.totalmAh > $1.value.totalmAh }
            .map { _, data in
                AppRanking(
                    id: data.id,
                    appName: data.appName,
                    subtitle: data.subtitle,
                    icon: iconCache.getIcon(bundleIdentifier: data.bundleIdentifier, appName: data.appName),
                    totalMilliampHours: data.totalmAh,
                    percentage: data.totalmAh / totalmAh * 100
                )
            }
    }

    // MARK: - Maintenance

    func pruneOldData(olderThan date: Date) {
        energyRecords.removeAll { $0.timestamp < date }
        batteryRecords.removeAll { $0.timestamp < date }
        save()
    }

    func deleteAll() {
        energyRecords.removeAll()
        batteryRecords.removeAll()
        save()
    }

    // MARK: - Private

    private func load() {
        if let data = try? Data(contentsOf: energyURL),
           let decoded = try? JSONDecoder().decode([EnergyRecord].self, from: data) {
            energyRecords = decoded
        }
        if let data = try? Data(contentsOf: batteryURL),
           let decoded = try? JSONDecoder().decode([BatteryRecord].self, from: data) {
            batteryRecords = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(energyRecords) {
            try? data.write(to: energyURL, options: .atomic)
        }
        if let data = try? JSONEncoder().encode(batteryRecords) {
            try? data.write(to: batteryURL, options: .atomic)
        }
    }

    private func aggregateRecords(_ records: [EnergyRecord], grouping: RankingGrouping) -> [String: AggregatedData] {
        var aggregated: [String: AggregatedData] = [:]

        for record in records {
            let key: String
            let subtitle: String?

            switch grouping {
            case .byApp:
                key = record.bundleIdentifier
                subtitle = nil
            case .byProcess:
                key = "\(record.bundleIdentifier)::\(record.processName)"
                subtitle = record.bundleIdentifier
            }

            if var existing = aggregated[key] {
                existing.totalmAh += record.attributedMilliampHours
                existing.appName = record.appName
                aggregated[key] = existing
            } else {
                aggregated[key] = AggregatedData(
                    id: key,
                    appName: grouping == .byApp ? record.appName : record.processName,
                    subtitle: subtitle,
                    bundleIdentifier: record.bundleIdentifier,
                    totalmAh: record.attributedMilliampHours
                )
            }
        }

        return aggregated
    }
}

private struct AggregatedData {
    let id: String
    var appName: String
    let subtitle: String?
    let bundleIdentifier: String
    var totalmAh: Double
}
