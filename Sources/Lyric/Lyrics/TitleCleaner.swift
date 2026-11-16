import Foundation

/// Strips decorations such as "- Remastered 2011" or "(feat. …)" that rarely appear in lyrics databases.
nonisolated enum TitleCleaner {
    static func clean(_ title: String) -> String {
        var result = title
        if let dash = result.range(of: " - ") {
            result = String(result[..<dash.lowerBound])
        }
        let decoration = /\s*[\(\[](feat\.?|ft\.?|with|from|remaster|live|mono|stereo|deluxe|original|radio edit|version)[^\)\]]*[\)\]]/.ignoresCase()
        result = result.replacing(decoration, with: "")
        return result.trimmingCharacters(in: .whitespaces)
    }
}
