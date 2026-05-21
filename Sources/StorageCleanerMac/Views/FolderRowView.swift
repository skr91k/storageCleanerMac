import SwiftUI

struct FolderRowView: View {
    let item: FolderItem
    let totalSize: Int64

    private var fraction: Double {
        guard totalSize > 0, item.isSizeReady else { return 0 }
        return min(Double(item.size) / Double(totalSize), 1.0)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .foregroundStyle(item.isDirectory ? .blue : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.quaternary)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(barColor)
                            .frame(width: geo.size.width * fraction)
                            .animation(.easeOut(duration: 0.3), value: fraction)
                    }
                }
                .frame(height: 4)
            }

            Spacer()

            sizeLabel
                .frame(width: 90, alignment: .trailing)

            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var sizeLabel: some View {
        if !item.isSizeReady {
            // No cache — show spinner
            ProgressView()
                .scaleEffect(0.55)
                .frame(width: 16, height: 16)
        } else if item.isCachedSize {
            // Cached value, recalculating in background
            HStack(spacing: 4) {
                Text(item.formattedSize)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                ProgressView()
                    .scaleEffect(0.45)
                    .frame(width: 12, height: 12)
            }
        } else {
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.formattedSize)
                    .font(.subheadline.monospacedDigit())
                Text(String(format: "%.1f%%", fraction * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var barColor: Color {
        switch fraction {
        case 0..<0.3:   return .green
        case 0.3..<0.6: return .yellow
        default:        return .red
        }
    }
}
