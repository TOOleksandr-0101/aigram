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

    var mediaDirectory: URL {
        storageDirectory
    }

    func totalCacheSize() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for file in files {
            if let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    func totalCacheSizeString() -> String {
        let size = totalCacheSize()
        let mb = Double(size) / (1024.0 * 1024.0)
        if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        } else {
            let kb = Double(size) / 1024.0
            return String(format: "%.0f KB", kb)
        }
    }

    func clearMediaCache() {
        cache.removeAllObjects()
        if let files = try? fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    func savedImageFiles() -> [String] {
        guard let files = try? fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil) else { return [] }
        return files.compactMap { url -> String? in
            let ext = url.pathExtension.lowercased()
            if ["png", "jpg", "jpeg", "heic", "webp"].contains(ext) {
                return url.lastPathComponent
            }
            return nil
        }
    }

    private init() {
        seedPresetAssetsIfNeeded()
    }

    func fileURL(for filename: String) -> URL {
        storageDirectory.appendingPathComponent(filename)
    }

    func videoURL(for filename: String) -> URL {
        fileURL(for: filename)
    }

    func fileExists(filename: String) -> Bool {
        let url = fileURL(for: filename)
        return fileManager.fileExists(atPath: url.path)
    }

    @discardableResult
    func saveVideo(from sourceURL: URL, filename: String) -> URL? {
        let destination = fileURL(for: filename)
        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: sourceURL, to: destination)
            return destination
        } catch {
            print("[MediaStorageService] Error saving video: \(error)")
            return nil
        }
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

        seedPresetDocumentsIfNeeded()
    }

    private func seedPresetDocumentsIfNeeded() {
        let swiftDoc = """
        // AIGram Native Concurrency Architecture Specification
        // Swift 6 Strict Concurrency & Actor Isolation

        import Foundation
        import SwiftUI

        @globalActor
        actor AIGramCoreActor {
            static let shared = AIGramCoreActor()
        }

        protocol MessageStreamDelegate: Sendable {
            func didStreamChunk(_ token: String) async
            func didCompleteStreaming(totalTokens: Int, latencyMs: Double) async
        }

        final class LLMOrchestrator: @unchecked Sendable {
            private let session = URLSession.shared

            func dispatchAgentDiscussion(prompt: String, agents: [String]) async -> [String: String] {
                // Multi-agent consensus pipeline with turn-taking arbitration
                print("[Orchestrator] Dispatching multi-agent turn sequence for prompt: \\(prompt)")
                return [:]
            }
        }
        """

        let roadmapDoc = """
        # AIGram Product Roadmap (2026 Q3 - Q4)

        ## Core Value Proposition
        AIGram combines the speed and responsiveness of native iOS messaging with an autonomous multi-agent intelligence layer.

        ### Key Milestones
        1. **Milestone 1: Native UX Parity**
           - Floating emoji reactions with tactile feedback
           - Swipe-to-reply gesture with quote attachment preview
           - Pinned message banner with smooth viewport navigation
        2. **Milestone 2: Live Duplex Audio AI Mode**
           - Full-duplex voice streaming with audio decibel visualizer orb
           - Persona-tailored pitch and cadence modulation
        3. **Milestone 3: Autonomous Multi-Agent Brainstorming**
           - @mention autocomplete for direct & group interactions
           - Turn-taking discussion sequencing across AI specialists
        4. **Milestone 4: Local RAG Knowledge Base**
           - File attachment support (.swift, .json, .md, .pdf)
           - In-app syntax-highlighted code & text viewer
           - Context injection into LLM reasoning engine
        """

        let jsonDoc = """
        {
          "project": "AIGram",
          "version": "2.4.0",
          "metrics": {
            "cold_start_ms": 142.5,
            "frame_rate_fps": 120.0,
            "audio_latency_ms": 18.2,
            "memory_footprint_mb": 46.8,
            "llm_time_to_first_token_ms": 285.0,
            "average_tokens_per_second": 84.6
          },
          "status": "Healthy",
          "build_environment": "Release_Swift6"
        }
        """

        let paperDoc = """
        AIGram On-Device & Gateway Neural Inference
        Technical Research Brief

        Abstract:
        We present an optimized hybrid dispatch pipeline for mobile agentic workflows.
        By combining low-latency on-device token estimation with dynamic provider routing
        (OpenRouter, Groq, Ollama), client perceived latency is reduced by up to 64%.
        Key mechanisms include speculative decoding, KV-cache prefix sharing across
        group personas, and streaming audio synthesis via AVSpeechSynthesizer.
        """

        let docs = [
            ("Architecture_Spec.swift", swiftDoc),
            ("Product_Roadmap.md", roadmapDoc),
            ("Telemetry_Metrics.json", jsonDoc),
            ("ML_Inference_Paper.txt", paperDoc)
        ]

        for (filename, content) in docs {
            if !fileExists(filename: filename) {
                _ = saveDocument(text: content, filename: filename)
            }
        }
    }

    @discardableResult
    func saveDocument(data: Data, filename: String) -> URL? {
        let destination = fileURL(for: filename)
        do {
            try data.write(to: destination, options: .atomic)
            return destination
        } catch {
            print("[MediaStorageService] Error saving document: \(error)")
            return nil
        }
    }

    @discardableResult
    func saveDocument(text: String, filename: String) -> URL? {
        guard let data = text.data(using: .utf8) else { return nil }
        return saveDocument(data: data, filename: filename)
    }

    func readDocumentText(filename: String) -> String? {
        let url = fileURL(for: filename)
        if let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) {
            return text
        }
        return nil
    }

    func samplePresetDocuments() -> [(name: String, size: String, ext: String, summary: String)] {
        return [
            ("Architecture_Spec.swift", "1.4 KB", "swift", "Swift 6 strict concurrency actor specification"),
            ("Product_Roadmap.md", "2.1 KB", "md", "AIGram Q3-Q4 features and milestones plan"),
            ("Telemetry_Metrics.json", "890 B", "json", "Real-time latency, fps and tokens telemetry"),
            ("ML_Inference_Paper.txt", "1.8 KB", "txt", "Mobile on-device LLM inference technical brief")
        ]
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
