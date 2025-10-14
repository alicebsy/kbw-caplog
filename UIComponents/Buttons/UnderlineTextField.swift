import SwiftUI

struct UnderlineTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isSecure {
                SecureField("", text: $text,
                            prompt: Text(placeholder).foregroundColor(Color.registerPlaceholder))
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .autocorrectionDisabled()
            } else {
                TextField("", text: $text,
                          prompt: Text(placeholder).foregroundColor(Color.registerPlaceholder))
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .autocorrectionDisabled()
            }
            Divider().background(Color.divider)
        }
    }
}
