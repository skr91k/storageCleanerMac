import Foundation

@MainActor
class FolderScanner: ObservableObject {
    @Published var items: [FolderItem] = []
    @Published var isScanning = false
    @Published var pathStack: [URL] = [FileManager.default.homeDirectoryForCurrentUser]
    @Published var diskInfo: DiskInfo?

    struct DiskInfo {
        let total: Int64
        let free: Int64
        var used: Int64 { total - free }
        var usedFraction: Double { total > 0 ? Double(used) / Double(total) : 0 }
    }

    var currentURL: URL { pathStack.last! }
    var canGoBack: Bool { pathStack.count > 1 }

    func loadDiskInfo() {
        let url = URL(fileURLWithPath: "/")
        guard let v = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]) else { return }
        diskInfo = DiskInfo(
            total: Int64(v.volumeTotalCapacity ?? 0),
            free: Int64(v.volumeAvailableCapacityForImportantUsage ?? 0)
        )
    }

    func navigateTo(_ url: URL) {
        pathStack.append(url)
        Task { await scan(url) }
    }

    func navigateBack() {
        guard canGoBack else { return }
        pathStack.removeLast()
        Task { await scan(currentURL) }
    }

    func navigateTo(stackIndex index: Int) {
        guard index < pathStack.count - 1 else { return }
        pathStack = Array(pathStack.prefix(index + 1))
        Task { await scan(currentURL) }
    }

    func refresh() {
        Task { await scan(currentURL) }
    }

    func delete(_ item: FolderItem) throws {
        try FileManager.default.removeItem(at: item.url)
        items.removeAll { $0.id == item.id }
        loadDiskInfo()
    }

    private func scan(_ url: URL) async {
        isScanning = true
        items = []

        let found = await Task.detached(priority: .userInitiated) {
            Self.scanDirectory(url)
        }.value

        items = found.sorted { $0.size > $1.size }
        isScanning = false
    }

    nonisolated private static func scanDirectory(_ url: URL) -> [FolderItem] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents.compactMap { childURL in
            guard let values = try? childURL.resourceValues(
                forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]
            ) else { return nil }

            // skip symlinks to avoid loops
            if values.isSymbolicLink == true { return nil }

            let isDir = values.isDirectory == true
            let size = isDir ? totalSize(of: childURL) : Int64(values.fileSize ?? 0)

            return FolderItem(
                url: childURL,
                name: childURL.lastPathComponent,
                size: size,
                isDirectory: isDir
            )
        }
    }

    nonisolated private static func totalSize(of url: URL) -> Int64 {
        let fm = FileManager.default
        let keys: Set<URLResourceKey> = [.fileSizeKey, .isRegularFileKey]
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let v = try? fileURL.resourceValues(forKeys: keys),
               v.isRegularFile == true {
                total += Int64(v.fileSize ?? 0)
            }
        }
        return total
    }
}
