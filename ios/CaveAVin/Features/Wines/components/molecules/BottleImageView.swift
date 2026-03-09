import SwiftUI

struct BottleImageView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 300)
    }
}

#Preview {
    BottleImageView(image: UIImage(systemName: "wineglass")!)
}
