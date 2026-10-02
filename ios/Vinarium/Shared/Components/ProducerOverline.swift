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

/// The top of a wine row: the producer above the name, tight against it, and the
/// trailing marks (rating, position) sharing the first line only, so the lines below
/// run under them at full width.
struct WineRowHeading<Name: View, Marks: View>: View {
    let producer: String?
    let name: Name
    let marks: Marks

    init(producer: String?, @ViewBuilder name: () -> Name, @ViewBuilder marks: () -> Marks) {
        self.producer = producer
        self.name = name()
        self.marks = marks()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if let producer {
                    ProducerOverline(producer: producer)
                } else {
                    name
                }
                Spacer(minLength: 0)
                // Above a name, height-neutral: a mark taller than the overline
                // overflows it, centered, instead of pushing the name further down.
                // Its own height stays ideal, or the position badge would shrink its
                // text. Without a producer the line is the name and keeps the mark's
                // height, so the mark never reaches the member tag below.
                HStack { marks }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: producer == nil ? nil : 0)
            }
            .alignmentGuide(.firstLine) { $0[VerticalAlignment.center] }
            if producer != nil {
                name
            }
        }
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
