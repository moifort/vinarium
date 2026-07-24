import SwiftUI

struct WineAgingSection: View {
    let drinkFrom: Int?
    let drinkUntil: Int?

    var body: some View {
        if drinkFrom != nil || drinkUntil != nil {
            Section("Garde") {
                if let from = drinkFrom {
                    LabeledInfoRow(title: "\u{00C0} partir de", value: "\(from)", icon: "hourglass.bottomhalf.filled")
                }
                if let until = drinkUntil {
                    LabeledInfoRow(title: "Jusqu'\u{00E0}", value: "\(until)", icon: "hourglass.tophalf.filled")
                    if until <= Calendar.current.component(.year, from: Date()) + 1 {
                        Label {
                            Text("À déguster rapidement")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                                .fontWeight(.medium)
                        } icon: {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    List {
        WineAgingSection(drinkFrom: 2025, drinkUntil: 2027)
    }
}
