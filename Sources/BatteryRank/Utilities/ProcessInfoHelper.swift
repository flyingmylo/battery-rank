import AppKit
import Foundation

class ProcessInfoHelper {
    static let shared = ProcessInfoHelper()

    private var iconCache: [String: NSImage] = [:]

    func getIcon(for appName: String) -> NSImage? {
        if let cached = iconCache[appName] {
            return cached
        }

        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.localizedName == appName {
                if let icon = app.icon {
                    let resized = NSImage(size: NSSize(width: 32, height: 32))
                    resized.lockFocus()
                    icon.draw(in: NSRect(x: 0, y: 0, width: 32, height: 32))
                    resized.unlockFocus()
                    iconCache[appName] = resized
                    return resized
                }
            }
        }

        return nil
    }

    func getIcon(forBundleIdentifier bundleID: String) -> NSImage? {
        if let cached = iconCache[bundleID] {
            return cached
        }

        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.bundleIdentifier == bundleID {
                if let icon = app.icon {
                    let resized = NSImage(size: NSSize(width: 32, height: 32))
                    resized.lockFocus()
                    icon.draw(in: NSRect(x: 0, y: 0, width: 32, height: 32))
                    resized.unlockFocus()
                    iconCache[bundleID] = resized
                    return resized
                }
            }
        }

        return nil
    }

    func getIcon(bundleIdentifier: String?, appName: String) -> NSImage? {
        if let bundleIdentifier,
           let icon = getIcon(forBundleIdentifier: bundleIdentifier) {
            return icon
        }

        return getIcon(for: appName)
    }
}
