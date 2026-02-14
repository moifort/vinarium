import Foundation
import SwiftUI

enum ScanStep {
    case camera
    case scanning
    case review(ScanResult, Data)
    case placing(Wine)
    case confirmed(Wine, String)
}

@MainActor @Observable
final class ScanViewModel {
    var step: ScanStep = .camera
    var error: String?

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
        error = nil

        Task {
            do {
                let wine = try await WineAPI.create(request)
                self.step = .placing(wine)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func reset() {
        step = .camera
        error = nil
    }
}
