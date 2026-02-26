import Foundation

/// Watches for macOS appearance changes and triggers theme switching.
/// Listens to AppleInterfaceThemeChangedNotification via DistributedNotificationCenter.

class ThemeWatcher {
    let scriptPath: String

    init() {
        // Resolve the switch-theme.fish script path relative to this binary
        let binDir = (CommandLine.arguments[0] as NSString).deletingLastPathComponent
        scriptPath = (binDir as NSString).appendingPathComponent("switch-theme.fish")

        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(themeChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }

    func currentMode() -> String {
        let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        return (style == "Dark") ? "dark" : "light"
    }

    @objc func themeChanged(notification: Notification) {
        let mode = currentMode()
        switchTheme(to: mode)
    }

    func switchTheme(to mode: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/fish")
        process.arguments = [scriptPath, mode]
        process.environment = ProcessInfo.processInfo.environment
        try? process.run()
        process.waitUntilExit()
    }

    func run() {
        // Apply current theme on startup
        switchTheme(to: currentMode())
        // Block and wait for notifications
        RunLoop.main.run()
    }
}

let watcher = ThemeWatcher()
watcher.run()
