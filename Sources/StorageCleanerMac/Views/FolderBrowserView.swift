import SwiftUI

struct FolderBrowserView: View {
    @ObservedObject var scanner: FolderScanner
    @State private var selectedItem: FolderItem?
    @State private var confirmDelete: FolderItem?

    private var totalSize: Int64 {
        scanner.items.reduce(0) { $0 + $1.size }
    }

    var body: some View {
        VStack(spacing: 0) {
            BreadcrumbView(pathStack: scanner.pathStack) { index in
                scanner.navigateTo(stackIndex: index)
            }

            Divider()

            if scanner.isScanning {
                Spacer()
                ProgressView("Scanning…")
                    .progressViewStyle(.circular)
                Spacer()
            } else if scanner.items.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("This folder is empty or inaccessible.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List(scanner.items, selection: $selectedItem) { item in
                    FolderRowView(item: item, totalSize: totalSize)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if item.isDirectory {
                                scanner.navigateTo(item.url)
                            } else {
                                selectedItem = item
                            }
                        }
                        .contextMenu {
                            Button("Show in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([item.url])
                            }
                            Divider()
                            Button("Delete…", role: .destructive) {
                                confirmDelete = item
                            }
                        }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            Divider()

            statusBar
        }
        .confirmationDialog(
            "Delete File",
            isPresented: Binding(
                get: { confirmDelete != nil },
                set: { if !$0 { confirmDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: confirmDelete
        ) { item in
            Button("Delete \"\(item.name)\"", role: .destructive) {
                try? scanner.delete(item)
                confirmDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmDelete = nil }
        } message: { item in
            Text("Permanently removes \(item.formattedSize).")
        }
    }

    private var statusBar: some View {
        HStack {
            Text("\(scanner.items.count) items")
                .foregroundStyle(.secondary)
            Spacer()
            if totalSize > 0 {
                Text("Total: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
                    .foregroundStyle(.secondary)
            }
            Button {
                scanner.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}
