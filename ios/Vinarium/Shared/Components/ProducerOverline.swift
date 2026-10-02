import SwiftUI

/// The producer set above a wine's name in every list that shows wines: the wine
/// list, the search, the cellar and the journal. A fixed size, deliberately outside
/// Dynamic Type.
struct ProducerOverline: View {
    let producer: String

    var body: some View {
        Text(producer)
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    /// The producer to set above `name`, nil when the name already carries it, case
    /// and accents aside: a "Château Margaux" made by Château Margaux needs no overline.
    static func text(for producer: String?, name: String) -> String? {
        guard let producer = producer?.trimmingCharacters(in: .whitespacesAndNewlines),
              !producer.isEmpty else { return nil }
        return name.localizedStandardContains(producer) ? nil : producer
    }
}

extension VerticalAlignment {
    private enum FirstLine: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }

    /// The middle of a row's first line, where its leading badge or icon sits.
    static let firstLine = VerticalAlignment(FirstLine.self)
}

#Preview {
    VStack(alignment: .leading, spacing: 2) {
        ProducerOverline(producer: "Domaine Leflaive")
        Text("Les Pucelles")
            .font(.headline)
    }
    .padding()
}
