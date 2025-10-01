import SwiftUI

struct CheckBoxView: View {
    @Binding var isChecked: Bool

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6).stroke(Color.gray, lineWidth: 2)
                    if isChecked {
                        RoundedRectangle(cornerRadius: 6).fill(Color.checkMint)
                        Image(systemName: "checkmark").foregroundColor(.white).font(.system(size: 12, weight: .bold))
                    }
                }
                .frame(width: 24, height: 24)

                Text("I agree to receive newsletters and product updates from Caplog.")
                    .font(.system(size: 14)).foregroundColor(.gray).multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
    }
}
