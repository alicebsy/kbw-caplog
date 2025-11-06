import SwiftUI

struct MyPageProfileSection: View {
    typealias Gender = MyPageViewModel.Gender
    @Binding var gender: Gender
    @Binding var birthday: Date?
    @State private var showPicker = false
    var onSave: () -> Void
    var isSaveEnabled: Bool = true
    
    // ✅ 🔥 추가: 원래 값 추적
    @State private var originalGender: Gender = .male
    @State private var originalBirthday: Date? = nil

    private let profileFieldFont = Font.system(size: 16, weight: .regular)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "프로필")

            HStack(spacing: 12) {
                Text("성별")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 90, alignment: .leading)

                HStack(spacing: 24) {
                    RadioButton(isOn: gender == .male,   title: "남성") {
                        print("✅ 남성 선택됨")
                        gender = .male
                    }
                    RadioButton(isOn: gender == .female, title: "여성") {
                        print("✅ 여성 선택됨")
                        gender = .female
                    }
                }

                Spacer(minLength: 8)

                CapsuleButton(
                    title: "저장",
                    action: {
                        print("✅ 프로필 저장 버튼 클릭됨")
                        print("✅ 현재 성별: \(gender.rawValue)")
                        print("✅ 현재 생일: \(birthday?.description ?? "없음")")
                        onSave()
                        // ✅ 🔥 저장 후 원래 값 업데이트
                        originalGender = gender
                        originalBirthday = birthday
                    },
                    tint: .primary,
                    fill: .white,
                    fullWidth: false,
                    // ✅ 🔥 수정: 항상 활성화
                    isEnabled: true
                )
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
        .onAppear {
            // ✅ 🔥 추가: 초기값 저장
            originalGender = gender
            originalBirthday = birthday
        }
        .onChange(of: gender) { oldValue, newValue in
            print("✅ 성별 변경됨: \(oldValue.rawValue) -> \(newValue.rawValue)")
        }
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") {
                            showPicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("완료") {
                            print("✅ 생년월일 선택 완료: \(birthday?.description ?? "없음")")
                            showPicker = false
                        }
                    }
                }
            }
        }
    }
}

private extension DateFormatter {
    static let display: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy. MM. dd."
        return f
    }()
}
