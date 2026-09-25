import SwiftUI

/// Branding mark for the login/onboarding screens: the capsule mosaic of
/// `BrandMark`, cascading in with a one-shot entrance animation (no continuous
/// loop).
struct BrandLogo: View {
    var capsuleSize: CGFloat = 34

    @State private var appeared = false

    var body: some View {
        BrandMark(capsuleSize: capsuleSize) { slot in
            BrandCapsule(slot: slot)
                .scaleEffect(appeared ? 1 : 0.3)
                .opacity(appeared ? 1 : 0)
                .animation(
                    .spring(duration: 0.5, bounce: 0.4)
                        .delay(Double(slot.row + slot.column) * 0.06),
                    value: appeared
                )
        }
        .onAppear { appeared = true }
    }
}

#Preview("Logo") {
    BrandLogo()
        .padding(40)
}

#Preview("Dark") {
    BrandLogo()
        .padding(40)
        .preferredColorScheme(.dark)
}
