import Foundation
import SwiftUI

enum ScanStep {
    case camera
    case scanning
    case review(ScanResult, Data)
    case placing(id: String, name: String, color: WineColor, vintage: Int?)
    case confirmed(name: String, color: WineColor, position: String)
    case favoriteSaved
    case shortlistSaved
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
                self.error = reportError(error)
                self.step = .camera
            }
        }
    }

    func saveWine(_ request: CreateWineRequest) async {
        guard !isSaving else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let wine = try await WineAPI.create(request)
            step = .placing(id: wine.id, name: wine.name, color: wine.color, vintage: wine.vintage)
        } catch {
            self.error = reportError(error)
        }
    }

    func saveAsFavorite(_ request: CreateWineRequest, consumedDate: Date, contacts: [String], tastingNotes: String?) async {
        guard !isSaving else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            var enrichedRequest = request
            let formatter = ISO8601DateFormatter()
            enrichedRequest.consumedDate = formatter.string(from: consumedDate)
            enrichedRequest.contacts = contacts.isEmpty ? nil : contacts
            enrichedRequest.tastingNotes = tastingNotes
            _ = try await WineAPI.create(enrichedRequest)
            step = .favoriteSaved
        } catch {
            self.error = reportError(error)
        }
    }

    func saveAsShortlist(_ request: CreateWineRequest, consumedDate: Date, rating: Int?, contacts: [String], tastingNotes: String?) async {
        guard !isSaving else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            var enrichedRequest = request
            let formatter = ISO8601DateFormatter()
            enrichedRequest.consumedDate = formatter.string(from: consumedDate)
            enrichedRequest.contacts = contacts.isEmpty ? nil : contacts
            enrichedRequest.tastingNotes = tastingNotes
            enrichedRequest.rating = rating
            enrichedRequest.shortlist = true
            _ = try await WineAPI.create(enrichedRequest)
            step = .shortlistSaved
        } catch {
            self.error = reportError(error)
        }
    }

    func saveAsRecommendation(_ request: CreateWineRequest, recommenderName: String?, comment: String?) async {
        guard !isSaving else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let wine = try await WineAPI.create(request)
            try await RecommendationAPI.create(wineId: wine.id, recommenderName: recommenderName, comment: comment)
            step = .recommendationSaved
        } catch {
            self.error = reportError(error)
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
        case (.camera, .camera), (.scanning, .scanning), (.favoriteSaved, .favoriteSaved), (.shortlistSaved, .shortlistSaved), (.recommendationSaved, .recommendationSaved): return true
        case (.review, .review), (.placing, .placing), (.confirmed, .confirmed): return true
        default: return false
        }
    }
}
