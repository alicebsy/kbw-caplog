import SwiftUI

struct PermissionRow: View {
    let title: String
    let desc: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.headline)
            Text(desc).font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
            Button(actionTitle, action: action)
                .font(.body.bold())
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color.blue.opacity(0.1)).cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
