import Foundation

struct AppCleanTarget: Identifiable {
    let id = UUID()
    let appName: String
    let icon: String
    let paths: [String]
    var size: Int64 = 0
    var isPresent: Bool = false

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

@MainActor
class QuickCleanScanner: ObservableObject {
    @Published var targets: [AppCleanTarget] = []
    @Published var isScanning = false

    private let home = FileManager.default.homeDirectoryForCurrentUser.path

    func scan() async {
        isScanning = true
        var raw = knownTargets()

        raw = await Task.detached(priority: .userInitiated) {
            raw.map { target in
                var t = target
                let total = target.paths
                    .map { URL(fileURLWithPath: $0) }
                    .filter { FileManager.default.fileExists(atPath: $0.path) }
                    .reduce(Int64(0)) { $0 + Self.directorySize($1) }
                t.size = total
                t.isPresent = total > 0
                return t
            }
        }.value

        targets = raw.filter { $0.isPresent }.sorted { $0.size > $1.size }
        isScanning = false
    }

    func clean(_ target: AppCleanTarget) throws {
        for rawPath in target.paths {
            let url = URL(fileURLWithPath: rawPath)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            // Clear directory contents rather than deleting the folder itself
            if let contents = try? FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: nil
            ) {
                for item in contents {
                    try? FileManager.default.removeItem(at: item)
                }
            }
        }
        targets.removeAll { $0.id == target.id }
    }

    nonisolated private static func directorySize(_ url: URL) -> Int64 {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }

        if !isDir.boolValue {
            let keys: Set<URLResourceKey> = [.fileSizeKey]
            return Int64((try? url.resourceValues(forKeys: keys).fileSize) ?? 0)
        }

        let keys: Set<URLResourceKey> = [.fileSizeKey, .isRegularFileKey]
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let file as URL in enumerator {
            if let v = try? file.resourceValues(forKeys: keys),
               v.isRegularFile == true {
                total += Int64(v.fileSize ?? 0)
            }
        }
        return total
    }

    private func knownTargets() -> [AppCleanTarget] {
        [
            AppCleanTarget(
                appName: "Google Chrome",
                icon: "globe",
                paths: [
                    "\(home)/Library/Caches/Google/Chrome",
                    "\(home)/Library/Application Support/Google/Chrome/Default/Cache",
                    "\(home)/Library/Application Support/Google/Chrome/Default/Code Cache"
                ]
            ),
            AppCleanTarget(
                appName: "Telegram",
                icon: "paperplane.fill",
                paths: [
                    "\(home)/Library/Application Support/Telegram Desktop/tdata/user_data/media_cache",
                    "\(home)/Library/Caches/ru.keepcoder.Telegram",
                    "\(home)/Library/Caches/com.tdesktop.Telegram"
                ]
            ),
            AppCleanTarget(
                appName: "Slack",
                icon: "bubble.left.and.bubble.right.fill",
                paths: [
                    "\(home)/Library/Application Support/Slack/Cache",
                    "\(home)/Library/Application Support/Slack/Code Cache",
                    "\(home)/Library/Caches/com.tinyspeck.slackmacgap"
                ]
            ),
            AppCleanTarget(
                appName: "Spotify",
                icon: "music.note",
                paths: [
                    "\(home)/Library/Application Support/Spotify/PersistentCache",
                    "\(home)/Library/Caches/com.spotify.client"
                ]
            ),
            AppCleanTarget(
                appName: "Discord",
                icon: "gamecontroller.fill",
                paths: [
                    "\(home)/Library/Application Support/discord/Cache",
                    "\(home)/Library/Application Support/discord/Code Cache",
                    "\(home)/Library/Caches/com.hnc.Discord"
                ]
            ),
            AppCleanTarget(
                appName: "WhatsApp",
                icon: "message.fill",
                paths: [
                    "\(home)/Library/Application Support/WhatsApp/Cache",
                    "\(home)/Library/Caches/net.whatsapp.WhatsApp"
                ]
            ),
            AppCleanTarget(
                appName: "Firefox",
                icon: "flame.fill",
                paths: [
                    "\(home)/Library/Caches/Firefox",
                    "\(home)/Library/Application Support/Firefox/Profiles"
                ]
            ),
            AppCleanTarget(
                appName: "Zoom",
                icon: "video.fill",
                paths: [
                    "\(home)/Library/Application Support/zoom.us/data",
                    "\(home)/Library/Caches/us.zoom.xos"
                ]
            ),
            AppCleanTarget(
                appName: "Xcode Derived Data",
                icon: "hammer.fill",
                paths: [
                    "\(home)/Library/Developer/Xcode/DerivedData"
                ]
            ),
            AppCleanTarget(
                appName: "iOS Simulators",
                icon: "iphone",
                paths: [
                    "\(home)/Library/Developer/CoreSimulator/Caches",
                    "\(home)/Library/Developer/CoreSimulator/Devices"
                ]
            ),
            AppCleanTarget(
                appName: "System Logs",
                icon: "doc.text.fill",
                paths: [
                    "\(home)/Library/Logs",
                    "/Library/Logs"
                ]
            ),
            AppCleanTarget(
                appName: "System Caches",
                icon: "memorychip",
                paths: [
                    "\(home)/Library/Caches"
                ]
            ),
        ]
    }
}
