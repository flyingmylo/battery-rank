import SwiftUI

@MainActor
class RankingViewModel: ObservableObject {
    @Published var rankings: [AppRanking] = []
    @Published var currentBatteryLevel: Double = 0
    @Published var isOnBatteryPower = false
    @Published var isMonitoring = false
    @Published var grouping: RankingGrouping = .byApp

    private let processMonitor = ProcessMonitor()
    let batteryMonitor = BatteryMonitor()
    private let energyAttributor = EnergyAttributor()
    let dataStore = DataStore()

    private var lastBatteryLevel: Double?
    private var batteryTimer: DispatchSourceTimer?
    private var pendingDrainPercent: Double = 0
    private var retentionDays = Constants.defaultRetentionDays

    init() {}

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        print("[BatteryRank] startMonitoring called")

        // Delay all heavy work 1 second to let popover render first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.beginDeferredMonitoring()
        }
    }

    private func beginDeferredMonitoring() {
        startBatteryPolling()
        processMonitor.start(interval: Constants.defaultPollingInterval) { [weak self] snapshot, previous in
            self?.handleProcessSample(current: snapshot, previous: previous)
        }
        refreshRankings()
    }

    func refreshRankings() {
        let startDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        rankings = dataStore.fetchRankings(from: startDate, grouping: grouping)
    }

    func updateGrouping(_ grouping: RankingGrouping) {
        self.grouping = grouping
        refreshRankings()
    }

    func updatePollingInterval(_ seconds: Int) {
        processMonitor.updateInterval(TimeInterval(seconds))
    }

    func updateRetentionDays(_ days: Int) {
        retentionDays = days
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        dataStore.pruneOldData(olderThan: cutoff)
    }

    func resetData() {
        dataStore.deleteAll()
        rankings = []
    }

    // MARK: - Private handlers

    private func handleBatteryPoll(_ info: BatteryInfo) {
        let oldLevel = lastBatteryLevel ?? currentBatteryLevel
        currentBatteryLevel = info.levelPercent
        isOnBatteryPower = !info.isOnAC

        if !info.isOnAC && oldLevel > info.levelPercent {
            pendingDrainPercent += oldLevel - info.levelPercent
            dataStore.saveBatteryEvent(info)
        }

        lastBatteryLevel = info.levelPercent
    }

    private func handleProcessSample(current: ProcessSnapshot, previous: ProcessSnapshot?) {
        guard let previous = previous else { return }

        let drainPercent = pendingDrainPercent

        guard drainPercent > 0 else { return }

        let batteryInfo = batteryMonitor.getCurrentBatteryInfo()
        let capacitymAh = batteryInfo?.maxCapacitymAh ?? 5000

        let energies = energyAttributor.attribute(
            current: current,
            previous: previous,
            batteryDrainPercent: drainPercent,
            batteryCapacitymAh: capacitymAh
        )

        guard !energies.isEmpty else { return }

        dataStore.saveEnergyReadings(energies, drainPercent: drainPercent, timestamp: current.timestamp)
        pendingDrainPercent = 0
        refreshRankings()
    }

    private func startBatteryPolling() {
        batteryTimer?.cancel()

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "com.batteryrank.battery", qos: .utility))
        timer.schedule(deadline: .now(), repeating: Constants.defaultPollingInterval)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let info = self.batteryMonitor.getCurrentBatteryInfo()
            Task { @MainActor in
                if let info {
                    self.handleBatteryPoll(info)
                }
            }
        }
        batteryTimer = timer
        timer.resume()
    }
}
