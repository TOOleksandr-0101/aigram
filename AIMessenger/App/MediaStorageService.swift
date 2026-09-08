import UIKit

final class MediaStorageService {
    static let shared = MediaStorageService()

    private let fileManager = FileManager.default
    private let cache = NSCache<NSString, UIImage>()

    private var storageDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("AIGramMedia", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private init() {
        seedPresetAssetsIfNeeded()
    }

    func fileURL(for filename: String) -> URL {
        storageDirectory.appendingPathComponent(filename)
    }

    func fileExists(filename: String) -> Bool {
        let url = fileURL(for: filename)
        return fileManager.fileExists(atPath: url.path)
    }

    @discardableResult
    func saveImage(data: Data, filename: String) -> URL? {
        let destination = fileURL(for: filename)
        do {
            try data.write(to: destination, options: .atomic)
            if let image = UIImage(data: data) {
                cache.setObject(image, forKey: filename as NSString)
            }
            return destination
        } catch {
            print("[MediaStorageService] Error saving image: \(error)")
            return nil
        }
    }

    func loadImage(named name: String) -> UIImage? {
        if let cached = cache.object(forKey: name as NSString) {
            return cached
        }

        let url = fileURL(for: name)
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            cache.setObject(image, forKey: name as NSString)
            return image
        }

        // Generate dynamic artwork on demand if it's a known preset or sample
        if let generated = generateArtwork(for: name) {
            if let data = generated.jpegData(compressionQuality: 0.9) {
                _ = saveImage(data: data, filename: name)
            }
            cache.setObject(generated, forKey: name as NSString)
            return generated
        }

        return nil
    }

    func fileSizeString(for filename: String) -> String {
        let url = fileURL(for: filename)
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return "1.2 MB"
        }
        let mb = Double(size) / (1024.0 * 1024.0)
        if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        } else {
            let kb = Double(size) / 1024.0
            return String(format: "%.0f KB", kb)
        }
    }

    // MARK: - Preset Asset Generator
    private func seedPresetAssetsIfNeeded() {
        let presets = [
            "Architecture_V2.png",
            "Wireframe_Screen.png",
            "Design_Tokens.png",
            "app_preview_art",
            "Dashboard_Metrics.png",
            "AI_Cluster_Map.png",
            "Mobile_Mockup.png"
        ]

        for name in presets {
            if !fileExists(filename: name) {
                if let img = generateArtwork(for: name), let data = img.jpegData(compressionQuality: 0.9) {
                    saveImage(data: data, filename: name)
                }
            }
        }
    }

    private func generateArtwork(for title: String) -> UIImage? {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let cg = ctx.cgContext

            let bgColors: [CGColor]
            let accentSymbol: String

            if title.contains("Architecture") {
                bgColors = [UIColor(red: 0.08, green: 0.15, blue: 0.32, alpha: 1.0).cgColor,
                            UIColor(red: 0.15, green: 0.38, blue: 0.72, alpha: 1.0).cgColor]
                accentSymbol = "server.rack"
            } else if title.contains("Wireframe") {
                bgColors = [UIColor(red: 0.20, green: 0.10, blue: 0.38, alpha: 1.0).cgColor,
                            UIColor(red: 0.45, green: 0.25, blue: 0.75, alpha: 1.0).cgColor]
                accentSymbol = "rectangle.split.3x3"
            } else if title.contains("Design") {
                bgColors = [UIColor(red: 0.35, green: 0.08, blue: 0.22, alpha: 1.0).cgColor,
                            UIColor(red: 0.75, green: 0.20, blue: 0.48, alpha: 1.0).cgColor]
                accentSymbol = "paintbrush.pointed.fill"
            } else if title.contains("Dashboard") {
                bgColors = [UIColor(red: 0.05, green: 0.25, blue: 0.20, alpha: 1.0).cgColor,
                            UIColor(red: 0.12, green: 0.60, blue: 0.45, alpha: 1.0).cgColor]
                accentSymbol = "chart.bar.xaxis"
            } else if title.contains("Cluster") {
                bgColors = [UIColor(red: 0.35, green: 0.20, blue: 0.05, alpha: 1.0).cgColor,
                            UIColor(red: 0.85, green: 0.50, blue: 0.15, alpha: 1.0).cgColor]
                accentSymbol = "cpu.fill"
            } else {
                bgColors = [UIColor(red: 0.08, green: 0.25, blue: 0.35, alpha: 1.0).cgColor,
                            UIColor(red: 0.15, green: 0.55, blue: 0.70, alpha: 1.0).cgColor]
                accentSymbol = "photo.artframe"
            }

            // Draw gradient background
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors as CFArray, locations: [0.0, 1.0]) {
                cg.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: size.width, y: size.height), options: [])
            }

            // Draw subtle isometric grid lines
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.12).cgColor)
            cg.setLineWidth(1.5)
            for x in stride(from: 0, to: size.width, by: 40) {
                cg.move(to: CGPoint(x: x, y: 0))
                cg.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: 0, to: size.height, by: 40) {
                cg.move(to: CGPoint(x: 0, y: y))
                cg.addLine(to: CGPoint(x: size.width, y: y))
            }
            cg.strokePath()

            // Draw center card
            let cardRect = CGRect(x: 100, y: 80, width: size.width - 200, height: size.height - 160)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 24)
            UIColor.black.withAlphaComponent(0.35).setFill()
            cardPath.fill()
            UIColor.white.withAlphaComponent(0.2).setStroke()
            cardPath.lineWidth = 2
            cardPath.stroke()

            // Draw SF Symbol icon in center card
            let config = UIImage.SymbolConfiguration(pointSize: 96, weight: .semibold)
            if let symbol = UIImage(systemName: accentSymbol, withConfiguration: config)?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                let symbolRect = CGRect(x: (size.width - 120) / 2, y: 160, width: 120, height: 120)
                symbol.draw(in: symbolRect)
            }

            // Draw Title Text
            let titleFont = UIFont.systemFont(ofSize: 32, weight: .bold)
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white
            ]
            let cleanTitle = title.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: ".png", with: "").replacingOccurrences(of: ".jpg", with: "")
            let titleSize = cleanTitle.size(withAttributes: titleAttrs)
            let titleRect = CGRect(x: (size.width - titleSize.width) / 2, y: 320, width: titleSize.width, height: titleSize.height)
            cleanTitle.draw(in: titleRect, withAttributes: titleAttrs)

            // Draw subtitle watermark
            let subFont = UIFont.systemFont(ofSize: 18, weight: .medium)
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: subFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ]
            let subText = "AIGram High Definition Visual Asset"
            let subSize = subText.size(withAttributes: subAttrs)
            let subRect = CGRect(x: (size.width - subSize.width) / 2, y: 370, width: subSize.width, height: subSize.height)
            subText.draw(in: subRect, withAttributes: subAttrs)
        }
    }
}
