import SwiftUI

struct QuickCleanView: View {
    @StateObject private var scanner = QuickCleanScanner()
    @State private var confirmTarget: AppCleanTarget?
    @State private var browseTarget: AppCleanTarget?

    var body: some View {
        VStack(spacing: 0) {
            if scanner.isScanning {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Scanning for cleanable files…")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else if scanner.targets.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(.green)
                    Text("Nothing to clean — you're all good!")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Button("Scan Again") { Task { await scanner.scan() } }
                }
                Spacer()
            } else {
                List(scanner.targets) { target in
                    AppCleanRow(target: target) {
                        browseTarget = target
                    } onClean: {
                        confirmTarget = target
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))

                Divider()
                statusBar
            }
        }
        .navigationTitle("Quick Clean")
        .toolbar {
            ToolbarItem {
                Button { Task { await scanner.scan() } } label: {
                    Label("Scan", systemImage: "magnifyingglass")
                }
                .disabled(scanner.isScanning)
            }
        }
        .sheet(item: $browseTarget) { target in
            AppFileBrowserSheet(target: target) {
                confirmTarget = target
                browseTarget = nil
            }
        }
        .confirmationDialog(
            "Clean App Cache",
            isPresented: Binding(
                get: { confirmTarget != nil },
                set: { if !$0 { confirmTarget = nil } }
            ),
            titleVisibility: .visible,
            presenting: confirmTarget
        ) { target in
            Button("Clean \(target.appName) (\(target.formattedSize))", role: .destructive) {
                try? scanner.clean(target)
                confirmTarget = nil
            }
            Button("Cancel", role: .cancel) { confirmTarget = nil }
        } message: { target in
            Text("Cache and temporary files for \(target.appName) will be removed. The app will rebuild them as needed.")
        }
        .onAppear { Task { await scanner.scan() } }
    }

    private var totalReclaimable: Int64 {
        scanner.targets.reduce(0) { $0 + $1.size }
    }

    private var statusBar: some View {
        HStack {
            Text("\(scanner.targets.count) apps with cleanable data")
                .foregroundStyle(.secondary)
            Spacer()
            Text("Reclaimable: \(ByteCountFormatter.string(fromByteCount: totalReclaimable, countStyle: .file))")
                .foregroundStyle(.orange)
                .fontWeight(.medium)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

// MARK: - Row

private struct AppCleanRow: View {
    let target: AppCleanTarget
    let onBrowse: () -> Void
    let onClean: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: target.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(target.appName)
                    .fontWeight(.medium)
                Text("Cache & temporary files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(target.formattedSize)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.orange)

            Button("Files", action: onBrowse)
                .buttonStyle(.bordered)
                .controlSize(.small)

            Button("Clean", action: onClean)
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - File browser sheet

private struct AppFileBrowserSheet: View {
    let target: AppCleanTarget
    let onClean: () -> Void
    @StateObject private var scanner = FolderScanner()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: target.icon)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(target.appName)
                        .font(.headline)
                    Text("Cache & temporary files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Button("Clean All") {
                    onClean()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()

            Divider()

            FolderBrowserView(scanner: scanner)
        }
        .frame(width: 700, height: 480)
        .onAppear {
            // Navigate to the first existing path for this target
            for rawPath in target.paths {
                let url = URL(fileURLWithPath: rawPath)
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    scanner.pathStack = [url]
                    scanner.refresh()
                    return
                }
            }
        }
    }
}

