import Foundation
import SwiftUI

enum ScanStep {
    case camera
    case scanning
    case review(ScanResult, Data)
    case placing(Wine)
    case confirmed(Wine, String)
    case favoriteSaved
    case recommendationSaved
}

@MainActor @Observable
final class ScanViewModel {
    var step: ScanStep = .camera
    var error: String?
    var isSaving = false

    func capturePhoto(_ imageData: Data) {
        step = .scanning
        error = nil

        Task {
            do {
                let result = try await WineAPI.scan(imageData: imageData)
                self.step = .review(result, imageData)
            } catch {
                self.error = error.localizedDescription
                self.step = .camera
            }
        }
    }

    func saveWine(_ request: CreateWineRequest) {
        guard !isSaving else { return }
        isSaving = true
        error = nil

        Task {
            do {
                let wine = try await WineAPI.create(request)
                self.step = .placing(wine)
            } catch {
                self.error = error.localizedDescription
            }
            self.isSaving = false
        }
    }

    func saveAsFavorite(_ request: CreateWineRequest) {
        guard !isSaving else { return }
        isSaving = true
        error = nil

        Task {
            do {
                _ = try await WineAPI.create(request)
                self.step = .favoriteSaved
            } catch {
                self.error = error.localizedDescription
            }
            self.isSaving = false
        }
    }

    func saveAsRecommendation(_ request: CreateWineRequest, recommenderName: String?, comment: String?) {
        guard !isSaving else { return }
        isSaving = true
        error = nil

        Task {
            do {
                let wine = try await WineAPI.create(request)
                try await RecommendationAPI.create(wineId: wine.id, recommenderName: recommenderName, comment: comment)
                self.step = .recommendationSaved
            } catch {
                self.error = error.localizedDescription
            }
            self.isSaving = false
        }
    }

    func reset() {
        step = .camera
        error = nil
    }
}

extension ScanStep: Equatable {
    static func == (lhs: ScanStep, rhs: ScanStep) -> Bool {
        switch (lhs, rhs) {
        case (.camera, .camera), (.scanning, .scanning), (.favoriteSaved, .favoriteSaved), (.recommendationSaved, .recommendationSaved): return true
        case (.review, .review), (.placing, .placing), (.confirmed, .confirmed): return true
        default: return false
        }
    }
}
