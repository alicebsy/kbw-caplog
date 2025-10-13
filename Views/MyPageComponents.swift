import SwiftUI

private let accentGreen = Color(red: 0.06, green: 0.36, blue: 0)

struct MyPageSectionHeader: View {
    var title: String
    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(accentGreen)
    }
}

struct LabeledRow<Content: View>: View {
    var label: String
    @ViewBuilder var content: Content
    var body: some View {
        HStack(spacing: 12) {
            Text(label).font(.system(size: 15, weight: .semibold))
                .frame(width: 90, alignment: .leading)
            content
            Spacer()
        }
    }
}

struct CapsuleButton: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(.white)
                .overlay(Capsule().stroke(Color(uiColor: .systemGray4), lineWidth: 0.5))
                .clipShape(Capsule())
        }.buttonStyle(.plain)
    }
}

struct RadioButton: View {
    var isOn: Bool
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().stroke(Color.primary, lineWidth: 1).frame(width: 16, height: 16)
                    if isOn { Circle().fill(Color.primary).frame(width: 8, height: 8) }
                }
                Text(title).font(.system(size: 15))
            }
        }.buttonStyle(.plain)
    }
}

struct ToggleRow: View {
    var title: String
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            Text(title).font(.system(size: 15, weight: .semibold))
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden()
        }
    }
}

extension View {
    func sectionContainer() -> some View {
        self
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
            .padding(.horizontal, 20).padding(.top, 10)
    }
}
