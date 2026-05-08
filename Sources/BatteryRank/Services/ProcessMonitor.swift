import Foundation
import CLibProc
import AppKit

class ProcessMonitor {
    private let queue = DispatchQueue(label: "com.batteryrank.processmonitor", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var interval: TimeInterval = Constants.defaultPollingInterval
    private var lastSnapshot: ProcessSnapshot?
    private var onSample: ((ProcessSnapshot, ProcessSnapshot?) -> Void)?

    func start(
        interval: TimeInterval = Constants.defaultPollingInterval,
        onSample: @escaping (ProcessSnapshot, ProcessSnapshot?) -> Void
    ) {
        self.interval = interval
        self.onSample = onSample
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now() + .seconds(5), repeating: interval)
        timer?.setEventHandler { [weak self] in
            self?.sample()
        }
        timer?.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func updateInterval(_ newInterval: TimeInterval) {
        stop()
        start(interval: newInterval) { [weak self] snapshot, prev in
            self?.onSample?(snapshot, prev)
        }
    }

    private func sample() {
        let pids = getAllPIDs()
        var entries: [ProcessEntry] = []

        for pid in pids {
            if let entry = getInfo(for: pid) {
                entries.append(entry)
            }
        }

        let snapshot = ProcessSnapshot(timestamp: Date(), entries: entries)
        let prev = lastSnapshot
        lastSnapshot = snapshot

        guard let callback = onSample else { return }
        DispatchQueue.main.async {
            callback(snapshot, prev)
        }
    }

    private func getAllPIDs() -> [Int32] {
        let bufferSize: Int32 = 4096
        var pids = [Int32](repeating: 0, count: Int(bufferSize / 4))
        let count = proc_listallpids(&pids, bufferSize)
        guard count > 0 else { return [] }
        let numPids = Int(count) / MemoryLayout<Int32>.size
        return Array(pids.prefix(numPids)).filter { $0 != 0 }
    }

    private func getInfo(for pid: Int32) -> ProcessEntry? {
        var info = proc_taskallinfo()
        let size = Int32(MemoryLayout<proc_taskallinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDTASKALLINFO, 0, &info, size)
        guard result > 0 else { return nil }

        let cpuTime = info.ptinfo.pti_total_user + info.ptinfo.pti_total_system
        guard cpuTime > 0 else { return nil }

        let name = withUnsafePointer(to: info.pbsd.pbi_comm) {
            $0.withMemoryRebound(to: CChar.self, capacity: 16) {
                String(cString: $0)
            }
        }

        let runningApp = NSRunningApplication(processIdentifier: pid)
        let displayName = runningApp?.localizedName
        let bundleID = runningApp?.bundleIdentifier

        guard displayName != nil || bundleID != nil || !name.isEmpty else { return nil }

        return ProcessEntry(
            pid: pid,
            name: name,
            displayName: displayName,
            bundleIdentifier: bundleID,
            totalUserTime: info.ptinfo.pti_total_user,
            totalSystemTime: info.ptinfo.pti_total_system,
            residentSize: info.ptinfo.pti_resident_size
        )
    }
}
