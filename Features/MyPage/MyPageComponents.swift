import SwiftUI

// MARK: - 섹션 헤더 (타이포·여백 통일)
struct MyPageSectionHeader: View {
    var title: String
    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.primary)
            .padding(.bottom, 2)
    }
}

/// 아이콘 + 라벨 + 콘텐츠 행 (가입정보·설정 등 리스트형)
struct MyPageLabeledRow<Content: View>: View {
    var icon: String?
    var label: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 14) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.myPageSectionGreen)
                    .frame(width: 24, alignment: .center)
            }
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: icon != nil ? nil : 80, alignment: .leading)
            content
            Spacer(minLength: 8)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

struct LabeledRow<Content: View>: View {
    var label: String
    @ViewBuilder var content: Content
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
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
    var verticalPadding: CGFloat = 8
    var fontSize: CGFloat = 14
    /// true면 액센트 블루 배경 (저장 등 주요 액션)
    var isPrimary: Bool = false

    private var effectiveFill: Color {
        if isPrimary && isEnabled { return Color.myPageActionBlue }
        return fill
    }
    private var effectiveTint: Color {
        if isPrimary && isEnabled { return .white }
        return tint
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: fontSize, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .foregroundColor(isEnabled ? effectiveTint : Color.gray.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, verticalPadding)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(effectiveFill)
                .overlay(Capsule().stroke(isPrimary ? Color.clear : Color(uiColor: .systemGray4), lineWidth: 0.5))
                .clipShape(Capsule())
                .opacity(isEnabled ? 1 : 0.6)
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
                    Circle()
                        .stroke(isOn ? Color.myPageSectionGreen : Color(uiColor: .systemGray3), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isOn {
                        Circle()
                            .fill(Color.myPageSectionGreen)
                            .frame(width: 10, height: 10)
                    }
                }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

/// 세그먼트형 선택 (성별 등)
struct MyPageSegmentedChoice: View {
    var options: [(id: String, title: String)]
    var selection: String?
    var action: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(options, id: \.id) { item in
                Button {
                    action(item.id)
                } label: {
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selection == item.id ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == item.id ? Color.myPageSectionGreen : Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
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
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
    }
}

/// 섹션 내 구분선 (리스트 행 사이)
struct MyPageRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(uiColor: .separator).opacity(0.4))
            .frame(height: 1)
    }
}
