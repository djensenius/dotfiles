import Foundation

/// Watches for macOS appearance changes by polling AppleInterfaceStyle.
/// Polls every 2 seconds (negligible CPU) and calls switch-theme.fish on change.

let binDir = (CommandLine.arguments[0] as NSString).deletingLastPathComponent
let scriptPath = (binDir as NSString).appendingPathComponent("switch-theme.fish")

func currentMode() -> String {
    let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
    return (style == "Dark") ? "dark" : "light"
}

func switchTheme(to mode: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    print("\(timestamp) Switching to \(mode)", terminator: "\n")
    fflush(stdout)

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/fish")
    process.arguments = [scriptPath, mode]
    var env = ProcessInfo.processInfo.environment
    env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + (env["PATH"] ?? "")
    process.environment = env

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            print("\(timestamp) \(output)", terminator: "")
            fflush(stdout)
        }
    } catch {
        FileHandle.standardError.write(Data("\(timestamp) Error: \(error)\n".utf8))
    }
}

// Initial switch
var lastMode = currentMode()
switchTheme(to: lastMode)

// Poll every 2 seconds
while true {
    Thread.sleep(forTimeInterval: 2.0)
    // Force UserDefaults to re-read from disk
    UserDefaults.standard.synchronize()
    let mode = currentMode()
    if mode != lastMode {
        switchTheme(to: mode)
        lastMode = mode
    }
}
