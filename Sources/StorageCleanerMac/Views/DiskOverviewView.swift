import SwiftUI

struct DiskOverviewView: View {
    @ObservedObject var scanner: FolderScanner

    var body: some View {
        VStack(spacing: 32) {
            if let disk = scanner.diskInfo {
                diskGauge(disk)
                diskStats(disk)
            } else {
                ProgressView()
            }

            Text("Browse folders to find large files, or use Quick Clean to remove app caches.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Overview")
    }

    private func diskGauge(_ disk: FolderScanner.DiskInfo) -> some View {
        Gauge(value: disk.usedFraction) {
            Text("Used")
        } currentValueLabel: {
            VStack(spacing: 2) {
                Text(ByteCountFormatter.string(fromByteCount: disk.used, countStyle: .file))
                    .font(.title2.bold())
                Text("used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } minimumValueLabel: {
            Text("0")
        } maximumValueLabel: {
            Text(ByteCountFormatter.string(fromByteCount: disk.total, countStyle: .file))
        }
        .gaugeStyle(.accessoryCircular)
        .scaleEffect(2.8)
        .frame(height: 200)
        .tint(disk.usedFraction > 0.85 ? .red : disk.usedFraction > 0.6 ? .orange : .blue)
    }

    private func diskStats(_ disk: FolderScanner.DiskInfo) -> some View {
        HStack(spacing: 48) {
            statItem(
                label: "Used",
                value: ByteCountFormatter.string(fromByteCount: disk.used, countStyle: .file),
                color: .primary
            )
            statItem(
                label: "Free",
                value: ByteCountFormatter.string(fromByteCount: disk.free, countStyle: .file),
                color: .green
            )
            statItem(
                label: "Total",
                value: ByteCountFormatter.string(fromByteCount: disk.total, countStyle: .file),
                color: .secondary
            )
        }
    }

    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
