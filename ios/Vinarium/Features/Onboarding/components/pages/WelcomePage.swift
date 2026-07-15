import SwiftUI

struct WelcomePage: View {
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            BrandLogo()
            VStack(spacing: 12) {
                Text("Bienvenue dans Vinarium")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Configurons votre cave en quelques étapes : votre prénom et les dimensions de votre cave.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            Spacer()
            Button(action: onNext) {
                Text("Commencer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("onboarding-start")
        }
        .padding()
    }
}

#Preview {
    WelcomePage(onNext: {})
}
