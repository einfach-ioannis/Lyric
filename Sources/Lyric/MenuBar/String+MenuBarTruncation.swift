import Foundation

extension String {
    /// Shortens text to at most `length` characters, ending in an ellipsis when cut.
    func truncated(to length: Int = Theme.MenuBar.maximumTextLength) -> String {
        guard count > length, length > 1 else { return self }
        let trimmed = prefix(length - 1).trimmingCharacters(in: .whitespaces)
        return "\(trimmed)…"
    }
}
