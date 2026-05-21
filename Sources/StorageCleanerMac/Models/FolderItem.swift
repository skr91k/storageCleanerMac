import Foundation

struct FolderItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let isDirectory: Bool

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var icon: String {
        isDirectory ? "folder.fill" : iconForExtension(url.pathExtension)
    }

    static func == (lhs: FolderItem, rhs: FolderItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

private func iconForExtension(_ ext: String) -> String {
    switch ext.lowercased() {
    case "pdf":                          return "doc.richtext"
    case "zip", "gz", "tar", "rar":     return "doc.zipper"
    case "mp4", "mov", "avi", "mkv":    return "film"
    case "mp3", "aac", "flac", "wav":   return "music.note"
    case "jpg", "jpeg", "png", "heic":  return "photo"
    case "dmg", "pkg":                  return "shippingbox"
    default:                             return "doc"
    }
}
