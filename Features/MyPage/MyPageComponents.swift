import SwiftUI

struct MyPageSectionHeader: View {
    var title: String
    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Color.myPageSectionGreen)
    }
}

struct LabeledRow<Content: View>: View {
    var label: String
    @ViewBuilder var content: Content
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 90, alignment: .leading)
            content
            Spacer()
        }
    }
}

struct CapsuleButton: View {
    var title: String
    var action: () -> Void
    var tint: Color = .primary
    var fill: Color = .white
    var fullWidth: Bool = false
    var isEnabled: Bool = true
    
    // ✅ 1. 이 두 줄이 추가되어야 합니다.
    var verticalPadding: CGFloat = 8
    var fontSize: CGFloat = 14

    var body: some View {
        Button(action: action) {
            Text(title)
                // ✅ 2. 폰트 크기 파라미터 적용
                .font(.system(size: fontSize, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .foregroundColor(isEnabled ? tint : Color.gray.opacity(0.5))
                .padding(.horizontal, 14)
                // ✅ 3. 세로 높이(패딩) 파라미터 적용
                .padding(.vertical, verticalPadding)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(fill)
                .overlay(Capsule().stroke(Color(uiColor: .systemGray4), lineWidth: 0.5))
                .clipShape(Capsule())
                .opacity(isEnabled ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
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
        }
        .buttonStyle(.plain)
    }
}

struct ToggleRow: View {
    var title: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            Spacer(minLength: 12)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SlimToggleStyle())
        }
        .contentShape(Rectangle())
        .onTapGesture { isOn.toggle() }
    }
}

struct SlimToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(configuration.isOn ? Color.myPageSectionGreen : Color.gray.opacity(0.3))
                    .frame(width: 42, height: 24)
                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.12), radius: 1, x: 0, y: 1)
                    .padding(.horizontal, 3)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: configuration.isOn)
    }
}

extension View {
    func sectionContainer() -> some View {
        self
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
            .padding(.top, 10)
    }
}
