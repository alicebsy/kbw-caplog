import SwiftUI

// ✅ 프로젝트 통일 색
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
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .lineLimit(1)                 // ✅ 줄바꿈 금지
                .minimumScaleFactor(0.85)     // ✅ 공간 부족 시 살짝 축소
                .fixedSize(horizontal: true, vertical: false) // ✅ 버튼 폭을 고정형으로
                .padding(.horizontal, 12)     // (기존 14 → 12로 조금 더 컴팩트)
                .padding(.vertical, 6)
                .background(.white)
                .overlay(Capsule().stroke(Color(uiColor: .systemGray4), lineWidth: 0.5))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

// ✅ 통합 토글
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
    private var onColor: Color { accentGreen }
    private let offColor = Color.gray.opacity(0.3)
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(configuration.isOn ? onColor : offColor)
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
