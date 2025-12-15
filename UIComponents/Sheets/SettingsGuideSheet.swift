import SwiftUI

struct SettingsGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let message: String
    let pathHint: String
    var onOpenSettings: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Capsule().frame(width: 40, height: 5).foregroundColor(.secondary.opacity(0.4))
                .padding(.top, 8)

            Text(title).font(.system(size: 22, weight: .bold))
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("이동 경로").font(.footnote).foregroundStyle(.secondary)
                Text(pathHint).font(.footnote)
            }
            .padding(.top, 4)

            Spacer(minLength: 12)

            Button {
                onOpenSettings()
                dismiss()
            } label: {
                Text("설정 열기")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
            }

            Button("취소") {
                onCancel()
                dismiss()
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(20)
    }
}
