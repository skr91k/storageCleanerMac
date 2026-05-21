import Foundation

@MainActor
class FolderScanner: ObservableObject {
    @Published var items: [FolderItem] = []
    @Published var isLoadingList = false
    @Published var isCalculatingSizes = false
    @Published var pathStack: [URL] = [FileManager.default.homeDirectoryForCurrentUser]
    @Published var diskInfo: DiskInfo?

    // Persists across navigations — shows instantly on revisit
    private var sizeCache: [URL: Int64] = [:]
    private var currentScanTask: Task<Void, Never>?

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
        startScan(url)
    }

    func navigateBack() {
        guard canGoBack else { return }
        pathStack.removeLast()
        startScan(currentURL)
    }

    func navigateTo(stackIndex index: Int) {
        guard index < pathStack.count - 1 else { return }
        pathStack = Array(pathStack.prefix(index + 1))
        startScan(currentURL)
    }

    func refresh() {
        // Clear cache for current dir so sizes are recalculated fresh
        items.map(\.url).forEach { sizeCache.removeValue(forKey: $0) }
        startScan(currentURL)
    }

    func delete(_ item: FolderItem) throws {
        try FileManager.default.removeItem(at: item.url)
        items.removeAll { $0.id == item.id }
        sizeCache.removeValue(forKey: item.url)
        loadDiskInfo()
    }

    // MARK: - Private

    private func startScan(_ url: URL) {
        currentScanTask?.cancel()
        currentScanTask = Task { await scan(url) }
    }

    private func scan(_ url: URL) async {
        isLoadingList = true
        isCalculatingSizes = false
        items = []

        // Step 1: list directory entries immediately (no size calc, very fast)
        let entries = await Task.detached(priority: .userInitiated) {
            Self.listDirectory(url)
        }.value

        guard !Task.isCancelled else { isLoadingList = false; return }

        // Step 2: show file list instantly using cached sizes where available
        items = entries.map { entry in
            let cached = sizeCache[entry.url]
            return FolderItem(
                url: entry.url,
                name: entry.name,
                size: cached ?? 0,
                isSizeReady: cached != nil,
                isCachedSize: cached != nil,
                isDirectory: entry.isDirectory
            )
        }.sorted {
            let s0 = sizeCache[$0.url] ?? 0
            let s1 = sizeCache[$1.url] ?? 0
            return s0 != s1 ? s0 > s1 : $0.name.localizedCompare($1.name) == .orderedAscending
        }

        isLoadingList = false
        guard !entries.isEmpty else { return }
        isCalculatingSizes = true

        // Step 3: calculate sizes concurrently in background, update each item as it finishes
        await withTaskGroup(of: (URL, Int64).self) { group in
            for entry in entries {
                group.addTask {
                    let size = Self.calculateSize(entry.url, isDirectory: entry.isDirectory)
                    return (entry.url, size)
                }
            }
            for await (url, size) in group {
                guard !Task.isCancelled else { break }
                sizeCache[url] = size
                if let i = items.firstIndex(where: { $0.url == url }) {
                    items[i].size = size
                    items[i].isSizeReady = true
                    items[i].isCachedSize = false
                }
            }
        }

        guard !Task.isCancelled else { isCalculatingSizes = false; return }

        items.sort { $0.size > $1.size }
        isCalculatingSizes = false
    }

    // MARK: - Static helpers (nonisolated = run off main thread)

    private struct FileEntry {
        let url: URL
        let name: String
        let isDirectory: Bool
    }

    nonisolated private static func listDirectory(_ url: URL) -> [FileEntry] {
        let fm = FileManager.default
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey]
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: []  // show hidden files
        ) else { return [] }

        return contents.compactMap { child in
            guard let v = try? child.resourceValues(forKeys: keys) else { return nil }
            guard v.isSymbolicLink != true else { return nil }
            return FileEntry(url: child, name: child.lastPathComponent, isDirectory: v.isDirectory == true)
        }
    }

    nonisolated private static func calculateSize(_ url: URL, isDirectory: Bool) -> Int64 {
        guard isDirectory else {
            let keys: Set<URLResourceKey> = [.fileSizeKey]
            return Int64((try? url.resourceValues(forKeys: keys).fileSize) ?? 0)
        }
        return totalSize(of: url)
    }

    nonisolated private static func totalSize(of url: URL) -> Int64 {
        let fm = FileManager.default
        let keys: Set<URLResourceKey> = [.fileSizeKey, .isRegularFileKey]
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: []  // include hidden files in size calculation
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let v = try? fileURL.resourceValues(forKeys: keys), v.isRegularFile == true {
                total += Int64(v.fileSize ?? 0)
            }
        }
        return total
    }
}
