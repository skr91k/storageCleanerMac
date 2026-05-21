import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case overview   = "Overview"
    case browser    = "Browse Files"
    case quickClean = "Quick Clean"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview:   return "gauge.medium"
        case .browser:    return "folder.fill"
        case .quickClean: return "sparkles"
        }
    }
}

struct ContentView: View {
    @StateObject private var folderScanner = FolderScanner()
    @State private var selection: SidebarItem = .overview

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationTitle("Storage Cleaner")
        } detail: {
            switch selection {
            case .overview:
                DiskOverviewView(scanner: folderScanner)
            case .browser:
                FolderBrowserView(scanner: folderScanner)
                    .navigationTitle("Browse Files")
            case .quickClean:
                QuickCleanView()
            }
        }
        .onAppear {
            folderScanner.loadDiskInfo()
            folderScanner.refresh()
        }
    }
}
