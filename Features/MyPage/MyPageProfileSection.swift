import SwiftUI

struct MyPageProfileSection: View {
    typealias Gender = MyPageViewModel.Gender
    @Binding var gender: Gender?
    @Binding var birthday: Date?
    @State private var showPicker = false
    var onSave: () -> Void
    var isSaveEnabled: Bool = true
    
    @State private var originalGender: Gender? = nil
    @State private var originalBirthday: Date? = nil
    @State private var tempBirthday: Date = Date()

    private let profileFieldFont = Font.system(size: 16, weight: .regular)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "프로필")

            HStack(spacing: 12) {
                Text("성별")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 90, alignment: .leading)

                HStack(spacing: 24) {
                    RadioButton(
                        isOn: {
                            if let g = gender {
                                return g == .male
                            }
                            return false
                        }(),
                        title: "남성"
                    ) {
                        print("✅ 남성 선택됨")
                        gender = .male
                    }
                    RadioButton(
                        isOn: {
                            if let g = gender {
                                return g == .female
                            }
                            return false
                        }(),
                        title: "여성"
                    ) {
                        print("✅ 여성 선택됨")
                        gender = .female
                    }
                }

                Spacer(minLength: 8)

                CapsuleButton(
                    title: "저장",
                    action: {
                        print("✅ 프로필 저장 버튼 클릭됨")
                        print("✅ 현재 성별: \(gender?.rawValue ?? "미선택")")
                        print("✅ 현재 생일: \(birthday?.description ?? "없음")")
                        onSave()
                        originalGender = gender
                        originalBirthday = birthday
                    },
                    tint: .primary,
                    fill: .white,
                    fullWidth: false,
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
                    action: {
                        tempBirthday = birthday ?? Date()
                        showPicker = true
                    },
                    tint: .primary,
                    fill: .white
                )
            }
            .animation(.none, value: birthday)
        }
        .sectionContainer()
        .onAppear {
            originalGender = gender
            originalBirthday = birthday
        }
        .onChange(of: gender) { oldValue, newValue in
            print("✅ 성별 변경됨: \(oldValue?.rawValue ?? "없음") -> \(newValue?.rawValue ?? "없음")")
        }
        .sheet(isPresented: $showPicker) {
            BirthdayPickerSheet(
                selectedDate: $tempBirthday,
                onConfirm: {
                    birthday = tempBirthday
                    showPicker = false
                },
                onCancel: {
                    showPicker = false
                }
            )
        }
    }
}

// MARK: - Birthday Picker Sheet

struct BirthdayPickerSheet: View {
    @Binding var selectedDate: Date
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 여백
                Spacer()
                    .frame(height: 20)
                
                // DatePicker
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                
                Spacer()
                    .frame(height: 20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("생년월일")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        onCancel()
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        print("✅ 생년월일 선택 완료: \(selectedDate.description)")
                        onConfirm()
                    }
                    .foregroundColor(Color.myPageActionBlue)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
    }
}

private extension DateFormatter {
    static let display: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy. MM. dd."
        return f
    }()
}

#Preview {
    struct PreviewWrapper: View {
        @State var gender: MyPageViewModel.Gender? = nil
        @State var birthday: Date? = nil
        
        var body: some View {
            MyPageProfileSection(
                gender: $gender,
                birthday: $birthday,
                onSave: {
                    print("저장됨")
                }
            )
        }
    }
    
    return PreviewWrapper()
}
