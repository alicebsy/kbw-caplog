import SwiftUI

struct MyPageProfileSection: View {
    typealias Gender = MyPageViewModel.Gender
    @Binding var gender: Gender
    @Binding var birthday: Date?
    @State private var showPicker = false

    private let profileFieldFont = Font.system(size: 16, weight: .regular)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "프로필")

            LabeledRow(label: "성별") {
                HStack(spacing: 24) {
                    RadioButton(isOn: gender == .male,   title: "남성") { gender = .male }
                    RadioButton(isOn: gender == .female, title: "여성") { gender = .female }
                }
            }

            HStack(spacing: 12) {
                Text("생년월일")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 90, alignment: .leading)

                Text(birthday.map { DateFormatter.display.string(from: $0) } ?? "미설정")
                    .font(profileFieldFont)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1)

                Spacer(minLength: 8)

                CapsuleButton(
                    title: "날짜 선택하기",
                    action: { showPicker = true },
                    tint: .primary,
                    fill: .white
                )
            }
            .animation(.none, value: birthday)
        }
        .sectionContainer()
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "",
                        selection: Binding<Date>(
                            get: { birthday ?? Date() },
                            set: { birthday = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                }
                .navigationTitle("생년월일")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("완료") { showPicker = false }
                    }
                }
            }
        }
    }
}

private extension DateFormatter {
    static let display: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd."
        return f
    }()
}
