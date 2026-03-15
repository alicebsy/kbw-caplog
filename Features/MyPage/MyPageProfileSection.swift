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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MyPageSectionHeader(title: "프로필")

            VStack(spacing: 0) {
                // 성별
                HStack(spacing: 14) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.myPageSectionGreen)
                        .frame(width: 24, alignment: .center)
                    Text("성별")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 72, alignment: .leading)
                    MyPageSegmentedChoice(
                        options: [
                            (id: "남성", title: "남성"),
                            (id: "여성", title: "여성")
                        ],
                        selection: gender?.rawValue,
                        action: { id in
                            gender = id == "남성" ? .male : .female
                        }
                    )
                    .frame(maxWidth: 140)
                    CapsuleButton(
                        title: "저장",
                        action: {
                            onSave()
                            originalGender = gender
                            originalBirthday = birthday
                        },
                        tint: .white,
                        fill: .clear,
                        fullWidth: false,
                        isEnabled: true,
                        verticalPadding: 6,
                        fontSize: 13,
                        isPrimary: true
                    )
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)

                MyPageRowDivider()

                // 생년월일
                Button {
                    tempBirthday = birthday ?? Date()
                    showPicker = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "calendar")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.myPageSectionGreen)
                            .frame(width: 24, alignment: .center)
                        Text("생년월일")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 72, alignment: .leading)
                        Text(birthday.map { DateFormatter.display.string(from: $0) } ?? "미설정")
                            .font(.system(size: 15))
                            .foregroundColor(birthday == nil ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .sectionContainer()
        .onAppear {
            originalGender = gender
            originalBirthday = birthday
        }
        .sheet(isPresented: $showPicker) {
            BirthdayPickerSheet(
                selectedDate: $tempBirthday,
                onConfirm: {
                    birthday = tempBirthday
                    showPicker = false
                    onSave()
                },
                onCancel: { showPicker = false }
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
                Spacer().frame(height: 20)
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                Spacer().frame(height: 20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("생년월일")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { onCancel() }
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { onConfirm() }
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
                onSave: { }
            )
        }
    }
    return PreviewWrapper()
}
