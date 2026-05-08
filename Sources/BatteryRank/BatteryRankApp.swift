import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var vm: RankingViewModel!
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    private var lastOpenTime: Date = .distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        vm = RankingViewModel()

        let contentView = PopoverView(vm: vm)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 400)
        popover.behavior = .applicationDefined
        popover.contentViewController = NSHostingController(rootView: contentView)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "BR"
            button.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
            button.action = #selector(togglePopover)
            button.target = self
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.vm.startMonitoring()
        }
    }

    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                closePopover()
            } else {
                guard Date().timeIntervalSince(lastOpenTime) > 0.6 else { return }
                lastOpenTime = Date()

                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
                installEventMonitors()
            }
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    private func installEventMonitors() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return event }

            // Keep the popover open while interacting with it or re-clicking the status item.
            if let eventWindow = event.window,
               eventWindow == self.popover.contentViewController?.view.window || eventWindow == self.statusItem.button?.window {
                return event
            }

            self.closePopover()
            return event
        }
    }
}

@main
struct BatteryRankMain {
    private static var retainedDelegate: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        retainedDelegate = delegate
        app.delegate = delegate
        app.run()
    }
}
