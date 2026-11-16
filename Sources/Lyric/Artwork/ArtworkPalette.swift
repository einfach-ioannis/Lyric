import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// Derives an accent colour from cover art, lifted so it reads well on black.
nonisolated enum ArtworkPalette {
    @concurrent
    static func accent(from data: Data) async -> Color? {
        guard let image = CIImage(data: data) else { return nil }

        let filter = CIFilter.areaAverage()
        filter.inputImage = image
        filter.extent = image.extent
        guard let output = filter.outputImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        context.render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        let average = NSColor(
            srgbRed: Double(pixel[0]) / 255,
            green: Double(pixel[1]) / 255,
            blue: Double(pixel[2]) / 255,
            alpha: 1
        )
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        average.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

        return Color(
            hue: hue,
            saturation: min(saturation * 1.35, 0.85),
            brightness: max(brightness, 0.78)
        )
    }
}
