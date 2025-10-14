import SwiftUI

struct MyPageProfileSection: View {
    typealias Gender = MyPageViewModel.Gender
    @Binding var gender: Gender
    @Binding var birthday: Date?
    @State private var showPicker = false

    // 공용 폰트 (성별 / 생년월일 텍스트 통일)
    private let profileFieldFont = Font.system(size: 16, weight: .regular)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "프로필")

            // 성별 선택
            LabeledRow(label: "성별") {
                HStack(spacing: 24) {
                    RadioButton(isOn: gender == .male, title: "남성") { gender = .male }
                    RadioButton(isOn: gender == .female, title: "여성") { gender = .female }
                }
            }

            // 생년월일 선택
            LabeledRow(label: "생년월일") {
                HStack(spacing: 10) {
                    Text(birthday.map { DateFormatter.display.string(from: $0) } ?? "미설정")
                        .font(profileFieldFont) // ✅ 글씨 크기 통일
                    Spacer()
                    CapsuleButton(title: "날짜 선택하기") { showPicker = true }
                }
            }
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
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()
}
