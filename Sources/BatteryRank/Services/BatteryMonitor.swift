import Foundation
import IOKit.ps

struct BatteryInfo {
    let levelPercent: Double
    let isCharging: Bool
    let isOnAC: Bool
    let maxCapacitymAh: Double?
}

class BatteryMonitor {
    var onBatteryChange: ((BatteryInfo) -> Void)?

    /// Read current battery info from IOKit (no callback, no runloop, just polling).
    func getCurrentBatteryInfo() -> BatteryInfo? {
        guard let psInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
        guard let psList = IOPSCopyPowerSourcesList(psInfo)?.takeRetainedValue() as? [CFTypeRef] else { return nil }

        for ps in psList {
            // IOPSGetPowerSourceDescription follows Core Foundation "Get" semantics.
            // The returned dictionary is not retained for us, so consuming it with
            // takeRetainedValue() over-releases and can crash the process shortly after launch.
            guard let desc = IOPSGetPowerSourceDescription(psInfo, ps)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            guard let type = desc[kIOPSTypeKey as String] as? String,
                  type == kIOPSInternalBatteryType else { continue }

            let level = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 0
            let state = desc[kIOPSPowerSourceStateKey as String] as? String ?? ""
            let isCharging = desc[kIOPSIsChargingKey as String] as? Bool ?? false
            let isOnAC = state == kIOPSACPowerValue
            let maxCap = desc[kIOPSMaxCapacityKey as String] as? Int

            return BatteryInfo(
                levelPercent: Double(level),
                isCharging: isCharging,
                isOnAC: isOnAC,
                maxCapacitymAh: maxCap.map { Double($0) }
            )
        }

        return nil
    }
}
