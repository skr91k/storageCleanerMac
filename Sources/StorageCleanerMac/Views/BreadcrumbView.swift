import SwiftUI

struct BreadcrumbView: View {
    let pathStack: [URL]
    let onTap: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(pathStack.enumerated()), id: \.offset) { index, url in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Button {
                        onTap(index)
                    } label: {
                        Text(index == 0 ? "Home" : url.lastPathComponent)
                            .font(.subheadline)
                            .foregroundStyle(index == pathStack.count - 1 ? .primary : .secondary)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                    .disabled(index == pathStack.count - 1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }
}
