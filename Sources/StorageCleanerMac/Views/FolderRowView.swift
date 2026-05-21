import SwiftUI

struct FolderRowView: View {
    let item: FolderItem
    let totalSize: Int64

    private var fraction: Double {
        guard totalSize > 0 else { return 0 }
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
                    }
                }
                .frame(height: 4)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.formattedSize)
                    .font(.subheadline.monospacedDigit())
                Text(String(format: "%.1f%%", fraction * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, alignment: .trailing)

            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var barColor: Color {
        switch fraction {
        case 0..<0.3:  return .green
        case 0.3..<0.6: return .yellow
        default:        return .red
        }
    }
}
